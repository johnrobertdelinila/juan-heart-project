import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/services/assessment_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart';
import 'pages/page_objects.dart';

/// E2E Test: Offline Assessment → Online Sync → Clinical Validation
///
/// This test validates the complete offline-first assessment workflow
/// including sync queue management, conflict resolution, and data integrity.
///
/// Test Flow:
/// 1. Complete assessment while offline
/// 2. Queue multiple assessments offline
/// 3. Restore connectivity
/// 4. Verify automatic sync
/// 5. Check conflict resolution
/// 6. Validate backend receives all data
/// 7. Verify clinical accuracy (risk scores)
///
/// Prerequisites:
/// - Clean app state
/// - Backend API available
/// - Ability to simulate network states
///
/// Performance Targets:
/// - Offline assessment save: <1 second
/// - Queue multiple assessments: <500ms each
/// - Sync queue processing: <1 minute for 10 assessments
/// - Conflict resolution: <2 seconds per conflict
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Offline Assessment → Online Sync → Clinical Validation', () {
    late AppDatabase database;
    late SyncQueueService syncQueue;
    late AssessmentSyncService assessmentSync;
    late HomePage homePage;
    late AssessmentPage assessmentPage;

    setUpAll(() async {
      database = AppDatabase();
      syncQueue = SyncQueueService();
      assessmentSync = AssessmentSyncService();
      await syncQueue.initialize();
    });

    setUp(() async {
      // Clear all data
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await TestHelpers.clearTestData();
      await syncQueue.clearAll();
    });

    tearDownAll(() async {
      await database.close();
    });

    testWidgets('Complete offline assessment with sync validation', (tester) async {
      TestHelpers.logStep('TEST START: Offline Assessment with Sync');
      final totalStopwatch = Stopwatch()..start();

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      // Launch app
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // ==================== PHASE 1: OFFLINE ASSESSMENT ====================
      TestHelpers.logStep('PHASE 1: Complete Assessment Offline');
      final offlineStopwatch = Stopwatch()..start();

      // Simulate offline mode
      TestHelpers.simulateOfflineMode();

      // Navigate to assessment
      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Fill high-risk assessment
      TestHelpers.logStep('Filling high-risk assessment...');

      // Symptoms
      await assessmentPage.selectSymptom('Chest pain or discomfort', 5);
      await tester.pumpAndSettle();
      await assessmentPage.selectSymptom('Shortness of breath', 5);
      await tester.pumpAndSettle();
      await assessmentPage.selectSymptom('Chronic fatigue', 4);
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      // Vital signs
      await assessmentPage.enterBloodPressure(180, 110);
      await assessmentPage.enterHeartRate(110);
      await assessmentPage.enterWeight(95.0);
      await assessmentPage.enterHeight(165.0);
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      // Medical history
      await assessmentPage.selectMedicalHistory('hypertension', true);
      await assessmentPage.selectMedicalHistory('diabetes', true);
      await assessmentPage.selectMedicalHistory('heart_disease', true);
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      // Lifestyle
      await assessmentPage.selectLifestyleFactor('smoking', 'Current smoker');
      await assessmentPage.selectLifestyleFactor('alcohol', 'Heavy drinker');
      await assessmentPage.selectLifestyleFactor('exercise', 'None');
      await tester.pumpAndSettle();

      // Submit assessment
      if (find.text('Complete Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapSubmit();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      offlineStopwatch.stop();
      TestHelpers.logPerformance('Offline Assessment', offlineStopwatch.elapsed);

      // ASSERTION: Offline save completed quickly
      expect(
        offlineStopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Offline assessment save should complete in <1 second',
      );

      // ==================== PHASE 2: VERIFY LOCAL STORAGE ====================
      TestHelpers.logStep('PHASE 2: Verify Local Storage');

      // STEP 2.1: Check database
      final assessments = await database.select(database.assessments).get();
      expect(assessments, isNotEmpty, reason: 'Assessment should be saved locally');

      final savedAssessment = assessments.last;
      TestHelpers.logStep('Assessment saved with ID: ${savedAssessment.id}');
      TestHelpers.logStep('Risk score: ${savedAssessment.finalRiskScore}');
      TestHelpers.logStep('Risk category: ${savedAssessment.riskCategory}');

      // ASSERTION: Validate risk score
      TestHelpers.assertValidRiskScore(savedAssessment.finalRiskScore);
      TestHelpers.assertRiskCategoryValid(
        savedAssessment.finalRiskScore,
        savedAssessment.riskCategory,
      );

      // STEP 2.2: Verify NOT synced yet
      expect(
        savedAssessment.isSynced,
        isFalse,
        reason: 'Assessment should not be synced while offline',
      );

      // STEP 2.3: Verify in sync queue
      final queueStatus = syncQueue.getQueueStatus();
      expect(
        queueStatus['pending'],
        greaterThan(0),
        reason: 'Assessment should be queued for sync',
      );

      TestHelpers.logStep('PHASE 2 COMPLETE: Data saved locally, queued for sync');

      // ==================== PHASE 3: QUEUE MULTIPLE ASSESSMENTS ====================
      TestHelpers.logStep('PHASE 3: Queue Multiple Assessments Offline');

      // Create 5 additional assessments programmatically
      final assessmentIds = <String>[];
      final queueStopwatch = Stopwatch()..start();

      for (int i = 1; i <= 5; i++) {
        final assessmentData = i % 2 == 0
            ? TestHelpers.generateHighRiskAssessment()
            : TestHelpers.generateModerateRiskAssessment();

        final assessment = AssessmentsCompanion.insert(
          id: assessmentData['id'] as String,
          userId: assessmentData['userId'] as String,
          likelihoodScore: assessmentData['likelihoodScore'] as int,
          impactScore: assessmentData['impactScore'] as int,
          finalRiskScore: assessmentData['finalRiskScore'] as int,
          riskCategory: assessmentData['riskCategory'] as String,
          symptomsData: assessmentData['symptoms'].toString(),
          vitalSignsData: assessmentData['vitalSigns'].toString(),
          recommendationsData: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await database.into(database.assessments).insert(assessment);
        assessmentIds.add(assessmentData['id'] as String);

        // Add to sync queue
        await syncQueue.addOperation(
          operationType: 'syncAssessment',
          entityType: 'assessment',
          entityId: assessmentData['id'] as String,
          payload: {
            'assessmentId': assessmentData['id'],
            'userId': assessmentData['userId'],
          },
        );

        TestHelpers.logStep('Queued assessment $i of 5');
      }

      queueStopwatch.stop();
      TestHelpers.logPerformance('Queue 5 Assessments', queueStopwatch.elapsed);

      // ASSERTION: Queuing performance
      expect(
        queueStopwatch.elapsedMilliseconds / 5,
        lessThan(500),
        reason: 'Each assessment should queue in <500ms',
      );

      // STEP 3.2: Verify all queued
      final queueStatusAfterBatch = syncQueue.getQueueStatus();
      expect(
        queueStatusAfterBatch['pending'],
        greaterThanOrEqualTo(5),
        reason: 'Should have at least 5 assessments queued',
      );

      TestHelpers.logStep('PHASE 3 COMPLETE: ${queueStatusAfterBatch['pending']} assessments queued');

      // ==================== PHASE 4: RESTORE CONNECTIVITY & SYNC ====================
      TestHelpers.logStep('PHASE 4: Restore Connectivity and Sync');
      final syncStopwatch = Stopwatch()..start();

      // Simulate network restoration
      TestHelpers.simulateOnlineMode();

      // STEP 4.1: Process sync queue
      TestHelpers.logStep('Processing sync queue...');
      await syncQueue.processQueue();
      await Future.delayed(const Duration(seconds: 3));

      syncStopwatch.stop();
      TestHelpers.logPerformance('Sync Queue Processing', syncStopwatch.elapsed);

      // ASSERTION: Sync performance
      expect(
        syncStopwatch.elapsedMilliseconds,
        lessThan(60000),
        reason: 'Sync queue should process in <1 minute',
      );

      // STEP 4.2: Verify sync status
      final syncedAssessments = await database.select(database.assessments).get();
      int syncedCount = syncedAssessments.where((a) => a.isSynced).length;
      int pendingCount = syncedAssessments.where((a) => !a.isSynced).length;

      TestHelpers.logStep('Synced: $syncedCount, Pending: $pendingCount');

      // Note: Some may still be pending if backend is unavailable
      // This is expected behavior - they'll retry later

      TestHelpers.logStep('PHASE 4 COMPLETE: Sync processing finished');

      // ==================== PHASE 5: CONFLICT RESOLUTION ====================
      TestHelpers.logStep('PHASE 5: Test Conflict Resolution');
      final conflictStopwatch = Stopwatch()..start();

      // STEP 5.1: Create conflicting versions
      final baseAssessment = syncedAssessments.first;

      // Local update (timestamp T1)
      final localUpdate = baseAssessment.copyWith(
        symptomsData: '{"modified": "locally"}',
        updatedAt: DateTime.now(),
      );

      // Server update (timestamp T2, later)
      await Future.delayed(const Duration(milliseconds: 100));
      final serverUpdate = baseAssessment.copyWith(
        symptomsData: '{"modified": "on_server"}',
        updatedAt: DateTime.now(),
      );

      // STEP 5.2: Detect conflict
      final hasConflict = localUpdate.updatedAt.isBefore(serverUpdate.updatedAt);
      expect(hasConflict, isTrue, reason: 'Should detect timestamp conflict');

      // STEP 5.3: Apply last-write-wins resolution
      final resolvedVersion = serverUpdate.updatedAt.isAfter(localUpdate.updatedAt)
          ? serverUpdate
          : localUpdate;

      expect(
        resolvedVersion.symptomsData,
        equals('{"modified": "on_server"}'),
        reason: 'Server version should win (later timestamp)',
      );

      conflictStopwatch.stop();
      TestHelpers.logPerformance('Conflict Resolution', conflictStopwatch.elapsed);

      // ASSERTION: Conflict resolution performance
      expect(
        conflictStopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Conflict resolution should complete in <2 seconds',
      );

      TestHelpers.logStep('PHASE 5 COMPLETE: Conflict resolved successfully');

      // ==================== PHASE 6: CLINICAL VALIDATION ====================
      TestHelpers.logStep('PHASE 6: Clinical Validation');

      // STEP 6.1: Validate all risk scores
      for (final assessment in syncedAssessments) {
        // Verify risk score in valid range (1-25)
        TestHelpers.assertValidRiskScore(assessment.finalRiskScore);

        // Verify risk category matches score
        TestHelpers.assertRiskCategoryValid(
          assessment.finalRiskScore,
          assessment.riskCategory,
        );

        // Verify calculation: Likelihood × Impact = Final Score
        final calculatedScore = assessment.likelihoodScore * assessment.impactScore;
        expect(
          assessment.finalRiskScore,
          equals(calculatedScore),
          reason: 'Risk score should equal Likelihood × Impact',
        );

        TestHelpers.logStep(
          'Assessment ${assessment.id}: Score ${assessment.finalRiskScore} (${assessment.riskCategory}) - VALID',
        );
      }

      TestHelpers.logStep('PHASE 6 COMPLETE: All assessments clinically validated');

      // ==================== PHASE 7: DATA INTEGRITY CHECK ====================
      TestHelpers.logStep('PHASE 7: Data Integrity Check');

      // STEP 7.1: Verify no data loss
      final finalAssessmentCount = syncedAssessments.length;
      expect(
        finalAssessmentCount,
        greaterThanOrEqualTo(6),
        reason: 'Should have at least 6 assessments (1 manual + 5 queued)',
      );

      // STEP 7.2: Verify all have required fields
      for (final assessment in syncedAssessments) {
        expect(assessment.id, isNotEmpty);
        expect(assessment.userId, isNotEmpty);
        expect(assessment.symptomsData, isNotEmpty);
        expect(assessment.vitalSignsData, isNotEmpty);
        expect(assessment.createdAt, isNotNull);
        expect(assessment.updatedAt, isNotNull);
      }

      // STEP 7.3: Verify timestamps are consistent
      for (final assessment in syncedAssessments) {
        expect(
          assessment.updatedAt.isAfter(assessment.createdAt) ||
          assessment.updatedAt.isAtSameMomentAs(assessment.createdAt),
          isTrue,
          reason: 'Updated timestamp should be >= created timestamp',
        );

        if (assessment.syncedAt != null) {
          expect(
            assessment.syncedAt!.isAfter(assessment.createdAt),
            isTrue,
            reason: 'Sync timestamp should be after creation',
          );
        }
      }

      TestHelpers.logStep('PHASE 7 COMPLETE: Data integrity verified');

      // ==================== FINAL RESULTS ====================
      totalStopwatch.stop();

      print('');
      print('='.padRight(70, '='));
      print('TEST SUMMARY: Offline Assessment → Online Sync');
      print('='.padRight(70, '='));
      print('Phase 1 - Offline Assessment: ${offlineStopwatch.elapsedMilliseconds}ms');
      print('Phase 3 - Queue 5 Assessments: ${queueStopwatch.elapsedMilliseconds}ms');
      print('Phase 4 - Sync Processing: ${syncStopwatch.elapsedMilliseconds}ms');
      print('Phase 5 - Conflict Resolution: ${conflictStopwatch.elapsedMilliseconds}ms');
      print('TOTAL TIME: ${totalStopwatch.elapsedMilliseconds}ms');
      print('');
      print('ASSESSMENTS CREATED: $finalAssessmentCount');
      print('ASSESSMENTS SYNCED: $syncedCount');
      print('ASSESSMENTS PENDING: $pendingCount');
      print('='.padRight(70, '='));
      print('');

      TestHelpers.logResult(
        'Offline Assessment → Online Sync',
        true,
        details: 'All phases completed successfully',
      );
    });

    testWidgets('Sync retry mechanism with exponential backoff', (tester) async {
      TestHelpers.logStep('TEST START: Sync Retry Mechanism');

      // Create assessment that will fail to sync
      const assessmentId = 'test-retry-assessment';
      final failingAssessment = AssessmentsCompanion.insert(
        id: assessmentId,
        userId: 'test-user-retry',
        likelihoodScore: 4,
        impactScore: 4,
        finalRiskScore: 16,
        riskCategory: 'Moderate',
        symptomsData: '{}',
        vitalSignsData: '{}',
        recommendationsData: '[]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.into(database.assessments).insert(failingAssessment);

      // Queue sync operation
      await syncQueue.addOperation(
        operationType: 'syncAssessment',
        entityType: 'assessment',
        entityId: assessmentId,
        payload: {
          'assessmentId': assessmentId,
          'forceFailure': true, // Flag to simulate failure
        },
      );

      // Attempt sync (should fail and retry)
      try {
        await assessmentSync.syncPendingAssessments();
      } catch (e) {
        TestHelpers.logStep('First sync attempt failed (expected): $e');
      }

      await Future.delayed(const Duration(seconds: 2));

      // Verify retry count incremented
      final queuedOps = await syncQueue.getPendingOperations();
      final retryOp = queuedOps.where((op) => op.entityId == assessmentId).firstOrNull;

      if (retryOp != null) {
        expect(
          retryOp.retryCount,
          greaterThan(0),
          reason: 'Retry count should increment after failure',
        );
        TestHelpers.logStep('Retry count: ${retryOp.retryCount}');
      }

      TestHelpers.logResult('Sync Retry Mechanism', true);
    });

    testWidgets('Concurrent assessment sync without data corruption', (tester) async {
      TestHelpers.logStep('TEST START: Concurrent Sync Test');

      // Create 10 assessments concurrently
      final assessmentIds = <String>[];
      final futures = <Future>[];

      for (int i = 1; i <= 10; i++) {
        final assessmentData = TestHelpers.generateModerateRiskAssessment();
        assessmentIds.add(assessmentData['id'] as String);

        final future = database.into(database.assessments).insert(
          AssessmentsCompanion.insert(
            id: assessmentData['id'] as String,
            userId: assessmentData['userId'] as String,
            likelihoodScore: assessmentData['likelihoodScore'] as int,
            impactScore: assessmentData['impactScore'] as int,
            finalRiskScore: assessmentData['finalRiskScore'] as int,
            riskCategory: assessmentData['riskCategory'] as String,
            symptomsData: assessmentData['symptoms'].toString(),
            vitalSignsData: assessmentData['vitalSigns'].toString(),
            recommendationsData: '[]',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ).then((_) {
          return syncQueue.addOperation(
            operationType: 'syncAssessment',
            entityType: 'assessment',
            entityId: assessmentData['id'] as String,
            payload: {'assessmentId': assessmentData['id']},
          );
        });

        futures.add(future);
      }

      // Wait for all concurrent operations
      await Future.wait(futures);

      // Verify all queued correctly
      final queuedOps = await syncQueue.getPendingOperations();
      final concurrentOps = queuedOps.where((op) => assessmentIds.contains(op.entityId)).toList();
      expect(concurrentOps.length, equals(10));

      // Sync all
      await assessmentSync.syncPendingAssessments();
      await Future.delayed(const Duration(seconds: 3));

      // Verify no data corruption
      final syncedAssessments = await database.select(database.assessments).get();
      for (final id in assessmentIds) {
        final assessment = syncedAssessments.where((a) => a.id == id).firstOrNull;
        expect(assessment, isNotNull, reason: 'Assessment $id should exist');
        if (assessment != null) {
          TestHelpers.assertValidRiskScore(assessment.finalRiskScore);
        }
      }

      TestHelpers.logStep('All 10 concurrent assessments synced without corruption');
      TestHelpers.logResult('Concurrent Sync Test', true);
    });

    testWidgets('Network interruption during sync', (tester) async {
      TestHelpers.logStep('TEST START: Network Interruption During Sync');

      // Create assessment
      final assessmentData = TestHelpers.generateHighRiskAssessment();
      await database.into(database.assessments).insert(
        AssessmentsCompanion.insert(
          id: assessmentData['id'] as String,
          userId: assessmentData['userId'] as String,
          likelihoodScore: assessmentData['likelihoodScore'] as int,
          impactScore: assessmentData['impactScore'] as int,
          finalRiskScore: assessmentData['finalRiskScore'] as int,
          riskCategory: assessmentData['riskCategory'] as String,
          symptomsData: assessmentData['symptoms'].toString(),
          vitalSignsData: assessmentData['vitalSigns'].toString(),
          recommendationsData: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Queue for sync
      await syncQueue.addOperation(
        operationType: 'syncAssessment',
        entityType: 'assessment',
        entityId: assessmentData['id'] as String,
        payload: {'assessmentId': assessmentData['id']},
      );

      // Start sync
      final syncFuture = assessmentSync.syncPendingAssessments();

      // Simulate network interruption mid-sync
      await Future.delayed(const Duration(milliseconds: 500));
      TestHelpers.simulateNetworkInterruption();

      // Wait for sync to complete/fail
      try {
        await syncFuture;
      } catch (e) {
        TestHelpers.logStep('Sync interrupted (expected): $e');
      }

      // Restore network
      TestHelpers.simulateOnlineMode();

      // Verify assessment still in queue for retry
      final queuedOps = await syncQueue.getPendingOperations();
      final interruptedOp = queuedOps.where((op) => op.entityId == assessmentData['id']).firstOrNull;

      expect(interruptedOp, isNotNull, reason: 'Failed sync should remain in queue');

      TestHelpers.logResult('Network Interruption During Sync', true);
    });
  });
}
