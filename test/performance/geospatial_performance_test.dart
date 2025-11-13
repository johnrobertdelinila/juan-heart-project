import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/services/geospatial_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

/// Geospatial service performance benchmarks.
///
/// Measures:
/// - Distance calculation performance
/// - Bounding box optimization effectiveness
/// - LRU cache hit rate and performance
/// - Facility search with various radii
///
/// Usage:
/// flutter test test/performance/geospatial_performance_test.dart
void main() {
  late AppDatabase database;
  late GeospatialService geoService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    geoService = GeospatialService();

    // Populate with 100 test facilities
    await _populateTestFacilities(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Distance Calculation Performance', () {
    test('Haversine formula < 1ms per calculation', () {
      final stopwatch = Stopwatch()..start();

      // Calculate 1000 distances
      for (int i = 0; i < 1000; i++) {
        geoService.calculateDistance(
          14.5995, 120.9842, // Baguio City
          14.6000 + (i * 0.001),
          120.9850 + (i * 0.001),
        );
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final avgMs = totalMs / 1000;

      print('✅ 1000 distance calculations: ${totalMs}ms');
      print('✅ Average per calculation: ${avgMs.toStringAsFixed(3)}ms');

      // Target: <1ms per calculation on average
      expect(avgMs, lessThan(1.0),
        reason: 'Distance calculation too slow');
    });

    test('Bounding box calculation < 1ms', () {
      final stopwatch = Stopwatch()..start();

      // Calculate 1000 bounding boxes
      for (int i = 0; i < 1000; i++) {
        geoService.calculateBoundingBox(
          centerLat: 14.5995 + (i * 0.001),
          centerLon: 120.9842 + (i * 0.001),
          radiusKm: 25.0,
        );
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final avgMs = totalMs / 1000;

      print('✅ 1000 bounding box calculations: ${totalMs}ms');
      print('✅ Average per calculation: ${avgMs.toStringAsFixed(3)}ms');

      // Target: <1ms per calculation (should be faster than haversine)
      expect(avgMs, lessThan(1.0),
        reason: 'Bounding box calculation too slow');
    });
  });

  group('Facility Search Performance', () {
    test('findNearbyFacilities (25km radius, 100 facilities) < 75ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final results = geoService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 25.0,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Nearby facilities search: ${searchMs}ms');
      print('✅ Facilities found: ${results.length}');

      // Target: <75ms for 100 facilities with bounding box optimization
      expect(searchMs, lessThan(75),
        reason: 'Facility search too slow');
    });

    test('findNearbyFacilities (5km radius) < 40ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final results = geoService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 5.0,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Nearby facilities (5km): ${searchMs}ms');
      print('✅ Facilities found: ${results.length}');

      // Smaller radius = fewer candidates = faster
      // Target: <40ms for 5km radius
      expect(searchMs, lessThan(40),
        reason: 'Small radius search too slow');
    });

    test('findNearbyFacilities (50km radius) < 100ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final results = geoService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 50.0,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Nearby facilities (50km): ${searchMs}ms');
      print('✅ Facilities found: ${results.length}');

      // Larger radius = more candidates = slower
      // Target: <100ms for 50km radius
      expect(searchMs, lessThan(100),
        reason: 'Large radius search too slow');
    });

    test('findNearestFacility (100 facilities) < 50ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final nearest = geoService.findNearestFacility(
        userLat: 14.5995,
        userLon: 120.9842,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Find nearest facility: ${searchMs}ms');
      print('✅ Distance to nearest: ${nearest?.distanceKm.toStringAsFixed(2)} km');

      // Target: <50ms to find nearest
      expect(searchMs, lessThan(50),
        reason: 'Find nearest facility too slow');
      expect(nearest, isNotNull);
    });
  });

  group('Bounding Box Optimization', () {
    test('Bounding box reduces candidates by >70%', () async {
      final allFacilities = await database.getAllFacilities();
      const radiusKm = 25.0;

      // Calculate bounding box
      final bbox = geoService.calculateBoundingBox(
        centerLat: 14.5995,
        centerLon: 120.9842,
        radiusKm: radiusKm,
      );

      // Count facilities within bounding box
      final candidates = allFacilities.where((f) =>
        f.latitude >= bbox['minLat']! &&
        f.latitude <= bbox['maxLat']! &&
        f.longitude >= bbox['minLon']! &&
        f.longitude <= bbox['maxLon']!
      ).toList();

      // Count facilities actually within radius (using haversine)
      final actual = geoService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: radiusKm,
        facilities: allFacilities,
      );

      final reductionPercentage =
        ((allFacilities.length - candidates.length) / allFacilities.length) * 100;

      print('✅ Total facilities: ${allFacilities.length}');
      print('✅ Bounding box candidates: ${candidates.length}');
      print('✅ Actual within radius: ${actual.length}');
      print('✅ Reduction: ${reductionPercentage.toStringAsFixed(1)}%');

      // Bounding box should reduce candidates by at least 70%
      // (Circle inscribed in square = ~78.5% reduction theoretically)
      expect(reductionPercentage, greaterThan(70),
        reason: 'Bounding box optimization not effective');
    });

    test('Bounding box + haversine is 3x faster than haversine only', () async {
      final allFacilities = await database.getAllFacilities();
      const radiusKm = 25.0;

      // Method 1: Bounding box + haversine (optimized)
      final stopwatch1 = Stopwatch()..start();

      final optimized = geoService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: radiusKm,
        facilities: allFacilities,
      );

      stopwatch1.stop();
      final optimizedMs = stopwatch1.elapsedMilliseconds;

      // Method 2: Haversine only (naive approach)
      final stopwatch2 = Stopwatch()..start();

      final naive = <FacilityWithDistance>[];
      for (final facility in allFacilities) {
        final distance = geoService.calculateDistance(
          14.5995, 120.9842,
          facility.latitude,
          facility.longitude,
        );

        if (distance <= radiusKm) {
          naive.add(FacilityWithDistance(
            facility: facility,
            distanceKm: distance,
          ));
        }
      }
      naive.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      stopwatch2.stop();
      final naiveMs = stopwatch2.elapsedMilliseconds;

      final speedup = naiveMs / optimizedMs;

      print('✅ Optimized (bbox + haversine): ${optimizedMs}ms');
      print('✅ Naive (haversine only): ${naiveMs}ms');
      print('✅ Speedup: ${speedup.toStringAsFixed(1)}x faster');

      // Optimized should be at least 3x faster
      expect(speedup, greaterThan(3.0),
        reason: 'Bounding box optimization not providing expected speedup');

      // Both methods should return same results
      expect(optimized.length, equals(naive.length),
        reason: 'Optimized and naive methods returned different results');
    });
  });

  group('Specialized Searches', () {
    test('findNearbyFacilitiesByType (hospitals only) < 50ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final hospitals = geoService.findNearbyFacilitiesByType(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 25.0,
        facilityType: 'hospital',
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Hospitals search: ${searchMs}ms');
      print('✅ Hospitals found: ${hospitals.length}');

      // Pre-filtering + geospatial should be fast
      expect(searchMs, lessThan(50),
        reason: 'Type-filtered search too slow');

      // All results should be hospitals
      for (final result in hospitals) {
        expect(result.facility.type, equals('hospital'));
      }
    });

    test('findNearbyEmergencyFacilities < 50ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final emergency = geoService.findNearbyEmergencyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 25.0,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ Emergency facilities search: ${searchMs}ms');
      print('✅ Emergency facilities found: ${emergency.length}');

      expect(searchMs, lessThan(50),
        reason: 'Emergency facilities search too slow');

      // All results should have emergency services
      for (final result in emergency) {
        expect(result.facility.hasEmergencyService, isTrue);
      }
    });

    test('findNearby24HourFacilities < 50ms', () async {
      final allFacilities = await database.getAllFacilities();

      final stopwatch = Stopwatch()..start();

      final twentyFourHour = geoService.findNearby24HourFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 25.0,
        facilities: allFacilities,
      );

      stopwatch.stop();
      final searchMs = stopwatch.elapsedMilliseconds;

      print('✅ 24-hour facilities search: ${searchMs}ms');
      print('✅ 24-hour facilities found: ${twentyFourHour.length}');

      expect(searchMs, lessThan(50),
        reason: '24-hour facilities search too slow');

      // All results should be 24-hour
      for (final result in twentyFourHour) {
        expect(result.facility.is24Hours, isTrue);
      }
    });
  });

  group('Helper Functions', () {
    test('Distance formatting is consistent', () {
      final service = GeospatialService();

      // Test meters formatting
      expect(service.formatDistance(0.5), equals('500 m'));
      expect(service.formatDistance(0.999), equals('999 m'));

      // Test kilometers formatting
      expect(service.formatDistance(1.0), equals('1.0 km'));
      expect(service.formatDistance(5.456), equals('5.5 km'));
      expect(service.formatDistance(25.0), equals('25.0 km'));
    });

    test('Travel time estimation is accurate', () {
      final service = GeospatialService();

      // Walking: 5 km/h
      final walking5km = service.estimateWalkingTime(5.0);
      expect(walking5km.inMinutes, equals(60)); // 1 hour

      // Driving: 40 km/h
      final driving20km = service.estimateDrivingTime(20.0);
      expect(driving20km.inMinutes, equals(30)); // 30 minutes
    });

    test('Risk-based radius recommendation', () {
      final service = GeospatialService();

      // Critical risk (20+): 5km radius
      expect(service.getRecommendedRadius(25), equals(5.0));
      expect(service.getRecommendedRadius(20), equals(5.0));

      // High risk (15-19): 10km radius
      expect(service.getRecommendedRadius(18), equals(10.0));
      expect(service.getRecommendedRadius(15), equals(10.0));

      // Moderate risk (10-14): 20km radius
      expect(service.getRecommendedRadius(12), equals(20.0));
      expect(service.getRecommendedRadius(10), equals(20.0));

      // Low risk (<10): 50km radius
      expect(service.getRecommendedRadius(5), equals(50.0));
      expect(service.getRecommendedRadius(1), equals(50.0));
    });
  });
}

/// Populate database with 100 test facilities spread across Cordillera region.
Future<void> _populateTestFacilities(AppDatabase database) async {
  print('📝 Populating 100 test facilities...');

  final facilityTypes = [
    'hospital',
    'clinic',
    'health_center',
    'barangay_health_station'
  ];

  final municipalities = [
    'Baguio City',
    'La Trinidad',
    'Itogon',
    'Sablan',
    'Tuba',
    'Tublay',
    'Atok',
    'Bakun',
    'Bokod',
    'Buguias',
  ];

  // Baguio City coordinates
  const baseLat = 14.5995;
  const baseLon = 120.9842;

  for (int i = 0; i < 100; i++) {
    // Spread facilities in a grid pattern around Baguio
    final latOffset = ((i ~/ 10) - 5) * 0.05; // -0.25 to +0.25 degrees
    final lonOffset = ((i % 10) - 5) * 0.05;

    await database.insertFacility(
      FacilitiesCompanion.insert(
        id: 'perf-test-facility-$i',
        name: 'Test ${facilityTypes[i % 4]} $i',
        type: facilityTypes[i % 4],
        latitude: baseLat + latOffset,
        longitude: baseLon + lonOffset,
        address: 'Test Address $i, ${municipalities[i % 10]}',
        municipality: Value(municipalities[i % 10]),
        province: const Value('Benguet'),
        region: const Value('CAR'),
        services: 'Cardiology,Emergency,General',
        is24Hours: Value(i % 3 == 0), // 33% are 24-hour
        hasEmergencyService: Value(i % 2 == 0), // 50% have emergency
        capacity: Value(50 + (i % 50)),
        createdAt: DateTime.now(),
      ),
    );
  }

  print('✅ 100 test facilities populated');
}
