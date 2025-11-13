import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user consent for AI assessment features
///
/// This service handles:
/// - One-time consent dialog for sending data to Gemini API
/// - Consent status persistence
/// - Consent revocation
/// - Analytics tracking (opt-in rates)
class AIConsentService {
  static const String _consentKey = 'juan_heart_ai_consent';
  static const String _consentTimestampKey = 'juan_heart_ai_consent_timestamp';
  static const String _consentVersionKey = 'juan_heart_ai_consent_version';

  /// Current consent version (increment when privacy policy changes)
  static const int currentConsentVersion = 1;

  /// Check if user has given consent for AI assessment
  ///
  /// Returns true only if:
  /// 1. User has explicitly consented
  /// 2. Consent version matches current version
  static Future<bool> hasConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if consent exists
      final consented = prefs.getBool(_consentKey) ?? false;
      if (!consented) {
        return false;
      }

      // Check if consent version is current
      final consentVersion = prefs.getInt(_consentVersionKey) ?? 0;
      if (consentVersion < currentConsentVersion) {
        debugPrint('⚠️ Consent version outdated. Re-consent required.');
        return false;
      }

      debugPrint('✅ User has valid AI assessment consent');
      return true;

    } catch (e) {
      debugPrint('❌ Failed to check AI consent: $e');
      return false; // Fail closed for privacy
    }
  }

  /// Grant consent for AI assessment
  ///
  /// This is called when user accepts the consent dialog.
  static Future<bool> grantConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save consent status
      await prefs.setBool(_consentKey, true);
      await prefs.setInt(_consentVersionKey, currentConsentVersion);
      await prefs.setString(
        _consentTimestampKey,
        DateTime.now().toIso8601String(),
      );

      debugPrint('✅ AI assessment consent granted');

      // Track analytics (if enabled)
      _trackConsentEvent('granted');

      return true;

    } catch (e) {
      debugPrint('❌ Failed to grant AI consent: $e');
      return false;
    }
  }

  /// Revoke consent for AI assessment
  ///
  /// This can be called from app settings if user changes their mind.
  static Future<bool> revokeConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove consent
      await prefs.setBool(_consentKey, false);
      await prefs.remove(_consentTimestampKey);
      await prefs.remove(_consentVersionKey);

      debugPrint('🚫 AI assessment consent revoked');

      // Track analytics
      _trackConsentEvent('revoked');

      return true;

    } catch (e) {
      debugPrint('❌ Failed to revoke AI consent: $e');
      return false;
    }
  }

  /// Get consent timestamp
  ///
  /// Returns when user granted consent, or null if not consented.
  static Future<DateTime?> getConsentTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final timestamp = prefs.getString(_consentTimestampKey);
      if (timestamp == null) return null;

      return DateTime.parse(timestamp);

    } catch (e) {
      debugPrint('❌ Failed to get consent timestamp: $e');
      return null;
    }
  }

  /// Get consent status summary
  ///
  /// Returns full consent information for display in settings.
  static Future<Map<String, dynamic>> getConsentStatus() async {
    final hasConsentStatus = await hasConsent();
    final timestamp = await getConsentTimestamp();

    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getInt(_consentVersionKey);

    return {
      'has_consent': hasConsentStatus,
      'consent_timestamp': timestamp?.toIso8601String(),
      'consent_version': version,
      'current_version': currentConsentVersion,
      'needs_update': version != null && version < currentConsentVersion,
    };
  }

  /// Check if user should see consent dialog
  ///
  /// Returns true if:
  /// - User hasn't consented yet, OR
  /// - Consent version is outdated
  static Future<bool> shouldShowConsentDialog() async {
    return !(await hasConsent());
  }

  /// Track consent events for analytics
  ///
  /// This is privacy-respecting: we only track opt-in/opt-out rates,
  /// not personal data.
  static void _trackConsentEvent(String action) {
    try {
      // Integration with AnalyticsService would go here
      debugPrint('📊 Consent event tracked: $action');

      // Example:
      // AnalyticsService.logEvent(
      //   'ai_consent_$action',
      //   parameters: {
      //     'timestamp': DateTime.now().toIso8601String(),
      //     'consent_version': currentConsentVersion,
      //   },
      // );

    } catch (e) {
      debugPrint('❌ Failed to track consent event: $e');
    }
  }

  /// Clear all consent data (for testing/debugging)
  static Future<void> clearConsentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_consentKey);
      await prefs.remove(_consentTimestampKey);
      await prefs.remove(_consentVersionKey);

      debugPrint('🗑️ AI consent data cleared');

    } catch (e) {
      debugPrint('❌ Failed to clear consent data: $e');
    }
  }

  /// Get privacy policy text for consent dialog
  ///
  /// This explains what data is sent to Gemini API.
  static String getConsentText({required bool isFilipino}) {
    if (isFilipino) {
      return '''
Upang magamit ang AI-powered assessment, ang inyong data ay ipadadala sa Google Gemini API para sa pagsusuri.

Ang data na ipadadala:
• Edad at kasarian
• Mga sintomas at vital signs
• Medikal na kasaysayan
• Lifestyle factors

IMPORTANTE:
• Ang inyong data ay HINDI gagamitin para sa training ng AI model
• Ang inyong data ay encrypted at secure
• Kailangan ng internet connection
• Maaari ninyong bawiin ang consent anumang oras sa Settings

Naiintindihan ko at sumasang-ayon ako na ang aking data ay ipadadala sa Google Gemini API para sa AI assessment.
''';
    }

    return '''
To use AI-powered assessment, your data will be sent to Google Gemini API for analysis.

Data sent includes:
• Age and sex
• Symptoms and vital signs
• Medical history
• Lifestyle factors

IMPORTANT:
• Your data is NOT used for training the AI model
• Your data is encrypted and secure
• Internet connection required
• You can revoke consent anytime in Settings

I understand and agree that my data will be sent to Google Gemini API for AI assessment.
''';
  }

  /// Get privacy policy URL
  static String getPrivacyPolicyUrl() {
    // Replace with your actual privacy policy URL
    return 'https://juan-heart.ph/privacy-policy#ai-assessment';
  }
}
