import 'package:flutter/material.dart';

/// Model representing a healthcare appointment
class Appointment {
  final String id;
  final String facilityId;
  final String facilityName;
  final String doctorName;
  final DateTime appointmentDate;
  final String appointmentTime; // Format: "10:00 AM"
  final AppointmentStatus status;
  final AppointmentType type;
  final String? notes;
  final String? patientName;
  final String? contactNumber;

  // Related assessment data
  final String? assessmentId;
  final int? riskScore;
  final String? riskCategory;
  final Map<String, dynamic>? assessmentData; // NEW: Full assessment data for doctor review

  // Pre-consultation questionnaire status
  final String? questionnaireStatus; // null, "draft", "submitted", "reviewed"

  // Backend sync tracking
  final int? backendId; // Database ID from backend
  final String? syncStatus; // 'synced', 'pending', 'failed'
  final DateTime? lastSyncedAt;
  final DateTime createdAt; // When appointment was created locally

  Appointment({
    required this.id,
    required this.facilityId,
    required this.facilityName,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    required this.type,
    this.notes,
    this.patientName,
    this.contactNumber,
    this.assessmentId,
    this.riskScore,
    this.riskCategory,
    this.assessmentData,
    this.questionnaireStatus,
    this.backendId,
    this.syncStatus,
    this.lastSyncedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get appointment status color
  Color getStatusColor() {
    switch (status) {
      case AppointmentStatus.pending:
        return const Color(0xFFFFA500); // Orange
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50); // Green
      case AppointmentStatus.completed:
        return const Color(0xFF2196F3); // Blue
      case AppointmentStatus.cancelled:
        return const Color(0xFFF44336); // Red
      case AppointmentStatus.noShow:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get appointment status icon
  IconData getStatusIcon() {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.noShow:
        return Icons.person_off;
    }
  }

  /// Get appointment status display text
  String getStatusText(String languageCode) {
    if (languageCode == 'fil') {
      switch (status) {
        case AppointmentStatus.pending:
          return 'Naghihintay';
        case AppointmentStatus.confirmed:
          return 'Nakumpirma';
        case AppointmentStatus.completed:
          return 'Tapos Na';
        case AppointmentStatus.cancelled:
          return 'Kinansela';
        case AppointmentStatus.noShow:
          return 'Hindi Dumating';
      }
    }
    return status.toString().split('.').last.toUpperCase();
  }

  /// Get appointment type display text
  String getTypeText(String languageCode) {
    if (languageCode == 'fil') {
      switch (type) {
        case AppointmentType.consultation:
          return 'Konsultasyon';
        case AppointmentType.followUp:
          return 'Follow-up';
        case AppointmentType.emergency:
          return 'Emergency';
        case AppointmentType.checkup:
          return 'Checkup';
        case AppointmentType.screening:
          return 'Screening';
      }
    }
    return type.toString().split('.').last;
  }

  /// Check if appointment is upcoming
  bool get isUpcoming {
    if (status == AppointmentStatus.cancelled ||
        status == AppointmentStatus.completed ||
        status == AppointmentStatus.noShow) {
      return false;
    }
    return appointmentDate.isAfter(DateTime.now());
  }

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
           appointmentDate.month == now.month &&
           appointmentDate.day == now.day;
  }

  /// Check if questionnaire needs to be filled
  bool get needsQuestionnaire {
    return isUpcoming &&
           (questionnaireStatus == null || questionnaireStatus == 'draft');
  }

  /// Check if questionnaire is completed
  bool get hasCompletedQuestionnaire {
    return questionnaireStatus == 'submitted' || questionnaireStatus == 'reviewed';
  }

  /// Check if patient can join waiting room
  /// (Appointment is today and starts within 30 minutes)
  bool canJoinWaitingRoom() {
    if (!isToday ||
        status == AppointmentStatus.cancelled ||
        status == AppointmentStatus.completed) {
      return false;
    }

    // Parse appointment time (format: "10:00 AM")
    try {
      final timeParts = appointmentTime.split(' ');
      final hourMin = timeParts[0].split(':');
      int hour = int.parse(hourMin[0]);
      final minute = int.parse(hourMin[1]);

      // Convert to 24-hour format
      if (timeParts[1].toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (timeParts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      final appointmentDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );

      final now = DateTime.now();
      final difference = appointmentDateTime.difference(now);

      // Allow joining 30 minutes before and up to 2 hours after appointment time
      return difference.inMinutes <= 30 && difference.inMinutes >= -120;
    } catch (e) {
      return false;
    }
  }

  /// Get questionnaire status badge text
  String getQuestionnaireStatusText(String languageCode) {
    if (questionnaireStatus == null) {
      return languageCode == 'fil' ? 'Hindi pa Nasagot' : 'Not Started';
    }

    switch (questionnaireStatus) {
      case 'draft':
        return languageCode == 'fil' ? 'Draft' : 'Draft';
      case 'submitted':
        return languageCode == 'fil' ? 'Naisumite' : 'Submitted';
      case 'reviewed':
        return languageCode == 'fil' ? 'Nasuri na' : 'Reviewed';
      default:
        return languageCode == 'fil' ? 'Hindi pa Nasagot' : 'Not Started';
    }
  }

  /// Get questionnaire status badge color
  Color getQuestionnaireStatusColor() {
    if (questionnaireStatus == null) {
      return const Color(0xFF9E9E9E); // Grey
    }

    switch (questionnaireStatus) {
      case 'draft':
        return const Color(0xFFFFA500); // Orange
      case 'submitted':
        return const Color(0xFF4CAF50); // Green
      case 'reviewed':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'doctorName': doctorName,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime': appointmentTime,
      'status': status.toString(),
      'type': type.toString(),
      'notes': notes,
      'patientName': patientName,
      'contactNumber': contactNumber,
      'assessmentId': assessmentId,
      'riskScore': riskScore,
      'riskCategory': riskCategory,
      'assessmentData': assessmentData,
      'questionnaireStatus': questionnaireStatus,
      'backendId': backendId,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      facilityId: json['facilityId'] as String,
      facilityName: json['facilityName'] as String,
      doctorName: json['doctorName'] as String,
      appointmentDate: DateTime.parse(json['appointmentDate'] as String),
      appointmentTime: json['appointmentTime'] as String,
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      type: AppointmentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AppointmentType.consultation,
      ),
      notes: json['notes'] as String?,
      patientName: json['patientName'] as String?,
      contactNumber: json['contactNumber'] as String?,
      assessmentId: json['assessmentId'] as String?,
      riskScore: json['riskScore'] as int?,
      riskCategory: json['riskCategory'] as String?,
      assessmentData: json['assessmentData'] as Map<String, dynamic>?,
      questionnaireStatus: json['questionnaireStatus'] as String?,
      backendId: json['backendId'] as int?,
      syncStatus: json['syncStatus'] as String?,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Copy with method for immutability
  Appointment copyWith({
    String? id,
    String? facilityId,
    String? facilityName,
    String? doctorName,
    DateTime? appointmentDate,
    String? appointmentTime,
    AppointmentStatus? status,
    AppointmentType? type,
    String? notes,
    String? patientName,
    String? contactNumber,
    String? assessmentId,
    int? riskScore,
    String? riskCategory,
    Map<String, dynamic>? assessmentData,
    String? questionnaireStatus,
    int? backendId,
    String? syncStatus,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      facilityId: facilityId ?? this.facilityId,
      facilityName: facilityName ?? this.facilityName,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      patientName: patientName ?? this.patientName,
      contactNumber: contactNumber ?? this.contactNumber,
      assessmentId: assessmentId ?? this.assessmentId,
      riskScore: riskScore ?? this.riskScore,
      riskCategory: riskCategory ?? this.riskCategory,
      assessmentData: assessmentData ?? this.assessmentData,
      questionnaireStatus: questionnaireStatus ?? this.questionnaireStatus,
      backendId: backendId ?? this.backendId,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Appointment status enum
enum AppointmentStatus {
  pending,      // Waiting for confirmation
  confirmed,    // Confirmed by facility
  completed,    // Appointment finished
  cancelled,    // Cancelled by patient or facility
  noShow,       // Patient didn't show up
}

/// Appointment type enum
enum AppointmentType {
  consultation,  // General consultation
  followUp,      // Follow-up appointment
  emergency,     // Emergency appointment
  checkup,       // Routine checkup
  screening,     // Health screening
}

/// Time slot model for appointment booking
class TimeSlot {
  final String time; // Format: "10:00 AM"
  final bool isAvailable;

  const TimeSlot({
    required this.time,
    required this.isAvailable,
  });
}
