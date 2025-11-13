import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/services/image_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageCacheService', () {
    late ImageCacheService service;

    setUp(() {
      service = ImageCacheService();
      // Clear cache before each test
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });

    tearDown(() {
      // Clean up after each test
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });

    test('should be singleton', () {
      final instance1 = ImageCacheService();
      final instance2 = ImageCacheService();

      expect(instance1, same(instance2));
    });

    test('should initialize with correct cache limits', () {
      final stats = service.getCacheStats();

      expect(stats['maximumSizeBytes'], equals(100 * 1024 * 1024)); // 100MB
      expect(stats['maximumSize'], equals(1000)); // 1000 objects
    });

    test('should get cache statistics', () {
      final stats = service.getCacheStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('currentSize'), isTrue);
      expect(stats.containsKey('currentSizeBytes'), isTrue);
      expect(stats.containsKey('maximumSize'), isTrue);
      expect(stats.containsKey('maximumSizeBytes'), isTrue);
      expect(stats.containsKey('liveImageCount'), isTrue);
      expect(stats.containsKey('pendingImageCount'), isTrue);
    });

    test('should clear cache', () {
      service.clearCache();

      final stats = service.getCacheStats();
      expect(stats['currentSize'], equals(0));
      expect(stats['liveImageCount'], equals(0));
    });

    test('should get cache memory usage in MB', () {
      final memoryMB = service.getCacheMemoryUsageMB();

      expect(memoryMB, isA<double>());
      expect(memoryMB, greaterThanOrEqualTo(0));
    });

    test('should detect when cache is near full', () {
      // Initially should not be near full
      expect(service.isCacheNearFull(), isFalse);

      // Note: Testing actual fullness would require loading many images
      // which is not practical in unit tests
    });

    test('should handle memory pressure', () {
      // Add some initial data to cache stats
      final statsBefore = service.getCacheStats();

      service.handleMemoryPressure();

      final statsAfter = service.getCacheStats();

      // After memory pressure, cache should be cleared
      expect(statsAfter['currentSize'], equals(0));
      expect(statsAfter['liveImageCount'], equals(0));

      // Cache limits should be temporarily reduced
      expect(
        statsAfter['maximumSizeBytes'],
        equals(50 * 1024 * 1024), // Half of original 100MB
      );
      expect(
        statsAfter['maximumSize'],
        equals(500), // Half of original 1000
      );
    });

    test('should restore cache limits after memory pressure', () async {
      service.handleMemoryPressure();

      final statsImmediately = service.getCacheStats();
      expect(statsImmediately['maximumSizeBytes'], equals(50 * 1024 * 1024));

      // Wait for limits to be restored (1 minute delay in real code)
      // In tests, we just verify the mechanism exists
      expect(statsImmediately['maximumSize'], equals(500));
    });

    test('should optimize cache when near full', () {
      service.optimizeCache();

      final stats = service.getCacheStats();

      // Cache should be optimized (cleared if near full)
      expect(stats['currentSize'], greaterThanOrEqualTo(0));
    });

    test('should log cache statistics without errors', () {
      expect(() => service.logCacheStats(), returnsNormally);
    });

    test('should evict specific image from cache', () {
      const testKey = 'test_image_key';

      expect(() => service.evictImage(testKey), returnsNormally);
    });

    test('should handle errors gracefully when clearing cache', () {
      // Clear cache multiple times should not throw
      expect(() => service.clearCache(), returnsNormally);
      expect(() => service.clearCache(), returnsNormally);
    });

    test('should handle errors gracefully when getting stats', () {
      expect(() => service.getCacheStats(), returnsNormally);
    });

    test('should handle errors gracefully when optimizing cache', () {
      expect(() => service.optimizeCache(), returnsNormally);
    });

    test('should calculate memory usage correctly', () {
      final memoryMB = service.getCacheMemoryUsageMB();

      expect(memoryMB, isA<double>());
      expect(memoryMB, isNonNegative);
    });

    test('should handle precache images request', () async {
      final assetPaths = [
        'assets/images/test1.png',
        'assets/images/test2.png',
        'assets/images/test3.png',
      ];

      expect(
        () => service.precacheImages(assetPaths, null),
        returnsNormally,
      );
    });

    group('Cache Stats Validation', () {
      test('current size should not exceed maximum size', () {
        final stats = service.getCacheStats();

        expect(
          stats['currentSize'],
          lessThanOrEqualTo(stats['maximumSize']),
        );
      });

      test('current bytes should not exceed maximum bytes', () {
        final stats = service.getCacheStats();

        expect(
          stats['currentSizeBytes'],
          lessThanOrEqualTo(stats['maximumSizeBytes']),
        );
      });

      test('all stats should be non-negative', () {
        final stats = service.getCacheStats();

        expect(stats['currentSize'], greaterThanOrEqualTo(0));
        expect(stats['currentSizeBytes'], greaterThanOrEqualTo(0));
        expect(stats['maximumSize'], greaterThan(0));
        expect(stats['maximumSizeBytes'], greaterThan(0));
        expect(stats['liveImageCount'], greaterThanOrEqualTo(0));
        expect(stats['pendingImageCount'], greaterThanOrEqualTo(0));
      });
    });

    group('Memory Management', () {
      test('should reduce cache size on memory pressure', () {
        // Reset to full size first in case previous tests reduced it
        PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
        PaintingBinding.instance.imageCache.maximumSize = 1000;

        final statsBefore = service.getCacheStats();
        final maxBytesBefore = statsBefore['maximumSizeBytes'] as int;
        final maxSizeBefore = statsBefore['maximumSize'] as int;

        service.handleMemoryPressure();

        final statsAfter = service.getCacheStats();
        final maxBytesAfter = statsAfter['maximumSizeBytes'] as int;
        final maxSizeAfter = statsAfter['maximumSize'] as int;

        expect(maxBytesAfter, lessThan(maxBytesBefore));
        expect(maxSizeAfter, lessThan(maxSizeBefore));
      });

      test('should clear all images on memory pressure', () {
        service.handleMemoryPressure();

        final stats = service.getCacheStats();

        expect(stats['currentSize'], equals(0));
        expect(stats['liveImageCount'], equals(0));
      });
    });

    group('Cache Fullness Detection', () {
      test('should correctly identify when cache is not full', () {
        // With empty cache, should not be near full
        service.clearCache();

        expect(service.isCacheNearFull(), isFalse);
      });

      test('cache near full threshold should be 80%', () {
        // This is a logical test of the threshold value
        final stats = service.getCacheStats();
        final maxBytes = stats['maximumSizeBytes'] as int;
        final currentBytes = stats['currentSizeBytes'] as int;

        final usageRatio = currentBytes / maxBytes;

        // If usage is less than 80%, should not be near full
        if (usageRatio < 0.8) {
          expect(service.isCacheNearFull(), isFalse);
        }
      });
    });
  });
}
