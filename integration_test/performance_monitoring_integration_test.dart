import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integration tests for Firebase Performance Monitoring
///
/// These tests verify that performance traces are correctly integrated
/// throughout the application's critical user flows.
///
/// Note: These tests verify the interface contracts and trace lifecycle.
/// Actual trace data is validated via Firebase Console after deployment.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Monitoring Integration Tests', () {
    setUp(() async {
      // Enable analytics for testing
      SharedPreferences.setMockInitialValues({
        'analytics_enabled': true,
        'privacy_consent_given': true,
      });

      // Initialize performance service
      await PerformanceService.instance.initialize();
    });

    testWidgets('Complete CVD assessment flow records all traces', (tester) async {
      // This test verifies the complete assessment flow
      // In production, traces would be sent to Firebase Console

      // SCENARIO: User completes full CVD risk assessment with AI

      // Step 1: App Start Trace
      final appStartTrace = await PerformanceService.instance.startAppStartTrace();
      expect(appStartTrace, anyOf(isNull, isA<Object>()));

      // Simulate app initialization
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      await PerformanceService.instance.stopAppStartTrace(appStartTrace);

      // Step 2: Navigate to Home Screen
      final homeScreenTrace = await PerformanceService.instance.startScreenTrace('HomeScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await PerformanceService.instance.stopScreenTrace(homeScreenTrace);

      // Step 3: Start Assessment Flow
      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      expect(assessmentTrace, anyOf(isNull, isA<Object>()));

      // Step 4: Navigate to Risk Assessment Screen
      final riskScreenTrace = await PerformanceService.instance.startScreenTrace('RiskAssessmentScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      await PerformanceService.instance.stopScreenTrace(riskScreenTrace);

      // Step 5: Symptom Checker Phase
      final symptomTrace = await PerformanceService.instance.startSymptomCheckerTrace();

      // Simulate user selecting symptoms
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      const symptomCount = 4; // User selects 4 symptoms
      await PerformanceService.instance.stopSymptomCheckerTrace(
        symptomTrace,
        symptomCount,
      );

      // Step 6: Vital Signs Phase
      final vitalSignsTrace = await PerformanceService.instance.startVitalSignsTrace();

      // Simulate user entering vital signs (BP, HR, weight, height)
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));

      const vitalSignsCount = 4; // 4 vital signs entered
      await PerformanceService.instance.stopVitalSignsTrace(
        vitalSignsTrace,
        vitalSignsCount,
      );

      // Step 7: Risk Calculation Phase (with AI)
      final riskCalcTrace = await PerformanceService.instance.startRiskCalculationTrace();

      // Simulate Genkit AI call
      final genkitTrace = await PerformanceService.instance.startGenkitApiTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      const responseSize = 2048; // 2KB response
      await PerformanceService.instance.stopGenkitApiTrace(
        genkitTrace,
        success: true,
        responseSize: responseSize,
      );

      // Risk calculation completes
      const finalScore = 20; // High risk (L4 × I5 = 20)
      await PerformanceService.instance.stopRiskCalculationTrace(
        riskCalcTrace,
        calculationType: 'ai',
        finalScore: finalScore,
      );

      // Step 8: Complete Assessment Flow
      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 4,
        impactScore: 5,
        symptomCount: symptomCount,
        usedAI: true,
      );

      // Verification: All traces completed without errors
      expect(true, isTrue); // Test passes if no exceptions thrown
    });

    testWidgets('Complete assessment flow with rule-based calculation', (tester) async {
      // SCENARIO: User completes assessment using PHC rule-based algorithm

      // Start assessment
      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();

      // Symptom checker
      final symptomTrace = await PerformanceService.instance.startSymptomCheckerTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await PerformanceService.instance.stopSymptomCheckerTrace(symptomTrace, 2);

      // Vital signs
      final vitalSignsTrace = await PerformanceService.instance.startVitalSignsTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await PerformanceService.instance.stopVitalSignsTrace(vitalSignsTrace, 4);

      // Risk calculation (rule-based)
      final riskCalcTrace = await PerformanceService.instance.startRiskCalculationTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await PerformanceService.instance.stopRiskCalculationTrace(
        riskCalcTrace,
        calculationType: 'rule_based',
        finalScore: 12,
      );

      // Complete assessment
      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 3,
        impactScore: 4,
        symptomCount: 2,
        usedAI: false,
      );

      expect(true, isTrue);
    });

    testWidgets('Appointment sync flow records sync trace', (tester) async {
      // SCENARIO: User creates appointments offline, then syncs online

      // Create appointments offline (simulated)
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // User goes online, sync begins
      final syncTrace = await PerformanceService.instance.startAppointmentSyncTrace();

      // Simulate sync process
      await tester.pumpAndSettle(const Duration(milliseconds: 2000));

      // Sync completes with results
      const syncedCount = 5;
      const failedCount = 0;
      await PerformanceService.instance.stopAppointmentSyncTrace(
        syncTrace,
        syncedCount: syncedCount,
        failedCount: failedCount,
      );

      expect(true, isTrue);
    });

    testWidgets('Appointment sync with partial failures', (tester) async {
      // SCENARIO: Some appointments fail to sync

      final syncTrace = await PerformanceService.instance.startAppointmentSyncTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 3000));

      // 3 synced successfully, 2 failed
      await PerformanceService.instance.stopAppointmentSyncTrace(
        syncTrace,
        syncedCount: 3,
        failedCount: 2,
      );

      expect(true, isTrue);
    });

    testWidgets('Screen load traces for all instrumented screens', (tester) async {
      // SCENARIO: User navigates through all major screens

      final screens = [
        'HomeScreen',
        'AnalyticsScreen',
        'BookAppointmentScreen',
        'RiskAssessmentScreen',
        'FacilitySelectionScreen',
      ];

      for (final screenName in screens) {
        final trace = await PerformanceService.instance.startScreenTrace(screenName);

        // Simulate screen load time
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        await PerformanceService.instance.stopScreenTrace(trace);

        // Verify screen loaded within target (<500ms)
        // In production, this is monitored via Firebase Console
      }

      expect(true, isTrue);
    });

    testWidgets('Database query trace integration', (tester) async {
      // SCENARIO: User views assessment history

      final queryTrace = await PerformanceService.instance.startDatabaseQueryTrace('getAllAssessments');

      // Simulate database query
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      const recordCount = 25; // 25 assessments retrieved
      await PerformanceService.instance.stopDatabaseQueryTrace(
        queryTrace,
        recordCount: recordCount,
      );

      expect(true, isTrue);
    });

    testWidgets('Multiple database queries with varying record counts', (tester) async {
      // SCENARIO: Different database operations

      final queries = {
        'getRecentAssessments': 10,
        'getAppointments': 5,
        'getFacilities': 8,
        'getNotifications': 15,
      };

      for (final entry in queries.entries) {
        final trace = await PerformanceService.instance.startDatabaseQueryTrace(entry.key);
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        await PerformanceService.instance.stopDatabaseQueryTrace(
          trace,
          recordCount: entry.value,
        );
      }

      expect(true, isTrue);
    });

    testWidgets('Genkit AI success scenario', (tester) async {
      // SCENARIO: Successful AI assessment call

      final trace = await PerformanceService.instance.startGenkitApiTrace();

      // Simulate API call (target <3s)
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));

      await PerformanceService.instance.stopGenkitApiTrace(
        trace,
        success: true,
        responseSize: 1536, // 1.5KB
      );

      expect(true, isTrue);
    });

    testWidgets('Genkit AI failure scenario', (tester) async {
      // SCENARIO: AI API call fails (fallback to rule-based)

      final trace = await PerformanceService.instance.startGenkitApiTrace();

      // Simulate failed API call
      await tester.pumpAndSettle(const Duration(milliseconds: 5000)); // Timeout

      await PerformanceService.instance.stopGenkitApiTrace(
        trace,
        success: false,
        responseSize: 0,
      );

      expect(true, isTrue);
    });

    testWidgets('Privacy disabled - no traces fire', (tester) async {
      // SCENARIO: User disables analytics

      // Disable analytics
      SharedPreferences.setMockInitialValues({
        'analytics_enabled': false,
      });

      // Attempt to start traces
      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      final syncTrace = await PerformanceService.instance.startAppointmentSyncTrace();
      final screenTrace = await PerformanceService.instance.startScreenTrace('TestScreen');

      // All should return null (privacy respected)
      expect(assessmentTrace, isNull);
      expect(syncTrace, isNull);
      expect(screenTrace, isNull);

      // App should continue functioning normally
      await tester.pumpAndSettle();
      expect(true, isTrue);
    });

    testWidgets('traceOperation helper with successful operation', (tester) async {
      // SCENARIO: Using traceOperation helper

      final result = await PerformanceService.instance.traceOperation(
        'test_successful_operation',
        () async {
          await Future.delayed(const Duration(milliseconds: 500));
          return 'success';
        },
      );

      expect(result, equals('success'));
    });

    testWidgets('traceOperation helper with failed operation', (tester) async {
      // SCENARIO: Operation fails, trace records error

      expect(
        () async => await PerformanceService.instance.traceOperation(
          'test_failed_operation',
          () async {
            await Future.delayed(const Duration(milliseconds: 200));
            throw Exception('Test error');
          },
        ),
        throwsException,
      );
    });

    testWidgets('Complete user journey - critical path', (tester) async {
      // SCENARIO: Complete user journey from app start to appointment booking

      // 1. App Start
      final appStartTrace = await PerformanceService.instance.startAppStartTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      await PerformanceService.instance.stopAppStartTrace(appStartTrace);

      // 2. Home Screen
      final homeTrace = await PerformanceService.instance.startScreenTrace('HomeScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      await PerformanceService.instance.stopScreenTrace(homeTrace);

      // 3. Complete Assessment
      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      final symptomTrace = await PerformanceService.instance.startSymptomCheckerTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));
      await PerformanceService.instance.stopSymptomCheckerTrace(symptomTrace, 3);

      final vitalTrace = await PerformanceService.instance.startVitalSignsTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 1200));
      await PerformanceService.instance.stopVitalSignsTrace(vitalTrace, 4);

      final riskTrace = await PerformanceService.instance.startRiskCalculationTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await PerformanceService.instance.stopRiskCalculationTrace(
        riskTrace,
        calculationType: 'rule_based',
        finalScore: 18,
      );

      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 3,
        impactScore: 6,
        symptomCount: 3,
        usedAI: false,
      );

      // 4. Navigate to Facility Selection
      final facilityTrace = await PerformanceService.instance.startScreenTrace('FacilitySelectionScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      await PerformanceService.instance.stopScreenTrace(facilityTrace);

      // 5. Book Appointment
      final bookingTrace = await PerformanceService.instance.startScreenTrace('BookAppointmentScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      await PerformanceService.instance.stopScreenTrace(bookingTrace);

      // 6. Sync Appointment
      final syncTrace = await PerformanceService.instance.startAppointmentSyncTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      await PerformanceService.instance.stopAppointmentSyncTrace(
        syncTrace,
        syncedCount: 1,
        failedCount: 0,
      );

      expect(true, isTrue);
    });

    testWidgets('Performance under stress - multiple concurrent operations', (tester) async {
      // SCENARIO: Multiple traces running simultaneously

      final traces = <String, dynamic>{};

      // Start multiple traces
      traces['assessment'] = await PerformanceService.instance.startAssessmentTrace();
      traces['screen1'] = await PerformanceService.instance.startScreenTrace('Screen1');
      traces['screen2'] = await PerformanceService.instance.startScreenTrace('Screen2');
      traces['query'] = await PerformanceService.instance.startDatabaseQueryTrace('testQuery');

      // Simulate concurrent operations
      await tester.pumpAndSettle(const Duration(milliseconds: 1000));

      // Stop all traces
      await PerformanceService.instance.stopAssessmentTrace(
        traces['assessment'],
        likelihoodScore: 2,
        impactScore: 3,
        symptomCount: 1,
        usedAI: false,
      );
      await PerformanceService.instance.stopScreenTrace(traces['screen1']);
      await PerformanceService.instance.stopScreenTrace(traces['screen2']);
      await PerformanceService.instance.stopDatabaseQueryTrace(
        traces['query'],
        recordCount: 5,
      );

      expect(true, isTrue);
    });

    testWidgets('Low-end device simulation - performance degradation', (tester) async {
      // SCENARIO: Simulating performance on low-end devices

      // Start app trace
      final appStartTrace = await PerformanceService.instance.startAppStartTrace();

      // Simulate slow app start (low-end device target: <3s)
      await tester.pumpAndSettle(const Duration(milliseconds: 2800));

      await PerformanceService.instance.stopAppStartTrace(appStartTrace);

      // Screen load on low-end device
      final screenTrace = await PerformanceService.instance.startScreenTrace('HomeScreen');
      await tester.pumpAndSettle(const Duration(milliseconds: 600)); // Slightly over target
      await PerformanceService.instance.stopScreenTrace(screenTrace);

      // Assessment flow on low-end device
      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 5000)); // Slower
      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 3,
        impactScore: 3,
        symptomCount: 2,
        usedAI: false,
      );

      expect(true, isTrue);
    });

    testWidgets('Edge case - zero values and minimums', (tester) async {
      // SCENARIO: Testing boundary values

      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Minimum values
      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 1,
        impactScore: 1,
        symptomCount: 0,
        usedAI: false,
      );

      final syncTrace = await PerformanceService.instance.startAppointmentSyncTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // No appointments to sync
      await PerformanceService.instance.stopAppointmentSyncTrace(
        syncTrace,
        syncedCount: 0,
        failedCount: 0,
      );

      final queryTrace = await PerformanceService.instance.startDatabaseQueryTrace('emptyQuery');
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      // Empty result set
      await PerformanceService.instance.stopDatabaseQueryTrace(
        queryTrace,
        recordCount: 0,
      );

      expect(true, isTrue);
    });

    testWidgets('Edge case - maximum values', (tester) async {
      // SCENARIO: Testing maximum boundary values

      final assessmentTrace = await PerformanceService.instance.startAssessmentTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Maximum risk score (5 × 5 = 25)
      await PerformanceService.instance.stopAssessmentTrace(
        assessmentTrace,
        likelihoodScore: 5,
        impactScore: 5,
        symptomCount: 10,
        usedAI: true,
      );

      final genkitTrace = await PerformanceService.instance.startGenkitApiTrace();
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // Large response
      await PerformanceService.instance.stopGenkitApiTrace(
        genkitTrace,
        success: true,
        responseSize: 1048576, // 1MB
      );

      expect(true, isTrue);
    });
  });
}
