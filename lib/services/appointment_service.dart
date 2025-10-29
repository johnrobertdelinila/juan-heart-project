import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/appointment_notification_service.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/services/appointment_sync_service.dart';

/// Service for managing appointments with local storage and backend sync
class AppointmentService {
  static const String _storageKey = 'juan_heart_appointments';

  /// Get all appointments from storage
  static Future<List<Appointment>> getAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading appointments: $e');
      return [];
    }
  }

  /// Save a new appointment
  static Future<bool> saveAppointment(Appointment appointment) async {
    try {
      final appointments = await getAppointments();

      // Check for duplicate IDs
      if (appointments.any((apt) => apt.id == appointment.id)) {
        print('⚠️ Appointment with ID ${appointment.id} already exists');
        return false;
      }

      // Set initial sync status
      final appointmentWithSyncStatus = appointment.copyWith(
        syncStatus: 'pending',
        createdAt: appointment.createdAt,
      );

      appointments.add(appointmentWithSyncStatus);
      await _saveAppointmentsList(appointments);

      // Schedule notification reminders
      try {
        await AppointmentNotificationService().scheduleAppointmentReminders(appointmentWithSyncStatus);
        print('✅ Notification reminders scheduled for: ${appointment.id}');
      } catch (e) {
        print('⚠️ Failed to schedule notifications: $e');
        // Don't fail the whole operation if notifications fail
      }

      // Add to sync queue for backend sync (non-blocking)
      _queueAppointmentSync(appointmentWithSyncStatus);

      print('✅ Appointment saved locally: ${appointment.id}');
      return true;
    } catch (e) {
      print('❌ Error saving appointment: $e');
      return false;
    }
  }

  /// Queue appointment for backend sync
  static void _queueAppointmentSync(Appointment appointment) {
    try {
      final syncOperation = SyncOperation(
        id: appointment.id,
        type: SyncOperationType.syncAppointment,
        data: appointment.toJson(),
      );

      SyncQueueService().addOperation(syncOperation);
      print('📤 Appointment queued for sync: ${appointment.id}');
    } catch (e) {
      print('⚠️ Failed to queue appointment sync: $e');
      // Don't fail the operation - appointment is saved locally
    }
  }

  /// Update an existing appointment
  static Future<bool> updateAppointment(Appointment updatedAppointment) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == updatedAppointment.id);

      if (index == -1) {
        print('⚠️ Appointment not found: ${updatedAppointment.id}');
        return false;
      }

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      print('✅ Appointment updated: ${updatedAppointment.id}');
      return true;
    } catch (e) {
      print('❌ Error updating appointment: $e');
      return false;
    }
  }

  /// Delete an appointment
  static Future<bool> deleteAppointment(String appointmentId) async {
    try {
      final appointments = await getAppointments();
      final initialLength = appointments.length;

      appointments.removeWhere((apt) => apt.id == appointmentId);

      if (appointments.length == initialLength) {
        print('⚠️ Appointment not found: $appointmentId');
        return false;
      }

      await _saveAppointmentsList(appointments);

      // Cancel notification reminders
      try {
        await AppointmentNotificationService().cancelAppointmentReminders(appointmentId);
        print('✅ Notification reminders cancelled for: $appointmentId');
      } catch (e) {
        print('⚠️ Failed to cancel notifications: $e');
      }

      print('✅ Appointment deleted: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error deleting appointment: $e');
      return false;
    }
  }

  /// Get appointments by status
  static Future<List<Appointment>> getAppointmentsByStatus(AppointmentStatus status) async {
    final appointments = await getAppointments();
    return appointments.where((apt) => apt.status == status).toList();
  }

  /// Get upcoming appointments (pending or confirmed, future dates)
  static Future<List<Appointment>> getUpcomingAppointments() async {
    final appointments = await getAppointments();
    return appointments
        .where((apt) => apt.isUpcoming)
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
  }

  /// Get past appointments
  static Future<List<Appointment>> getPastAppointments() async {
    final appointments = await getAppointments();
    final now = DateTime.now();
    return appointments
        .where((apt) => apt.appointmentDate.isBefore(now))
        .toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
  }

  /// Get today's appointments
  static Future<List<Appointment>> getTodayAppointments() async {
    final appointments = await getAppointments();
    return appointments
        .where((apt) => apt.isToday)
        .toList()
      ..sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
  }

  /// Cancel an appointment
  static Future<bool> cancelAppointment(String appointmentId, {String? reason}) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);

      if (index == -1) {
        return false;
      }

      final updatedAppointment = appointments[index].copyWith(
        status: AppointmentStatus.cancelled,
        notes: reason != null
            ? '${appointments[index].notes ?? ''}\nCancelled: $reason'
            : appointments[index].notes,
      );

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      // Cancel notification reminders
      try {
        await AppointmentNotificationService().cancelAppointmentReminders(appointmentId);
        print('✅ Notification reminders cancelled for: $appointmentId');
      } catch (e) {
        print('⚠️ Failed to cancel notifications: $e');
      }

      print('✅ Appointment cancelled: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      return false;
    }
  }

  /// Reschedule an appointment
  static Future<bool> rescheduleAppointment(
    String appointmentId,
    DateTime newDate,
    String newTime,
  ) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);

      if (index == -1) {
        return false;
      }

      final updatedAppointment = appointments[index].copyWith(
        appointmentDate: newDate,
        appointmentTime: newTime,
        status: AppointmentStatus.pending, // Reset to pending after reschedule
      );

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      // Reschedule notification reminders (cancel old, schedule new)
      try {
        await AppointmentNotificationService().rescheduleAppointmentReminders(updatedAppointment);
        print('✅ Notification reminders rescheduled for: $appointmentId');
      } catch (e) {
        print('⚠️ Failed to reschedule notifications: $e');
      }

      print('✅ Appointment rescheduled: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error rescheduling appointment: $e');
      return false;
    }
  }

  /// Get appointment statistics
  static Future<Map<String, int>> getAppointmentStats() async {
    final appointments = await getAppointments();

    return {
      'total': appointments.length,
      'upcoming': appointments.where((apt) => apt.isUpcoming).length,
      'completed': appointments
          .where((apt) => apt.status == AppointmentStatus.completed)
          .length,
      'cancelled': appointments
          .where((apt) => apt.status == AppointmentStatus.cancelled)
          .length,
      'today': appointments.where((apt) => apt.isToday).length,
    };
  }

  /// Check if time slot is available for a facility
  static Future<bool> isTimeSlotAvailable(
    String facilityId,
    DateTime date,
    String time,
  ) async {
    final appointments = await getAppointments();

    // Check if any appointment exists for this facility, date, and time
    final conflictExists = appointments.any((apt) =>
        apt.facilityId == facilityId &&
        apt.appointmentDate.year == date.year &&
        apt.appointmentDate.month == date.month &&
        apt.appointmentDate.day == date.day &&
        apt.appointmentTime == time &&
        apt.status != AppointmentStatus.cancelled);

    return !conflictExists;
  }

  /// Get available time slots for a date
  static Future<List<TimeSlot>> getAvailableTimeSlots(
    String facilityId,
    DateTime date,
  ) async {
    // Generate time slots from 8 AM to 5 PM
    final List<String> allTimeSlots = [
      '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM',
      '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
      '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
      '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
      '04:00 PM', '04:30 PM', '05:00 PM',
    ];

    final appointments = await getAppointments();
    final now = DateTime.now();
    final isToday = date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;

    // Get booked time slots for this facility and date
    final bookedSlots = appointments
        .where((apt) =>
            apt.facilityId == facilityId &&
            apt.appointmentDate.year == date.year &&
            apt.appointmentDate.month == date.month &&
            apt.appointmentDate.day == date.day &&
            apt.status != AppointmentStatus.cancelled)
        .map((apt) => apt.appointmentTime)
        .toSet();

    // Return time slots with availability status
    return allTimeSlots.map((time) {
      bool isPast = false;

      // Check if time slot is in the past (only for today's date)
      if (isToday) {
        final slotDateTime = _parseTimeSlotToDateTime(date, time);
        isPast = slotDateTime.isBefore(now);
      }

      return TimeSlot(
        time: time,
        isAvailable: !bookedSlots.contains(time) && !isPast,
      );
    }).toList();
  }

  /// Helper: Parse time slot string to DateTime
  static DateTime _parseTimeSlotToDateTime(DateTime date, String timeSlot) {
    // Parse "08:00 AM" format
    final parts = timeSlot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final period = parts[1];

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Clear all appointments (for testing/debugging)
  static Future<bool> clearAllAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('✅ All appointments cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing appointments: $e');
      return false;
    }
  }

  /// Private helper to save appointments list
  static Future<void> _saveAppointmentsList(List<Appointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = appointments.map((apt) => apt.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Get appointments count
  static Future<int> getAppointmentsCount() async {
    final appointments = await getAppointments();
    return appointments.length;
  }

  /// Get next upcoming appointment
  static Future<Appointment?> getNextUpcomingAppointment() async {
    final upcomingAppointments = await getUpcomingAppointments();
    return upcomingAppointments.isNotEmpty ? upcomingAppointments.first : null;
  }

  /// Mark appointment as completed
  static Future<bool> markAsCompleted(String appointmentId) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);

      if (index == -1) {
        return false;
      }

      final updatedAppointment = appointments[index].copyWith(
        status: AppointmentStatus.completed,
      );

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      print('✅ Appointment marked as completed: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error marking appointment as completed: $e');
      return false;
    }
  }

  /// Confirm appointment
  static Future<bool> confirmAppointment(String appointmentId) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);

      if (index == -1) {
        return false;
      }

      final updatedAppointment = appointments[index].copyWith(
        status: AppointmentStatus.confirmed,
      );

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      print('✅ Appointment confirmed: $appointmentId');
      return true;
    } catch (e) {
      print('❌ Error confirming appointment: $e');
      return false;
    }
  }

  /// Update appointment sync status
  static Future<bool> updateSyncStatus({
    required String appointmentId,
    required String syncStatus,
    int? backendId,
  }) async {
    try {
      final appointments = await getAppointments();
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);

      if (index == -1) {
        print('⚠️ Appointment not found for sync status update: $appointmentId');
        return false;
      }

      final updatedAppointment = appointments[index].copyWith(
        syncStatus: syncStatus,
        backendId: backendId ?? appointments[index].backendId,
        lastSyncedAt: syncStatus == 'synced' ? DateTime.now() : null,
      );

      appointments[index] = updatedAppointment;
      await _saveAppointmentsList(appointments);

      print('✅ Sync status updated for $appointmentId: $syncStatus');
      return true;
    } catch (e) {
      print('❌ Error updating sync status: $e');
      return false;
    }
  }

  /// Get appointments that need sync
  static Future<List<Appointment>> getUnsyncedAppointments() async {
    final appointments = await getAppointments();
    return appointments
        .where((apt) => apt.syncStatus == 'pending' || apt.syncStatus == 'failed')
        .toList();
  }

  /// Get sync statistics
  static Future<Map<String, int>> getSyncStats() async {
    final appointments = await getAppointments();

    return {
      'synced': appointments.where((apt) => apt.syncStatus == 'synced').length,
      'pending': appointments.where((apt) => apt.syncStatus == 'pending').length,
      'failed': appointments.where((apt) => apt.syncStatus == 'failed').length,
      'not_synced': appointments.where((apt) => apt.syncStatus == null).length,
    };
  }
}
