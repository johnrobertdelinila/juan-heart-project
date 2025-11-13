import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'dart:convert';

/// User preferences for notifications
class NotificationPreferences {
  final bool enabledForAssessment;
  final bool enabledForAppointment;
  final bool enabledForHealthAlert;
  final bool enabledForFollowUp;
  final bool enabledForSystem;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final bool enableSound;
  final bool enableVibration;
  final bool enableBadge;

  const NotificationPreferences({
    this.enabledForAssessment = true,
    this.enabledForAppointment = true,
    this.enabledForHealthAlert = true,
    this.enabledForFollowUp = true,
    this.enabledForSystem = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.enableSound = true,
    this.enableVibration = true,
    this.enableBadge = true,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'enabledForAssessment': enabledForAssessment,
      'enabledForAppointment': enabledForAppointment,
      'enabledForHealthAlert': enabledForHealthAlert,
      'enabledForFollowUp': enabledForFollowUp,
      'enabledForSystem': enabledForSystem,
      'quietHoursStart': quietHoursStart != null
          ? {'hour': quietHoursStart!.hour, 'minute': quietHoursStart!.minute}
          : null,
      'quietHoursEnd': quietHoursEnd != null
          ? {'hour': quietHoursEnd!.hour, 'minute': quietHoursEnd!.minute}
          : null,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'enableBadge': enableBadge,
    };
  }

  /// Create from JSON
  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTimeOfDay(Map<String, dynamic>? timeMap) {
      if (timeMap == null) return null;
      return TimeOfDay(
        hour: timeMap['hour'] as int,
        minute: timeMap['minute'] as int,
      );
    }

    return NotificationPreferences(
      enabledForAssessment: json['enabledForAssessment'] as bool? ?? true,
      enabledForAppointment: json['enabledForAppointment'] as bool? ?? true,
      enabledForHealthAlert: json['enabledForHealthAlert'] as bool? ?? true,
      enabledForFollowUp: json['enabledForFollowUp'] as bool? ?? true,
      enabledForSystem: json['enabledForSystem'] as bool? ?? true,
      quietHoursStart: parseTimeOfDay(
        json['quietHoursStart'] as Map<String, dynamic>?
      ),
      quietHoursEnd: parseTimeOfDay(
        json['quietHoursEnd'] as Map<String, dynamic>?
      ),
      enableSound: json['enableSound'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableBadge: json['enableBadge'] as bool? ?? true,
    );
  }

  /// Create copy with modified fields
  NotificationPreferences copyWith({
    bool? enabledForAssessment,
    bool? enabledForAppointment,
    bool? enabledForHealthAlert,
    bool? enabledForFollowUp,
    bool? enabledForSystem,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? enableSound,
    bool? enableVibration,
    bool? enableBadge,
    bool clearQuietHours = false,
  }) {
    return NotificationPreferences(
      enabledForAssessment: enabledForAssessment ?? this.enabledForAssessment,
      enabledForAppointment: enabledForAppointment ?? this.enabledForAppointment,
      enabledForHealthAlert: enabledForHealthAlert ?? this.enabledForHealthAlert,
      enabledForFollowUp: enabledForFollowUp ?? this.enabledForFollowUp,
      enabledForSystem: enabledForSystem ?? this.enabledForSystem,
      quietHoursStart: clearQuietHours ? null : (quietHoursStart ?? this.quietHoursStart),
      quietHoursEnd: clearQuietHours ? null : (quietHoursEnd ?? this.quietHoursEnd),
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableBadge: enableBadge ?? this.enableBadge,
    );
  }

  /// Check if notification category is enabled
  bool isEnabledFor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.assessment:
        return enabledForAssessment;
      case NotificationCategory.appointment:
        return enabledForAppointment;
      case NotificationCategory.healthAlert:
        return enabledForHealthAlert;
      case NotificationCategory.followUp:
        return enabledForFollowUp;
      case NotificationCategory.system:
        return enabledForSystem;
    }
  }

  /// Check if any quiet hours are set
  bool get hasQuietHours =>
      quietHoursStart != null && quietHoursEnd != null;

  @override
  String toString() {
    return 'NotificationPreferences(assessment: $enabledForAssessment, '
        'appointment: $enabledForAppointment, sound: $enableSound)';
  }
}

/// Service for managing notification preferences.
/// Uses SharedPreferences for persistent storage.
/// Singleton pattern ensures consistent access.
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();

  factory NotificationPreferencesService() => _instance;

  NotificationPreferencesService._internal();

  /// SharedPreferences key for storing preferences
  static const String _prefsKey = 'notification_preferences';

  NotificationPreferences? _cachedPreferences;

  /// Load notification preferences from storage
  Future<NotificationPreferences> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString(_prefsKey);

      if (prefsString != null) {
        final json = jsonDecode(prefsString) as Map<String, dynamic>;
        _cachedPreferences = NotificationPreferences.fromJson(json);
        debugPrint('Notification preferences loaded');
      } else {
        // Return default preferences if none saved
        _cachedPreferences = const NotificationPreferences();
        debugPrint('Using default notification preferences');
      }

      return _cachedPreferences!;
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
      // Return default preferences on error
      _cachedPreferences = const NotificationPreferences();
      return _cachedPreferences!;
    }
  }

  /// Save notification preferences to storage
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = preferences.toJson();
      final jsonString = jsonEncode(json);

      await prefs.setString(_prefsKey, jsonString);
      _cachedPreferences = preferences;

      debugPrint('Notification preferences saved');
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
      rethrow;
    }
  }

  /// Get cached preferences (returns default if not loaded)
  NotificationPreferences getCachedPreferences() {
    return _cachedPreferences ?? const NotificationPreferences();
  }

  /// Check if notification should be shown based on preferences
  Future<bool> shouldShowNotification(NotificationCategory category) async {
    try {
      final prefs = await loadPreferences();

      // Check if category is enabled
      if (!prefs.isEnabledFor(category)) {
        return false;
      }

      // Check if in quiet hours
      if (isInQuietHours(prefs)) {
        // Always show health alerts even during quiet hours
        if (category == NotificationCategory.healthAlert) {
          return true;
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking if notification should be shown: $e');
      // Default to showing notification on error
      return true;
    }
  }

  /// Check if current time is within quiet hours
  bool isInQuietHours([NotificationPreferences? preferences]) {
    try {
      final prefs = preferences ?? _cachedPreferences;
      if (prefs == null || !prefs.hasQuietHours) {
        return false;
      }

      final now = TimeOfDay.now();
      final start = prefs.quietHoursStart!;
      final end = prefs.quietHoursEnd!;

      // Convert to minutes for easier comparison
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;

      // Handle quiet hours that span midnight
      if (startMinutes <= endMinutes) {
        // Normal case: e.g., 22:00 to 07:00
        return nowMinutes >= startMinutes && nowMinutes < endMinutes;
      } else {
        // Spans midnight: e.g., 22:00 to 07:00
        return nowMinutes >= startMinutes || nowMinutes < endMinutes;
      }
    } catch (e) {
      debugPrint('Error checking quiet hours: $e');
      return false;
    }
  }

  /// Reset preferences to default
  Future<void> resetToDefaults() async {
    try {
      const defaultPrefs = NotificationPreferences();
      await savePreferences(defaultPrefs);
      debugPrint('Notification preferences reset to defaults');
    } catch (e) {
      debugPrint('Error resetting preferences: $e');
      rethrow;
    }
  }

  /// Enable all notification categories
  Future<void> enableAllCategories() async {
    try {
      final prefs = await loadPreferences();
      final updatedPrefs = NotificationPreferences(
        enabledForAssessment: true,
        enabledForAppointment: true,
        enabledForHealthAlert: true,
        enabledForFollowUp: true,
        enabledForSystem: true,
        quietHoursStart: prefs.quietHoursStart,
        quietHoursEnd: prefs.quietHoursEnd,
        enableSound: prefs.enableSound,
        enableVibration: prefs.enableVibration,
        enableBadge: prefs.enableBadge,
      );

      await savePreferences(updatedPrefs);
    } catch (e) {
      debugPrint('Error enabling all categories: $e');
      rethrow;
    }
  }

  /// Disable all notification categories
  Future<void> disableAllCategories() async {
    try {
      final prefs = await loadPreferences();
      final updatedPrefs = NotificationPreferences(
        enabledForAssessment: false,
        enabledForAppointment: false,
        enabledForHealthAlert: true, // Keep health alerts enabled
        enabledForFollowUp: false,
        enabledForSystem: false,
        quietHoursStart: prefs.quietHoursStart,
        quietHoursEnd: prefs.quietHoursEnd,
        enableSound: prefs.enableSound,
        enableVibration: prefs.enableVibration,
        enableBadge: prefs.enableBadge,
      );

      await savePreferences(updatedPrefs);
    } catch (e) {
      debugPrint('Error disabling all categories: $e');
      rethrow;
    }
  }
}
