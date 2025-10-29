import 'dart:convert';
import 'package:intl/intl.dart';
import '../core/constants/api_constants.dart';
import '../core/network/authenticated_http_client.dart';
import '../models/appointment_model.dart';

/// Service for syncing appointments to backend database.
///
/// Handles transformation of mobile Appointment model to backend format,
/// datetime conversion, enum mapping, and assessment integration.
class AppointmentSyncService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  /// Sync appointment to backend.
  ///
  /// Transforms mobile appointment format to backend API format and
  /// creates appointment record in database.
  ///
  /// Returns map with sync result:
  /// - success: bool
  /// - message: string
  /// - data: backend appointment data
  /// - backendId: int (database ID)
  static Future<Map<String, dynamic>> syncAppointmentToBackend(
    Appointment appointment,
  ) async {
    try {
      final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.appointmentsEndpoint}');

      // Transform appointment to backend format
      final payload = _transformToBackendFormat(appointment);

      print('🔄 Syncing appointment to backend...');
      print('📦 Appointment ID: ${appointment.id}');
      print('🏥 Facility: ${appointment.facilityName}');

      final response = await _httpClient.post(
        url,
        body: payload,
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final appointmentData = data['data'];

          print('✅ Appointment synced successfully!');
          print('🆔 Backend ID: ${appointmentData['id']}');

          return {
            'success': true,
            'message': 'Appointment synced successfully',
            'data': appointmentData,
            'backendId': appointmentData['id'],
          };
        }
      }

      // Handle error response
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? 'Unknown error';

      print('❌ Sync failed: $errorMessage');

      return {
        'success': false,
        'message': errorMessage,
        'error': response.body,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      print('❌ Exception during sync: $e');

      return {
        'success': false,
        'message': 'Error syncing appointment',
        'error': e.toString(),
      };
    }
  }

  /// Transform mobile appointment to backend format.
  static Map<String, dynamic> _transformToBackendFormat(Appointment appointment) {
    // Split patient name into first and last
    final nameParts = _splitName(appointment.patientName ?? 'Unknown Patient');

    // Combine date and time into datetime
    final appointmentDatetime = _combineDateTimeForBackend(
      appointment.appointmentDate,
      appointment.appointmentTime,
    );

    return {
      // Mobile tracking
      'mobile_appointment_id': appointment.id,

      // Patient information
      'patient_first_name': nameParts['firstName'],
      'patient_last_name': nameParts['lastName'],
      'patient_phone': appointment.contactNumber ?? 'N/A',
      'patient_email': null, // Not captured in mobile app currently

      // Facility (send name for backend to resolve if needed)
      'facility_id': int.tryParse(appointment.facilityId) ?? null,
      'facility_name': appointment.facilityName,

      // Doctor (optional)
      'doctor_id': null, // Mobile app doesn't select specific doctor
      'doctor_name': appointment.doctorName,

      // Appointment details
      'appointment_datetime': appointmentDatetime,
      'duration_minutes': 30,

      // Type mapping
      'appointment_type': _mapAppointmentType(appointment.type),

      // Reason for visit
      'reason_for_visit': appointment.notes ?? 'Scheduled via Juan Heart mobile app',
      'special_requirements': null,

      // Status mapping
      'status': _mapAppointmentStatus(appointment.status),

      // Assessment integration
      if (appointment.assessmentData != null) ...{
        'assessment_external_id': appointment.assessmentId,
        'assessment_id': null, // Backend will resolve by external_id
      },

      // Booking source
      'booking_source': 'mobile',

      // Mobile timestamps
      'mobile_created_at': appointment.createdAt.toIso8601String(),
    };
  }

  /// Split patient name into first and last names.
  static Map<String, String> _splitName(String fullName) {
    final trimmed = fullName.trim();

    if (trimmed.isEmpty) {
      return {'firstName': 'Unknown', 'lastName': 'Patient'};
    }

    final parts = trimmed.split(' ');

    if (parts.length == 1) {
      return {'firstName': parts[0], 'lastName': 'Patient'};
    }

    return {
      'firstName': parts[0],
      'lastName': parts.skip(1).join(' '),
    };
  }

  /// Combine date and time into ISO 8601 datetime string.
  ///
  /// Converts mobile format (DateTime + "10:00 AM") to backend format
  /// (ISO 8601 datetime string).
  static String _combineDateTimeForBackend(DateTime date, String time) {
    // Parse time string (format: "10:00 AM" or "14:30")
    final timeParts = time.split(' ');
    final hourMinuteParts = timeParts[0].split(':');

    int hour = int.parse(hourMinuteParts[0]);
    final minute = int.parse(hourMinuteParts[1]);

    // Handle AM/PM if present
    if (timeParts.length > 1) {
      final period = timeParts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    // Create datetime
    final datetime = DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    return datetime.toIso8601String();
  }

  /// Map mobile appointment type to backend enum.
  static String _mapAppointmentType(AppointmentType type) {
    switch (type) {
      case AppointmentType.consultation:
        return 'consultation';
      case AppointmentType.followUp:
        return 'follow_up';
      case AppointmentType.emergency:
        return 'emergency';
      case AppointmentType.checkup:
        return 'consultation'; // Map checkup to consultation
      case AppointmentType.screening:
        return 'screening';
    }
  }

  /// Map mobile appointment status to backend enum.
  static String _mapAppointmentStatus(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'scheduled';
      case AppointmentStatus.confirmed:
        return 'confirmed';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.cancelled:
        return 'cancelled';
      case AppointmentStatus.noShow:
        return 'no_show';
    }
  }

  /// Update appointment status on backend.
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int backendId,
    required AppointmentStatus newStatus,
    String? reason,
  }) async {
    try {
      final url = Uri.parse(
        '${APIConstant.baseUrl}${APIConstant.appointmentsEndpoint}/$backendId',
      );

      final payload = {
        'status': _mapAppointmentStatus(newStatus),
        if (reason != null) 'status_notes': reason,
      };

      final response = await _httpClient.put(url, body: payload);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Appointment status updated',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to update appointment status',
        'error': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating appointment status',
        'error': e.toString(),
      };
    }
  }

  /// Cancel appointment on backend.
  static Future<Map<String, dynamic>> cancelAppointmentOnBackend({
    required int backendId,
    required String reason,
  }) async {
    try {
      final url = Uri.parse(
        '${APIConstant.baseUrl}${APIConstant.appointmentsEndpoint}/$backendId/cancel',
      );

      final payload = {'reason': reason};

      final response = await _httpClient.post(url, body: payload);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Appointment cancelled successfully',
          'data': data['data'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to cancel appointment',
        'error': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error cancelling appointment',
        'error': e.toString(),
      };
    }
  }

  /// Reschedule appointment on backend.
  static Future<Map<String, dynamic>> rescheduleAppointmentOnBackend({
    required int backendId,
    required DateTime newDate,
    required String newTime,
    String? reason,
  }) async {
    try {
      final url = Uri.parse(
        '${APIConstant.baseUrl}${APIConstant.appointmentsEndpoint}/$backendId/reschedule',
      );

      final newDatetime = _combineDateTimeForBackend(newDate, newTime);

      final payload = {
        'new_datetime': newDatetime,
        if (reason != null) 'reason': reason,
      };

      final response = await _httpClient.post(url, body: payload);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Appointment rescheduled successfully',
          'data': data['data'],
          'backendId': data['data']['id'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to reschedule appointment',
        'error': response.body,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error rescheduling appointment',
        'error': e.toString(),
      };
    }
  }
}
