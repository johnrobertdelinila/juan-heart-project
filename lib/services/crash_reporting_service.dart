import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash Reporting Service
///
/// Centralized wrapper for Firebase Crashlytics with graceful degradation.
/// Provides methods for logging errors, setting user context, and custom keys.
/// All methods fail silently if Crashlytics is not initialized.
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  static CrashReportingService get instance => _instance;

  FirebaseCrashlytics? _crashlytics;
  bool _isInitialized = false;

  /// Initialize Crashlytics (called from main.dart)
  Future<void> initialize() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;
      _isInitialized = true;
      debugPrint('✅ CrashReportingService initialized');
    } catch (e) {
      debugPrint('⚠️ CrashReportingService initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Log non-fatal error to Crashlytics
  ///
  /// Use this for caught exceptions that don't crash the app
  /// but are important to track for debugging.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stack) {
  ///   CrashReportingService.instance.logError(
  ///     error: e,
  ///     stackTrace: stack,
  ///     reason: 'Failed to sync appointment',
  ///     fatal: false,
  ///   );
  /// }
  /// ```
  Future<void> logError({
    required dynamic error,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_isInitialized || _crashlytics == null) {
      debugPrint('⚠️ Crashlytics not initialized. Error: $error');
      return;
    }

    try {
      // Add additional context if provided
      if (additionalInfo != null) {
        for (final entry in additionalInfo.entries) {
          await _crashlytics!.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Log the error
      await _crashlytics!.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      debugPrint('📊 Error logged to Crashlytics: ${error.toString()}');
    } catch (e) {
      debugPrint('⚠️ Failed to log error to Crashlytics: $e');
    }
  }

  /// Log a custom message to Crashlytics
  ///
  /// Use this for breadcrumb logging to understand user flow
  /// before a crash occurs.
  Future<void> log(String message) async {
    if (!_isInitialized || _crashlytics == null) {
      debugPrint('📝 $message');
      return;
    }

    try {
      await _crashlytics!.log(message);
    } catch (e) {
      debugPrint('⚠️ Failed to log message to Crashlytics: $e');
    }
  }

  /// Set user identifier for crash reports
  ///
  /// Call this after successful authentication to associate
  /// crashes with specific users.
  Future<void> setUserId(String userId) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setUserIdentifier(userId);
      debugPrint('👤 User ID set in Crashlytics: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to set user ID in Crashlytics: $e');
    }
  }

  /// Set custom key-value pair for crash context
  ///
  /// Use this to add app state information that will be
  /// included in crash reports.
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_isInitialized || _crashlytics == null) return;

    try {
      await _crashlytics!.setCustomKey(key, value.toString());
    } catch (e) {
      debugPrint('⚠️ Failed to set custom key in Crashlytics: $e');
    }
  }

  /// Force a test crash (for verification only)
  ///
  /// ONLY use this in debug builds to verify Crashlytics
  /// is working correctly. NEVER call this in production.
  Future<void> testCrash() async {
    if (!_isInitialized || _crashlytics == null) {
      debugPrint('⚠️ Crashlytics not initialized. Cannot test crash.');
      return;
    }

    debugPrint('💥 Forcing test crash...');
    _crashlytics!.crash();
  }

  /// Check if Crashlytics is initialized and ready
  bool get isInitialized => _isInitialized;
}
