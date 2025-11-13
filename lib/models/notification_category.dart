import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:juan_heart/core/utils/color_constants.dart';

part 'notification_category.g.dart';

/// Notification categories for Juan Heart Mobile
/// Supports bilingual display (English/Filipino)
@HiveType(typeId: 1)
enum NotificationCategory {
  @HiveField(0)
  assessment,
  @HiveField(1)
  appointment,
  @HiveField(2)
  healthAlert,
  @HiveField(3)
  followUp,
  @HiveField(4)
  system,
}

/// Extension methods for NotificationCategory enum
extension NotificationCategoryExtension on NotificationCategory {
  /// Get display name in English
  String get displayNameEn {
    switch (this) {
      case NotificationCategory.assessment:
        return 'Risk Assessment';
      case NotificationCategory.appointment:
        return 'Appointment';
      case NotificationCategory.healthAlert:
        return 'Health Alert';
      case NotificationCategory.followUp:
        return 'Follow Up';
      case NotificationCategory.system:
        return 'System';
    }
  }

  /// Get display name in Filipino
  String get displayNameFil {
    switch (this) {
      case NotificationCategory.assessment:
        return 'Pagsusuri ng Panganib';
      case NotificationCategory.appointment:
        return 'Appointment';
      case NotificationCategory.healthAlert:
        return 'Babala sa Kalusugan';
      case NotificationCategory.followUp:
        return 'Subaybayan';
      case NotificationCategory.system:
        return 'Sistema';
    }
  }

  /// Get display name based on language
  String getDisplayName(bool isFilipino) {
    return isFilipino ? displayNameFil : displayNameEn;
  }

  /// Get icon data for this category
  IconData get iconData {
    switch (this) {
      case NotificationCategory.assessment:
        return Icons.assessment_outlined;
      case NotificationCategory.appointment:
        return Icons.calendar_today;
      case NotificationCategory.healthAlert:
        return Icons.warning_amber_rounded;
      case NotificationCategory.followUp:
        return Icons.follow_the_signs;
      case NotificationCategory.system:
        return Icons.notifications_active;
    }
  }

  /// Get color for this category (aligned with Juan Heart color scheme)
  Color get color {
    switch (this) {
      case NotificationCategory.assessment:
        return ColorConstant.blueColor;
      case NotificationCategory.appointment:
        return ColorConstant.calmingBlue;
      case NotificationCategory.healthAlert:
        return ColorConstant.emergencyBadge;
      case NotificationCategory.followUp:
        return ColorConstant.reassuringGreen;
      case NotificationCategory.system:
        return ColorConstant.pupuleColor;
    }
  }

  /// Get background color for this category
  Color get backgroundColor {
    switch (this) {
      case NotificationCategory.assessment:
        return ColorConstant.lightBlueBackground;
      case NotificationCategory.appointment:
        return ColorConstant.gradientBlueStart;
      case NotificationCategory.healthAlert:
        return ColorConstant.redLightBackground;
      case NotificationCategory.followUp:
        return ColorConstant.warmBeige;
      case NotificationCategory.system:
        return ColorConstant.softWhite;
    }
  }

  /// Get string value for serialization
  String get value {
    return toString().split('.').last;
  }

  /// Parse from string value
  static NotificationCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'assessment':
        return NotificationCategory.assessment;
      case 'appointment':
        return NotificationCategory.appointment;
      case 'healthalert':
        return NotificationCategory.healthAlert;
      case 'followup':
        return NotificationCategory.followUp;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.system;
    }
  }
}
