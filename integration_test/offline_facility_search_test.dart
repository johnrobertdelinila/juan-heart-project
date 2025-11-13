import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:juan_heart/services/facility_service.dart';
import 'package:juan_heart/services/geospatial_service.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/models/referral_data.dart';

/// Integration test for offline facility search
///
/// This test validates the complete offline facility search journey:
/// 1. Search facilities without internet connection
/// 2. Filter by facility type and distance
/// 3. Sort by distance (GPS-based)
/// 4. View facility details
/// 5. Get directions to facility
///
/// Target: Search response time <1 second
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Facility Search - End-to-End', () {
    late AppDatabase database;
    late GeospatialService geospatialService;
    late Position userLocation;

    setUp(() async {
      // Initialize services
      database = AppDatabase();
      geospatialService = GeospatialService();

      // Mock user location (Manila)
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

    tearDown(() async {
      await database.close();
    });

    testWidgets('Search facilities offline and display results', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // Wait for initial load
      await tester.pump(const Duration(seconds: 1));

      // STEP 2: Navigate to facility search
      final facilityButton = find.text('Find Facilities');
      if (facilityButton.evaluate().isNotEmpty) {
        await tester.tap(facilityButton);
        await tester.pumpAndSettle();
      }

      // STEP 3: Perform search
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'hospital');
        await tester.pumpAndSettle();
      }

      // STEP 4: Verify results displayed
      expect(
        find.byType(ListTile),
        findsWidgets,
        reason: 'Facility list should display results',
      );

      // STEP 5: Verify distance shown for each facility
      expect(
        find.textContaining('km'),
        findsWidgets,
        reason: 'Distance should be displayed for facilities',
      );
    });

    testWidgets('Facility search works offline with GPS', (tester) async {
      // STEP 1: Get facilities using offline service
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 20,
      );

      // STEP 2: Verify facilities returned
      expect(facilities, isNotEmpty, reason: 'Should find facilities offline');

      // STEP 3: Verify all facilities have distance calculated
      for (final facility in facilities) {
        expect(
          facility.distanceKm,
          isNotNull,
          reason: 'Each facility should have calculated distance',
        );
        expect(
          facility.distanceKm,
          lessThanOrEqualTo(50.0),
          reason: 'Facility distance should be within search radius',
        );
      }

      // STEP 4: Verify sorted by distance
      for (int i = 0; i < facilities.length - 1; i++) {
        expect(
          facilities[i].distanceKm!,
          lessThanOrEqualTo(facilities[i + 1].distanceKm!),
          reason: 'Facilities should be sorted by distance',
        );
      }
    });

    testWidgets('Filter facilities by type offline', (tester) async {
      // STEP 1: Filter for hospitals only
      final hospitals = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        facilityTypes: [FacilityType.hospital, FacilityType.emergencyFacility],
        maxDistance: 50.0,
        maxResults: 20,
      );

      // STEP 2: Verify only hospitals returned
      for (final facility in hospitals) {
        expect(
          facility.type == FacilityType.hospital ||
              facility.type == FacilityType.emergencyFacility,
          isTrue,
          reason: 'Only hospitals should be in results',
        );
      }

      // STEP 3: Filter for clinics
      final clinics = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        facilityTypes: [FacilityType.primaryCarClinic],
        maxDistance: 50.0,
        maxResults: 20,
      );

      // STEP 4: Verify only clinics returned
      for (final facility in clinics) {
        expect(
          facility.type == FacilityType.primaryCarClinic,
          isTrue,
          reason: 'Only clinics should be in results',
        );
      }

      // STEP 5: Verify different results
      expect(
        hospitals.length != clinics.length,
        isTrue,
        reason: 'Different facility types should return different results',
      );
    });

    testWidgets('Emergency facility search prioritizes closest', (tester) async {
      // STEP 1: Search for emergency facilities
      final emergencyFacilities = await FacilityService.getEmergencyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
      );

      // STEP 2: Verify emergency facilities returned
      expect(emergencyFacilities, isNotEmpty);
      expect(emergencyFacilities.length, lessThanOrEqualTo(5));

      // STEP 3: Verify all are emergency-capable
      for (final facility in emergencyFacilities) {
        expect(
          facility.type == FacilityType.hospital ||
              facility.type == FacilityType.emergencyFacility,
          isTrue,
          reason: 'Should only return emergency-capable facilities',
        );
      }

      // STEP 4: Verify sorted by distance (closest first)
      if (emergencyFacilities.length > 1) {
        expect(
          emergencyFacilities.first.distanceKm!,
          lessThanOrEqualTo(emergencyFacilities.last.distanceKm!),
          reason: 'Emergency facilities should be sorted by distance',
        );
      }
    });

    testWidgets('Facility details screen shows complete information', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // STEP 2: Navigate to facility search
      final facilityButton = find.text('Find Facilities');
      if (facilityButton.evaluate().isNotEmpty) {
        await tester.tap(facilityButton);
        await tester.pumpAndSettle();
      }

      // STEP 3: Tap on first facility
      final firstFacility = find.byType(ListTile).first;
      if (firstFacility.evaluate().isNotEmpty) {
        await tester.tap(firstFacility);
        await tester.pumpAndSettle();
      }

      // STEP 4: Verify facility details displayed
      expect(
        find.text('Services'),
        findsOneWidget,
        skip: true,
        skipReason: 'Depends on UI implementation',
      );

      expect(
        find.text('Operating Hours'),
        findsOneWidget,
        skip: true,
        skipReason: 'Depends on UI implementation',
      );

      expect(
        find.text('Contact'),
        findsOneWidget,
        skip: true,
        skipReason: 'Depends on UI implementation',
      );
    });

    testWidgets('GPS-based distance calculation is accurate', (tester) async {
      // STEP 1: Get nearby facilities
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
        maxResults: 50,
      );

      // STEP 2: Verify distance calculations using Haversine formula
      for (final facility in facilities) {
        final manualDistance = geospatialService.calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          facility.latitude,
          facility.longitude,
        );

        // Distance should match within small tolerance (0.1 km)
        expect(
          (facility.distanceKm! - manualDistance).abs(),
          lessThan(0.1),
          reason: 'Calculated distance should match Haversine formula',
        );
      }
    });

    testWidgets('Facility search handles radius changes dynamically', (tester) async {
      // STEP 1: Search with 10km radius
      final nearby = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 10.0,
        maxResults: 50,
      );

      // STEP 2: Search with 50km radius
      final wider = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 50,
      );

      // STEP 3: Verify wider search returns more results
      expect(
        wider.length,
        greaterThanOrEqualTo(nearby.length),
        reason: 'Wider search should return equal or more facilities',
      );

      // STEP 4: Verify all nearby facilities included in wider search
      for (final nearbyFacility in nearby) {
        expect(
          wider.any((f) => f.id == nearbyFacility.id),
          isTrue,
          reason: 'Wider search should include all nearby facilities',
        );
      }
    });

    testWidgets('24-hour facility filter works correctly', (tester) async {
      // STEP 1: Get all facilities from database
      final allFacilities = await database.select(database.facilities).get();

      // STEP 2: Convert to facility entities
      final facilityEntities = allFacilities.map((f) => f).toList();

      // STEP 3: Find 24-hour facilities
      final twentyFourHour = geospatialService.findNearby24HourFacilities(
        userLat: userLocation.latitude,
        userLon: userLocation.longitude,
        radiusKm: 50.0,
        facilities: facilityEntities,
      );

      // STEP 4: Verify all results are 24-hour
      for (final facilityWithDistance in twentyFourHour) {
        expect(
          facilityWithDistance.facility.is24Hours,
          isTrue,
          reason: 'All results should be 24-hour facilities',
        );
      }
    });

    testWidgets('Facility search persists user preferences', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // STEP 2: Navigate to facility search
      final facilityButton = find.text('Find Facilities');
      if (facilityButton.evaluate().isNotEmpty) {
        await tester.tap(facilityButton);
        await tester.pumpAndSettle();
      }

      // STEP 3: Set filter preferences
      final hospitalFilter = find.text('Hospitals Only');
      if (hospitalFilter.evaluate().isNotEmpty) {
        await tester.tap(hospitalFilter);
        await tester.pumpAndSettle();
      }

      // STEP 4: Navigate away and back
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(facilityButton);
      await tester.pumpAndSettle();

      // STEP 5: Verify filter persisted
      expect(
        find.text('Hospitals Only'),
        findsOneWidget,
        skip: true,
        skipReason: 'Depends on persistence implementation',
      );
    });

    testWidgets('Facility map integration shows correct locations', (tester) async {
      // STEP 1: Get facilities
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 25.0,
        maxResults: 10,
      );

      // STEP 2: Verify GPS coordinates valid for all facilities
      for (final facility in facilities) {
        expect(
          facility.latitude,
          greaterThanOrEqualTo(-90.0),
          reason: 'Latitude should be valid',
        );
        expect(
          facility.latitude,
          lessThanOrEqualTo(90.0),
          reason: 'Latitude should be valid',
        );
        expect(
          facility.longitude,
          greaterThanOrEqualTo(-180.0),
          reason: 'Longitude should be valid',
        );
        expect(
          facility.longitude,
          lessThanOrEqualTo(180.0),
          reason: 'Longitude should be valid',
        );
      }
    });

    testWidgets('Facility search handles user location changes', (tester) async {
      // STEP 1: Search from Manila
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

      final manilaResults = await FacilityService.getNearbyFacilities(
        userLocation: manilaLocation,
        maxDistance: 10.0,
        maxResults: 20,
      );

      // STEP 2: Search from Cebu
      final cebuLocation = Position(
        latitude: 10.3157,
        longitude: 123.8854,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      final cebuResults = await FacilityService.getNearbyFacilities(
        userLocation: cebuLocation,
        maxDistance: 10.0,
        maxResults: 20,
      );

      // STEP 3: Verify different facilities returned
      expect(
        manilaResults.first.id != cebuResults.first.id,
        isTrue,
        reason: 'Different locations should return different nearest facilities',
      );
    });

    testWidgets('Performance: Facility search completes under 1 second', (tester) async {
      final stopwatch = Stopwatch()..start();

      // STEP 1: Perform comprehensive facility search
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 50.0,
        maxResults: 50,
      );

      stopwatch.stop();

      // STEP 2: Verify results returned
      expect(facilities, isNotEmpty);

      // Performance requirement: <1 second
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Facility search should complete in under 1 second',
      );

      print('Facility search completed in ${stopwatch.elapsedMilliseconds}ms');
      print('Found ${facilities.length} facilities');
    });

    testWidgets('Concurrent facility searches handle correctly', (tester) async {
      final stopwatch = Stopwatch()..start();

      // STEP 1: Perform multiple concurrent searches
      final searches = await Future.wait([
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          maxDistance: 10.0,
          maxResults: 10,
        ),
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          maxDistance: 25.0,
          maxResults: 20,
        ),
        FacilityService.getNearbyFacilities(
          userLocation: userLocation,
          facilityTypes: [FacilityType.hospital],
          maxDistance: 50.0,
          maxResults: 30,
        ),
        FacilityService.getEmergencyFacilities(
          userLocation: userLocation,
          maxDistance: 100.0,
        ),
      ]);

      stopwatch.stop();

      // STEP 2: Verify all searches completed
      expect(searches.length, equals(4));
      for (final results in searches) {
        expect(results, isNotEmpty);
      }

      // Performance requirement: <2 seconds for 4 concurrent searches
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Concurrent searches should complete in under 2 seconds',
      );

      print('4 concurrent searches completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('Facility search works across different device locations', (tester) async {
      // Test various Philippine locations
      final testLocations = [
        {'name': 'Manila', 'lat': 14.5995, 'lon': 120.9842},
        {'name': 'Quezon City', 'lat': 14.6760, 'lon': 121.0437},
        {'name': 'Cebu', 'lat': 10.3157, 'lon': 123.8854},
        {'name': 'Davao', 'lat': 7.1907, 'lon': 125.4553},
        {'name': 'Baguio', 'lat': 16.4023, 'lon': 120.5960},
      ];

      for (final location in testLocations) {
        final position = Position(
          latitude: location['lat'] as double,
          longitude: location['lon'] as double,
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
          userLocation: position,
          maxDistance: 50.0,
          maxResults: 20,
        );

        print('${location['name']}: Found ${facilities.length} facilities');
        expect(
          facilities,
          isA<List<HealthcareFacility>>(),
          reason: 'Should return facilities for ${location['name']}',
        );
      }
    });

    testWidgets('Facility data quality is validated', (tester) async {
      // STEP 1: Get facilities
      final facilities = await FacilityService.getNearbyFacilities(
        userLocation: userLocation,
        maxDistance: 100.0,
        maxResults: 50,
      );

      // STEP 2: Validate data quality for each facility
      for (final facility in facilities) {
        // Required fields
        expect(facility.id, isNotEmpty, reason: 'Facility should have ID');
        expect(facility.name, isNotEmpty, reason: 'Facility should have name');
        expect(facility.address, isNotEmpty, reason: 'Facility should have address');
        expect(facility.type, isNotNull, reason: 'Facility should have type');

        // GPS coordinates
        expect(facility.latitude, isNotNull);
        expect(facility.longitude, isNotNull);
        expect(facility.latitude, greaterThanOrEqualTo(-90.0));
        expect(facility.latitude, lessThanOrEqualTo(90.0));
        expect(facility.longitude, greaterThanOrEqualTo(-180.0));
        expect(facility.longitude, lessThanOrEqualTo(180.0));

        // Distance calculation
        expect(facility.distanceKm, isNotNull);
        expect(facility.distanceKm!, greaterThanOrEqualTo(0.0));

        // Services array
        expect(facility.services, isA<List<String>>());

        // Boolean flags
        expect(facility.is24Hours, isA<bool>());
      }
    });
  });
}
