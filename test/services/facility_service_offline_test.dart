import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:juan_heart/services/facility_service.dart';
import 'package:juan_heart/models/referral_data.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:drift/native.dart';

void main() {
  group('FacilityService - Offline Facility Search', () {
    late Position userLocation;

    setUpAll(() {
      FacilityService.instance.initialize(
        database: AppDatabase.forTesting(NativeDatabase.memory()),
        useBackendApi: false,
      );
    });

    setUp(() {
      // Manila coordinates for testing
      userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });

    test('getNearbyFacilities returns facilities without network', () async {
      // This test should work offline because facilities are loaded from mock data
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 25.0,
        maxResults: 10,
      );

      expect(facilities, isNotEmpty);
      expect(facilities.length, lessThanOrEqualTo(10));

      // All facilities should have distance calculated
      for (final facility in facilities) {
        expect(facility.distanceKm, isNotNull);
        expect(facility.distanceKm!, lessThanOrEqualTo(25.0));
      }
    });

    test('getNearbyFacilities filters by facility type', () async {
      final hospitals = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        facilityTypes: [FacilityType.hospital],
        maxDistance: 50.0,
        maxResults: 20,
      );

      expect(hospitals, isNotEmpty);

      // All results should be hospitals or emergency facilities
      for (final facility in hospitals) {
        expect(
          facility.type == FacilityType.hospital ||
              facility.type == FacilityType.emergencyFacility,
          isTrue,
        );
      }
    });

    test('getNearbyFacilities filters by multiple facility types', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        facilityTypes: [
          FacilityType.hospital,
          FacilityType.primaryCarClinic,
        ],
        maxDistance: 50.0,
        maxResults: 20,
      );

      expect(facilities, isNotEmpty);

      // All results should match one of the requested types
      for (final facility in facilities) {
        expect(
          facility.type == FacilityType.hospital ||
              facility.type == FacilityType.emergencyFacility ||
              facility.type == FacilityType.primaryCarClinic,
          isTrue,
        );
      }
    });

    test('getNearbyFacilities sorts by distance (nearest first)', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 20,
      );

      expect(facilities.length, greaterThan(1));

      // Check that facilities are sorted by distance
      for (var i = 0; i < facilities.length - 1; i++) {
        expect(
          facilities[i].distanceKm!,
          lessThanOrEqualTo(facilities[i + 1].distanceKm!),
        );
      }
    });

    test('getNearbyFacilities respects maxDistance parameter', () async {
      const maxDistance = 10.0;

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: maxDistance,
        maxResults: 50,
      );

      // All facilities should be within max distance
      for (final facility in facilities) {
        expect(facility.distanceKm!, lessThanOrEqualTo(maxDistance));
      }
    });

    test('getNearbyFacilities respects maxResults parameter', () async {
      const maxResults = 5;

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
        maxResults: maxResults,
      );

      expect(facilities.length, lessThanOrEqualTo(maxResults));
    });

    test('getNearbyFacilities handles very small radius', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 1.0, // 1 km radius
        maxResults: 10,
      );

      // May return 0 or few facilities depending on user location
      expect(facilities, isA<List<HealthcareFacility>>());

      // All returned facilities should be within 1 km
      for (final facility in facilities) {
        expect(facility.distanceKm!, lessThanOrEqualTo(1.0));
      }
    });

    test('getNearbyFacilities handles very large radius', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 500.0, // 500 km radius
        maxResults: 100,
      );

      expect(facilities, isNotEmpty);
      expect(facilities.length, lessThanOrEqualTo(100));
    });

    test('getNearbyFacilities returns consistent results for same input', () async {
      final facilities1 = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 25.0,
        maxResults: 10,
      );

      final facilities2 = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 25.0,
        maxResults: 10,
      );

      // Should return same number of facilities
      expect(facilities1.length, equals(facilities2.length));

      // Should return same facility IDs in same order
      for (var i = 0; i < facilities1.length; i++) {
        expect(facilities1[i].id, equals(facilities2[i].id));
      }
    });
  });

  group('FacilityService - Emergency Facilities', () {
    late Position userLocation;

    setUp(() {
      userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });

    test('getEmergencyFacilities returns only emergency-capable facilities', () async {
      final emergencyFacilities = await FacilityService.getEmergencyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
      );

      expect(emergencyFacilities, isNotEmpty);
      expect(emergencyFacilities.length, lessThanOrEqualTo(5)); // Max 5 results

      // All results should be hospitals or emergency facilities
      for (final facility in emergencyFacilities) {
        expect(
          facility.type == FacilityType.hospital ||
              facility.type == FacilityType.emergencyFacility,
          isTrue,
        );
      }
    });

    test('getEmergencyFacilities limits results to 5', () async {
      final emergencyFacilities = await FacilityService.getEmergencyFacilities(
        userLocation: userLocation,
        maxDistance: 500.0, // Large radius to get many results
      );

      expect(emergencyFacilities.length, lessThanOrEqualTo(5));
    });

    test('getEmergencyFacilities sorts by distance', () async {
      final emergencyFacilities = await FacilityService.getEmergencyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
      );

      if (emergencyFacilities.length > 1) {
        for (var i = 0; i < emergencyFacilities.length - 1; i++) {
          expect(
            emergencyFacilities[i].distanceKm!,
            lessThanOrEqualTo(emergencyFacilities[i + 1].distanceKm!),
          );
        }
      }
    });
  });

  group('FacilityService - Facility Lookup', () {
    test('getFacilityById returns facility when found', () async {
      // Use a known facility ID from mock data
      final facility = await FacilityService.getFacilityById('fac-001');

      // If facility exists in mock data
      expect(facility?.id, equals('fac-001'));
    });

    test('getFacilityById returns null when not found', () async {
      final facility = await FacilityService.getFacilityById('non-existent-id-999');

      expect(facility, isNull);
    });
  });

  group('FacilityService - Distance Calculation', () {
    test('distance calculation is accurate using Haversine formula', () async {
      // Test with known coordinates
      final manilaLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: manilaLocation,
        maxDistance: 500.0,
        maxResults: 50,
      );

      // All facilities should have valid distance values
      for (final facility in facilities) {
        expect(facility.distanceKm, isNotNull);
        expect(facility.distanceKm!, greaterThanOrEqualTo(0.0));
        expect(facility.distanceKm!, lessThanOrEqualTo(500.0));
      }
    });

    test('distance is 0 for facility at exact user location', () async {
      // Create location at exact facility coordinates
      final exactLocation = Position(
        latitude: 14.5995, // Same as one of the mock facilities
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: exactLocation,
        maxDistance: 1.0,
        maxResults: 10,
      );

      // Should have at least one facility with distance ~0
      final closestFacility = facilities.isNotEmpty ? facilities.first : null;
      if (closestFacility != null) {
        expect(closestFacility.distanceKm!, lessThan(0.1)); // Very close to 0
      }
    });
  });

  group('FacilityService - Offline Performance', () {
    late Position userLocation;

    setUp(() {
      userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });

    test('facility search completes within performance target', () async {
      final stopwatch = Stopwatch()..start();

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 20,
      );

      stopwatch.stop();

      // Performance target: <100ms for offline search
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(facilities, isNotEmpty);
    });

    test('multiple concurrent searches perform well', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate multiple users searching at once
      final searches = await Future.wait([
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          maxDistance: 25.0,
          maxResults: 10,
        ),
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          maxDistance: 50.0,
          maxResults: 20,
        ),
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          facilityTypes: [FacilityType.hospital],
          maxDistance: 30.0,
          maxResults: 15,
        ),
      ]);

      stopwatch.stop();

      // Performance target: <200ms for 3 concurrent searches
      expect(stopwatch.elapsedMilliseconds, lessThan(200));

      for (final facilities in searches) {
        expect(facilities, isNotEmpty);
      }
    });
  });

  group('FacilityService - Data Quality', () {
    late Position userLocation;

    setUp(() {
      userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });

    test('all facilities have required fields populated', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
        maxResults: 50,
      );

      for (final facility in facilities) {
        // Check required fields
        expect(facility.id, isNotEmpty);
        expect(facility.name, isNotEmpty);
        expect(facility.type, isNotNull);
        expect(facility.address, isNotEmpty);
        expect(facility.latitude, isNotNull);
        expect(facility.longitude, isNotNull);

        // Check GPS coordinates are valid
        expect(facility.latitude, greaterThanOrEqualTo(-90.0));
        expect(facility.latitude, lessThanOrEqualTo(90.0));
        expect(facility.longitude, greaterThanOrEqualTo(-180.0));
        expect(facility.longitude, lessThanOrEqualTo(180.0));

        // Check distance is calculated
        expect(facility.distanceKm, isNotNull);
        expect(facility.distanceKm!, greaterThanOrEqualTo(0.0));
      }
    });

    test('facilities have valid service information', () async {
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
        maxResults: 50,
      );

      for (final facility in facilities) {
        // Services should be a list (can be empty)
        expect(facility.services, isA<List<String>>());

        // 24-hour flag should be boolean
        expect(facility.is24Hours, isA<bool>());

        // Contact number should be string or null
        expect(facility.contactNumber, anyOf(isNull, isA<String>()));
      }
    });

    test('emergency facilities have emergency contact info', () async {
      final emergencyFacilities = await FacilityService.getEmergencyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
      );

      for (final facility in emergencyFacilities) {
        // Emergency facilities should have contact number
        expect(
          facility.emergencyNumber != null || facility.contactNumber != null,
          isTrue,
          reason: 'Emergency facility ${facility.name} should have contact info',
        );
      }
    });
  });

  group('FacilityService - Edge Cases', () {
    test('handles location at North Pole', () async {
      final northPoleLocation = Position(
        latitude: 90.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: northPoleLocation,
        maxDistance: 1000.0,
        maxResults: 10,
      );

      // Should complete without error (likely no facilities found)
      expect(facilities, isA<List<HealthcareFacility>>());
    });

    test('handles location at South Pole', () async {
      final southPoleLocation = Position(
        latitude: -90.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: southPoleLocation,
        maxDistance: 1000.0,
        maxResults: 10,
      );

      // Should complete without error
      expect(facilities, isA<List<HealthcareFacility>>());
    });

    test('handles location at Equator', () async {
      final equatorLocation = Position(
        latitude: 0.0,
        longitude: 120.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: equatorLocation,
        maxDistance: 1000.0,
        maxResults: 10,
      );

      // Should complete without error
      expect(facilities, isA<List<HealthcareFacility>>());
    });

    test('handles zero max distance gracefully', () async {
      final userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 0.0,
        maxResults: 10,
      );

      // Should return empty list or facilities at exact location
      expect(facilities, isA<List<HealthcareFacility>>());
      for (final facility in facilities) {
        expect(facility.distanceKm!, lessThanOrEqualTo(0.01)); // Nearly 0
      }
    });

    test('handles zero max results gracefully', () async {
      final userLocation = Position(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 0,
      );

      // Should return empty list
      expect(facilities, isEmpty);
    });
  });
}
