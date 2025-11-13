import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/authenticated_http_client.dart';
import '../models/appointment_model.dart';
import 'crash_reporting_service.dart';

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

      debugPrint('🔄 Syncing appointment to backend...');
      debugPrint('📦 Appointment ID: ${appointment.id}');
      debugPrint('🏥 Facility: ${appointment.facilityName}');
      debugPrint('🆔 Mobile Facility ID: ${appointment.facilityId}');
      debugPrint('🔢 Backend Facility ID: ${payload['facility_id']}');
      if (payload['facility_id'] == null) {
        debugPrint('⚠️ WARNING: No backend ID mapping! Backend will try facility_name lookup.');
      }

      final response = await _httpClient.post(
        url,
        body: payload,
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final appointmentData = data['data'];

          debugPrint('✅ Appointment synced successfully!');
          debugPrint('🆔 Backend ID: ${appointmentData['id']}');

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
      final backendMessage = errorData['message'] ?? 'Unknown error';
      final errorInfo = categorizeError(backendMessage, statusCode: response.statusCode);

      debugPrint('❌ Sync failed (${errorInfo['category']}): ${errorInfo['userMessage']}');
      debugPrint('📋 Technical details: ${errorInfo['technicalDetails']}');

      return {
        'success': false,
        'message': errorInfo['userMessage'],
        'category': errorInfo['category'],
        'technicalDetails': errorInfo['technicalDetails'],
        'statusCode': response.statusCode,
      };
    } catch (e, stackTrace) {
      final errorInfo = categorizeError(e);

      debugPrint('❌ Exception during sync (${errorInfo['category']}): ${errorInfo['userMessage']}');
      debugPrint('📋 Technical details: ${errorInfo['technicalDetails']}');

      // Report to Crashlytics
      await CrashReportingService.instance.logError(
        error: e,
        stackTrace: stackTrace,
        reason: 'Appointment sync failed',
        fatal: false,
        additionalInfo: {
          'appointment_id': appointment.id,
          'facility_name': appointment.facilityName,
          'error_category': errorInfo['category'],
        },
      );

      return {
        'success': false,
        'message': errorInfo['userMessage'],
        'category': errorInfo['category'],
        'technicalDetails': errorInfo['technicalDetails'],
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

    // Map facility name to backend ID (critical for sync)
    final backendFacilityId = _mapFacilityNameToBackendId(appointment.facilityName);

    return {
      // Mobile tracking
      'mobile_appointment_id': appointment.id,

      // Patient information
      'patient_first_name': nameParts['firstName'],
      'patient_last_name': nameParts['lastName'],
      'patient_phone': appointment.contactNumber ?? 'N/A',
      'patient_email': null, // Not captured in mobile app currently

      // Facility - use backend ID mapping for known facilities
      'facility_id': backendFacilityId,
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

  /// Map mobile facility name to backend facility ID.
  ///
  /// This is a critical mapping layer that translates mock facility names
  /// to actual backend database IDs. Required because mobile app uses
  /// 50 mock facilities while backend has only 5 seeded facilities.
  ///
  /// Backend facilities (from HealthcareFacilitySeeder.php):
  /// 1. Philippine Heart Center (ID: 1)
  /// 2. Philippine General Hospital (ID: 2)
  /// 3. Vicente Sotto Memorial Medical Center (ID: 3)
  /// 4. Southern Philippines Medical Center (ID: 4)
  /// 5. Quezon City General Hospital (ID: 5)
  ///
  /// Returns backend ID if match found, null otherwise.
  /// If null, backend will attempt facility_name lookup (may fail).
  static int? _mapFacilityNameToBackendId(String facilityName) {
    final nameLower = facilityName.trim().toLowerCase();

    // Map known facilities to backend IDs
    if (nameLower.contains('philippine heart center')) {
      return 1;
    } else if (nameLower.contains('philippine general hospital')) {
      return 2;
    } else if (nameLower.contains('vicente sotto')) {
      return 3;
    } else if (nameLower.contains('southern philippines medical')) {
      return 4;
    } else if (nameLower.contains('quezon city general')) {
      return 5;
    }

    // No mapping found - backend will try facility_name lookup
    debugPrint('⚠️ No backend ID mapping for facility: $facilityName');
    debugPrint('📋 Backend will attempt facility_name lookup (may fail)');
    return null;
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
    } catch (e, stackTrace) {
      // Report to Crashlytics
      await CrashReportingService.instance.logError(
        error: e,
        stackTrace: stackTrace,
        reason: 'Appointment status update failed',
        fatal: false,
        additionalInfo: {
          'backend_id': backendId,
          'new_status': newStatus.toString(),
        },
      );

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
    } catch (e, stackTrace) {
      // Report to Crashlytics
      await CrashReportingService.instance.logError(
        error: e,
        stackTrace: stackTrace,
        reason: 'Appointment cancellation failed',
        fatal: false,
        additionalInfo: {
          'backend_id': backendId,
          'cancellation_reason': reason,
        },
      );

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
    } catch (e, stackTrace) {
      // Report to Crashlytics
      await CrashReportingService.instance.logError(
        error: e,
        stackTrace: stackTrace,
        reason: 'Appointment reschedule failed',
        fatal: false,
        additionalInfo: {
          'backend_id': backendId,
          'new_date': newDate.toIso8601String(),
          'new_time': newTime,
        },
      );

      return {
        'success': false,
        'message': 'Error rescheduling appointment',
        'error': e.toString(),
      };
    }
  }

  /// Categorize sync error and return user-friendly message.
  ///
  /// Takes error object/message and HTTP status code (if available)
  /// and returns structured error information for display and logging.
  static Map<String, dynamic> categorizeError(dynamic error, {int? statusCode}) {
    String category;
    String userMessage;
    String technicalDetails;

    // Categorize based on status code
    if (statusCode != null) {
      switch (statusCode) {
        case 401:
          category = 'authentication';
          userMessage = 'Authentication failed. Please try again.';
          technicalDetails = 'HTTP 401: Unauthorized access to backend API';
          break;
        case 404:
          category = 'not_found';
          userMessage = 'Facility or doctor not found in system.';
          technicalDetails = 'HTTP 404: Resource not found on backend';
          break;
        case 422:
          category = 'validation';
          userMessage = 'Invalid appointment data. Please check your information.';
          technicalDetails = 'HTTP 422: Validation error from backend';
          break;
        case 500:
        case 502:
        case 503:
          category = 'server_error';
          userMessage = 'Backend server error. Please try again later.';
          technicalDetails = 'HTTP $statusCode: Backend server error';
          break;
        default:
          category = 'unknown';
          userMessage = 'An unexpected error occurred (Code: $statusCode).';
          technicalDetails = 'HTTP $statusCode: Unknown error';
      }
    }
    // Categorize based on error content
    else {
      final errorString = error.toString().toLowerCase();

      if (errorString.contains('connection refused') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network unreachable')) {
        category = 'connection';
        userMessage = 'Cannot connect to backend. Please check your network.';
        technicalDetails = 'Connection refused or network unreachable';
      } else if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        category = 'timeout';
        userMessage = 'Request timed out. Please try again.';
        technicalDetails = 'Request exceeded 15-second timeout';
      } else if (errorString.contains('no connection') ||
          errorString.contains('offline')) {
        category = 'offline';
        userMessage = 'No internet connection. Will retry when online.';
        technicalDetails = 'Device is offline';
      } else if (errorString.contains('format') ||
          errorString.contains('parsing') ||
          errorString.contains('json')) {
        category = 'data_format';
        userMessage = 'Invalid data format received from backend.';
        technicalDetails = 'JSON parsing or format error';
      } else {
        category = 'unknown';
        userMessage = 'An unexpected error occurred. Please try again.';
        technicalDetails = error.toString();
      }
    }

    return {
      'category': category,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
