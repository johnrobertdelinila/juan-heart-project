import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/appointment_service.dart';
import '../services/sync_queue_service.dart';

/// Service for migrating existing local data to backend.
///
/// Handles one-time data migration when sync functionality is first enabled.
/// Ensures existing appointments in local storage are synced to database.
class MigrationService {
  static const String _migrationCompleteKey = 'migration_appointments_v1_complete';

  /// Check if migration has already been completed.
  static Future<bool> isMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationCompleteKey) ?? false;
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return false;
    }
  }

  /// Mark migration as complete.
  static Future<void> markMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_migrationCompleteKey, true);
      debugPrint('✅ Migration marked as complete');
    } catch (e) {
      debugPrint('❌ Error marking migration complete: $e');
    }
  }

  /// Migrate existing appointments to backend.
  ///
  /// This should be called on app startup if migration hasn't been completed.
  /// Loads all local appointments and queues them for sync to backend.
  static Future<MigrationResult> migrateAppointments() async {
    debugPrint('🔄 Starting appointment migration...');

    try {
      // Check if already migrated
      if (await isMigrationComplete()) {
        debugPrint('ℹ️ Migration already completed, skipping...');
        return const MigrationResult(
          success: true,
          alreadyMigrated: true,
          totalAppointments: 0,
          queuedForSync: 0,
        );
      }

      // Get all appointments from local storage
      final appointments = await AppointmentService.getAppointments();

      if (appointments.isEmpty) {
        debugPrint('ℹ️ No appointments to migrate');
        await markMigrationComplete();
        return const MigrationResult(
          success: true,
          alreadyMigrated: false,
          totalAppointments: 0,
          queuedForSync: 0,
        );
      }

      debugPrint('📊 Found ${appointments.length} appointments to migrate');

      int queuedCount = 0;
      int skippedCount = 0;

      // Queue each appointment for sync
      for (final appointment in appointments) {
        // Skip appointments that are already synced
        if (appointment.syncStatus == 'synced' && appointment.backendId != null) {
          debugPrint('⏭️  Skipping already synced appointment: ${appointment.id}');
          skippedCount++;
          continue;
        }

        // Update sync status to pending if not already set
        if (appointment.syncStatus == null) {
          await AppointmentService.updateSyncStatus(
            appointmentId: appointment.id,
            syncStatus: 'pending',
          );
        }

        // Queue for sync
        final syncOperation = SyncOperation(
          id: appointment.id,
          type: SyncOperationType.syncAppointment,
          data: appointment.toJson(),
        );

        await SyncQueueService().addOperation(syncOperation);
        queuedCount++;

        debugPrint('✅ Queued appointment $queuedCount/${appointments.length - skippedCount}: ${appointment.id}');
      }

      // Mark migration as complete
      await markMigrationComplete();

      debugPrint('🎉 Migration completed successfully!');
      debugPrint('   Total: ${appointments.length}');
      debugPrint('   Queued: $queuedCount');
      debugPrint('   Skipped: $skippedCount');

      return MigrationResult(
        success: true,
        alreadyMigrated: false,
        totalAppointments: appointments.length,
        queuedForSync: queuedCount,
        skipped: skippedCount,
      );
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      return MigrationResult(
        success: false,
        alreadyMigrated: false,
        totalAppointments: 0,
        queuedForSync: 0,
        error: e.toString(),
      );
    }
  }

  /// Reset migration status (for testing/debugging only).
  ///
  /// WARNING: This will cause all appointments to be re-synced.
  static Future<void> resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationCompleteKey);
      debugPrint('⚠️ Migration status reset');
    } catch (e) {
      debugPrint('❌ Error resetting migration status: $e');
    }
  }
}

/// Result of migration operation.
class MigrationResult {
  final bool success;
  final bool alreadyMigrated;
  final int totalAppointments;
  final int queuedForSync;
  final int skipped;
  final String? error;

  const MigrationResult({
    required this.success,
    required this.alreadyMigrated,
    required this.totalAppointments,
    required this.queuedForSync,
    this.skipped = 0,
    this.error,
  });

  @override
  String toString() {
    if (!success) {
      return 'Migration failed: $error';
    }

    if (alreadyMigrated) {
      return 'Migration already completed';
    }

    return 'Migration successful: $queuedForSync/$totalAppointments appointments queued for sync';
  }
}
