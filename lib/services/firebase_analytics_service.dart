/// Firebase Analytics Service
///
/// Wrapper service for Firebase Analytics with privacy controls
/// Respects user privacy preferences set in PrivacyService
/// Tracks key events for app improvement and user engagement
///
/// Setup Instructions:
/// 1. Add firebase_analytics to pubspec.yaml:
///    firebase_analytics: ^10.8.0
///    firebase_core: ^2.24.0
/// 2. Configure Firebase project (google-services.json for Android, GoogleService-Info.plist for iOS)
/// 3. Initialize Firebase in main.dart before runApp()
/// 4. Uncomment the imports and methods below

// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:juan_heart/services/privacy_service.dart';

class FirebaseAnalyticsService {
  // Singleton pattern
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  FirebaseAnalyticsService._internal();

  // Firebase Analytics instance (uncomment when firebase_analytics is added)
  // late FirebaseAnalytics _analytics;
  // late FirebaseAnalyticsObserver _observer;

  bool _isInitialized = false;

  /// Initialize Firebase Analytics
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Uncomment when firebase_analytics package is added:
      // _analytics = FirebaseAnalytics.instance;
      // _observer = FirebaseAnalyticsObserver(analytics: _analytics);

      // Set user properties
      await _setDefaultUserProperties();

      _isInitialized = true;
      print('✅ Firebase Analytics initialized');
    } catch (e) {
      print('❌ Failed to initialize Firebase Analytics: $e');
    }
  }

  /// Get the analytics observer for navigation tracking
  /// Use in MaterialApp: navigatorObservers: [FirebaseAnalyticsService().observer]
  // FirebaseAnalyticsObserver get observer => _observer;

  /// Set default user properties
  Future<void> _setDefaultUserProperties() async {
    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.setUserProperty(
      //   name: 'app_version',
      //   value: '2.0.0', // Get from package_info
      // );
      // await _analytics.setUserProperty(
      //   name: 'language',
      //   value: 'en', // Get from locale
      // );
    } catch (e) {
      print('Failed to set user properties: $e');
    }
  }

  /// Check if analytics is enabled (respects privacy preferences)
  Future<bool> _isAnalyticsEnabled() async {
    return await PrivacyService.isAnalyticsEnabled();
  }

  /// Track assessment completion
  Future<void> logAssessmentCompleted({
    required int riskScore,
    required String riskCategory,
    required int likelihoodScore,
    required int impactScore,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'assessment_completed',
      //   parameters: {
      //     'risk_score': riskScore,
      //     'risk_category': riskCategory,
      //     'likelihood_score': likelihoodScore,
      //     'impact_score': impactScore,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: Assessment completed - $riskCategory ($riskScore)');
    } catch (e) {
      print('Failed to log assessment: $e');
    }
  }

  /// Track referral generation
  Future<void> logReferralGenerated({
    required String facilityType,
    required String riskCategory,
    required double distanceKm,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'referral_generated',
      //   parameters: {
      //     'facility_type': facilityType,
      //     'risk_category': riskCategory,
      //     'distance_km': distanceKm,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: Referral generated - $facilityType');
    } catch (e) {
      print('Failed to log referral: $e');
    }
  }

  /// Track PDF export
  Future<void> logPdfExported({
    required String exportType, // 'assessment', 'analytics', 'referral'
    required int recordCount,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'pdf_exported',
      //   parameters: {
      //     'export_type': exportType,
      //     'record_count': recordCount,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: PDF exported - $exportType');
    } catch (e) {
      print('Failed to log PDF export: $e');
    }
  }

  /// Track CSV export
  Future<void> logCsvExported({
    required String exportType, // 'assessment_history', 'vital_signs', 'complete'
    required int recordCount,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'csv_exported',
      //   parameters: {
      //     'export_type': exportType,
      //     'record_count': recordCount,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: CSV exported - $exportType');
    } catch (e) {
      print('Failed to log CSV export: $e');
    }
  }

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logScreenView(
      //   screenName: screenName,
      //   screenClass: screenClass ?? screenName,
      // );

      print('📊 Analytics: Screen view - $screenName');
    } catch (e) {
      print('Failed to log screen view: $e');
    }
  }

  /// Track feature usage
  Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'feature_used',
      //   parameters: {
      //     'feature_name': featureName,
      //     'timestamp': DateTime.now().toIso8601String(),
      //     ...?parameters,
      //   },
      // );

      print('📊 Analytics: Feature used - $featureName');
    } catch (e) {
      print('Failed to log feature usage: $e');
    }
  }

  /// Track privacy preference change
  Future<void> logPrivacyPreferenceChanged({
    required String preferenceName,
    required bool newValue,
  }) async {
    // Always log privacy changes (even if analytics is disabled)
    // This helps understand opt-out rates
    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'privacy_preference_changed',
      //   parameters: {
      //     'preference_name': preferenceName,
      //     'new_value': newValue,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: Privacy preference changed - $preferenceName: $newValue');
    } catch (e) {
      print('Failed to log privacy change: $e');
    }
  }

  /// Track data deletion request
  Future<void> logDataDeletionRequested({
    required int recordsDeleted,
  }) async {
    // Always log data deletion (even if analytics is disabled)
    // This is important for compliance tracking
    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'data_deletion_requested',
      //   parameters: {
      //     'records_deleted': recordsDeleted,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: Data deletion requested - $recordsDeleted records');
    } catch (e) {
      print('Failed to log data deletion: $e');
    }
  }

  /// Track app open
  Future<void> logAppOpen() async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logAppOpen();

      print('📊 Analytics: App opened');
    } catch (e) {
      print('Failed to log app open: $e');
    }
  }

  /// Track search
  Future<void> logSearch({
    required String searchTerm,
    required String searchCategory, // 'facilities', 'assessments', 'health_topics'
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logSearch(
      //   searchTerm: searchTerm,
      //   parameters: {
      //     'search_category': searchCategory,
      //   },
      // );

      print('📊 Analytics: Search - $searchTerm in $searchCategory');
    } catch (e) {
      print('Failed to log search: $e');
    }
  }

  /// Track user engagement time
  Future<void> logUserEngagement({
    required String feature,
    required Duration engagementTime,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.logEvent(
      //   name: 'user_engagement',
      //   parameters: {
      //     'feature': feature,
      //     'engagement_seconds': engagementTime.inSeconds,
      //     'timestamp': DateTime.now().toIso8601String(),
      //   },
      // );

      print('📊 Analytics: User engagement - $feature (${engagementTime.inSeconds}s)');
    } catch (e) {
      print('Failed to log user engagement: $e');
    }
  }

  /// Set user ID (for authenticated users)
  Future<void> setUserId(String? userId) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.setUserId(id: userId);

      print('📊 Analytics: User ID set');
    } catch (e) {
      print('Failed to set user ID: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!await _isAnalyticsEnabled()) return;

    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.setUserProperty(
      //   name: name,
      //   value: value,
      // );

      print('📊 Analytics: User property set - $name: $value');
    } catch (e) {
      print('Failed to set user property: $e');
    }
  }

  /// Reset analytics data (on logout or data deletion)
  Future<void> resetAnalyticsData() async {
    try {
      // Uncomment when firebase_analytics is added:
      // await _analytics.resetAnalyticsData();

      print('📊 Analytics: Data reset');
    } catch (e) {
      print('Failed to reset analytics: $e');
    }
  }
}

/// Analytics Event Names (for consistency)
class AnalyticsEvents {
  static const String assessmentCompleted = 'assessment_completed';
  static const String referralGenerated = 'referral_generated';
  static const String pdfExported = 'pdf_exported';
  static const String csvExported = 'csv_exported';
  static const String featureUsed = 'feature_used';
  static const String privacyPreferenceChanged = 'privacy_preference_changed';
  static const String dataDeletionRequested = 'data_deletion_requested';
  static const String userEngagement = 'user_engagement';
}

/// Analytics Parameter Names (for consistency)
class AnalyticsParameters {
  static const String riskScore = 'risk_score';
  static const String riskCategory = 'risk_category';
  static const String likelihoodScore = 'likelihood_score';
  static const String impactScore = 'impact_score';
  static const String facilityType = 'facility_type';
  static const String distanceKm = 'distance_km';
  static const String exportType = 'export_type';
  static const String recordCount = 'record_count';
  static const String featureName = 'feature_name';
  static const String preferenceName = 'preference_name';
  static const String newValue = 'new_value';
  static const String searchCategory = 'search_category';
  static const String engagementSeconds = 'engagement_seconds';
  static const String timestamp = 'timestamp';
}
