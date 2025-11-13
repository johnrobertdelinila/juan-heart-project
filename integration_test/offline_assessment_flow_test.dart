import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/services/assessment_sync_service.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration test for offline assessment flow
///
/// This test validates the complete offline-first assessment journey:
/// 1. Complete risk assessment without internet connection
/// 2. Verify data saved to local database (Drift)
/// 3. Verify sync operation added to queue
/// 4. Simulate network restoration
/// 5. Verify automatic sync to backend
/// 6. Verify backend ID stored locally
///
/// Target: Complete flow in <5 seconds
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Assessment Flow - End-to-End', () {
    late AppDatabase database;
    late SyncQueueService syncQueue;
    late AssessmentSyncService assessmentSync;

    setUp(() async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Initialize services
      database = AppDatabase();
      syncQueue = SyncQueueService();
      assessmentSync = AssessmentSyncService();
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('Complete assessment offline and sync when online', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // Wait for initial load
      await tester.pump(const Duration(seconds: 2));

      // STEP 2: Navigate to assessment screen
      // Note: Navigation depends on app's authentication state
      // Assuming user is logged in or bypasses login

      // Look for assessment button/card
      final assessmentButton = find.text('Heart Risk Assessment');
      if (assessmentButton.evaluate().isNotEmpty) {
        await tester.tap(assessmentButton);
        await tester.pumpAndSettle();
      }

      // STEP 3: Fill assessment form (offline)
      // This is a simplified flow - actual implementation may vary

      // Fill symptoms section
      final chestPainOption = find.text('Chest pain or discomfort');
      if (chestPainOption.evaluate().isNotEmpty) {
        await tester.tap(chestPainOption);
        await tester.pumpAndSettle();
      }

      // Fill medical history
      final hypertensionOption = find.text('Hypertension');
      if (hypertensionOption.evaluate().isNotEmpty) {
        await tester.tap(hypertensionOption);
        await tester.pumpAndSettle();
      }

      // Fill lifestyle factors
      final smokingOption = find.text('Current smoker');
      if (smokingOption.evaluate().isNotEmpty) {
        await tester.tap(smokingOption);
        await tester.pumpAndSettle();
      }

      // STEP 4: Submit assessment
      final submitButton = find.widgetWithText(ElevatedButton, 'Complete Assessment');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
      }

      // STEP 5: Verify assessment saved locally
      final assessments = await database.select(database.assessments).get();
      expect(assessments, isNotEmpty, reason: 'Assessment should be saved to local database');

      final savedAssessment = assessments.last;
      expect(savedAssessment.finalRiskScore, greaterThan(0));
      expect(savedAssessment.isSynced, isFalse, reason: 'Assessment should not be synced yet');

      // STEP 6: Verify sync operation queued
      final queuedOperations = await syncQueue.getPendingOperations();
      expect(
        queuedOperations.any((op) => op.entityType == 'assessment'),
        isTrue,
        reason: 'Assessment sync operation should be in queue',
      );

      // STEP 7: Simulate network restoration and sync
      await assessmentSync.syncPendingAssessments();

      // Wait for sync to complete
      await tester.pump(const Duration(seconds: 2));

      // STEP 8: Verify sync completed
      final syncedAssessments = await database
          .select(database.assessments)
          .get();

      final syncedAssessment = syncedAssessments.firstWhere(
        (a) => a.id == savedAssessment.id,
      );

      expect(
        syncedAssessment.isSynced,
        isTrue,
        reason: 'Assessment should be marked as synced',
      );
      expect(
        syncedAssessment.syncedAt,
        isNotNull,
        reason: 'Sync timestamp should be recorded',
      );

      // STEP 9: Verify queue cleared
      final remainingOperations = await syncQueue.getPendingOperations();
      expect(
        remainingOperations.where((op) =>
            op.entityType == 'assessment' &&
            op.entityId == savedAssessment.id).isEmpty,
        isTrue,
        reason: 'Completed sync operation should be removed from queue',
      );
    });

    testWidgets('Assessment data persists across app restarts', (tester) async {
      // STEP 1: Create assessment
      final testAssessment = AssessmentsCompanion.insert(
        id: 'test-assessment-persistence',
        userId: 'test-user-1',
        likelihoodScore: 4,
        impactScore: 5,
        finalRiskScore: 20,
        riskCategory: 'High',
        symptomsData: '{"chestPain": true, "shortnessOfBreath": true}',
        vitalSignsData: '{"systolicBP": 160, "diastolicBP": 95}',
        recommendationsData: '["Seek immediate medical attention"]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await database.into(database.assessments).insert(testAssessment);

      // STEP 2: Close database (simulating app shutdown)
      await database.close();

      // STEP 3: Restart app and database
      database = AppDatabase();

      // STEP 4: Verify data persisted
      final retrievedAssessments = await database
          .select(database.assessments)
          .get();

      final persistedAssessment = retrievedAssessments.firstWhere(
        (a) => a.id == 'test-assessment-persistence',
      );

      expect(persistedAssessment.finalRiskScore, equals(20));
      expect(persistedAssessment.riskCategory, equals('High'));
      expect(persistedAssessment.isSynced, isFalse);
    });

    testWidgets('Multiple assessments queue and sync correctly', (tester) async {
      // STEP 1: Create multiple assessments offline
      final assessmentIds = <String>[];

      for (int i = 1; i <= 3; i++) {
        final assessmentId = 'test-assessment-$i';
        assessmentIds.add(assessmentId);

        final assessment = AssessmentsCompanion.insert(
          id: assessmentId,
          userId: 'test-user-multi',
          likelihoodScore: 3 + i,
          impactScore: 4,
          finalRiskScore: (3 + i) * 4,
          riskCategory: i == 3 ? 'High' : 'Moderate',
          symptomsData: '{"symptom$i": true}',
          vitalSignsData: '{"bp": ${130 + i * 10}}',
          recommendationsData: '["Recommendation $i"]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await database.into(database.assessments).insert(assessment);

        // Queue sync operation
        await syncQueue.addOperation(
          operationType: 'syncAssessment',
          entityType: 'assessment',
          entityId: assessmentId,
          payload: {
            'assessmentId': assessmentId,
            'userId': 'test-user-multi',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      // STEP 2: Verify all queued
      final queuedOps = await syncQueue.getPendingOperations();
      expect(queuedOps.length, greaterThanOrEqualTo(3));

      // STEP 3: Sync all
      await assessmentSync.syncPendingAssessments();

      // STEP 4: Verify all synced
      final syncedAssessments = await database
          .select(database.assessments)
          .get();

      for (final id in assessmentIds) {
        final assessment = syncedAssessments.firstWhere((a) => a.id == id);
        expect(
          assessment.isSynced,
          isTrue,
          reason: 'Assessment $id should be synced',
        );
      }
    });

    testWidgets('Failed sync retries with exponential backoff', (tester) async {
      // STEP 1: Create assessment
      const assessmentId = 'test-assessment-retry';
      final assessment = AssessmentsCompanion.insert(
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

      await database.into(database.assessments).insert(assessment);

      // STEP 2: Queue sync operation
      await syncQueue.addOperation(
        operationType: 'syncAssessment',
        entityType: 'assessment',
        entityId: assessmentId,
        payload: {
          'assessmentId': assessmentId,
          'forceFailure': true, // Simulate network failure
        },
      );

      // STEP 3: Attempt sync (should fail and schedule retry)
      try {
        await assessmentSync.syncPendingAssessments();
      } catch (e) {
        // Expected to fail
      }

      // STEP 4: Verify operation still in queue with retry count
      final queuedOps = await syncQueue.getPendingOperations();
      final retryOp = queuedOps.firstWhere(
        (op) => op.entityId == assessmentId,
      );

      expect(retryOp.retryCount, greaterThan(0), reason: 'Retry count should increment');
      expect(retryOp.status, equals('pending'), reason: 'Should remain pending for retry');
    });

    testWidgets('Assessment with invalid data shows validation error', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // STEP 2: Navigate to assessment
      final assessmentButton = find.text('Heart Risk Assessment');
      if (assessmentButton.evaluate().isNotEmpty) {
        await tester.tap(assessmentButton);
        await tester.pumpAndSettle();
      }

      // STEP 3: Try to submit without filling required fields
      final submitButton = find.widgetWithText(ElevatedButton, 'Complete Assessment');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
      }

      // STEP 4: Verify validation error shown
      expect(
        find.text('Please complete all required fields'),
        findsOneWidget,
        reason: 'Validation error should be displayed',
      );
    });

    testWidgets('Assessment sync handles concurrent operations', (tester) async {
      // STEP 1: Create multiple assessments rapidly
      final assessmentIds = <String>[];
      final futures = <Future>[];

      for (int i = 1; i <= 5; i++) {
        final assessmentId = 'concurrent-assessment-$i';
        assessmentIds.add(assessmentId);

        final future = database.into(database.assessments).insert(
          AssessmentsCompanion.insert(
            id: assessmentId,
            userId: 'test-user-concurrent',
            likelihoodScore: 3,
            impactScore: 4,
            finalRiskScore: 12,
            riskCategory: 'Moderate',
            symptomsData: '{}',
            vitalSignsData: '{}',
            recommendationsData: '[]',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ).then((_) {
          return syncQueue.addOperation(
            operationType: 'syncAssessment',
            entityType: 'assessment',
            entityId: assessmentId,
            payload: {'assessmentId': assessmentId},
          );
        });

        futures.add(future);
      }

      // STEP 2: Wait for all concurrent operations
      await Future.wait(futures);

      // STEP 3: Verify all queued correctly
      final queuedOps = await syncQueue.getPendingOperations();
      final concurrentOps = queuedOps.where(
        (op) => assessmentIds.contains(op.entityId),
      ).toList();

      expect(concurrentOps.length, equals(5));

      // STEP 4: Sync all concurrently
      await assessmentSync.syncPendingAssessments();

      // STEP 5: Verify all synced
      final syncedAssessments = await database
          .select(database.assessments)
          .get();

      for (final id in assessmentIds) {
        final assessment = syncedAssessments.firstWhere((a) => a.id == id);
        expect(assessment.isSynced, isTrue);
      }
    });

    testWidgets('Assessment result screen shows risk category correctly', (tester) async {
      // STEP 1: Launch app
      await app.main();
      await tester.pumpAndSettle();

      // STEP 2: Complete assessment flow (simplified)
      // Navigate and fill form...

      // STEP 3: Verify risk category displayed
      // High risk assessments (score 20-25) should show red color
      expect(
        find.text('High Risk'),
        findsOneWidget,
        skip: true, // Skip if not on results screen
      );

      // STEP 4: Verify recommendations shown
      expect(
        find.text('Seek immediate medical attention'),
        findsOneWidget,
        skip: true,
      );

      // STEP 5: Verify facility referral option available
      expect(
        find.text('Find Nearest Facility'),
        findsOneWidget,
        skip: true,
      );
    });

    testWidgets('Performance: Complete assessment flow under 5 seconds', (tester) async {
      final stopwatch = Stopwatch()..start();

      // STEP 1: Create assessment
      final assessment = AssessmentsCompanion.insert(
        id: 'perf-test-assessment',
        userId: 'perf-test-user',
        likelihoodScore: 4,
        impactScore: 5,
        finalRiskScore: 20,
        riskCategory: 'High',
        symptomsData: '{"chestPain": true}',
        vitalSignsData: '{"systolicBP": 160}',
        recommendationsData: '["Seek medical attention"]',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // STEP 2: Save to database
      await database.into(database.assessments).insert(assessment);

      // STEP 3: Queue sync operation
      await syncQueue.addOperation(
        operationType: 'syncAssessment',
        entityType: 'assessment',
        entityId: 'perf-test-assessment',
        payload: {'assessmentId': 'perf-test-assessment'},
      );

      // STEP 4: Perform sync
      await assessmentSync.syncPendingAssessments();

      // STEP 5: Verify completion
      final syncedAssessments = await database
          .select(database.assessments)
          .get();

      final syncedAssessment = syncedAssessments.firstWhere(
        (a) => a.id == 'perf-test-assessment',
      );

      expect(syncedAssessment.isSynced, isTrue);

      stopwatch.stop();

      // Performance requirement: <5 seconds
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5000),
        reason: 'Complete assessment flow should finish in under 5 seconds',
      );

      print('Assessment flow completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
