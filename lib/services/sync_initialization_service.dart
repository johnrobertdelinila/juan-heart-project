import 'package:flutter/foundation.dart';
import '../services/sync_queue_service.dart';
import '../services/appointment_sync_service.dart';
import '../services/appointment_service.dart';
import '../services/analytics_service.dart';
import '../models/appointment_model.dart';
import '../models/assessment_history_model.dart';

/// Service for initializing sync infrastructure.
///
/// Sets up sync executors, registers handlers, and prepares the sync queue
/// for background operation.
class SyncInitializationService {
  static bool _initialized = false;

  /// Initialize sync infrastructure.
  ///
  /// Call this once during app startup (in main.dart).
  /// Registers sync executors for all operation types.
  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('ℹ️ Sync infrastructure already initialized');
      return;
    }

    debugPrint('🔧 Initializing sync infrastructure...');

    try {
      // Initialize sync queue
      await SyncQueueService().initialize();

      // Register sync executors
      _registerSyncExecutors();

      // Queue any unsynced assessments from local storage
      await _queueUnsyncedAssessments();

      _initialized = true;
      debugPrint('✅ Sync infrastructure initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize sync infrastructure: $e');
      rethrow;
    }
  }

  /// Queue unsynced assessments for background sync
  ///
  /// Loads assessment history from local storage and queues any that
  /// haven't been synced to the backend yet.
  static Future<void> _queueUnsyncedAssessments() async {
    try {
      debugPrint('🔄 Checking for unsynced assessments...');

      // Get all assessments from local storage
      final assessments = await AnalyticsService.getAssessmentHistory();

      if (assessments.isEmpty) {
        debugPrint('📊 No assessments found in local storage');
        return;
      }

      final syncQueue = SyncQueueService();
      int queuedCount = 0;

      // Queue each assessment for sync
      // Note: Since SharedPreferences doesn't track sync status,
      // we queue all assessments and let the sync executor handle duplicates
      for (final assessment in assessments) {
        try {
          await syncQueue.addOperation(
            SyncOperation(
              id: 'assessment_sync_${assessment.id}_startup',
              type: SyncOperationType.syncAssessment,
              data: assessment.toJson(),
            ),
          );
          queuedCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to queue assessment ${assessment.id}: $e');
        }
      }

      debugPrint('✅ Queued $queuedCount/${assessments.length} assessments for sync');

      // Trigger queue processing if we have items
      if (queuedCount > 0) {
        debugPrint('🚀 Triggering sync queue processing...');
        syncQueue.processQueue();
      }
    } catch (e) {
      debugPrint('❌ Failed to queue unsynced assessments: $e');
      // Don't rethrow - sync infrastructure should still initialize
    }
  }

  /// Register sync executors for each operation type.
  static void _registerSyncExecutors() {
    final syncQueue = SyncQueueService();

    // Register appointment sync executor
    syncQueue.registerExecutor(
      SyncOperationType.syncAppointment,
      _executeAppointmentSync,
    );

    // Register appointment update executor
    syncQueue.registerExecutor(
      SyncOperationType.updateAppointment,
      _executeAppointmentUpdate,
    );

    // Register appointment cancel executor
    syncQueue.registerExecutor(
      SyncOperationType.cancelAppointment,
      _executeAppointmentCancel,
    );

    debugPrint('✅ Registered ${3} sync executors');
  }

  /// Execute appointment sync operation.
  static Future<Map<String, dynamic>> _executeAppointmentSync(
    SyncOperation operation,
  ) async {
    try {
      debugPrint('🔄 Executing appointment sync: ${operation.id}');

      // Reconstruct appointment from operation data
      final appointment = Appointment.fromJson(operation.data);

      // Sync to backend
      final result = await AppointmentSyncService.syncAppointmentToBackend(
        appointment,
      );

      if (result['success'] == true) {
        // Update local appointment with backend ID and sync status
        await AppointmentService.updateSyncStatus(
          appointmentId: appointment.id,
          syncStatus: 'synced',
          backendId: result['backendId'] as int?,
          syncErrorMessage: null, // Clear any previous error
        );

        debugPrint('✅ Appointment synced successfully: ${appointment.id}');
        return result;
      } else {
        // Mark as failed with error details
        await AppointmentService.updateSyncStatus(
          appointmentId: appointment.id,
          syncStatus: 'failed',
          syncErrorMessage: result['message'] ?? 'Sync failed',
        );

        throw Exception(result['message'] ?? 'Sync failed');
      }
    } catch (e) {
      debugPrint('❌ Appointment sync failed: $e');
      rethrow;
    }
  }

  /// Execute appointment update operation.
  static Future<Map<String, dynamic>> _executeAppointmentUpdate(
    SyncOperation operation,
  ) async {
    try {
      debugPrint('🔄 Executing appointment update: ${operation.id}');

      final appointment = Appointment.fromJson(operation.data);

      // Check if appointment has backend ID
      if (appointment.backendId == null) {
        throw Exception('Cannot update appointment without backend ID');
      }

      // Update on backend
      final result = await AppointmentSyncService.updateAppointmentStatus(
        backendId: appointment.backendId!,
        newStatus: appointment.status,
      );

      if (result['success'] == true) {
        debugPrint('✅ Appointment updated successfully: ${appointment.id}');
        return result;
      } else {
        throw Exception(result['message'] ?? 'Update failed');
      }
    } catch (e) {
      debugPrint('❌ Appointment update failed: $e');
      rethrow;
    }
  }

  /// Execute appointment cancel operation.
  static Future<Map<String, dynamic>> _executeAppointmentCancel(
    SyncOperation operation,
  ) async {
    try {
      debugPrint('🔄 Executing appointment cancel: ${operation.id}');

      final appointment = Appointment.fromJson(operation.data);
      final reason = operation.data['cancellation_reason'] as String? ?? 'Cancelled by user';

      // Check if appointment has backend ID
      if (appointment.backendId == null) {
        throw Exception('Cannot cancel appointment without backend ID');
      }

      // Cancel on backend
      final result = await AppointmentSyncService.cancelAppointmentOnBackend(
        backendId: appointment.backendId!,
        reason: reason,
      );

      if (result['success'] == true) {
        debugPrint('✅ Appointment cancelled successfully: ${appointment.id}');
        return result;
      } else {
        throw Exception(result['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      debugPrint('❌ Appointment cancellation failed: $e');
      rethrow;
    }
  }

  /// Check if sync infrastructure is initialized.
  static bool isInitialized() => _initialized;

  /// Get current sync queue status.
  static Map<String, dynamic> getSyncStatus() {
    if (!_initialized) {
      return {'initialized': false};
    }

    final queueStatus = SyncQueueService().getQueueStatus();
    return {
      'initialized': true,
      ...queueStatus,
    };
  }
}
