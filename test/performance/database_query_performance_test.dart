import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

/// Database query performance benchmarks.
///
/// Measures:
/// - Indexed query performance
/// - Batch operation throughput
/// - Transaction speed
/// - Import operations
///
/// Tests verify that database indexes are working correctly and
/// queries complete within target timeframes.
///
/// Usage:
/// flutter test test/performance/database_query_performance_test.dart
void main() {
  late AppDatabase database;
  const uuid = Uuid();

  setUp(() async {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Populate with test data
    await _populateTestData(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Assessment Query Performance', () {
    test('getRecentAssessments with index < 50ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query recent assessments (should use idx_assessments_user_date)
      final assessments = await database.getRecentAssessments(
        'test-user-1',
        limit: 20,
      );

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Recent assessments query: ${queryTimeMs}ms');
      expect(assessments.length, equals(20));

      // Target: <50ms with index
      expect(queryTimeMs, lessThan(50),
        reason: 'Assessment query with index too slow');
    });

    test('getUnsyncedAssessments batch query < 30ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query unsynced assessments (should use idx_assessments_sync)
      final unsynced = await database.getUnsyncedAssessments(batchSize: 50);

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Unsynced assessments query: ${queryTimeMs}ms');
      expect(unsynced.length, greaterThan(0));

      // Target: <30ms with index
      expect(queryTimeMs, lessThan(30),
        reason: 'Unsynced query too slow');
    });

    test('Assessment insert < 10ms', () async {
      final stopwatch = Stopwatch()..start();

      await database.insertAssessment(
        AssessmentsCompanion.insert(
          id: uuid.v4(),
          userId: 'test-user-new',
          likelihoodScore: 4,
          impactScore: 5,
          finalRiskScore: 20,
          riskCategory: 'High',
          symptomsData: '{}',
          createdAt: DateTime.now(),
        ),
      );

      stopwatch.stop();
      final insertTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Assessment insert: ${insertTimeMs}ms');

      // Target: <10ms for single insert
      expect(insertTimeMs, lessThan(10),
        reason: 'Assessment insert too slow');
    });
  });

  group('Facility Query Performance', () {
    test('getFacilitiesByType with index < 50ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query by facility type (should use idx_facilities_type)
      final facilities = await database.getFacilitiesByType('hospital');

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Facilities by type query: ${queryTimeMs}ms');
      expect(facilities.length, greaterThan(0));

      // Target: <50ms with index
      expect(queryTimeMs, lessThan(50),
        reason: 'Facility type query too slow');
    });

    test('getFacilitiesInBoundingBox with spatial index < 75ms', () async {
      final stopwatch = Stopwatch()..start();

      // Bounding box for Baguio City area
      // (should use idx_facilities_location)
      final facilities = await database.getFacilitiesInBoundingBox(
        minLat: 14.5,
        maxLat: 15.5,
        minLon: 120.5,
        maxLon: 121.5,
      );

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Bounding box query: ${queryTimeMs}ms');
      expect(facilities.length, greaterThan(0));

      // Target: <75ms with index
      expect(queryTimeMs, lessThan(75),
        reason: 'Bounding box query too slow');
    });

    test('getFacilitiesByMunicipality with index < 50ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query by municipality (should use idx_facilities_municipality)
      final facilities = await database.getFacilitiesByMunicipality('Baguio City');

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Municipality query: ${queryTimeMs}ms');

      // Target: <50ms with index
      expect(queryTimeMs, lessThan(50),
        reason: 'Municipality query too slow');
    });

    test('Facility search (text query) < 100ms', () async {
      final stopwatch = Stopwatch()..start();

      // Text search (no specific index, uses full table scan)
      final facilities = await database.searchFacilities('hospital');

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Facility text search: ${queryTimeMs}ms');
      expect(facilities.length, greaterThan(0));

      // Target: <100ms for text search (unindexed)
      expect(queryTimeMs, lessThan(100),
        reason: 'Facility text search too slow');
    });
  });

  group('Appointment Query Performance', () {
    test('getUpcomingAppointments with index < 40ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query upcoming appointments (should use idx_appointments_user_datetime)
      final appointments = await database.getUpcomingAppointments(
        'test-user-1',
        limit: 10,
      );

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Upcoming appointments query: ${queryTimeMs}ms');

      // Target: <40ms with index
      expect(queryTimeMs, lessThan(40),
        reason: 'Upcoming appointments query too slow');
    });

    test('getAppointmentsByStatus with index < 40ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query by status (should use idx_appointments_status)
      final appointments = await database.getAppointmentsByStatus(
        'pending',
        limit: 20,
      );

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Appointments by status query: ${queryTimeMs}ms');

      // Target: <40ms with index
      expect(queryTimeMs, lessThan(40),
        reason: 'Appointment status query too slow');
    });
  });

  group('Sync Queue Query Performance', () {
    test('getPendingHighPrioritySyncOps with index < 30ms', () async {
      final stopwatch = Stopwatch()..start();

      // Query pending operations by priority
      // (should use idx_sync_status_priority)
      final operations = await database.getPendingHighPrioritySyncOps(
        batchSize: 10,
      );

      stopwatch.stop();
      final queryTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Pending sync operations query: ${queryTimeMs}ms');

      // Target: <30ms with index
      expect(queryTimeMs, lessThan(30),
        reason: 'Sync queue query too slow');
    });
  });

  group('Batch Operation Performance', () {
    test('Facility batch import (50 facilities) < 5 seconds', () async {
      // Create 50 facility models
      final facilities = List.generate(50, (i) {
        return {
          'id': 'batch-facility-$i',
          'name': 'Test Hospital $i',
          'type': 'hospital',
          'latitude': 14.5995 + (i * 0.01),
          'longitude': 120.9842 + (i * 0.01),
          'address': 'Test Address $i',
          'municipality': 'Baguio City',
          'province': 'Benguet',
          'region': 'CAR',
          'services': ['Cardiology', 'Emergency'],
          'open_24_hours': true,
          'emergency_services': true,
        };
      });

      final stopwatch = Stopwatch()..start();

      final count = await database.importFacilitiesFromBackend(facilities);

      stopwatch.stop();
      final importTimeMs = stopwatch.elapsedMilliseconds;
      final facilitiesPerSecond = (count / (importTimeMs / 1000)).round();

      print('✅ Batch import: 50 facilities in ${importTimeMs}ms');
      print('✅ Throughput: $facilitiesPerSecond facilities/second');

      expect(count, equals(50));

      // Target: <5000ms (5 seconds) for 50 facilities
      expect(importTimeMs, lessThan(5000),
        reason: 'Batch import too slow');

      // Should process at least 10 facilities per second
      expect(facilitiesPerSecond, greaterThan(10),
        reason: 'Import throughput too low');
    });

    test('Facility batch import (500 facilities) < 15 seconds', () async {
      // Create 500 facility models
      final facilities = List.generate(500, (i) {
        return {
          'id': 'large-batch-facility-$i',
          'name': 'Test Hospital $i',
          'type': 'hospital',
          'latitude': 14.5995 + (i * 0.001),
          'longitude': 120.9842 + (i * 0.001),
          'address': 'Test Address $i',
          'municipality': 'Baguio City',
          'services': ['Cardiology'],
        };
      });

      final stopwatch = Stopwatch()..start();

      final count = await database.importFacilitiesFromBackend(facilities);

      stopwatch.stop();
      final importTimeMs = stopwatch.elapsedMilliseconds;
      final facilitiesPerSecond = (count / (importTimeMs / 1000)).round();

      print('✅ Large batch import: 500 facilities in ${importTimeMs}ms');
      print('✅ Throughput: $facilitiesPerSecond facilities/second');

      expect(count, equals(500));

      // Target: <15000ms (15 seconds) for 500 facilities
      expect(importTimeMs, lessThan(15000),
        reason: 'Large batch import too slow');

      // Should process at least 30 facilities per second
      expect(facilitiesPerSecond, greaterThan(30),
        reason: 'Large import throughput too low');
    });

    test('Transaction performance (100 inserts) < 1 second', () async {
      final stopwatch = Stopwatch()..start();

      await database.transaction(() async {
        for (int i = 0; i < 100; i++) {
          await database.insertAssessment(
            AssessmentsCompanion.insert(
              id: 'batch-assessment-$i',
              userId: 'test-user-batch',
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

      stopwatch.stop();
      final transactionTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Transaction (100 inserts): ${transactionTimeMs}ms');

      // Target: <1000ms for 100 inserts in transaction
      expect(transactionTimeMs, lessThan(1000),
        reason: 'Transaction too slow');
    });
  });

  group('Database Statistics', () {
    test('getDatabaseStats completes quickly', () async {
      final stopwatch = Stopwatch()..start();

      final stats = await database.getDatabaseStats();

      stopwatch.stop();
      final statsTimeMs = stopwatch.elapsedMilliseconds;

      print('✅ Database stats: ${statsTimeMs}ms');
      print('   Assessments: ${stats['assessments']}');
      print('   Facilities: ${stats['facilities']}');
      print('   Appointments: ${stats['appointments']}');
      print('   Sync Queue: ${stats['syncQueue']}');

      // Target: <50ms for stats aggregation
      expect(statsTimeMs, lessThan(50),
        reason: 'Stats query too slow');
    });
  });
}

/// Populate database with realistic test data.
///
/// Creates:
/// - 100 assessments for 3 users
/// - 50 healthcare facilities
/// - 30 appointments
/// - 20 sync queue operations
Future<void> _populateTestData(AppDatabase database) async {
  const uuid = Uuid();
  print('📝 Populating test data...');

  // Create 100 assessments for multiple users
  for (int i = 0; i < 100; i++) {
    final userId = 'test-user-${(i % 3) + 1}'; // 3 users
    final isSynced = i % 5 != 0; // 20% unsynced

    await database.insertAssessment(
      AssessmentsCompanion.insert(
        id: uuid.v4(),
        userId: userId,
        likelihoodScore: (i % 5) + 1,
        impactScore: (i % 5) + 1,
        finalRiskScore: ((i % 5) + 1) * ((i % 5) + 1),
        riskCategory: _getRiskCategory(((i % 5) + 1) * ((i % 5) + 1)),
        symptomsData: '{"symptoms": ["test"]}',
        createdAt: DateTime.now().subtract(Duration(days: i)),
        isSynced: Value(isSynced),
      ),
    );
  }

  // Create 50 healthcare facilities
  final facilityTypes = ['hospital', 'clinic', 'health_center', 'barangay_health_station'];
  final municipalities = ['Baguio City', 'La Trinidad', 'Itogon', 'Sablan', 'Tuba'];

  for (int i = 0; i < 50; i++) {
    await database.insertFacility(
      FacilitiesCompanion.insert(
        id: 'facility-$i',
        name: 'Test ${facilityTypes[i % 4]} $i',
        type: facilityTypes[i % 4],
        latitude: 14.5995 + (i * 0.01), // Spread around Baguio
        longitude: 120.9842 + (i * 0.01),
        address: 'Test Address $i',
        municipality: Value(municipalities[i % 5]),
        province: const Value('Benguet'),
        region: const Value('CAR'),
        services: 'Cardiology,Emergency,General',
        is24Hours: Value(i % 3 == 0),
        hasEmergencyService: Value(i % 2 == 0),
        createdAt: DateTime.now(),
      ),
    );
  }

  // Create 30 appointments
  final statuses = ['pending', 'confirmed', 'completed', 'cancelled'];

  for (int i = 0; i < 30; i++) {
    final userId = 'test-user-${(i % 3) + 1}';
    final facilityId = 'facility-${i % 50}';
    final futureDate = i < 15; // Half future, half past

    await database.insertAppointment(
      AppointmentsCompanion.insert(
        id: 'appointment-$i',
        userId: userId,
        facilityId: facilityId,
        appointmentDateTime: futureDate
          ? DateTime.now().add(Duration(days: i))
          : DateTime.now().subtract(Duration(days: i)),
        appointmentType: 'consultation',
        status: statuses[i % 4],
        createdAt: DateTime.now(),
      ),
    );
  }

  // Create 20 sync queue operations
  final operationTypes = ['CREATE', 'UPDATE', 'DELETE'];
  final entityTypes = ['assessment', 'appointment', 'user'];
  final operationStatuses = ['pending', 'processing', 'failed'];

  for (int i = 0; i < 20; i++) {
    await database.insertSyncOperation(
      SyncQueueCompanion.insert(
        id: 'sync-op-$i',
        operationType: operationTypes[i % 3],
        entityType: entityTypes[i % 3],
        entityId: uuid.v4(),
        payload: '{"test": "data"}',
        priority: Value(i % 5), // Priority 0-4
        status: operationStatuses[i % 3],
        createdAt: DateTime.now().subtract(Duration(hours: i)),
      ),
    );
  }

  print('✅ Test data populated');
}

String _getRiskCategory(int score) {
  if (score <= 4) return 'Low';
  if (score <= 9) return 'Mild';
  if (score <= 14) return 'Moderate';
  if (score <= 19) return 'High';
  return 'Critical';
}
