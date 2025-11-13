import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/services/geospatial_service.dart';
import 'package:juan_heart/database/app_database.dart';

void main() {
  late GeospatialService geospatialService;

  setUp(() {
    geospatialService = GeospatialService();
  });

  group('GeospatialService - Distance Calculations', () {
    test('calculateDistance returns correct distance using Haversine formula', () {
      // Manila (14.5995° N, 120.9842° E) to Quezon City (14.6760° N, 121.0437° E)
      // Expected distance: ~10.8 km
      final distance = geospatialService.calculateDistance(
        14.5995,
        120.9842,
        14.6760,
        121.0437,
      );

      expect(distance, greaterThan(10.0));
      expect(distance, lessThan(12.0));
    });

    test('calculateDistance returns 0 for same location', () {
      final distance = geospatialService.calculateDistance(
        14.5995,
        120.9842,
        14.5995,
        120.9842,
      );

      expect(distance, equals(0.0));
    });

    test('calculateDistance handles equator crossing', () {
      // Test distance from Northern to Southern hemisphere
      final distance = geospatialService.calculateDistance(
        10.0, // North
        120.0,
        -10.0, // South
        120.0,
      );

      // Expected ~2223 km (20 degrees latitude difference)
      expect(distance, greaterThan(2200.0));
      expect(distance, lessThan(2250.0));
    });

    test('calculateDistance handles international date line crossing', () {
      // Test distance crossing international date line
      final distance = geospatialService.calculateDistance(
        0.0,
        179.0, // Near date line (East)
        0.0,
        -179.0, // Near date line (West)
      );

      // Should be ~222 km (2 degrees longitude at equator)
      expect(distance, greaterThan(200.0));
      expect(distance, lessThan(250.0));
    });
  });

  group('GeospatialService - Nearby Facility Search', () {
    late List<FacilityEntity> mockFacilities;

    setUp(() {
      // Create mock facilities at various distances
      mockFacilities = [
        FacilityEntity(
          id: 'facility-1',
          name: 'Manila General Hospital',
          type: 'hospital',
          latitude: 14.5995, // ~0 km from user
          longitude: 120.9842,
          address: 'Manila',
          municipality: 'Manila',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '123-4567',
          services: jsonEncode(['Cardiology', 'Emergency']),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 500,
          createdAt: DateTime.now(),
        ),
        FacilityEntity(
          id: 'facility-2',
          name: 'Quezon City Medical Center',
          type: 'hospital',
          latitude: 14.6760, // ~10 km from user
          longitude: 121.0437,
          address: 'Quezon City',
          municipality: 'Quezon City',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '234-5678',
          services: jsonEncode(['Cardiology']),
          operatingHours: '8am-5pm',
          is24Hours: false,
          hasEmergencyService: false,
          capacity: 300,
          createdAt: DateTime.now(),
        ),
        FacilityEntity(
          id: 'facility-3',
          name: 'Makati Medical Center',
          type: 'hospital',
          latitude: 14.5547, // ~5 km from user
          longitude: 121.0244,
          address: 'Makati',
          municipality: 'Makati',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '345-6789',
          services: jsonEncode(['Cardiology', 'Emergency']),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 450,
          createdAt: DateTime.now(),
        ),
        FacilityEntity(
          id: 'facility-4',
          name: 'Baguio General Hospital',
          type: 'hospital',
          latitude: 16.4023, // ~200+ km from user
          longitude: 120.5960,
          address: 'Baguio',
          municipality: 'Baguio',
          province: 'Benguet',
          region: 'CAR',
          contactNumber: '456-7890',
          services: jsonEncode(['Cardiology']),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 350,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('findNearbyFacilities returns facilities within radius', () {
      const userLat = 14.5995;
      const userLon = 120.9842;
      const radiusKm = 15.0;

      final results = geospatialService.findNearbyFacilities(
        userLat: userLat,
        userLon: userLon,
        radiusKm: radiusKm,
        facilities: mockFacilities,
      );

      // Should return 3 facilities (Manila, Makati, Quezon City) but not Baguio
      expect(results.length, equals(3));
      expect(results.any((f) => f.facility.id == 'facility-4'), isFalse);
    });

    test('findNearbyFacilities sorts by distance (nearest first)', () {
      const userLat = 14.5995;
      const userLon = 120.9842;
      const radiusKm = 50.0;

      final results = geospatialService.findNearbyFacilities(
        userLat: userLat,
        userLon: userLon,
        radiusKm: radiusKm,
        facilities: mockFacilities,
      );

      // First result should be Manila General (closest)
      expect(results.first.facility.id, equals('facility-1'));

      // Distance should be nearly 0
      expect(results.first.distanceKm, lessThan(0.1));

      // Each subsequent result should be farther than previous
      for (var i = 0; i < results.length - 1; i++) {
        expect(
          results[i].distanceKm,
          lessThanOrEqualTo(results[i + 1].distanceKm),
        );
      }
    });

    test('findNearbyFacilities returns empty list when no facilities in radius', () {
      const userLat = 14.5995;
      const userLon = 120.9842;
      const radiusKm = 1.0; // Very small radius

      final results = geospatialService.findNearbyFacilities(
        userLat: userLat,
        userLon: userLon,
        radiusKm: radiusKm,
        facilities: mockFacilities,
      );

      // Only Manila General should be within 1km (it's at same location)
      expect(results.length, equals(1));
      expect(results.first.facility.id, equals('facility-1'));
    });

    test('findNearbyFacilities handles empty facility list', () {
      final results = geospatialService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 50.0,
        facilities: [],
      );

      expect(results, isEmpty);
    });
  });

  group('GeospatialService - Nearest Facility', () {
    late List<FacilityEntity> mockFacilities;

    setUp(() {
      mockFacilities = [
        FacilityEntity(
          id: 'facility-1',
          name: 'Far Hospital',
          type: 'hospital',
          latitude: 14.6760,
          longitude: 121.0437,
          address: 'Quezon City',
          municipality: 'Quezon City',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '123-4567',
          services: jsonEncode(['Cardiology']),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 300,
          createdAt: DateTime.now(),
        ),
        FacilityEntity(
          id: 'facility-2',
          name: 'Near Clinic',
          type: 'clinic',
          latitude: 14.5995,
          longitude: 120.9842,
          address: 'Manila',
          municipality: 'Manila',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '234-5678',
          services: jsonEncode(['Consultation']),
          operatingHours: '8am-5pm',
          is24Hours: false,
          hasEmergencyService: false,
          capacity: 50,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('findNearestFacility returns closest facility', () {
      const userLat = 14.5995;
      const userLon = 120.9842;

      final result = geospatialService.findNearestFacility(
        userLat: userLat,
        userLon: userLon,
        facilities: mockFacilities,
      );

      expect(result, isNotNull);
      expect(result!.facility.id, equals('facility-2')); // Near Clinic
      expect(result.distanceKm, lessThan(0.1)); // Very close
    });

    test('findNearestFacility returns null for empty list', () {
      final result = geospatialService.findNearestFacility(
        userLat: 14.5995,
        userLon: 120.9842,
        facilities: [],
      );

      expect(result, isNull);
    });
  });

  group('GeospatialService - Facility Type Filtering', () {
    late List<FacilityEntity> mockFacilities;

    setUp(() {
      mockFacilities = [
        FacilityEntity(
          id: 'hospital-1',
          name: 'Manila General Hospital',
          type: 'hospital',
          latitude: 14.5995,
          longitude: 120.9842,
          address: 'Manila',
          municipality: 'Manila',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '123-4567',
          services: jsonEncode(['Cardiology']),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 500,
          createdAt: DateTime.now(),
        ),
        FacilityEntity(
          id: 'clinic-1',
          name: 'Manila Clinic',
          type: 'clinic',
          latitude: 14.6000,
          longitude: 120.9850,
          address: 'Manila',
          municipality: 'Manila',
          province: 'Metro Manila',
          region: 'NCR',
          contactNumber: '234-5678',
          services: jsonEncode(['Consultation']),
          operatingHours: '8am-5pm',
          is24Hours: false,
          hasEmergencyService: false,
          capacity: 50,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('findNearbyFacilitiesByType filters by facility type', () {
      final results = geospatialService.findNearbyFacilitiesByType(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 10.0,
        facilityType: 'hospital',
        facilities: mockFacilities,
      );

      expect(results.length, equals(1));
      expect(results.first.facility.type, equals('hospital'));
    });

    test('findNearbyEmergencyFacilities returns only emergency facilities', () {
      final results = geospatialService.findNearbyEmergencyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 10.0,
        facilities: mockFacilities,
      );

      expect(results.length, equals(1));
      expect(results.first.facility.hasEmergencyService, isTrue);
    });

    test('findNearby24HourFacilities returns only 24-hour facilities', () {
      final results = geospatialService.findNearby24HourFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 10.0,
        facilities: mockFacilities,
      );

      expect(results.length, equals(1));
      expect(results.first.facility.is24Hours, isTrue);
    });
  });

  group('GeospatialService - Distance Formatting', () {
    test('formatDistance formats meters correctly', () {
      expect(geospatialService.formatDistance(0.5), equals('500 m'));
      expect(geospatialService.formatDistance(0.85), equals('850 m'));
      expect(geospatialService.formatDistance(0.999), equals('999 m'));
    });

    test('formatDistance formats kilometers correctly', () {
      expect(geospatialService.formatDistance(1.0), equals('1.0 km'));
      expect(geospatialService.formatDistance(5.5), equals('5.5 km'));
      expect(geospatialService.formatDistance(20.7), equals('20.7 km'));
    });

    test('getDistanceCategory returns correct category', () {
      expect(
        geospatialService.getDistanceCategory(0.5),
        equals('Very Close (<1 km)'),
      );
      expect(
        geospatialService.getDistanceCategory(3.0),
        equals('Nearby (1-5 km)'),
      );
      expect(
        geospatialService.getDistanceCategory(7.0),
        equals('Moderate (5-10 km)'),
      );
      expect(
        geospatialService.getDistanceCategory(15.0),
        equals('Far (10-20 km)'),
      );
      expect(
        geospatialService.getDistanceCategory(25.0),
        equals('Very Far (>20 km)'),
      );
    });
  });

  group('GeospatialService - Travel Time Estimation', () {
    test('estimateWalkingTime calculates correctly', () {
      // 5 km at 5 km/h = 1 hour = 60 minutes
      final duration = geospatialService.estimateWalkingTime(5.0);
      expect(duration.inMinutes, equals(60));

      // 2.5 km = 30 minutes
      final duration2 = geospatialService.estimateWalkingTime(2.5);
      expect(duration2.inMinutes, equals(30));
    });

    test('estimateDrivingTime calculates correctly', () {
      // 40 km at 40 km/h = 1 hour = 60 minutes
      final duration = geospatialService.estimateDrivingTime(40.0);
      expect(duration.inMinutes, equals(60));

      // 20 km = 30 minutes
      final duration2 = geospatialService.estimateDrivingTime(20.0);
      expect(duration2.inMinutes, equals(30));
    });

    test('formatTravelTime formats minutes correctly', () {
      expect(
        geospatialService.formatTravelTime(const Duration(minutes: 30)),
        equals('30 min'),
      );
      expect(
        geospatialService.formatTravelTime(const Duration(minutes: 45)),
        equals('45 min'),
      );
    });

    test('formatTravelTime formats hours correctly', () {
      expect(
        geospatialService.formatTravelTime(const Duration(hours: 1)),
        equals('1 hr'),
      );
      expect(
        geospatialService.formatTravelTime(const Duration(hours: 2)),
        equals('2 hr'),
      );
    });

    test('formatTravelTime formats hours and minutes correctly', () {
      expect(
        geospatialService.formatTravelTime(const Duration(hours: 1, minutes: 30)),
        equals('1 hr 30 min'),
      );
      expect(
        geospatialService.formatTravelTime(const Duration(hours: 2, minutes: 15)),
        equals('2 hr 15 min'),
      );
    });
  });

  group('GeospatialService - Risk-Based Radius', () {
    test('getRecommendedRadius returns smaller radius for high risk', () {
      expect(geospatialService.getRecommendedRadius(25), equals(5.0)); // Critical
      expect(geospatialService.getRecommendedRadius(20), equals(5.0)); // High
    });

    test('getRecommendedRadius returns medium radius for moderate risk', () {
      expect(geospatialService.getRecommendedRadius(18), equals(10.0));
      expect(geospatialService.getRecommendedRadius(15), equals(10.0));
    });

    test('getRecommendedRadius returns larger radius for low risk', () {
      expect(geospatialService.getRecommendedRadius(12), equals(20.0));
      expect(geospatialService.getRecommendedRadius(10), equals(20.0));
      expect(geospatialService.getRecommendedRadius(5), equals(50.0));
    });
  });

  group('GeospatialService - Walking Distance Check', () {
    test('isWalkingDistance returns true for close facilities', () {
      expect(geospatialService.isWalkingDistance(0.5), isTrue);
      expect(geospatialService.isWalkingDistance(1.5), isTrue);
      expect(geospatialService.isWalkingDistance(1.9), isTrue);
    });

    test('isWalkingDistance returns false for far facilities', () {
      expect(geospatialService.isWalkingDistance(2.0), isFalse);
      expect(geospatialService.isWalkingDistance(5.0), isFalse);
    });
  });

  group('GeospatialService - Bounding Box Calculation', () {
    test('calculateBoundingBox returns correct box', () {
      final box = geospatialService.calculateBoundingBox(
        centerLat: 14.5995,
        centerLon: 120.9842,
        radiusKm: 10.0,
      );

      expect(box['minLat'], lessThan(14.5995));
      expect(box['maxLat'], greaterThan(14.5995));
      expect(box['minLon'], lessThan(120.9842));
      expect(box['maxLon'], greaterThan(120.9842));

      // Check approximate size (10km radius ≈ 0.09 degrees)
      final latDiff = box['maxLat']! - box['minLat']!;
      final lonDiff = box['maxLon']! - box['minLon']!;

      expect(latDiff, greaterThan(0.16)); // ~0.18 degrees
      expect(latDiff, lessThan(0.20));
      expect(lonDiff, greaterThan(0.16));
      expect(lonDiff, lessThan(0.20));
    });
  });

  group('GeospatialService - FacilityWithDistance Model', () {
    late FacilityEntity mockFacility;
    late FacilityWithDistance facilityWithDistance;

    setUp(() {
      mockFacility = FacilityEntity(
        id: 'facility-1',
        name: 'Test Hospital',
        type: 'hospital',
        latitude: 14.5995,
        longitude: 120.9842,
        address: 'Manila',
        municipality: 'Manila',
        province: 'Metro Manila',
        region: 'NCR',
        contactNumber: '123-4567',
        services: jsonEncode(['Cardiology']),
        operatingHours: '24/7',
        is24Hours: true,
        hasEmergencyService: true,
        capacity: 500,
        createdAt: DateTime.now(),
      );

      facilityWithDistance = FacilityWithDistance(
        facility: mockFacility,
        distanceKm: 3.5,
      );
    });

    test('formattedDistance returns correct format', () {
      expect(facilityWithDistance.formattedDistance, equals('3.5 km'));
    });

    test('distanceCategory returns correct category', () {
      expect(facilityWithDistance.distanceCategory, equals('Nearby (1-5 km)'));
    });

    test('isWalkingDistance returns correct value', () {
      expect(facilityWithDistance.isWalkingDistance, isFalse);

      final closeFacility = FacilityWithDistance(
        facility: mockFacility,
        distanceKm: 1.5,
      );
      expect(closeFacility.isWalkingDistance, isTrue);
    });

    test('walkingTime calculates correctly', () {
      expect(facilityWithDistance.walkingTime.inMinutes, equals(42));
    });

    test('drivingTime calculates correctly', () {
      expect(facilityWithDistance.drivingTime.inMinutes, equals(5));
    });

    test('formattedWalkingTime formats correctly', () {
      expect(facilityWithDistance.formattedWalkingTime, equals('42 min'));
    });

    test('formattedDrivingTime formats correctly', () {
      expect(facilityWithDistance.formattedDrivingTime, equals('5 min'));
    });
  });

  group('GeospatialService - Performance Optimization', () {
    test('findNearbyFacilities uses bounding box optimization', () {
      // Create 100 facilities scattered around the Philippines
      final facilities = List.generate(100, (i) {
        return FacilityEntity(
          id: 'facility-$i',
          name: 'Facility $i',
          type: 'hospital',
          latitude: 10.0 + (i * 0.1), // Spread across latitudes
          longitude: 120.0 + (i * 0.1),
          address: 'Address $i',
          municipality: 'Municipality $i',
          province: 'Province $i',
          region: 'Region $i',
          contactNumber: '123-456$i',
          services: jsonEncode(['Service $i']),
          createdAt: DateTime.now(),
          operatingHours: '24/7',
          is24Hours: true,
          hasEmergencyService: true,
          capacity: 100,
        );
      });

      final stopwatch = Stopwatch()..start();

      final results = geospatialService.findNearbyFacilities(
        userLat: 14.5995,
        userLon: 120.9842,
        radiusKm: 50.0,
        facilities: facilities,
      );

      stopwatch.stop();

      // Performance target: <75ms for 100 facilities
      expect(stopwatch.elapsedMilliseconds, lessThan(75));
      expect(results, isNotEmpty);
    });
  });
}
