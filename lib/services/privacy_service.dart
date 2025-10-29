/// Privacy & Compliance Service
///
/// Manages user privacy preferences and data protection compliance
/// Implements:
/// - Granular consent management
/// - Data deletion requests
/// - Personal data export
/// - Analytics opt-in/opt-out
/// - Philippine Data Privacy Act (DPA) compliance
///
/// Part of the Privacy & Compliance Platform

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/analytics_csv_service.dart';
import 'package:juan_heart/models/assessment_history_model.dart';

class PrivacyService {
  // Storage keys
  static const String _keyPrivacyConsentGiven = 'privacy_consent_given';
  static const String _keyPrivacyConsentDate = 'privacy_consent_date';
  static const String _keyAnalyticsEnabled = 'analytics_enabled';
  static const String _keyDataSharingEnabled = 'data_sharing_enabled';
  static const String _keyPersonalizedInsightsEnabled = 'personalized_insights_enabled';
  static const String _keyResearchContributionEnabled = 'research_contribution_enabled';

  /// Check if user has given privacy consent
  static Future<bool> hasGivenConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPrivacyConsentGiven) ?? false;
  }

  /// Record privacy consent
  static Future<void> giveConsent({
    required bool analyticsEnabled,
    required bool dataSharingEnabled,
    required bool personalizedInsightsEnabled,
    required bool researchContributionEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyPrivacyConsentGiven, true);
    await prefs.setString(_keyPrivacyConsentDate, DateTime.now().toIso8601String());
    await prefs.setBool(_keyAnalyticsEnabled, analyticsEnabled);
    await prefs.setBool(_keyDataSharingEnabled, dataSharingEnabled);
    await prefs.setBool(_keyPersonalizedInsightsEnabled, personalizedInsightsEnabled);
    await prefs.setBool(_keyResearchContributionEnabled, researchContributionEnabled);
  }

  /// Get consent date
  static Future<DateTime?> getConsentDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_keyPrivacyConsentDate);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  /// Check if analytics is enabled
  static Future<bool> isAnalyticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAnalyticsEnabled) ?? true; // Default to true
  }

  /// Check if data sharing is enabled
  static Future<bool> isDataSharingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDataSharingEnabled) ?? false; // Default to false
  }

  /// Check if personalized insights is enabled
  static Future<bool> isPersonalizedInsightsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPersonalizedInsightsEnabled) ?? true; // Default to true
  }

  /// Check if research contribution is enabled
  static Future<bool> isResearchContributionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyResearchContributionEnabled) ?? false; // Default to false
  }

  /// Update analytics preference
  static Future<void> setAnalyticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAnalyticsEnabled, enabled);
  }

  /// Update data sharing preference
  static Future<void> setDataSharingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDataSharingEnabled, enabled);
  }

  /// Update personalized insights preference
  static Future<void> setPersonalizedInsightsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPersonalizedInsightsEnabled, enabled);
  }

  /// Update research contribution preference
  static Future<void> setResearchContributionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyResearchContributionEnabled, enabled);
  }

  /// Get all privacy preferences
  static Future<PrivacyPreferences> getPrivacyPreferences() async {
    final hasConsent = await hasGivenConsent();

    if (!hasConsent) {
      return PrivacyPreferences(
        consentGiven: false,
        consentDate: null,
        analyticsEnabled: true,
        dataSharingEnabled: false,
        personalizedInsightsEnabled: true,
        researchContributionEnabled: false,
      );
    }

    return PrivacyPreferences(
      consentGiven: true,
      consentDate: await getConsentDate(),
      analyticsEnabled: await isAnalyticsEnabled(),
      dataSharingEnabled: await isDataSharingEnabled(),
      personalizedInsightsEnabled: await isPersonalizedInsightsEnabled(),
      researchContributionEnabled: await isResearchContributionEnabled(),
    );
  }

  /// Export all personal data to JSON
  static Future<Map<String, dynamic>> exportPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final history = await AnalyticsService.getAssessmentHistory();
    final preferences = await getPrivacyPreferences();

    return {
      'export_date': DateTime.now().toIso8601String(),
      'data_subject_rights': {
        'right_to_access': 'Exercised via this export',
        'right_to_portability': 'Data provided in machine-readable format',
        'right_to_erasure': 'Available via Delete My Data feature',
      },
      'privacy_preferences': {
        'consent_given': preferences.consentGiven,
        'consent_date': preferences.consentDate?.toIso8601String(),
        'analytics_enabled': preferences.analyticsEnabled,
        'data_sharing_enabled': preferences.dataSharingEnabled,
        'personalized_insights_enabled': preferences.personalizedInsightsEnabled,
        'research_contribution_enabled': preferences.researchContributionEnabled,
      },
      'assessment_history': {
        'total_assessments': history.length,
        'records': history.map((r) => r.toJson()).toList(),
      },
      'data_retention_policy': {
        'assessment_records': 'Last 50 assessments kept',
        'retention_period': 'Until user requests deletion',
        'auto_deletion': 'After 2 years of inactivity (future feature)',
      },
      'legal_basis': {
        'processing': 'Consent (Philippine Data Privacy Act)',
        'controller': 'Juan Heart Mobile Application',
        'dpo_contact': 'privacy@juanheart.ph (placeholder)',
      },
    };
  }

  /// Delete all user data (irreversible)
  static Future<DataDeletionResult> deleteAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await AnalyticsService.getAssessmentHistory();

      // Record deletion details before wiping
      final deletionRecord = {
        'deleted_at': DateTime.now().toIso8601String(),
        'assessments_deleted': history.length,
      };

      // Clear all assessment history
      await prefs.remove('assessment_history');

      // Clear all privacy preferences
      await prefs.remove(_keyPrivacyConsentGiven);
      await prefs.remove(_keyPrivacyConsentDate);
      await prefs.remove(_keyAnalyticsEnabled);
      await prefs.remove(_keyDataSharingEnabled);
      await prefs.remove(_keyPersonalizedInsightsEnabled);
      await prefs.remove(_keyResearchContributionEnabled);

      // Note: User profile data is NOT deleted (name, email, etc.)
      // as that's managed by authentication system
      // Only health assessment data is deleted

      return DataDeletionResult(
        success: true,
        message: 'All health assessment data deleted successfully',
        deletionDate: DateTime.now(),
        recordsDeleted: history.length,
      );
    } catch (e) {
      return DataDeletionResult(
        success: false,
        message: 'Failed to delete data: $e',
        deletionDate: DateTime.now(),
        recordsDeleted: 0,
      );
    }
  }

  /// Reset privacy preferences to defaults
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyAnalyticsEnabled, true);
    await prefs.setBool(_keyDataSharingEnabled, false);
    await prefs.setBool(_keyPersonalizedInsightsEnabled, true);
    await prefs.setBool(_keyResearchContributionEnabled, false);
  }

  /// Withdraw consent (keeps data but disables all processing)
  static Future<void> withdrawConsent() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyPrivacyConsentGiven, false);
    await prefs.setBool(_keyAnalyticsEnabled, false);
    await prefs.setBool(_keyDataSharingEnabled, false);
    await prefs.setBool(_keyPersonalizedInsightsEnabled, false);
    await prefs.setBool(_keyResearchContributionEnabled, false);
  }
}

/// Privacy preferences data model
class PrivacyPreferences {
  final bool consentGiven;
  final DateTime? consentDate;
  final bool analyticsEnabled;
  final bool dataSharingEnabled;
  final bool personalizedInsightsEnabled;
  final bool researchContributionEnabled;

  PrivacyPreferences({
    required this.consentGiven,
    this.consentDate,
    required this.analyticsEnabled,
    required this.dataSharingEnabled,
    required this.personalizedInsightsEnabled,
    required this.researchContributionEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'consent_given': consentGiven,
      'consent_date': consentDate?.toIso8601String(),
      'analytics_enabled': analyticsEnabled,
      'data_sharing_enabled': dataSharingEnabled,
      'personalized_insights_enabled': personalizedInsightsEnabled,
      'research_contribution_enabled': researchContributionEnabled,
    };
  }

  factory PrivacyPreferences.fromJson(Map<String, dynamic> json) {
    return PrivacyPreferences(
      consentGiven: json['consent_given'] as bool,
      consentDate: json['consent_date'] != null
          ? DateTime.parse(json['consent_date'] as String)
          : null,
      analyticsEnabled: json['analytics_enabled'] as bool,
      dataSharingEnabled: json['data_sharing_enabled'] as bool,
      personalizedInsightsEnabled: json['personalized_insights_enabled'] as bool,
      researchContributionEnabled: json['research_contribution_enabled'] as bool,
    );
  }
}

/// Data deletion result
class DataDeletionResult {
  final bool success;
  final String message;
  final DateTime deletionDate;
  final int recordsDeleted;

  DataDeletionResult({
    required this.success,
    required this.message,
    required this.deletionDate,
    required this.recordsDeleted,
  });
}
