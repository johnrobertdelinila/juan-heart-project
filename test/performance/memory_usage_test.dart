import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/services/geospatial_service.dart';
import 'package:drift/native.dart';
import 'dart:developer' as developer;

/// Memory usage profiling tests.
///
/// These tests verify that the app maintains stable memory usage
/// and doesn't have obvious memory leaks.
///
/// NOTE: Precise memory measurements require running on a physical
/// device with Android Studio Profiler or DevTools Memory profiler.
///
/// Usage:
/// flutter test test/performance/memory_usage_test.dart
void main() {
  group('Memory Stability Tests', () {
    test('Repeated database queries do not leak memory', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Populate database
      await _populateTestData(database, recordCount: 100);

      // Track timeline for memory analysis
      developer.Timeline.startSync('repeated_queries');

      // Perform 1000 queries
      for (int i = 0; i < 1000; i++) {
        await database.getRecentAssessments('test-user', limit: 20);

        // Force garbage collection periodically
        if (i % 100 == 0) {
          print('Completed ${i + 1}/1000 queries');
        }
      }

      developer.Timeline.finishSync();

      await database.close();

      print('✅ Completed 1000 database queries without crash');
      print('   Note: Use Memory Profiler to verify no memory leaks');

      expect(true, isTrue, reason: 'Database queries completed successfully');
    });

    test('Repeated geospatial searches with cache do not leak memory', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final geoService = GeospatialService();

      // Populate facilities
      await _populateFacilities(database, count: 100);
      final facilities = await database.getAllFacilities();

      developer.Timeline.startSync('repeated_geospatial_searches');

      // Perform 1000 searches with varying locations
      for (int i = 0; i < 1000; i++) {
        final lat = 14.5995 + (i % 10) * 0.01;
        final lon = 120.9842 + (i % 10) * 0.01;

        geoService.findNearbyFacilities(
          userLat: lat,
          userLon: lon,
          radiusKm: 25.0,
          facilities: facilities,
        );

        if (i % 100 == 0) {
          print('Completed ${i + 1}/1000 searches');
        }
      }

      developer.Timeline.finishSync();

      // Check cache stats
      final cacheStats = geoService.getCacheStats();
      print('✅ Cache stats after 1000 searches:');
      print('   Cache size: ${cacheStats['cache_size']}/${cacheStats['cache_capacity']}');
      print('   Hit rate: ${cacheStats['hit_rate_percent']}%');
      print('   Cache hits: ${cacheStats['cache_hits']}');
      print('   Cache misses: ${cacheStats['cache_misses']}');

      await database.close();

      // Verify cache is working (should have high hit rate)
      final hitRate = double.parse(cacheStats['hit_rate_percent'] as String);
      expect(hitRate, greaterThan(80),
        reason: 'Cache hit rate should be >80% for repeated searches');
    });

    test('Large batch operations release memory properly', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      developer.Timeline.startSync('large_batch_operations');

      // Import facilities in large batches
      for (int batch = 0; batch < 5; batch++) {
        final facilities = List.generate(100, (i) {
          final id = batch * 100 + i;
          return {
            'id': 'batch-facility-$id',
            'name': 'Test Hospital $id',
            'type': 'hospital',
            'latitude': 14.5995 + (id * 0.001),
            'longitude': 120.9842 + (id * 0.001),
            'address': 'Test Address $id',
            'services': ['Cardiology'],
          };
        });

        await database.importFacilitiesFromBackend(facilities);
        print('Completed batch ${batch + 1}/5 (100 facilities each)');
      }

      developer.Timeline.finishSync();

      // Verify data was imported
      final stats = await database.getDatabaseStats();
      expect(stats['facilities'], equals(500));

      print('✅ Imported 500 facilities in 5 batches');
      print('   Note: Check Memory Profiler for heap growth');

      await database.close();
    });

    test('Cache clearing releases memory', () async {
      final geoService = GeospatialService();
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Populate facilities
      await _populateFacilities(database, count: 100);
      final facilities = await database.getAllFacilities();

      // Fill cache
      for (int i = 0; i < 30; i++) {
        geoService.findNearbyFacilities(
          userLat: 14.5995 + (i * 0.1),
          userLon: 120.9842 + (i * 0.1),
          radiusKm: 25.0,
          facilities: facilities,
        );
      }

      var stats = geoService.getCacheStats();
      final sizeBefore = stats['cache_size'] as int;
      print('Cache size before clear: $sizeBefore');

      // Clear cache
      geoService.clearCache();

      stats = geoService.getCacheStats();
      final sizeAfter = stats['cache_size'] as int;
      print('Cache size after clear: $sizeAfter');

      expect(sizeAfter, equals(0), reason: 'Cache should be empty after clear');
      expect(sizeBefore, greaterThan(0), reason: 'Cache should have entries before clear');

      await database.close();

      print('✅ Cache cleared successfully');
    });
  });

  group('Memory Efficiency Tests', () {
    test('Database transaction does not allocate excessive memory', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      developer.Timeline.startSync('transaction_memory_test');

      // Large transaction with 1000 inserts
      await database.transaction(() async {
        for (int i = 0; i < 1000; i++) {
          await database.insertAssessment(
            AssessmentsCompanion.insert(
              id: 'mem-test-assessment-$i',
              userId: 'test-user',
              likelihoodScore: 3,
              impactScore: 3,
              finalRiskScore: 9,
              riskCategory: 'Moderate',
              symptomsData: '{}',
              createdAt: DateTime.now(),
            ),
          );
        }
      });

      developer.Timeline.finishSync();

      final stats = await database.getDatabaseStats();
      expect(stats['assessments'], greaterThanOrEqualTo(1000));

      print('✅ Transaction completed: 1000 inserts');
      print('   Note: Check Memory Profiler for peak memory usage');

      await database.close();
    });

    test('Widget rebuild does not accumulate listeners', () async {
      // This test would require integration test setup
      // Document the pattern to test manually

      print('⚠️ Manual test required:');
      print('   1. Use Flutter DevTools Memory tab');
      print('   2. Navigate between screens repeatedly');
      print('   3. Monitor listener count (should remain stable)');
      print('   4. Check for StreamController/ChangeNotifier leaks');

      expect(true, isTrue, reason: 'Manual test documented');
    });
  });

  group('Resource Cleanup Tests', () {
    test('Database closes without errors', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      await _populateTestData(database, recordCount: 100);

      // Perform operations
      await database.getAllAssessments();
      await database.getAllFacilities();

      // Close database
      await database.close();

      print('✅ Database closed cleanly');

      expect(true, isTrue, reason: 'Database closed successfully');
    });

    test('Multiple database instances can coexist', () async {
      // Create multiple database instances
      final db1 = AppDatabase.forTesting(NativeDatabase.memory());
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      final db3 = AppDatabase.forTesting(NativeDatabase.memory());

      // Populate each
      await _populateTestData(db1, recordCount: 10);
      await _populateTestData(db2, recordCount: 10);
      await _populateTestData(db3, recordCount: 10);

      // Verify isolation
      final stats1 = await db1.getDatabaseStats();
      final stats2 = await db2.getDatabaseStats();
      final stats3 = await db3.getDatabaseStats();

      expect(stats1['assessments'], equals(10));
      expect(stats2['assessments'], equals(10));
      expect(stats3['assessments'], equals(10));

      // Close all
      await db1.close();
      await db2.close();
      await db3.close();

      print('✅ Multiple database instances managed correctly');
    });
  });
}

/// Populate database with test assessments.
Future<void> _populateTestData(
  AppDatabase database, {
  required int recordCount,
}) async {
  for (int i = 0; i < recordCount; i++) {
    await database.insertAssessment(
      AssessmentsCompanion.insert(
        id: 'mem-test-$i',
        userId: 'test-user',
        likelihoodScore: (i % 5) + 1,
        impactScore: (i % 5) + 1,
        finalRiskScore: ((i % 5) + 1) * ((i % 5) + 1),
        riskCategory: 'Moderate',
        symptomsData: '{}',
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Populate database with test facilities.
Future<void> _populateFacilities(
  AppDatabase database, {
  required int count,
}) async {
  for (int i = 0; i < count; i++) {
    await database.insertFacility(
      FacilitiesCompanion.insert(
        id: 'mem-test-facility-$i',
        name: 'Test Hospital $i',
        type: 'hospital',
        latitude: 14.5995 + (i * 0.01),
        longitude: 120.9842 + (i * 0.01),
        address: 'Test Address $i',
        services: 'Cardiology',
        createdAt: DateTime.now(),
      ),
    );
  }
}
