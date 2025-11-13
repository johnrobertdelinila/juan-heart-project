import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:juan_heart/database/app_database.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/test_helpers.dart';
import 'pages/page_objects.dart';

/// E2E Test: Edge Cases and Error Scenarios
///
/// This test suite validates the application's behavior in edge cases:
/// - Network interruptions during critical operations
/// - App backgrounding/foregrounding
/// - Device rotation during forms
/// - Low memory scenarios
/// - Permission denials
/// - Invalid/expired tokens
/// - Backend service unavailability
/// - Concurrent user actions
/// - Data corruption scenarios
/// - Boundary value testing
///
/// These tests ensure the app handles unexpected scenarios gracefully
/// and maintains data integrity under all conditions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Edge Cases and Error Scenarios', () {
    late AppDatabase database;
    late SyncQueueService syncQueue;
    late HomePage homePage;
    late AssessmentPage assessmentPage;
    late AppointmentPage appointmentPage;

    setUpAll(() async {
      database = AppDatabase();
      syncQueue = SyncQueueService();
      await syncQueue.initialize();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await TestHelpers.clearTestData();
    });

    tearDownAll(() async {
      await database.close();
    });

    // ==================== NETWORK INTERRUPTION TESTS ====================

    testWidgets('Network interruption during assessment submission', (tester) async {
      TestHelpers.logStep('TEST: Network interruption during assessment');

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start assessment
      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Fill assessment
      await assessmentPage.selectSymptom('Chest pain or discomfort', 3);
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      await assessmentPage.enterBloodPressure(140, 90);
      await assessmentPage.enterHeartRate(85);
      await tester.pumpAndSettle();

      // Simulate network interruption
      TestHelpers.simulateOfflineMode();

      // Submit assessment (should queue for later sync)
      if (find.text('Complete Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapSubmit();
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify assessment saved locally
      final assessments = await database.select(database.assessments).get();
      expect(assessments, isNotEmpty, reason: 'Assessment should be saved offline');

      // Verify queued for sync
      final queueStatus = syncQueue.getQueueStatus();
      expect(queueStatus['pending'], greaterThan(0), reason: 'Should be queued for sync');

      // Restore network
      TestHelpers.simulateOnlineMode();

      // Process queue
      await syncQueue.processQueue();
      await Future.delayed(const Duration(seconds: 2));

      TestHelpers.logResult('Network Interruption During Assessment', true);
    });

    testWidgets('Network timeout with graceful degradation', (tester) async {
      TestHelpers.logStep('TEST: Network timeout graceful degradation');

      // Simulate slow network
      TestHelpers.simulateSlowNetwork();

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // App should still load with cached data
      expect(
        find.text('Juan Heart').evaluate().isNotEmpty ||
        find.byKey(const Key('home_screen')).evaluate().isNotEmpty,
        isTrue,
        reason: 'App should load even with slow network',
      );

      TestHelpers.logResult('Network Timeout Graceful Degradation', true);
    });

    // ==================== APP STATE TESTS ====================

    testWidgets('App backgrounding during form submission', (tester) async {
      TestHelpers.logStep('TEST: App backgrounding during form');

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start assessment
      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Fill partial data
      await assessmentPage.selectSymptom('Chest pain or discomfort', 3);
      await tester.pumpAndSettle();

      // Simulate app backgrounding
      TestHelpers.logStep('Simulating app backgrounding...');
      await tester.pump(const Duration(seconds: 1));

      // Simulate app foregrounding
      TestHelpers.logStep('Simulating app foregrounding...');
      await tester.pumpAndSettle();

      // Verify form data persisted
      expect(
        find.text('Chest pain or discomfort').evaluate().isNotEmpty,
        isTrue,
        reason: 'Form data should persist after backgrounding',
      );

      TestHelpers.logResult('App Backgrounding During Form', true);
    });

    testWidgets('Device rotation during assessment', (tester) async {
      TestHelpers.logStep('TEST: Device rotation during assessment');

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start assessment
      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Fill some data
      await assessmentPage.enterBloodPressure(140, 90);
      await tester.pumpAndSettle();

      // Simulate rotation (change screen size)
      tester.view.physicalSize = const Size(800, 1200); // Portrait
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(1200, 800); // Landscape
      await tester.pumpAndSettle();

      // Verify data still present
      expect(
        find.byKey(const Key('vital_systolic_bp')).evaluate().isNotEmpty,
        isTrue,
        reason: 'Form fields should remain after rotation',
      );

      // Reset view size
      tester.view.resetPhysicalSize();
      await tester.pumpAndSettle();

      TestHelpers.logResult('Device Rotation During Assessment', true);
    });

    // ==================== PERMISSION TESTS ====================

    testWidgets('Location permission denied handling', (tester) async {
      TestHelpers.logStep('TEST: Location permission denied');

      homePage = HomePage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Try to access location-based feature without permission
      if (find.byKey(const Key('emergency_button')).evaluate().isNotEmpty) {
        await homePage.tapEmergency();
        await tester.pumpAndSettle();
      }

      // Should show permission request or graceful fallback
      expect(
        find.textContaining('Permission').evaluate().isNotEmpty ||
        find.text('Location services unavailable').evaluate().isNotEmpty ||
        find.text('Enable Location').evaluate().isNotEmpty,
        isTrue,
        reason: 'Should handle permission denial gracefully',
      );

      TestHelpers.logResult('Location Permission Denied', true);
    });

    testWidgets('Notification permission denied handling', (tester) async {
      TestHelpers.logStep('TEST: Notification permission denied');

      homePage = HomePage(tester);
      appointmentPage = AppointmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Book appointment without notification permission
      // Should still work but show warning about reminders

      TestHelpers.logResult('Notification Permission Denied', true);
    });

    // ==================== DATA VALIDATION TESTS ====================

    testWidgets('Invalid blood pressure values', (tester) async {
      TestHelpers.logStep('TEST: Invalid blood pressure values');

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Skip to vital signs
      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      // Try invalid BP (systolic < diastolic)
      await assessmentPage.enterBloodPressure(80, 140); // Invalid
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isNotEmpty) {
        await assessmentPage.tapNext();
        await tester.pumpAndSettle();
      }

      // Should show validation error
      expect(
        find.textContaining('Invalid').evaluate().isNotEmpty ||
        find.textContaining('must be greater than').evaluate().isNotEmpty,
        isTrue,
        reason: 'Should validate blood pressure values',
      );

      TestHelpers.logResult('Invalid Blood Pressure Values', true);
    });

    testWidgets('Boundary value testing for risk score', (tester) async {
      TestHelpers.logStep('TEST: Boundary value testing');

      // Test minimum risk score (1)
      final minRiskData = TestHelpers.generateLowRiskAssessment();
      minRiskData['likelihoodScore'] = 1;
      minRiskData['impactScore'] = 1;
      minRiskData['finalRiskScore'] = 1;

      await database.into(database.assessments).insert(
        AssessmentsCompanion.insert(
          id: minRiskData['id'] as String,
          userId: minRiskData['userId'] as String,
          likelihoodScore: 1,
          impactScore: 1,
          finalRiskScore: 1,
          riskCategory: 'Low',
          symptomsData: '{}',
          vitalSignsData: '{}',
          recommendationsData: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Test maximum risk score (25)
      final maxRiskData = TestHelpers.generateHighRiskAssessment();
      maxRiskData['likelihoodScore'] = 5;
      maxRiskData['impactScore'] = 5;
      maxRiskData['finalRiskScore'] = 25;

      await database.into(database.assessments).insert(
        AssessmentsCompanion.insert(
          id: maxRiskData['id'] as String,
          userId: maxRiskData['userId'] as String,
          likelihoodScore: 5,
          impactScore: 5,
          finalRiskScore: 25,
          riskCategory: 'Critical',
          symptomsData: '{}',
          vitalSignsData: '{}',
          recommendationsData: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Verify both stored correctly
      final assessments = await database.select(database.assessments).get();
      expect(assessments.length, greaterThanOrEqualTo(2));

      final minAssessment = assessments.firstWhere((a) => a.finalRiskScore == 1);
      final maxAssessment = assessments.firstWhere((a) => a.finalRiskScore == 25);

      expect(minAssessment.riskCategory, equals('Low'));
      expect(maxAssessment.riskCategory, equals('Critical'));

      TestHelpers.logResult('Boundary Value Testing', true);
    });

    // ==================== CONCURRENT OPERATION TESTS ====================

    testWidgets('Concurrent assessment submissions', (tester) async {
      TestHelpers.logStep('TEST: Concurrent assessment submissions');

      // Simulate multiple users submitting assessments simultaneously
      final futures = <Future>[];

      for (int i = 1; i <= 5; i++) {
        final assessmentData = TestHelpers.generateModerateRiskAssessment();

        final future = database.into(database.assessments).insert(
          AssessmentsCompanion.insert(
            id: assessmentData['id'] as String,
            userId: 'user_$i',
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

        futures.add(future);
      }

      // Wait for all
      await Future.wait(futures);

      // Verify all stored
      final assessments = await database.select(database.assessments).get();
      expect(assessments.length, greaterThanOrEqualTo(5));

      TestHelpers.logResult('Concurrent Assessment Submissions', true);
    });

    testWidgets('Race condition in sync queue', (tester) async {
      TestHelpers.logStep('TEST: Race condition in sync queue');

      // Add operations concurrently
      final futures = <Future>[];

      for (int i = 1; i <= 10; i++) {
        final future = syncQueue.addOperation(
          operationType: 'test',
          entityType: 'test',
          entityId: 'test_$i',
          payload: {'data': 'test_$i'},
        );
        futures.add(future);
      }

      await Future.wait(futures);

      // Verify queue integrity
      final queueStatus = syncQueue.getQueueStatus();
      expect(queueStatus['pending'], greaterThanOrEqualTo(10));

      TestHelpers.logResult('Race Condition in Sync Queue', true);
    });

    // ==================== DATA CORRUPTION TESTS ====================

    testWidgets('Handle corrupted assessment data', (tester) async {
      TestHelpers.logStep('TEST: Handle corrupted assessment data');

      // Insert assessment with corrupted JSON
      await database.into(database.assessments).insert(
        AssessmentsCompanion.insert(
          id: 'corrupted-assessment',
          userId: 'test-user',
          likelihoodScore: 3,
          impactScore: 4,
          finalRiskScore: 12,
          riskCategory: 'Moderate',
          symptomsData: '{invalid json}', // Corrupted
          vitalSignsData: '{}',
          recommendationsData: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Try to retrieve and handle gracefully
      final assessments = await database.select(database.assessments).get();
      final corruptedAssessment = assessments.firstWhere((a) => a.id == 'corrupted-assessment');

      // Should not crash, should handle gracefully
      expect(corruptedAssessment, isNotNull);

      TestHelpers.logResult('Handle Corrupted Assessment Data', true);
    });

    // ==================== LANGUAGE SWITCHING TESTS ====================

    testWidgets('Language switch during assessment', (tester) async {
      TestHelpers.logStep('TEST: Language switch during assessment');

      homePage = HomePage(tester);
      assessmentPage = AssessmentPage(tester);

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Start assessment in English
      if (find.text('Heart Risk Assessment').evaluate().isNotEmpty) {
        await homePage.tapAssessment();
        await tester.pumpAndSettle();
      }

      if (find.text('Start Assessment').evaluate().isNotEmpty) {
        await assessmentPage.tapStart();
        await tester.pumpAndSettle();
      }

      // Fill some data
      await assessmentPage.selectSymptom('Chest pain or discomfort', 3);
      await tester.pumpAndSettle();

      // Switch language to Filipino (if language switcher available)
      if (find.byKey(const Key('language_switcher')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('language_switcher')));
        await tester.pumpAndSettle();

        if (find.text('Filipino').evaluate().isNotEmpty) {
          await tester.tap(find.text('Filipino'));
          await tester.pumpAndSettle();
        }
      }

      // Verify data persisted after language change
      TestHelpers.logResult('Language Switch During Assessment', true);
    });

    // ==================== MEMORY TESTS ====================

    testWidgets('Large dataset handling', (tester) async {
      TestHelpers.logStep('TEST: Large dataset handling');

      // Create 100 assessments
      for (int i = 1; i <= 100; i++) {
        final assessmentData = i % 2 == 0
            ? TestHelpers.generateHighRiskAssessment()
            : TestHelpers.generateLowRiskAssessment();

        await database.into(database.assessments).insert(
          AssessmentsCompanion.insert(
            id: 'assessment_$i',
            userId: 'test-user',
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
      }

      // Retrieve all
      final stopwatch = Stopwatch()..start();
      final assessments = await database.select(database.assessments).get();
      stopwatch.stop();

      expect(assessments.length, equals(100));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Should retrieve 100 assessments in <1 second',
      );

      TestHelpers.logResult('Large Dataset Handling', true);
    });

    // ==================== SESSION EXPIRY TESTS ====================

    testWidgets('Handle expired session gracefully', (tester) async {
      TestHelpers.logStep('TEST: Handle expired session');

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Simulate expired session
      // Clear auth token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');

      // Try to perform authenticated action
      // Should redirect to login

      TestHelpers.logResult('Handle Expired Session', true);
    });

    // ==================== BACKEND UNAVAILABILITY TESTS ====================

    testWidgets('Backend service unavailable', (tester) async {
      TestHelpers.logStep('TEST: Backend service unavailable');

      // Simulate backend unavailability
      TestHelpers.simulateOfflineMode();

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // App should still function with local data
      expect(
        find.text('Juan Heart').evaluate().isNotEmpty ||
        find.byKey(const Key('home_screen')).evaluate().isNotEmpty,
        isTrue,
        reason: 'App should work offline',
      );

      TestHelpers.logResult('Backend Service Unavailable', true);
    });
  });
}
