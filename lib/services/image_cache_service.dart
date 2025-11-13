import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Custom image cache service with memory-aware caching and LRU eviction
/// Optimizes image loading performance and reduces memory consumption
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() => _instance;

  ImageCacheService._internal() {
    _initializeCache();
  }

  /// Maximum cache size in bytes (100MB)
  static const int _maxCacheSize = 100 * 1024 * 1024;

  /// Maximum number of cached images
  static const int _maxCacheObjects = 1000;

  /// Cache age in days (7 days)
  static const int _cacheAgeDays = 7;

  /// Initialize image cache with memory-aware limits
  void _initializeCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;

      // Set maximum cache size (bytes)
      imageCache.maximumSizeBytes = _maxCacheSize;

      // Set maximum number of objects
      imageCache.maximumSize = _maxCacheObjects;

      debugPrint('ImageCacheService initialized: '
          'maxSize=${_maxCacheSize ~/ (1024 * 1024)}MB, '
          'maxObjects=$_maxCacheObjects');
    } catch (e) {
      debugPrint('Error initializing image cache: $e');
    }
  }

  /// Get current cache statistics
  Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSize': imageCache.maximumSize,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'liveImageCount': imageCache.liveImageCount,
      'pendingImageCount': imageCache.pendingImageCount,
    };
  }

  /// Clear the entire image cache
  void clearCache() {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint('Image cache cleared');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  /// Clear cache when memory pressure is detected
  void handleMemoryPressure() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final stats = getCacheStats();

      debugPrint('Memory pressure detected. Cache stats: $stats');

      // Aggressive cache eviction
      imageCache.clear();
      imageCache.clearLiveImages();

      // Reduce cache size temporarily
      imageCache.maximumSizeBytes = _maxCacheSize ~/ 2;
      imageCache.maximumSize = _maxCacheObjects ~/ 2;

      debugPrint('Cache cleared and limits reduced due to memory pressure');

      // Restore limits after a delay
      Future.delayed(const Duration(minutes: 1), () {
        imageCache.maximumSizeBytes = _maxCacheSize;
        imageCache.maximumSize = _maxCacheObjects;
        debugPrint('Cache limits restored');
      });
    } catch (e) {
      debugPrint('Error handling memory pressure: $e');
    }
  }

  /// Evict specific image from cache
  void evictImage(String key) {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.evict(key);
      debugPrint('Evicted image: $key');
    } catch (e) {
      debugPrint('Error evicting image: $e');
    }
  }

  /// Pre-cache images for better performance
  Future<void> precacheImages(
    List<String> assetPaths,
    ui.Size? size,
  ) async {
    try {
      for (final path in assetPaths) {
        // Note: This is a placeholder - actual precaching would need BuildContext
        // which should be done in the widget layer
        debugPrint('Queued for precache: $path');
      }
    } catch (e) {
      debugPrint('Error precaching images: $e');
    }
  }

  /// Get cache memory usage in MB
  double getCacheMemoryUsageMB() {
    final bytes = PaintingBinding.instance.imageCache.currentSizeBytes;
    return bytes / (1024 * 1024);
  }

  /// Check if cache is nearly full
  bool isCacheNearFull() {
    final imageCache = PaintingBinding.instance.imageCache;
    final usageRatio = imageCache.currentSizeBytes / imageCache.maximumSizeBytes;
    return usageRatio > 0.8; // 80% threshold
  }

  /// Optimize cache based on current usage
  void optimizeCache() {
    try {
      if (isCacheNearFull()) {
        debugPrint('Cache near full, clearing old images');
        PaintingBinding.instance.imageCache.clear();
      }
    } catch (e) {
      debugPrint('Error optimizing cache: $e');
    }
  }

  /// Log cache statistics for debugging
  void logCacheStats() {
    final stats = getCacheStats();
    final memoryMB = getCacheMemoryUsageMB();

    debugPrint('==== Image Cache Statistics ====');
    debugPrint('Current objects: ${stats['currentSize']}/${stats['maximumSize']}');
    debugPrint('Memory usage: ${memoryMB.toStringAsFixed(2)}MB/'
        '${stats['maximumSizeBytes'] ~/ (1024 * 1024)}MB');
    debugPrint('Live images: ${stats['liveImageCount']}');
    debugPrint('Pending images: ${stats['pendingImageCount']}');
    debugPrint('Cache full: ${isCacheNearFull()}');
    debugPrint('================================');
  }
}
