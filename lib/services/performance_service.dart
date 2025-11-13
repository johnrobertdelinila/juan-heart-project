import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:juan_heart/services/privacy_service.dart';

/// Firebase Performance Monitoring Service
///
/// Privacy-aware wrapper for Firebase Performance Monitoring that provides
/// custom performance tracking for critical user flows and system operations.
/// Respects user privacy preferences and gracefully degrades if unavailable.
///
/// Key Features:
/// - Custom trace management for assessment flows
/// - Network performance tracking
/// - Screen load time monitoring
/// - Privacy-aware (checks PrivacyService before tracking)
/// - Graceful error handling (never throws exceptions)
///
/// Usage Example:
/// ```dart
/// // Track assessment flow
/// final trace = await PerformanceService.instance.startAssessmentTrace();
/// // ... perform assessment logic ...
/// await PerformanceService.instance.stopAssessmentTrace(
///   trace,
///   likelihoodScore: 4,
///   impactScore: 5,
///   symptomCount: 3,
///   usedAI: true,
/// );
/// ```
///
/// Integration Notes:
/// - Firebase Performance must be initialized in main.dart before use
/// - All methods check privacy settings via PrivacyService.isAnalyticsEnabled()
/// - Returns null for trace methods if Firebase is unavailable
/// - Never throws exceptions - logs errors with debugPrint
class PerformanceService {
  // Singleton pattern
  static final PerformanceService _instance = PerformanceService._internal();
  static PerformanceService get instance => _instance;
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  /// Firebase Performance instance (lazy initialization)
  FirebasePerformance? _performance;
  bool _isInitialized = false;

  /// Trace name constants
  static const String traceAssessment = 'assessment_flow';
  static const String traceSymptomChecker = 'symptom_checker';
  static const String traceVitalSigns = 'vital_signs_input';
  static const String traceRiskCalculation = 'risk_calculation';
  static const String traceAppointmentSync = 'appointment_sync';
  static const String traceGenkitApi = 'genkit_api_call';
  static const String traceScreen = 'screen_load';
  static const String traceDatabaseQuery = 'database_query';
  static const String traceAppStart = 'app_start';

  /// Metric name constants
  static const String metricLikelihoodScore = 'likelihood_score';
  static const String metricImpactScore = 'impact_score';
  static const String metricSymptomCount = 'symptom_count';
  static const String metricVitalSignsCount = 'vital_signs_count';
  static const String metricFinalScore = 'final_score';
  static const String metricSyncedCount = 'synced_count';
  static const String metricFailedCount = 'failed_count';
  static const String metricResponseSize = 'response_size_bytes';

  /// Attribute name constants
  static const String attrUsedAi = 'used_ai';
  static const String attrCalculationType = 'calculation_type';
  static const String attrScreenName = 'screen_name';
  static const String attrSuccess = 'success';
  static const String attrErrorType = 'error_type';

  /// Initialize the performance service
  ///
  /// Should be called after Firebase.initializeApp() in main.dart
  /// Safe to call multiple times (idempotent)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _performance = FirebasePerformance.instance;
      _isInitialized = true;
      debugPrint('✅ PerformanceService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize PerformanceService: $e');
      _performance = null;
      _isInitialized = false;
    }
  }

  /// Check if performance collection should be enabled
  ///
  /// Returns true only if:
  /// 1. Service is initialized
  /// 2. User has enabled analytics in privacy settings
  Future<bool> _isTrackingEnabled() async {
    if (!_isInitialized || _performance == null) {
      return false;
    }

    try {
      return await PrivacyService.isAnalyticsEnabled();
    } catch (e) {
      debugPrint('❌ Error checking privacy settings: $e');
      return false;
    }
  }

  /// Set performance collection enabled/disabled
  ///
  /// Respects user privacy preferences
  /// Called automatically when privacy settings change
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    if (_performance == null) return;

    try {
      await _performance!.setPerformanceCollectionEnabled(enabled);
      debugPrint('📊 Performance collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Failed to set performance collection: $e');
    }
  }

  /// Check if performance collection is enabled
  Future<bool> isPerformanceCollectionEnabled() async {
    if (_performance == null) return false;

    try {
      return await _isTrackingEnabled();
    } catch (e) {
      debugPrint('❌ Error checking performance status: $e');
      return false;
    }
  }

  /// Start a custom trace
  ///
  /// [traceName] - Unique identifier for the trace
  /// Returns null if tracking is disabled or Firebase is unavailable
  Future<Trace?> startTrace(String traceName) async {
    if (!await _isTrackingEnabled()) return null;

    try {
      final trace = _performance!.newTrace(traceName);
      await trace.start();
      debugPrint('🔄 Started trace: $traceName');
      return trace;
    } catch (e) {
      debugPrint('❌ Failed to start trace $traceName: $e');
      return null;
    }
  }

  /// Stop a custom trace
  ///
  /// [trace] - The trace to stop (null-safe)
  Future<void> stopTrace(Trace? trace) async {
    if (trace == null) return;

    try {
      await trace.stop();
      debugPrint('✅ Stopped trace');
    } catch (e) {
      debugPrint('❌ Failed to stop trace: $e');
    }
  }

  /// Increment a metric in a trace
  ///
  /// [trace] - The trace to update (null-safe)
  /// [metric] - Metric name
  /// [value] - Amount to increment by
  Future<void> incrementMetric(
    Trace? trace,
    String metric,
    int value,
  ) async {
    if (trace == null) return;

    try {
      trace.incrementMetric(metric, value);
    } catch (e) {
      debugPrint('❌ Failed to increment metric $metric: $e');
    }
  }

  /// Set a metric value in a trace
  ///
  /// [trace] - The trace to update (null-safe)
  /// [metric] - Metric name
  /// [value] - Metric value
  Future<void> setMetric(Trace? trace, String metric, int value) async {
    if (trace == null) return;

    try {
      trace.setMetric(metric, value);
    } catch (e) {
      debugPrint('❌ Failed to set metric $metric: $e');
    }
  }

  /// Put a string attribute in a trace
  ///
  /// [trace] - The trace to update (null-safe)
  /// [key] - Attribute key
  /// [value] - Attribute value
  Future<void> putAttribute(
    Trace? trace,
    String key,
    String value,
  ) async {
    if (trace == null) return;

    try {
      trace.putAttribute(key, value);
    } catch (e) {
      debugPrint('❌ Failed to put attribute $key: $e');
    }
  }

  /// Start assessment flow trace
  ///
  /// Tracks the complete CVD risk assessment flow from start to finish
  /// Returns null if tracking is disabled
  Future<Trace?> startAssessmentTrace() async {
    return await startTrace(traceAssessment);
  }

  /// Stop assessment flow trace with metrics
  ///
  /// [trace] - The assessment trace to stop
  /// [likelihoodScore] - Likelihood score (1-5)
  /// [impactScore] - Impact score (1-5)
  /// [symptomCount] - Number of symptoms entered
  /// [usedAI] - Whether AI assessment was used
  Future<void> stopAssessmentTrace(
    Trace? trace, {
    required int likelihoodScore,
    required int impactScore,
    required int symptomCount,
    required bool usedAI,
  }) async {
    if (trace == null) return;

    try {
      await setMetric(trace, metricLikelihoodScore, likelihoodScore);
      await setMetric(trace, metricImpactScore, impactScore);
      await setMetric(trace, metricSymptomCount, symptomCount);
      await setMetric(
        trace,
        metricFinalScore,
        likelihoodScore * impactScore,
      );
      await putAttribute(trace, attrUsedAi, usedAI.toString());
      await stopTrace(trace);

      debugPrint(
        '✅ Assessment trace completed: L$likelihoodScore×I$impactScore=${likelihoodScore * impactScore} (AI: $usedAI)',
      );
    } catch (e) {
      debugPrint('❌ Failed to stop assessment trace: $e');
    }
  }

  /// Start symptom checker trace
  ///
  /// Tracks symptom selection and validation
  Future<Trace?> startSymptomCheckerTrace() async {
    return await startTrace(traceSymptomChecker);
  }

  /// Stop symptom checker trace with metrics
  ///
  /// [trace] - The symptom checker trace to stop
  /// [symptomCount] - Number of symptoms selected
  Future<void> stopSymptomCheckerTrace(
    Trace? trace,
    int symptomCount,
  ) async {
    if (trace == null) return;

    try {
      await setMetric(trace, metricSymptomCount, symptomCount);
      await stopTrace(trace);
      debugPrint('✅ Symptom checker trace completed: $symptomCount symptoms');
    } catch (e) {
      debugPrint('❌ Failed to stop symptom checker trace: $e');
    }
  }

  /// Start vital signs input trace
  ///
  /// Tracks vital signs data entry performance
  Future<Trace?> startVitalSignsTrace() async {
    return await startTrace(traceVitalSigns);
  }

  /// Stop vital signs input trace with metrics
  ///
  /// [trace] - The vital signs trace to stop
  /// [vitalSignsCount] - Number of vital signs entered
  Future<void> stopVitalSignsTrace(
    Trace? trace,
    int vitalSignsCount,
  ) async {
    if (trace == null) return;

    try {
      await setMetric(trace, metricVitalSignsCount, vitalSignsCount);
      await stopTrace(trace);
      debugPrint(
        '✅ Vital signs trace completed: $vitalSignsCount vital signs',
      );
    } catch (e) {
      debugPrint('❌ Failed to stop vital signs trace: $e');
    }
  }

  /// Start risk calculation trace
  ///
  /// Tracks the performance of risk score calculation (AI or rule-based)
  Future<Trace?> startRiskCalculationTrace() async {
    return await startTrace(traceRiskCalculation);
  }

  /// Stop risk calculation trace with metrics
  ///
  /// [trace] - The risk calculation trace to stop
  /// [calculationType] - "ai" or "rule_based"
  /// [finalScore] - Final calculated risk score (1-25)
  Future<void> stopRiskCalculationTrace(
    Trace? trace, {
    required String calculationType,
    required int finalScore,
  }) async {
    if (trace == null) return;

    try {
      await putAttribute(trace, attrCalculationType, calculationType);
      await setMetric(trace, metricFinalScore, finalScore);
      await stopTrace(trace);
      debugPrint(
        '✅ Risk calculation trace completed: $calculationType ($finalScore)',
      );
    } catch (e) {
      debugPrint('❌ Failed to stop risk calculation trace: $e');
    }
  }

  /// Start appointment sync trace
  ///
  /// Tracks appointment synchronization with backend
  Future<Trace?> startAppointmentSyncTrace() async {
    return await startTrace(traceAppointmentSync);
  }

  /// Stop appointment sync trace with metrics
  ///
  /// [trace] - The appointment sync trace to stop
  /// [syncedCount] - Number of appointments successfully synced
  /// [failedCount] - Number of appointments that failed to sync
  Future<void> stopAppointmentSyncTrace(
    Trace? trace, {
    required int syncedCount,
    required int failedCount,
  }) async {
    if (trace == null) return;

    try {
      await setMetric(trace, metricSyncedCount, syncedCount);
      await setMetric(trace, metricFailedCount, failedCount);
      await stopTrace(trace);
      debugPrint(
        '✅ Appointment sync trace completed: $syncedCount synced, $failedCount failed',
      );
    } catch (e) {
      debugPrint('❌ Failed to stop appointment sync trace: $e');
    }
  }

  /// Start ML Assessment API call trace
  ///
  /// Tracks performance of ML assessment API calls
  Future<Trace?> startGenkitApiTrace() async {
    return await startTrace(traceGenkitApi);
  }

  /// Stop ML Assessment API call trace with metrics
  ///
  /// [trace] - The ML Assessment API trace to stop
  /// [success] - Whether the API call succeeded
  /// [responseSize] - Size of response in bytes
  Future<void> stopGenkitApiTrace(
    Trace? trace, {
    required bool success,
    required int responseSize,
  }) async {
    if (trace == null) return;

    try {
      await putAttribute(trace, attrSuccess, success.toString());
      await setMetric(trace, metricResponseSize, responseSize);
      await stopTrace(trace);
      debugPrint(
        '✅ ML Assessment API trace completed: success=$success, size=$responseSize bytes',
      );
    } catch (e) {
      debugPrint('❌ Failed to stop ML Assessment API trace: $e');
    }
  }

  /// Start screen load trace
  ///
  /// [screenName] - Name of the screen being loaded
  /// Tracks screen initialization and render time
  Future<Trace?> startScreenTrace(String screenName) async {
    final trace = await startTrace(traceScreen);
    if (trace != null) {
      await putAttribute(trace, attrScreenName, screenName);
    }
    return trace;
  }

  /// Stop screen load trace
  ///
  /// [trace] - The screen trace to stop
  Future<void> stopScreenTrace(Trace? trace) async {
    await stopTrace(trace);
  }

  /// Start database query trace
  ///
  /// [queryName] - Name/description of the database query
  /// Tracks database operation performance
  Future<Trace?> startDatabaseQueryTrace(String queryName) async {
    final trace = await startTrace(traceDatabaseQuery);
    if (trace != null) {
      await putAttribute(trace, 'query_name', queryName);
    }
    return trace;
  }

  /// Stop database query trace
  ///
  /// [trace] - The database trace to stop
  /// [recordCount] - Number of records returned/affected
  Future<void> stopDatabaseQueryTrace(
    Trace? trace, {
    int? recordCount,
  }) async {
    if (trace == null) return;

    try {
      if (recordCount != null) {
        await setMetric(trace, 'record_count', recordCount);
      }
      await stopTrace(trace);
    } catch (e) {
      debugPrint('❌ Failed to stop database query trace: $e');
    }
  }

  /// Start app cold start trace
  ///
  /// Should be called at the very beginning of main()
  /// Tracks time from app launch to first frame
  Future<Trace?> startAppStartTrace() async {
    return await startTrace(traceAppStart);
  }

  /// Stop app cold start trace
  ///
  /// [trace] - The app start trace to stop
  /// Should be called after first frame is rendered
  Future<void> stopAppStartTrace(Trace? trace) async {
    if (trace == null) return;

    try {
      await stopTrace(trace);
      debugPrint('✅ App start trace completed');
    } catch (e) {
      debugPrint('❌ Failed to stop app start trace: $e');
    }
  }

  /// Create a custom trace with error tracking
  ///
  /// Convenience method for operations that may fail
  /// Automatically adds error attributes if an exception occurs
  ///
  /// Usage:
  /// ```dart
  /// await PerformanceService.instance.traceOperation(
  ///   'my_operation',
  ///   () async {
  ///     // Your operation here
  ///   },
  /// );
  /// ```
  Future<T> traceOperation<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    final trace = await startTrace(traceName);

    try {
      final result = await operation();
      await putAttribute(trace, attrSuccess, 'true');
      await stopTrace(trace);
      return result;
    } catch (e) {
      await putAttribute(trace, attrSuccess, 'false');
      await putAttribute(trace, attrErrorType, e.runtimeType.toString());
      await stopTrace(trace);
      rethrow;
    }
  }
}
