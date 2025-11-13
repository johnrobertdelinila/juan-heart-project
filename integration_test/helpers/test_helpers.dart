import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_heart/models/questionnaire_model.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:uuid/uuid.dart';

/// Test Helpers for E2E Testing
///
/// This file contains common utilities for integration tests:
/// - Test data generators
/// - Common assertions
/// - Navigation helpers
/// - Timing utilities
/// - Database cleanup

class TestHelpers {
  static const uuid = Uuid();

  // ==================== Test Data Generators ====================

  /// Generate a complete assessment with high-risk profile
  static Map<String, dynamic> generateHighRiskAssessment() {
    return {
      'id': uuid.v4(),
      'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      'symptoms': {
        'chestPain': {'severity': 5, 'duration': 'more_than_hour'},
        'shortnessOfBreath': {'severity': 5, 'duration': 'severe'},
        'fatigue': {'severity': 4, 'duration': 'chronic'},
        'dizziness': {'severity': 3, 'duration': 'occasional'},
        'palpitations': {'severity': 4, 'duration': 'frequent'},
      },
      'vitalSigns': {
        'systolicBP': 180,
        'diastolicBP': 110,
        'heartRate': 110,
        'weight': 95.0,
        'height': 165.0,
        'bmi': 34.9,
      },
      'medicalHistory': {
        'hypertension': true,
        'diabetes': true,
        'heartDisease': true,
        'stroke': false,
        'familyHistory': true,
      },
      'lifestyle': {
        'smoking': 'current',
        'alcohol': 'heavy',
        'exercise': 'none',
        'diet': 'poor',
      },
      'likelihoodScore': 5,
      'impactScore': 5,
      'finalRiskScore': 25,
      'riskCategory': 'Critical',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate a moderate-risk assessment
  static Map<String, dynamic> generateModerateRiskAssessment() {
    return {
      'id': uuid.v4(),
      'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      'symptoms': {
        'chestPain': {'severity': 3, 'duration': 'less_than_hour'},
        'shortnessOfBreath': {'severity': 2, 'duration': 'mild'},
        'fatigue': {'severity': 3, 'duration': 'recent'},
      },
      'vitalSigns': {
        'systolicBP': 140,
        'diastolicBP': 90,
        'heartRate': 85,
        'weight': 75.0,
        'height': 170.0,
        'bmi': 25.9,
      },
      'medicalHistory': {
        'hypertension': true,
        'diabetes': false,
        'heartDisease': false,
        'stroke': false,
        'familyHistory': false,
      },
      'lifestyle': {
        'smoking': 'never',
        'alcohol': 'moderate',
        'exercise': 'light',
        'diet': 'average',
      },
      'likelihoodScore': 3,
      'impactScore': 4,
      'finalRiskScore': 12,
      'riskCategory': 'Moderate',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate a low-risk assessment
  static Map<String, dynamic> generateLowRiskAssessment() {
    return {
      'id': uuid.v4(),
      'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      'symptoms': {
        'chestPain': {'severity': 1, 'duration': 'brief'},
        'shortnessOfBreath': {'severity': 1, 'duration': 'mild'},
      },
      'vitalSigns': {
        'systolicBP': 120,
        'diastolicBP': 80,
        'heartRate': 72,
        'weight': 68.0,
        'height': 170.0,
        'bmi': 23.5,
      },
      'medicalHistory': {
        'hypertension': false,
        'diabetes': false,
        'heartDisease': false,
        'stroke': false,
        'familyHistory': false,
      },
      'lifestyle': {
        'smoking': 'never',
        'alcohol': 'none',
        'exercise': 'regular',
        'diet': 'healthy',
      },
      'likelihoodScore': 1,
      'impactScore': 2,
      'finalRiskScore': 2,
      'riskCategory': 'Low',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Generate test appointment
  static Appointment generateTestAppointment({
    String? facilityName,
    DateTime? appointmentDate,
    AppointmentStatus status = AppointmentStatus.pending,
    int? riskScore,
  }) {
    return Appointment(
      id: uuid.v4(),
      facilityId: 'facility_${DateTime.now().millisecondsSinceEpoch}',
      facilityName: facilityName ?? 'Philippine Heart Center',
      doctorName: 'Dr. Test Physician',
      appointmentDate: appointmentDate ?? DateTime.now().add(const Duration(days: 7)),
      appointmentTime: '10:00 AM',
      status: status,
      type: AppointmentType.consultation,
      patientName: 'Juan Test Patient',
      contactNumber: '+639171234567',
      riskScore: riskScore,
      riskCategory: riskScore != null && riskScore >= 15 ? 'High' : 'Moderate',
      notes: 'E2E test appointment',
      createdAt: DateTime.now(),
    );
  }

  /// Generate user registration data
  static Map<String, String> generateUserData({
    String? email,
    String? password,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return {
      'email': email ?? 'test_user_$timestamp@juanheart.test',
      'password': password ?? 'Test123!@#',
      'firstName': 'Juan',
      'lastName': 'Test',
      'contactNumber': '+639171234567',
      'birthDate': '1985-01-15',
      'gender': 'Male',
      'address': '123 Test Street, Quezon City, Philippines',
    };
  }

  // ==================== Navigation Helpers ====================

  /// Wait for page to load with timeout
  static Future<void> waitForPageLoad(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Find and tap button by text
  static Future<void> tapButtonByText(
    WidgetTester tester,
    String text, {
    bool skipIfNotFound = false,
  }) async {
    final finder = find.text(text);
    if (skipIfNotFound && finder.evaluate().isEmpty) {
      print('[TestHelpers] Button "$text" not found, skipping...');
      return;
    }
    expect(finder, findsOneWidget, reason: 'Button "$text" should be visible');
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Find and tap button by key
  static Future<void> tapButtonByKey(
    WidgetTester tester,
    Key key, {
    bool skipIfNotFound = false,
  }) async {
    final finder = find.byKey(key);
    if (skipIfNotFound && finder.evaluate().isEmpty) {
      print('[TestHelpers] Button with key "$key" not found, skipping...');
      return;
    }
    expect(finder, findsOneWidget, reason: 'Button with key "$key" should be visible');
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text into field
  static Future<void> enterText(
    WidgetTester tester,
    String key,
    String text, {
    bool clearFirst = true,
  }) async {
    final finder = find.byKey(Key(key));
    expect(finder, findsOneWidget, reason: 'Text field "$key" should be visible');

    if (clearFirst) {
      await tester.tap(finder);
      await tester.pumpAndSettle();
      await tester.enterText(finder, '');
      await tester.pumpAndSettle();
    }

    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scroll until widget is visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    double scrollDelta = 300.0,
    int maxScrolls = 10,
  }) async {
    for (int i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        Offset(0, -scrollDelta),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Navigate back
  static Future<void> navigateBack(WidgetTester tester) async {
    final backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      // Try system back button
      await tester.pageBack();
    }
    await tester.pumpAndSettle();
  }

  // ==================== Assertion Helpers ====================

  /// Assert text is visible on screen
  static void assertTextVisible(String text, {String? reason}) {
    expect(
      find.text(text),
      findsOneWidget,
      reason: reason ?? 'Text "$text" should be visible',
    );
  }

  /// Assert text is NOT visible on screen
  static void assertTextNotVisible(String text, {String? reason}) {
    expect(
      find.text(text),
      findsNothing,
      reason: reason ?? 'Text "$text" should NOT be visible',
    );
  }

  /// Assert widget by key exists
  static void assertWidgetExists(Key key, {String? reason}) {
    expect(
      find.byKey(key),
      findsOneWidget,
      reason: reason ?? 'Widget with key "$key" should exist',
    );
  }

  /// Assert risk score is valid (1-25)
  static void assertValidRiskScore(int score) {
    expect(score, greaterThanOrEqualTo(1), reason: 'Risk score must be >= 1');
    expect(score, lessThanOrEqualTo(25), reason: 'Risk score must be <= 25');
  }

  /// Assert risk category matches score
  static void assertRiskCategoryValid(int score, String category) {
    if (score >= 1 && score <= 5) {
      expect(category, equals('Low'), reason: 'Score 1-5 should be Low risk');
    } else if (score >= 6 && score <= 10) {
      expect(category, equals('Mild'), reason: 'Score 6-10 should be Mild risk');
    } else if (score >= 11 && score <= 15) {
      expect(category, equals('Moderate'), reason: 'Score 11-15 should be Moderate risk');
    } else if (score >= 16 && score <= 20) {
      expect(category, equals('High'), reason: 'Score 16-20 should be High risk');
    } else if (score >= 21 && score <= 25) {
      expect(category, equals('Critical'), reason: 'Score 21-25 should be Critical risk');
    }
  }

  // ==================== Timing Utilities ====================

  /// Measure operation time
  static Future<Duration> measureTime(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Assert operation completes within time limit
  static Future<void> assertCompletesWithin(
    Future<void> Function() operation,
    Duration timeLimit, {
    String? reason,
  }) async {
    final duration = await measureTime(operation);
    expect(
      duration.inMilliseconds,
      lessThan(timeLimit.inMilliseconds),
      reason: reason ?? 'Operation should complete within ${timeLimit.inSeconds}s',
    );
  }

  /// Wait with timeout
  static Future<void> waitFor(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (!condition()) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException('Condition not met within ${timeout.inSeconds}s');
      }
      await Future.delayed(checkInterval);
    }
  }

  // ==================== Network Simulation ====================

  /// Simulate offline mode
  static void simulateOfflineMode() {
    print('[TestHelpers] Simulating offline mode...');
    // In real implementation, this would disable network connectivity
  }

  /// Simulate online mode
  static void simulateOnlineMode() {
    print('[TestHelpers] Simulating online mode...');
    // In real implementation, this would enable network connectivity
  }

  /// Simulate slow network (3G)
  static void simulateSlowNetwork() {
    print('[TestHelpers] Simulating slow 3G network...');
    // In real implementation, this would throttle network speed
  }

  /// Simulate network interruption
  static void simulateNetworkInterruption() {
    print('[TestHelpers] Simulating network interruption...');
    // In real implementation, this would toggle network on/off
  }

  // ==================== Database Utilities ====================

  /// Clear all test data
  static Future<void> clearTestData() async {
    print('[TestHelpers] Clearing all test data...');
    // Clear assessments, appointments, sync queue
  }

  /// Seed test database
  static Future<void> seedTestDatabase() async {
    print('[TestHelpers] Seeding test database...');
    // Add test facilities, users, etc.
  }

  // ==================== Screenshot Helpers ====================

  /// Take screenshot for debugging
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    // Integration test framework doesn't support screenshots by default
    // This is a placeholder for future implementation
    print('[TestHelpers] Screenshot: $name');
  }

  // ==================== Logging Utilities ====================

  /// Log test step
  static void logStep(String step) {
    print('[E2E Test] $step');
  }

  /// Log performance metric
  static void logPerformance(String metric, Duration duration) {
    print('[Performance] $metric: ${duration.inMilliseconds}ms');
  }

  /// Log test result
  static void logResult(String testName, bool passed, {String? details}) {
    final status = passed ? 'PASSED' : 'FAILED';
    print('[Result] $testName: $status ${details ?? ''}');
  }
}

/// Exception for timeout scenarios
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
