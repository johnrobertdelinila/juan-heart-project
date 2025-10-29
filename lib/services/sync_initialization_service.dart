import '../services/sync_queue_service.dart';
import '../services/appointment_sync_service.dart';
import '../services/appointment_service.dart';
import '../models/appointment_model.dart';

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
      print('ℹ️ Sync infrastructure already initialized');
      return;
    }

    print('🔧 Initializing sync infrastructure...');

    try {
      // Initialize sync queue
      await SyncQueueService().initialize();

      // Register sync executors
      _registerSyncExecutors();

      _initialized = true;
      print('✅ Sync infrastructure initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize sync infrastructure: $e');
      rethrow;
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

    print('✅ Registered ${3} sync executors');
  }

  /// Execute appointment sync operation.
  static Future<Map<String, dynamic>> _executeAppointmentSync(
    SyncOperation operation,
  ) async {
    try {
      print('🔄 Executing appointment sync: ${operation.id}');

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
        );

        print('✅ Appointment synced successfully: ${appointment.id}');
        return result;
      } else {
        // Mark as failed
        await AppointmentService.updateSyncStatus(
          appointmentId: appointment.id,
          syncStatus: 'failed',
        );

        throw Exception(result['message'] ?? 'Sync failed');
      }
    } catch (e) {
      print('❌ Appointment sync failed: $e');
      rethrow;
    }
  }

  /// Execute appointment update operation.
  static Future<Map<String, dynamic>> _executeAppointmentUpdate(
    SyncOperation operation,
  ) async {
    try {
      print('🔄 Executing appointment update: ${operation.id}');

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
        print('✅ Appointment updated successfully: ${appointment.id}');
        return result;
      } else {
        throw Exception(result['message'] ?? 'Update failed');
      }
    } catch (e) {
      print('❌ Appointment update failed: $e');
      rethrow;
    }
  }

  /// Execute appointment cancel operation.
  static Future<Map<String, dynamic>> _executeAppointmentCancel(
    SyncOperation operation,
  ) async {
    try {
      print('🔄 Executing appointment cancel: ${operation.id}');

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
        print('✅ Appointment cancelled successfully: ${appointment.id}');
        return result;
      } else {
        throw Exception(result['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      print('❌ Appointment cancellation failed: $e');
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
