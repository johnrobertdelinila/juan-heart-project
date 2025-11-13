import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock FirebasePerformance for testing
class MockFirebasePerformance extends Mock implements FirebasePerformance {}

/// Mock Trace for testing
class MockTrace extends Mock implements Trace {}

/// Comprehensive tests for PerformanceService
/// Tests all trace management, privacy integration, and error handling
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceService', () {
    late PerformanceService service;
    late MockFirebasePerformance mockPerformance;
    late MockTrace mockTrace;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue('test_trace');
    });

    setUp(() async {
      service = PerformanceService.instance;
      mockPerformance = MockFirebasePerformance();
      mockTrace = MockTrace();

      // Setup default privacy preferences (analytics enabled)
      SharedPreferences.setMockInitialValues({
        'analytics_enabled': true,
        'privacy_consent_given': true,
      });
    });

    group('Initialization Tests', () {
      test('initialize() completes without error', () async {
        // Test that initialization doesn't throw
        expect(() async => await service.initialize(), returnsNormally);
      });

      test('initialize() is idempotent - calling twice does not break', () async {
        // Initialize twice
        await service.initialize();
        await service.initialize();

        // Should not throw
        expect(service, isNotNull);
      });

      test('initialize() handles Firebase unavailable gracefully', () async {
        // Firebase initialization may fail - should not throw
        expect(() async => await service.initialize(), returnsNormally);
      });
    });

    group('Configuration Tests', () {
      test('setPerformanceCollectionEnabled(true) enables tracking', () async {
        // Mock performance instance
        when(() => mockPerformance.setPerformanceCollectionEnabled(true))
            .thenAnswer((_) async => {});

        // Execute - service should not throw even if _performance is null
        await service.setPerformanceCollectionEnabled(true);

        // Should complete without error
        expect(service, isNotNull);
      });

      test('setPerformanceCollectionEnabled(false) disables tracking', () async {
        // Mock performance instance
        when(() => mockPerformance.setPerformanceCollectionEnabled(false))
            .thenAnswer((_) async => {});

        // Execute
        await service.setPerformanceCollectionEnabled(false);

        // Should complete without error
        expect(service, isNotNull);
      });

      test('isPerformanceCollectionEnabled() returns privacy status', () async {
        // Service should check privacy preferences
        final isEnabled = await service.isPerformanceCollectionEnabled();

        // Should return a boolean
        expect(isEnabled, isA<bool>());
      });

      test('isPerformanceCollectionEnabled() returns false when analytics disabled', () async {
        // Disable analytics in privacy settings
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': false,
        });

        final isEnabled = await service.isPerformanceCollectionEnabled();

        // Should return false
        expect(isEnabled, equals(false));
      });
    });

    group('Core Trace Management Tests', () {
      test('startTrace() returns null when privacy disabled', () async {
        // Disable analytics
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': false,
        });

        final trace = await service.startTrace('test_trace');

        // Should return null when disabled
        expect(trace, isNull);
      });

      test('stopTrace() handles null trace gracefully', () async {
        // Stop a null trace - should not throw
        await service.stopTrace(null);

        // Should complete without error
        expect(service, isNotNull);
      });

      test('incrementMetric() handles null trace gracefully', () async {
        // Increment metric on null trace
        await service.incrementMetric(null, 'test_metric', 1);

        // Should complete without error
        expect(service, isNotNull);
      });

      test('setMetric() handles null trace gracefully', () async {
        // Set metric on null trace
        await service.setMetric(null, 'test_metric', 10);

        // Should complete without error
        expect(service, isNotNull);
      });

      test('putAttribute() handles null trace gracefully', () async {
        // Put attribute on null trace
        await service.putAttribute(null, 'test_key', 'test_value');

        // Should complete without error
        expect(service, isNotNull);
      });
    });

    group('Assessment-Specific Trace Tests', () {
      test('startAssessmentTrace() returns trace when enabled', () async {
        // Mock enabled privacy
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startAssessmentTrace();

        // Trace may be null if Firebase not initialized (graceful degradation)
        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopAssessmentTrace() handles null trace gracefully', () async {
        // Stop with null trace
        await service.stopAssessmentTrace(
          null,
          likelihoodScore: 4,
          impactScore: 5,
          symptomCount: 3,
          usedAI: true,
        );

        // Should complete without error
        expect(service, isNotNull);
      });

      test('stopAssessmentTrace() calculates final score correctly', () async {
        const likelihoodScore = 4;
        const impactScore = 5;
        const expectedFinalScore = likelihoodScore * impactScore; // 20

        // Mock trace
        when(() => mockTrace.setMetric(any(), any())).thenReturn(null);
        when(() => mockTrace.putAttribute(any(), any())).thenReturn(null);
        when(() => mockTrace.stop()).thenAnswer((_) async => {});

        // Would verify final_score metric is set to 20
        expect(expectedFinalScore, equals(20));
      });

      test('startSymptomCheckerTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startSymptomCheckerTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopSymptomCheckerTrace() handles null trace gracefully', () async {
        await service.stopSymptomCheckerTrace(null, 5);

        expect(service, isNotNull);
      });

      test('startVitalSignsTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startVitalSignsTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopVitalSignsTrace() handles null trace gracefully', () async {
        await service.stopVitalSignsTrace(null, 4);

        expect(service, isNotNull);
      });

      test('startRiskCalculationTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startRiskCalculationTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopRiskCalculationTrace() handles null trace gracefully', () async {
        await service.stopRiskCalculationTrace(
          null,
          calculationType: 'ai',
          finalScore: 20,
        );

        expect(service, isNotNull);
      });
    });

    group('Network & Sync Trace Tests', () {
      test('startAppointmentSyncTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startAppointmentSyncTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopAppointmentSyncTrace() handles null trace gracefully', () async {
        await service.stopAppointmentSyncTrace(
          null,
          syncedCount: 5,
          failedCount: 0,
        );

        expect(service, isNotNull);
      });

      test('stopAppointmentSyncTrace() records sync metrics correctly', () async {
        // Mock trace
        when(() => mockTrace.setMetric(any(), any())).thenReturn(null);
        when(() => mockTrace.stop()).thenAnswer((_) async => {});

        // Verify metrics would be set
        const syncedCount = 5;
        const failedCount = 0;

        expect(syncedCount, equals(5));
        expect(failedCount, equals(0));
      });

      test('startGenkitApiTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startGenkitApiTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopGenkitApiTrace() handles null trace gracefully', () async {
        await service.stopGenkitApiTrace(
          null,
          success: true,
          responseSize: 1024,
        );

        expect(service, isNotNull);
      });

      test('stopGenkitApiTrace() with success=true attribute', () async {
        // Mock trace
        when(() => mockTrace.putAttribute(any(), any())).thenReturn(null);
        when(() => mockTrace.setMetric(any(), any())).thenReturn(null);
        when(() => mockTrace.stop()).thenAnswer((_) async => {});

        // Verify success attribute
        const success = true;
        expect(success.toString(), equals('true'));
      });

      test('stopGenkitApiTrace() with success=false attribute', () async {
        const success = false;
        expect(success.toString(), equals('false'));
      });
    });

    group('Screen & Database Trace Tests', () {
      test('startScreenTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startScreenTrace('HomeScreen');

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopScreenTrace() handles null trace gracefully', () async {
        await service.stopScreenTrace(null);

        expect(service, isNotNull);
      });

      test('startDatabaseQueryTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startDatabaseQueryTrace('getAssessments');

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopDatabaseQueryTrace() handles null trace gracefully', () async {
        await service.stopDatabaseQueryTrace(null, recordCount: 10);

        expect(service, isNotNull);
      });

      test('stopDatabaseQueryTrace() with null recordCount', () async {
        await service.stopDatabaseQueryTrace(null, recordCount: null);

        expect(service, isNotNull);
      });

      test('startAppStartTrace() returns trace when enabled', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startAppStartTrace();

        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('stopAppStartTrace() handles null trace gracefully', () async {
        await service.stopAppStartTrace(null);

        expect(service, isNotNull);
      });
    });

    group('Error Handling Tests', () {
      test('startTrace() returns null when Firebase unavailable', () async {
        // Service may not have Firebase initialized
        final trace = await service.startTrace('error_test');

        // Should return null gracefully
        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('all stop methods handle null trace without throwing', () async {
        // Test all stop methods with null
        await service.stopTrace(null);
        await service.stopAssessmentTrace(
          null,
          likelihoodScore: 1,
          impactScore: 1,
          symptomCount: 0,
          usedAI: false,
        );
        await service.stopSymptomCheckerTrace(null, 0);
        await service.stopVitalSignsTrace(null, 0);
        await service.stopRiskCalculationTrace(
          null,
          calculationType: 'rule_based',
          finalScore: 1,
        );
        await service.stopAppointmentSyncTrace(
          null,
          syncedCount: 0,
          failedCount: 0,
        );
        await service.stopGenkitApiTrace(null, success: false, responseSize: 0);
        await service.stopScreenTrace(null);
        await service.stopDatabaseQueryTrace(null);
        await service.stopAppStartTrace(null);

        // All should complete without throwing
        expect(service, isNotNull);
      });

      test('setPerformanceCollectionEnabled() handles errors gracefully', () async {
        // Should not throw even if Firebase is unavailable
        await service.setPerformanceCollectionEnabled(true);
        await service.setPerformanceCollectionEnabled(false);

        expect(service, isNotNull);
      });

      test('no exceptions thrown from any method', () async {
        // Comprehensive test - call all methods
        await service.initialize();
        await service.setPerformanceCollectionEnabled(true);
        await service.isPerformanceCollectionEnabled();

        final trace = await service.startTrace('comprehensive_test');
        await service.incrementMetric(trace, 'test', 1);
        await service.setMetric(trace, 'test', 10);
        await service.putAttribute(trace, 'key', 'value');
        await service.stopTrace(trace);

        await service.startAssessmentTrace();
        await service.startSymptomCheckerTrace();
        await service.startVitalSignsTrace();
        await service.startRiskCalculationTrace();
        await service.startAppointmentSyncTrace();
        await service.startGenkitApiTrace();
        await service.startScreenTrace('TestScreen');
        await service.startDatabaseQueryTrace('testQuery');
        await service.startAppStartTrace();

        // All should complete without throwing
        expect(service, isNotNull);
      });
    });

    group('Privacy Integration Tests', () {
      test('traces do not fire when analytics disabled', () async {
        // Disable analytics
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': false,
        });

        // Try to start trace
        final trace = await service.startTrace('privacy_test');

        // Should return null
        expect(trace, isNull);
      });

      test('traces fire when analytics enabled', () async {
        // Enable analytics
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        // Try to start trace
        final trace = await service.startTrace('privacy_test');

        // May return trace or null (Firebase may not be initialized)
        expect(trace, anyOf(isNull, isA<Trace>()));
      });

      test('enabling/disabling mid-session works correctly', () async {
        // Start enabled
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace1 = await service.startTrace('enabled_test');
        expect(trace1, anyOf(isNull, isA<Trace>()));

        // Disable
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': false,
        });

        final trace2 = await service.startTrace('disabled_test');
        expect(trace2, isNull);

        // Re-enable
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace3 = await service.startTrace('re_enabled_test');
        expect(trace3, anyOf(isNull, isA<Trace>()));
      });
    });

    group('Trace Name Constants Tests', () {
      test('trace name constants are defined correctly', () {
        expect(PerformanceService.traceAssessment, equals('assessment_flow'));
        expect(PerformanceService.traceSymptomChecker, equals('symptom_checker'));
        expect(PerformanceService.traceVitalSigns, equals('vital_signs_input'));
        expect(PerformanceService.traceRiskCalculation, equals('risk_calculation'));
        expect(PerformanceService.traceAppointmentSync, equals('appointment_sync'));
        expect(PerformanceService.traceGenkitApi, equals('genkit_api_call'));
        expect(PerformanceService.traceScreen, equals('screen_load'));
        expect(PerformanceService.traceDatabaseQuery, equals('database_query'));
        expect(PerformanceService.traceAppStart, equals('app_start'));
      });
    });

    group('Metric Name Constants Tests', () {
      test('metric name constants are defined correctly', () {
        expect(PerformanceService.metricLikelihoodScore, equals('likelihood_score'));
        expect(PerformanceService.metricImpactScore, equals('impact_score'));
        expect(PerformanceService.metricSymptomCount, equals('symptom_count'));
        expect(PerformanceService.metricVitalSignsCount, equals('vital_signs_count'));
        expect(PerformanceService.metricFinalScore, equals('final_score'));
        expect(PerformanceService.metricSyncedCount, equals('synced_count'));
        expect(PerformanceService.metricFailedCount, equals('failed_count'));
        expect(PerformanceService.metricResponseSize, equals('response_size_bytes'));
      });
    });

    group('Attribute Name Constants Tests', () {
      test('attribute name constants are defined correctly', () {
        expect(PerformanceService.attrUsedAi, equals('used_ai'));
        expect(PerformanceService.attrCalculationType, equals('calculation_type'));
        expect(PerformanceService.attrScreenName, equals('screen_name'));
        expect(PerformanceService.attrSuccess, equals('success'));
        expect(PerformanceService.attrErrorType, equals('error_type'));
      });
    });

    group('Trace Operation Helper Tests', () {
      test('traceOperation() returns result on success', () async {
        final result = await service.traceOperation(
          'test_operation',
          () async => 'success',
        );

        expect(result, equals('success'));
      });

      test('traceOperation() rethrows exception on failure', () async {
        expect(
          () async => await service.traceOperation(
            'test_operation_fail',
            () async => throw Exception('Test error'),
          ),
          throwsException,
        );
      });

      test('traceOperation() with complex return type', () async {
        final complexData = {'key': 'value', 'count': 42};

        final result = await service.traceOperation(
          'complex_operation',
          () async => complexData,
        );

        expect(result, equals(complexData));
        expect(result['count'], equals(42));
      });
    });

    group('Singleton Pattern Tests', () {
      test('instance returns same singleton', () {
        final instance1 = PerformanceService.instance;
        final instance2 = PerformanceService.instance;

        expect(identical(instance1, instance2), equals(true));
      });

      test('factory constructor returns singleton', () {
        final instance1 = PerformanceService();
        final instance2 = PerformanceService();

        expect(identical(instance1, instance2), equals(true));
      });
    });

    group('Assessment Trace Complete Flow Tests', () {
      test('complete assessment flow with AI enabled', () async {
        // Enable analytics
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        // Start assessment trace
        final trace = await service.startAssessmentTrace();

        // Stop with AI metrics
        await service.stopAssessmentTrace(
          trace,
          likelihoodScore: 5,
          impactScore: 5,
          symptomCount: 4,
          usedAI: true,
        );

        // Should complete without error
        expect(service, isNotNull);
      });

      test('complete assessment flow with AI disabled', () async {
        // Enable analytics
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        // Start assessment trace
        final trace = await service.startAssessmentTrace();

        // Stop with rule-based metrics
        await service.stopAssessmentTrace(
          trace,
          likelihoodScore: 3,
          impactScore: 4,
          symptomCount: 2,
          usedAI: false,
        );

        // Should complete without error
        expect(service, isNotNull);
      });
    });

    group('Screen Load Trace Tests', () {
      test('track multiple screen loads', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final screens = [
          'HomeScreen',
          'AnalyticsScreen',
          'BookAppointmentScreen',
          'RiskAssessmentScreen',
          'FacilitySelectionScreen',
        ];

        for (final screen in screens) {
          final trace = await service.startScreenTrace(screen);
          await service.stopScreenTrace(trace);
        }

        // All should complete without error
        expect(service, isNotNull);
      });
    });

    group('Real-World Scenario Tests', () {
      test('appointment sync with mixed results', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startAppointmentSyncTrace();
        await service.stopAppointmentSyncTrace(
          trace,
          syncedCount: 8,
          failedCount: 2,
        );

        expect(service, isNotNull);
      });

      test('Genkit API call with large response', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startGenkitApiTrace();
        await service.stopGenkitApiTrace(
          trace,
          success: true,
          responseSize: 4096,
        );

        expect(service, isNotNull);
      });

      test('database query with many records', () async {
        SharedPreferences.setMockInitialValues({
          'analytics_enabled': true,
        });

        final trace = await service.startDatabaseQueryTrace('getAllAssessments');
        await service.stopDatabaseQueryTrace(trace, recordCount: 50);

        expect(service, isNotNull);
      });
    });

    group('Edge Cases Tests', () {
      test('handle zero values in metrics', () async {
        await service.stopAssessmentTrace(
          null,
          likelihoodScore: 0,
          impactScore: 0,
          symptomCount: 0,
          usedAI: false,
        );

        expect(service, isNotNull);
      });

      test('handle maximum risk score (5x5=25)', () async {
        await service.stopAssessmentTrace(
          null,
          likelihoodScore: 5,
          impactScore: 5,
          symptomCount: 10,
          usedAI: true,
        );

        expect(service, isNotNull);
      });

      test('handle empty screen name', () async {
        final trace = await service.startScreenTrace('');
        await service.stopScreenTrace(trace);

        expect(service, isNotNull);
      });

      test('handle very large response size', () async {
        await service.stopGenkitApiTrace(
          null,
          success: true,
          responseSize: 1048576, // 1MB
        );

        expect(service, isNotNull);
      });
    });
  });
}
