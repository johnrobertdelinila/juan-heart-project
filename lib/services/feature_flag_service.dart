import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for managing feature flags and gradual rollout
///
/// This service controls which users see the AI assessment option:
/// - Beta testing: Internal team only (manual whitelist)
/// - Gradual rollout: 10% → 50% → 100% of users
/// - Remote config: Feature flags fetched from server or local fallback
class FeatureFlagService {
  static const String _storageKey = 'juan_heart_feature_flags';
  static const String _userBucketKey = 'juan_heart_user_bucket';

  /// Feature flag keys
  static const String aiAssessmentEnabled = 'ai_assessment_enabled';
  static const String aiRolloutPercentage = 'ai_rollout_percentage';

  /// Default feature flags (used if remote config fails)
  static const Map<String, dynamic> _defaultFlags = {
    aiAssessmentEnabled: false, // Disabled by default
    aiRolloutPercentage: 0, // 0% rollout
  };

  /// Cache duration for remote config
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Check if AI assessment feature is enabled for current user
  ///
  /// This considers both the global feature flag and the user's bucket
  /// for gradual rollout.
  static Future<bool> isAIAssessmentEnabled() async {
    try {
      // Get feature flags
      final flags = await getFeatureFlags();

      // Check if feature is globally enabled
      final globallyEnabled = flags[aiAssessmentEnabled] as bool? ?? false;
      if (!globallyEnabled) {
        print('🚫 AI Assessment: Globally disabled');
        return false;
      }

      // Check rollout percentage
      final rolloutPercentage = flags[aiRolloutPercentage] as int? ?? 0;
      if (rolloutPercentage >= 100) {
        print('✅ AI Assessment: Enabled for all users (100% rollout)');
        return true;
      }

      // Check if user is in the rollout bucket
      final userBucket = await _getUserBucket();
      final isInRollout = userBucket < rolloutPercentage;

      print(
        '🎲 AI Assessment: User bucket=$userBucket, Rollout=$rolloutPercentage%, Enabled=$isInRollout',
      );

      return isInRollout;

    } catch (e) {
      print('❌ Feature flag check failed: $e');
      return false; // Fail closed for safety
    }
  }

  /// Get all feature flags
  ///
  /// This fetches flags from remote config (if available) or uses
  /// cached/default values as fallback.
  static Future<Map<String, dynamic>> getFeatureFlags() async {
    try {
      // Try to get cached flags first
      final cached = await _getCachedFlags();
      if (cached != null) {
        print('📦 Using cached feature flags');
        return cached;
      }

      // Fetch from remote config
      print('🌐 Fetching feature flags from remote config...');
      final remote = await _fetchRemoteFlags();

      // Cache the remote flags
      await _cacheFlags(remote);

      return remote;

    } catch (e) {
      print('❌ Failed to get feature flags: $e. Using defaults.');
      return _defaultFlags;
    }
  }

  /// Get user's rollout bucket (0-99)
  ///
  /// This is a stable hash of the user's device ID, ensuring consistent
  /// bucketing across app restarts.
  static Future<int> _getUserBucket() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user already has a bucket assigned
      final existingBucket = prefs.getInt(_userBucketKey);
      if (existingBucket != null) {
        return existingBucket;
      }

      // Generate a random bucket (0-99) for this user
      final random = Random();
      final newBucket = random.nextInt(100);

      // Save for consistency
      await prefs.setInt(_userBucketKey, newBucket);

      print('🆕 Assigned user to bucket: $newBucket');
      return newBucket;

    } catch (e) {
      print('❌ Failed to get user bucket: $e');
      return 0; // Conservative fallback
    }
  }

  /// Get cached feature flags if still valid
  static Future<Map<String, dynamic>?> _getCachedFlags() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if cache exists
      final cachedJson = prefs.getString(_storageKey);
      if (cachedJson == null) return null;

      // Parse cache
      final cached = jsonDecode(cachedJson) as Map<String, dynamic>;

      // Check cache age
      final cacheTime = DateTime.parse(cached['timestamp'] as String);
      final now = DateTime.now();

      if (now.difference(cacheTime) > _cacheDuration) {
        print('⏰ Feature flag cache expired');
        return null;
      }

      // Return cached flags
      return cached['flags'] as Map<String, dynamic>;

    } catch (e) {
      print('❌ Failed to read cached flags: $e');
      return null;
    }
  }

  /// Fetch feature flags from remote config server
  ///
  /// In production, this would fetch from Firebase Remote Config or
  /// a custom backend endpoint. For now, it uses a simple JSON endpoint.
  static Future<Map<String, dynamic>> _fetchRemoteFlags() async {
    try {
      // Get remote config URL from environment
      final configUrl = dotenv.env['FEATURE_FLAGS_URL'];

      if (configUrl == null || configUrl.isEmpty) {
        print('⚠️ FEATURE_FLAGS_URL not configured. Using defaults.');
        return _defaultFlags;
      }

      // Fetch from remote
      final response = await http
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Remote config returned ${response.statusCode}');
      }

      // Parse response
      final flags = jsonDecode(response.body) as Map<String, dynamic>;

      print('✅ Remote feature flags fetched successfully');
      return flags;

    } catch (e) {
      print('❌ Failed to fetch remote flags: $e');
      return _defaultFlags;
    }
  }

  /// Cache feature flags locally
  static Future<void> _cacheFlags(Map<String, dynamic> flags) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Add timestamp to cache
      final cache = {
        'flags': flags,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to storage
      await prefs.setString(_storageKey, jsonEncode(cache));

      print('💾 Feature flags cached');

    } catch (e) {
      print('❌ Failed to cache flags: $e');
    }
  }

  /// Manually set feature flags (for testing/debugging)
  ///
  /// This is useful for development and QA testing.
  static Future<void> setFeatureFlags(Map<String, dynamic> flags) async {
    try {
      await _cacheFlags(flags);
      print('🔧 Feature flags manually set: $flags');
    } catch (e) {
      print('❌ Failed to set feature flags: $e');
    }
  }

  /// Clear cached feature flags
  ///
  /// Forces a fresh fetch on next request.
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      print('🗑️ Feature flag cache cleared');
    } catch (e) {
      print('❌ Failed to clear cache: $e');
    }
  }

  /// Enable AI assessment for current user (override for testing)
  static Future<void> enableAIAssessmentForTesting() async {
    await setFeatureFlags({
      aiAssessmentEnabled: true,
      aiRolloutPercentage: 100,
    });
  }

  /// Disable AI assessment (override for testing)
  static Future<void> disableAIAssessment() async {
    await setFeatureFlags({
      aiAssessmentEnabled: false,
      aiRolloutPercentage: 0,
    });
  }

  /// Get current rollout status summary
  static Future<Map<String, dynamic>> getRolloutStatus() async {
    final flags = await getFeatureFlags();
    final userBucket = await _getUserBucket();
    final isEnabled = await isAIAssessmentEnabled();

    return {
      'ai_assessment_enabled': flags[aiAssessmentEnabled],
      'rollout_percentage': flags[aiRolloutPercentage],
      'user_bucket': userBucket,
      'is_enabled_for_user': isEnabled,
    };
  }
}
