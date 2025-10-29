import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/appointment_service.dart';

/// Service for validating appointment booking requests
class AppointmentValidationService {
  /// Validate appointment booking request
  /// Returns null if valid, otherwise returns error message
  static Future<String?> validateBooking({
    required String facilityId,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? doctorName,
    AppointmentType? appointmentType,
  }) async {
    // 1. Validate date is not in the past
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDay = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
    );

    if (appointmentDay.isBefore(today)) {
      return 'Cannot book appointments in the past';
    }

    // 2. Validate booking is not too far in the future (max 90 days)
    final maxFutureDate = today.add(const Duration(days: 90));
    if (appointmentDay.isAfter(maxFutureDate)) {
      return 'Cannot book appointments more than 90 days in advance';
    }

    // 3. Validate time slot is valid
    if (!_isValidTimeSlot(appointmentTime)) {
      return 'Invalid time slot. Must be between 8:00 AM and 5:00 PM';
    }

    // 4. Check if time slot is available
    final isAvailable = await AppointmentService.isTimeSlotAvailable(
      facilityId,
      appointmentDate,
      appointmentTime,
    );

    if (!isAvailable) {
      return 'This time slot is already booked. Please choose another time';
    }

    // 5. Validate no duplicate appointments on same day
    final hasDuplicateOnSameDay = await _checkDuplicateAppointmentOnSameDay(
      facilityId,
      appointmentDate,
    );

    if (hasDuplicateOnSameDay) {
      return 'You already have an appointment at this facility on this day';
    }

    // 6. Validate maximum appointments per day (limit: 3)
    final appointmentCount = await _getAppointmentCountForDay(appointmentDate);
    if (appointmentCount >= 3) {
      return 'Maximum 3 appointments allowed per day';
    }

    // 7. Validate minimum time between appointments (2 hours)
    final hasConflictingTime = await _checkTimeConflict(
      appointmentDate,
      appointmentTime,
    );

    if (hasConflictingTime) {
      return 'Another appointment within 2 hours of this time. Please choose a different time';
    }

    // 8. Validate emergency appointments
    if (appointmentType == AppointmentType.emergency) {
      // Emergency appointments can only be booked for today or tomorrow
      final maxEmergencyDate = today.add(const Duration(days: 1));
      if (appointmentDay.isAfter(maxEmergencyDate)) {
        return 'Emergency appointments can only be booked for today or tomorrow';
      }
    }

    // All validations passed
    return null;
  }

  /// Validate appointment cancellation
  static String? validateCancellation({
    required Appointment appointment,
  }) {
    // 1. Check if appointment is already cancelled
    if (appointment.status == AppointmentStatus.cancelled) {
      return 'This appointment is already cancelled';
    }

    // 2. Check if appointment is already completed
    if (appointment.status == AppointmentStatus.completed) {
      return 'Cannot cancel a completed appointment';
    }

    // 3. Check if appointment is in the past
    final now = DateTime.now();
    if (appointment.appointmentDate.isBefore(now)) {
      return 'Cannot cancel past appointments';
    }

    // 4. Check if cancellation is too close to appointment time (less than 2 hours)
    final appointmentDateTime = _parseAppointmentDateTime(
      appointment.appointmentDate,
      appointment.appointmentTime,
    );

    final hoursUntilAppointment = appointmentDateTime.difference(now).inHours;
    if (hoursUntilAppointment < 2) {
      return 'Cannot cancel appointments less than 2 hours before scheduled time';
    }

    // All validations passed
    return null;
  }

  /// Validate appointment rescheduling
  static Future<String?> validateReschedule({
    required Appointment appointment,
    required DateTime newDate,
    required String newTime,
  }) async {
    // 1. Check if appointment can be cancelled (reuses cancellation validation)
    final cancellationError = validateCancellation(appointment: appointment);
    if (cancellationError != null) {
      return cancellationError;
    }

    // 2. Validate new date and time using booking validation
    return await validateBooking(
      facilityId: appointment.facilityId,
      appointmentDate: newDate,
      appointmentTime: newTime,
      doctorName: appointment.doctorName,
      appointmentType: appointment.type,
    );
  }

  /// Check if time slot is within valid operating hours
  static bool _isValidTimeSlot(String timeSlot) {
    final validSlots = [
      '08:00 AM', '08:30 AM', '09:00 AM', '09:30 AM',
      '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
      '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
      '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM',
      '04:00 PM', '04:30 PM', '05:00 PM',
    ];

    return validSlots.contains(timeSlot);
  }

  /// Check if user already has an appointment at this facility on this day
  static Future<bool> _checkDuplicateAppointmentOnSameDay(
    String facilityId,
    DateTime date,
  ) async {
    final appointments = await AppointmentService.getAppointments();

    final duplicates = appointments.where((apt) =>
        apt.facilityId == facilityId &&
        apt.appointmentDate.year == date.year &&
        apt.appointmentDate.month == date.month &&
        apt.appointmentDate.day == date.day &&
        apt.status != AppointmentStatus.cancelled);

    return duplicates.isNotEmpty;
  }

  /// Get count of appointments for a specific day
  static Future<int> _getAppointmentCountForDay(DateTime date) async {
    final appointments = await AppointmentService.getAppointments();

    final dayAppointments = appointments.where((apt) =>
        apt.appointmentDate.year == date.year &&
        apt.appointmentDate.month == date.month &&
        apt.appointmentDate.day == date.day &&
        apt.status != AppointmentStatus.cancelled);

    return dayAppointments.length;
  }

  /// Check if there's a time conflict (appointments within 2 hours)
  static Future<bool> _checkTimeConflict(
    DateTime date,
    String timeSlot,
  ) async {
    final appointments = await AppointmentService.getAppointments();

    // Get appointments on the same day
    final dayAppointments = appointments.where((apt) =>
        apt.appointmentDate.year == date.year &&
        apt.appointmentDate.month == date.month &&
        apt.appointmentDate.day == date.day &&
        apt.status != AppointmentStatus.cancelled);

    // Parse the requested time
    final requestedTime = _parseAppointmentDateTime(date, timeSlot);

    // Check each appointment for time conflicts
    for (final apt in dayAppointments) {
      final existingTime = _parseAppointmentDateTime(
        apt.appointmentDate,
        apt.appointmentTime,
      );

      final timeDifference = requestedTime.difference(existingTime).abs();

      // If appointments are within 2 hours of each other, there's a conflict
      if (timeDifference.inMinutes < 120) {
        return true;
      }
    }

    return false;
  }

  /// Parse appointment date and time into a DateTime object
  static DateTime _parseAppointmentDateTime(DateTime date, String timeSlot) {
    // Parse time slot (e.g., "10:00 AM" -> hour: 10, minute: 0)
    final parts = timeSlot.split(' ');
    final timeParts = parts[0].split(':');
    final isPM = parts[1] == 'PM';

    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }

  /// Get user-friendly validation summary
  static String getValidationSummary() {
    return '''
Appointment Booking Rules:
• Appointments can be booked up to 90 days in advance
• Cannot book appointments in the past
• Time slots available: 8:00 AM - 5:00 PM (30-minute intervals)
• Maximum 3 appointments per day
• Minimum 2 hours between appointments
• One appointment per facility per day
• Emergency appointments: Today or tomorrow only
• Cancellation: At least 2 hours before appointment time
''';
  }

  /// Validate appointment data completeness
  static String? validateAppointmentData({
    required String facilityId,
    required String facilityName,
    required String doctorName,
    required DateTime appointmentDate,
    required String appointmentTime,
    required AppointmentType type,
    String? patientName,
    String? patientPhone,
  }) {
    if (facilityId.isEmpty) {
      return 'Facility is required';
    }

    if (facilityName.isEmpty) {
      return 'Facility name is required';
    }

    if (doctorName.isEmpty) {
      return 'Doctor name is required';
    }

    if (appointmentTime.isEmpty) {
      return 'Appointment time is required';
    }

    if (patientName != null && patientName.isEmpty) {
      return 'Patient name cannot be empty';
    }

    if (patientPhone != null && patientPhone.isNotEmpty) {
      // Basic phone number validation (Philippine format)
      final phoneRegex = RegExp(r'^(\+63|0)[0-9]{10}$');
      if (!phoneRegex.hasMatch(patientPhone)) {
        return 'Invalid phone number format. Use +639XXXXXXXXX or 09XXXXXXXXX';
      }
    }

    return null;
  }
}
