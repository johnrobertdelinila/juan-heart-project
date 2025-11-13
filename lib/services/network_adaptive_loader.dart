import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Network quality levels
enum NetworkQuality {
  wifi, // WiFi connection - full data
  fourG, // 4G/LTE - standard data
  threeG, // 3G - reduced data
  twoG, // 2G - minimal data
  offline, // No connection
}

/// Configuration for network-adaptive loading
class NetworkAdaptiveConfig {
  final int maxRecords;
  final bool includeVitalSigns;
  final bool includeRiskFactors;
  final bool loadImages;
  final int pageSize;

  const NetworkAdaptiveConfig({
    required this.maxRecords,
    required this.includeVitalSigns,
    required this.includeRiskFactors,
    required this.loadImages,
    required this.pageSize,
  });

  /// Configuration for WiFi (full data)
  static const wifi = NetworkAdaptiveConfig(
    maxRecords: 50,
    includeVitalSigns: true,
    includeRiskFactors: true,
    loadImages: true,
    pageSize: 20,
  );

  /// Configuration for 4G (standard data)
  static const fourG = NetworkAdaptiveConfig(
    maxRecords: 30,
    includeVitalSigns: true,
    includeRiskFactors: true,
    loadImages: false,
    pageSize: 15,
  );

  /// Configuration for 3G (reduced data)
  static const threeG = NetworkAdaptiveConfig(
    maxRecords: 20,
    includeVitalSigns: true,
    includeRiskFactors: false,
    loadImages: false,
    pageSize: 10,
  );

  /// Configuration for 2G (minimal data)
  static const twoG = NetworkAdaptiveConfig(
    maxRecords: 10,
    includeVitalSigns: false,
    includeRiskFactors: false,
    loadImages: false,
    pageSize: 5,
  );

  /// Configuration for offline (cache only)
  static const offline = NetworkAdaptiveConfig(
    maxRecords: 10,
    includeVitalSigns: false,
    includeRiskFactors: false,
    loadImages: false,
    pageSize: 5,
  );
}

/// Service for network-adaptive analytics loading
class NetworkAdaptiveLoader {
  static final Connectivity _connectivity = Connectivity();

  /// Detect current network quality
  static Future<NetworkQuality> detectNetworkQuality() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result == ConnectivityResult.none) {
        debugPrint('📡 Network: Offline');
        return NetworkQuality.offline;
      }

      if (result == ConnectivityResult.wifi || result == ConnectivityResult.ethernet) {
        debugPrint('📡 Network: WiFi (full data)');
        return NetworkQuality.wifi;
      }

      if (result == ConnectivityResult.mobile) {
        // Note: We cannot reliably detect 2G/3G/4G on all platforms
        // Default to 3G for mobile to be conservative
        debugPrint('📡 Network: Mobile (assuming 3G - reduced data)');
        return NetworkQuality.threeG;
      }

      // For VPN or other connection types, default to 4G
      debugPrint('📡 Network: Other (assuming 4G)');
      return NetworkQuality.fourG;
    } catch (e) {
      debugPrint('⚠️ Error detecting network: $e, defaulting to 3G');
      return NetworkQuality.threeG;
    }
  }

  /// Get configuration based on network quality
  static NetworkAdaptiveConfig getConfig(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.wifi:
        return NetworkAdaptiveConfig.wifi;
      case NetworkQuality.fourG:
        return NetworkAdaptiveConfig.fourG;
      case NetworkQuality.threeG:
        return NetworkAdaptiveConfig.threeG;
      case NetworkQuality.twoG:
        return NetworkAdaptiveConfig.twoG;
      case NetworkQuality.offline:
        return NetworkAdaptiveConfig.offline;
    }
  }

  /// Get adaptive configuration automatically
  static Future<NetworkAdaptiveConfig> getAdaptiveConfig() async {
    final quality = await detectNetworkQuality();
    return getConfig(quality);
  }

  /// Get user-friendly network quality message
  static String getNetworkMessage(NetworkQuality quality, bool isFilipino) {
    switch (quality) {
      case NetworkQuality.wifi:
        return isFilipino
            ? 'WiFi - Kumpletong data'
            : 'WiFi - Full data';
      case NetworkQuality.fourG:
        return isFilipino
            ? '4G - Karaniwang data'
            : '4G - Standard data';
      case NetworkQuality.threeG:
        return isFilipino
            ? '3G - Binawasang data para sa bilis'
            : '3G - Reduced data for speed';
      case NetworkQuality.twoG:
        return isFilipino
            ? '2G - Pinakamaliit na data lamang'
            : '2G - Minimal data only';
      case NetworkQuality.offline:
        return isFilipino
            ? 'Offline - Cache na data lamang'
            : 'Offline - Cached data only';
    }
  }

  /// Estimate load time based on network quality
  static Duration getEstimatedLoadTime(NetworkQuality quality, int recordCount) {
    // Rough estimates based on payload size and network speed
    switch (quality) {
      case NetworkQuality.wifi:
        return Duration(milliseconds: 500 + (recordCount * 10)); // ~0.5-1s
      case NetworkQuality.fourG:
        return Duration(milliseconds: 1000 + (recordCount * 20)); // ~1-2s
      case NetworkQuality.threeG:
        return Duration(milliseconds: 2000 + (recordCount * 50)); // ~2-3s
      case NetworkQuality.twoG:
        return Duration(milliseconds: 5000 + (recordCount * 100)); // ~5-6s
      case NetworkQuality.offline:
        return Duration(milliseconds: 100); // Instant from cache
    }
  }

  /// Check if network is good enough for full data load
  static Future<bool> isNetworkSufficient() async {
    final quality = await detectNetworkQuality();
    return quality == NetworkQuality.wifi || quality == NetworkQuality.fourG;
  }

  /// Stream network quality changes
  static Stream<NetworkQuality> watchNetworkQuality() {
    return _connectivity.onConnectivityChanged.asyncMap((_) async {
      return await detectNetworkQuality();
    });
  }

  /// Get recommended page size for pagination
  static Future<int> getRecommendedPageSize() async {
    final config = await getAdaptiveConfig();
    return config.pageSize;
  }

  /// Check if should use progressive loading
  static Future<bool> shouldUseProgressiveLoading() async {
    final quality = await detectNetworkQuality();
    // Use progressive loading on 3G or slower
    return quality == NetworkQuality.threeG ||
        quality == NetworkQuality.twoG;
  }

  /// Get timeout duration based on network quality
  static Future<Duration> getTimeoutDuration() async {
    final quality = await detectNetworkQuality();
    switch (quality) {
      case NetworkQuality.wifi:
        return const Duration(seconds: 10);
      case NetworkQuality.fourG:
        return const Duration(seconds: 15);
      case NetworkQuality.threeG:
        return const Duration(seconds: 20);
      case NetworkQuality.twoG:
        return const Duration(seconds: 30);
      case NetworkQuality.offline:
        return const Duration(seconds: 5);
    }
  }
}

/// Mixin for widgets that need network-adaptive behavior
mixin NetworkAdaptiveMixin {
  NetworkQuality? _currentQuality;

  /// Initialize network quality monitoring
  Future<void> initNetworkAdaptive() async {
    _currentQuality = await NetworkAdaptiveLoader.detectNetworkQuality();
  }

  /// Get current network quality
  NetworkQuality get networkQuality =>
      _currentQuality ?? NetworkQuality.threeG;

  /// Get adaptive configuration
  NetworkAdaptiveConfig get config =>
      NetworkAdaptiveLoader.getConfig(networkQuality);

  /// Check if should show network warning
  bool get shouldShowNetworkWarning =>
      networkQuality == NetworkQuality.twoG ||
      networkQuality == NetworkQuality.threeG;
}
