import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mocktail/mocktail.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/services/sync_queue_service.dart';

// Mock classes for testing
class MockConnectivity extends Mock implements Connectivity {}

/// Unit/Integration tests for Assessment Sync Service.
///
/// These tests validate the sync queue behavior without requiring
/// the full application context, focusing on:
/// 1. Offline assessment queueing
/// 2. Batch synchronization logic
/// 3. Retry mechanisms
/// 4. Error handling
void main() {
  late AppDatabase database;
  late SyncQueueService syncQueue;
  late MockConnectivity mockConnectivity;

  setUp(() async {
    // Create in-memory database
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Initialize sync queue
    syncQueue = SyncQueueService();
    await syncQueue.initialize();

    // Create mock connectivity
    mockConnectivity = MockConnectivity();
    syncQueue.setConnectivityProvider(mockConnectivity);
  });

  tearDown(() async {
    await database.close();
    await syncQueue.clearAll();
    syncQueue.dispose();
  });

  group('Assessment Sync Tests', () {
    test('Test 1: Assessment is queued for sync when created offline', () async {
      print('\n${'='*80}');
      print('TEST 1: Assessment Queued for Sync (Offline)');
      print('='*80);

      // ARRANGE: Mock offline state
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      final assessmentId = 'test_offline_${DateTime.now().millisecondsSinceEpoch}';
      print('1️⃣ Creating assessment offline (ID: $assessmentId)');

      // Create assessment in database
      await database.insertAssessment(
        AssessmentsCompanion.insert(
          id: assessmentId,
          userId: 'test_user',
          likelihoodScore: 3,
          impactScore: 4,
          finalRiskScore: 12,
          riskCategory: 'Moderate',
          symptomsData: jsonEncode({'chestPain': false, 'shortnessOfBreath': true}),
          createdAt: DateTime.now(),
          isSynced: drift.Value(false),
        ),
      );

      print('✅ Assessment saved to database (isSynced: false)');

      // ACT: Queue assessment for sync
      print('2️⃣ Queueing assessment for sync...');
      final mockAssessment = _createMockAssessment(assessmentId);

      await syncQueue.addOperation(
        SyncOperation(
          id: 'sync_$assessmentId',
          type: SyncOperationType.syncAssessment,
          data: mockAssessment.toJson(),
        ),
      );

      // ASSERT: Verify assessment is in queue
      final queueStatus = syncQueue.getQueueStatus();
      expect(queueStatus['pending'], 1, reason: 'One assessment should be queued');
      print('✅ Assessment queued successfully (pending: ${queueStatus['pending']})');

      // Verify database state
      final dbAssessment = await database.getAssessmentById(assessmentId);
      expect(dbAssessment, isNotNull);
      expect(dbAssessment!.isSynced, false, reason: 'Assessment not yet synced');
      expect(dbAssessment.syncError, isNull);

      print('✅ Database state verified (isSynced: false, syncError: null)');
      print('='*80);
      print('✅ TEST 1 PASSED\n');
    });

    test('Test 2: Multiple assessments can be queued for batch sync', () async {
      print('\n${'='*80}');
      print('TEST 2: Batch Assessment Queueing');
      print('='*80);

      // ARRANGE: Mock offline state
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      const batchSize = 10;
      final assessmentIds = <String>[];

      print('1️⃣ Creating $batchSize assessments offline...');

      // Create multiple assessments
      for (int i = 0; i < batchSize; i++) {
        final id = 'batch_${DateTime.now().millisecondsSinceEpoch}_$i';
        assessmentIds.add(id);

        await database.insertAssessment(
          AssessmentsCompanion.insert(
            id: id,
            userId: 'test_user',
            likelihoodScore: 2 + (i % 3),
            impactScore: 3 + (i % 2),
            finalRiskScore: (2 + (i % 3)) * (3 + (i % 2)),
            riskCategory: 'Moderate',
            symptomsData: jsonEncode({'test': true}),
            createdAt: DateTime.now(),
            isSynced: drift.Value(false),
          ),
        );
      }

      print('✅ Created $batchSize assessments in database');

      // ACT: Queue all assessments
      print('2️⃣ Queueing all assessments for sync...');

      for (final id in assessmentIds) {
        final assessment = await database.getAssessmentById(id);
        await syncQueue.addOperation(
          SyncOperation(
            id: 'sync_$id',
            type: SyncOperationType.syncAssessment,
            data: {
              'id': assessment!.id,
              'userId': assessment.userId,
              'finalRiskScore': assessment.finalRiskScore,
            },
          ),
        );
      }

      // ASSERT: Verify all queued
      final queueStatus = syncQueue.getQueueStatus();
      expect(queueStatus['pending'], batchSize, reason: 'All assessments should be queued');
      print('✅ All assessments queued (pending: ${queueStatus['pending']})');

      // Verify no duplicates
      final operations = queueStatus['operations'] as List;
      final uniqueIds = operations.map((op) => op['id']).toSet();
      expect(uniqueIds.length, batchSize, reason: 'No duplicate operations');
      print('✅ No duplicates detected (unique: ${uniqueIds.length})');

      print('='*80);
      print('✅ TEST 2 PASSED\n');
    });

    test('Test 3: Sync executor marks assessment as synced', () async {
      print('\n${'='*80}');
      print('TEST 3: Sync Executor Updates Database');
      print('='*80);

      // ARRANGE: Mock online state
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      final assessmentId = 'test_executor_${DateTime.now().millisecondsSinceEpoch}';
      print('1️⃣ Creating assessment (ID: $assessmentId)');

      await database.insertAssessment(
        AssessmentsCompanion.insert(
          id: assessmentId,
          userId: 'test_user',
          likelihoodScore: 3,
          impactScore: 4,
          finalRiskScore: 12,
          riskCategory: 'Moderate',
          symptomsData: jsonEncode({'test': true}),
          createdAt: DateTime.now(),
          isSynced: drift.Value(false),
        ),
      );

      print('✅ Assessment created (isSynced: false)');

      // ACT: Register executor that marks as synced
      print('2️⃣ Registering sync executor...');
      syncQueue.registerExecutor(
        SyncOperationType.syncAssessment,
        (operation) async {
          print('🔄 Executor running for: ${operation.id}');

          // Simulate successful sync
          await database.updateAssessment(
            AssessmentsCompanion(
              id: drift.Value(assessmentId),
              isSynced: drift.Value(true),
              syncedAt: drift.Value(DateTime.now()),
              syncError: drift.Value(null),
            ),
          );

          return {'success': true, 'message': 'Synced successfully'};
        },
      );

      // Queue and process
      await syncQueue.addOperation(
        SyncOperation(
          id: 'sync_$assessmentId',
          type: SyncOperationType.syncAssessment,
          data: _createMockAssessment(assessmentId).toJson(),
        ),
      );

      print('3️⃣ Processing sync queue...');
      await syncQueue.processQueue();

      // Wait for async completion
      await Future.delayed(Duration(milliseconds: 500));

      // ASSERT: Verify database updated
      print('4️⃣ Verifying database state...');
      final syncedAssessment = await database.getAssessmentById(assessmentId);

      expect(syncedAssessment, isNotNull);
      expect(syncedAssessment!.isSynced, true, reason: 'Assessment should be marked as synced');
      expect(syncedAssessment.syncedAt, isNotNull, reason: 'Sync timestamp should be set');
      expect(syncedAssessment.syncError, isNull, reason: 'No sync error');

      print('✅ Database updated successfully');
      print('   - isSynced: ${syncedAssessment.isSynced}');
      print('   - syncedAt: ${syncedAssessment.syncedAt}');
      print('   - syncError: ${syncedAssessment.syncError}');

      print('='*80);
      print('✅ TEST 3 PASSED\n');
    });

    test('Test 4: Failed sync stores error in database', () async {
      print('\n${'='*80}');
      print('TEST 4: Sync Error Handling');
      print('='*80);

      // ARRANGE: Mock online state
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);

      final assessmentId = 'test_error_${DateTime.now().millisecondsSinceEpoch}';
      print('1️⃣ Creating assessment (ID: $assessmentId)');

      await database.insertAssessment(
        AssessmentsCompanion.insert(
          id: assessmentId,
          userId: 'test_user',
          likelihoodScore: 3,
          impactScore: 4,
          finalRiskScore: 12,
          riskCategory: 'Moderate',
          symptomsData: jsonEncode({'test': true}),
          createdAt: DateTime.now(),
          isSynced: drift.Value(false),
        ),
      );

      print('✅ Assessment created');

      // ACT: Register executor that fails
      print('2️⃣ Registering failing executor...');
      const errorMessage = 'HTTP 500: Internal Server Error';

      syncQueue.registerExecutor(
        SyncOperationType.syncAssessment,
        (operation) async {
          print('❌ Simulating sync failure...');

          // Store error in database
          await database.updateAssessment(
            AssessmentsCompanion(
              id: drift.Value(assessmentId),
              syncError: drift.Value(errorMessage),
            ),
          );

          throw Exception(errorMessage);
        },
      );

      // Queue and attempt sync
      await syncQueue.addOperation(
        SyncOperation(
          id: 'sync_$assessmentId',
          type: SyncOperationType.syncAssessment,
          data: _createMockAssessment(assessmentId).toJson(),
        ),
      );

      print('3️⃣ Attempting sync (expecting failure)...');
      await syncQueue.processQueue();

      // Wait for async completion
      await Future.delayed(Duration(milliseconds: 500));

      // ASSERT: Verify error stored
      print('4️⃣ Verifying error handling...');
      final failedAssessment = await database.getAssessmentById(assessmentId);

      expect(failedAssessment, isNotNull);
      expect(failedAssessment!.isSynced, false, reason: 'Assessment should not be synced');
      expect(failedAssessment.syncError, isNotNull, reason: 'Error should be stored');
      expect(failedAssessment.syncError, contains('500'), reason: 'Error message should contain status code');

      print('✅ Error handled correctly');
      print('   - isSynced: ${failedAssessment.isSynced}');
      print('   - syncError: ${failedAssessment.syncError}');

      print('='*80);
      print('✅ TEST 4 PASSED\n');
    });

    test('Test 5: Queue persists across restarts', () async {
      print('\n${'='*80}');
      print('TEST 5: Queue Persistence');
      print('='*80);

      // ARRANGE: Create assessments and queue them
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      const testCount = 5;
      final assessmentIds = <String>[];

      print('1️⃣ Creating $testCount assessments and queueing...');

      for (int i = 0; i < testCount; i++) {
        final id = 'persist_${DateTime.now().millisecondsSinceEpoch}_$i';
        assessmentIds.add(id);

        await syncQueue.addOperation(
          SyncOperation(
            id: 'sync_$id',
            type: SyncOperationType.syncAssessment,
            data: {'id': id, 'test': true},
          ),
        );
      }

      final beforeStatus = syncQueue.getQueueStatus();
      expect(beforeStatus['pending'], testCount);
      print('✅ Queued $testCount operations (pending: ${beforeStatus['pending']})');

      // ACT: Simulate restart by disposing and recreating
      print('2️⃣ Simulating app restart...');
      syncQueue.dispose();

      // Create new sync queue instance
      final newSyncQueue = SyncQueueService();
      await newSyncQueue.initialize();
      newSyncQueue.setConnectivityProvider(mockConnectivity);

      // ASSERT: Verify queue restored
      print('3️⃣ Verifying queue restored after restart...');
      final afterStatus = newSyncQueue.getQueueStatus();

      expect(afterStatus['pending'], testCount, reason: 'Queue should persist across restarts');
      print('✅ Queue restored successfully (pending: ${afterStatus['pending']})');

      // Cleanup
      await newSyncQueue.clearAll();
      newSyncQueue.dispose();

      print('='*80);
      print('✅ TEST 5 PASSED\n');
    });
  });
}

/// Helper: Create mock assessment for testing
AssessmentRecord _createMockAssessment(String id) {
  return AssessmentRecord(
    id: id,
    date: DateTime.now(),
    finalRiskScore: 12,
    likelihoodScore: 3,
    impactScore: 4,
    riskCategory: 'Moderate',
    likelihoodLevel: 'Level 3',
    impactLevel: 'Level 4',
    recommendedAction: 'Consult healthcare provider',
    systolicBP: 130,
    diastolicBP: 85,
    heartRate: 78,
    symptoms: {'chestPain': false, 'shortnessOfBreath': true},
    riskFactors: {'hypertension': true, 'smoking': false},
    age: 45,
    sex: 'Male',
    userId: 'test_user',
  );
}
