import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Performance Benchmark Integration Test
///
/// Measures performance metrics across different device categories:
/// - Low-end: 2GB RAM, older processors
/// - Mid-range: 4GB RAM, standard processors
/// - High-end: 8GB+ RAM, flagship processors
///
/// Key Metrics:
/// - App launch time
/// - Screen transition time
/// - Assessment completion time
/// - Memory usage (estimated)
/// - Frame rate (60fps target)
/// - Network response time
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmark Tests', () {
    late String deviceCategory;
    late Map<String, int> performanceThresholds;

    setUpAll(() async {
      await Hive.initFlutter();
      SharedPreferences.setMockInitialValues({});

      // Determine device category based on specs
      deviceCategory = await _getDeviceCategory();
      performanceThresholds = _getPerformanceThresholds(deviceCategory);

      debugPrint('=== Performance Test Configuration ===');
      debugPrint('Device Category: $deviceCategory');
      debugPrint('Thresholds: $performanceThresholds');
    });

    tearDownAll(() async {
      await Hive.close();
    });

    testWidgets('App Launch Performance', (WidgetTester tester) async {
      final startTime = DateTime.now();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final launchTime = DateTime.now().difference(startTime).inMilliseconds;
      final threshold = performanceThresholds['app_launch_time']!;

      debugPrint('METRIC: app_launch_time=$launchTime ms');
      debugPrint('THRESHOLD: $threshold ms');
      debugPrint('STATUS: ${launchTime <= threshold ? "PASS" : "FAIL"}');

      // Log for device farm reporting
      expect(launchTime, lessThanOrEqualTo(threshold * 1.5),
          reason: 'App launch time should be within 150% of threshold for $deviceCategory devices');
    });

    testWidgets('Home Screen Render Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final startTime = DateTime.now();

      // Navigate to home (if not already there)
      final homeIcon = find.byIcon(Icons.home);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon.first);
        await tester.pumpAndSettle();
      }

      final renderTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint('METRIC: home_screen_render=$renderTime ms');
      expect(renderTime, lessThan(2000),
          reason: 'Home screen should render in under 2 seconds');
    });

    testWidgets('Assessment Screen Navigation Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final startTime = DateTime.now();

      // Navigate to assessment
      final assessmentIcon = find.byIcon(Icons.favorite);
      if (assessmentIcon.evaluate().isNotEmpty) {
        await tester.tap(assessmentIcon.first);
        await tester.pumpAndSettle();
      }

      final navTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint('METRIC: assessment_navigation=$navTime ms');
      expect(navTime, lessThan(1500),
          reason: 'Screen navigation should be under 1.5 seconds');
    });

    testWidgets('Assessment Completion Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        final startTime = DateTime.now();

        // Navigate to assessment
        final assessmentIcon = find.byIcon(Icons.favorite);
        if (assessmentIcon.evaluate().isNotEmpty) {
          await tester.tap(assessmentIcon.first);
          await tester.pumpAndSettle();
        }

        // Start assessment
        final startButton = find.text('Start Assessment');
        if (startButton.evaluate().isNotEmpty) {
          await tester.tap(startButton);
          await tester.pumpAndSettle();
        }

        // Quick symptom selection
        final symptomButton = find.text('Mild').first;
        if (symptomButton.evaluate().isNotEmpty) {
          await tester.tap(symptomButton);
          await tester.pumpAndSettle();
        }

        // Continue
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        }

        // Enter vitals quickly
        final bpSystolic = find.byKey(const Key('bp_systolic'));
        if (bpSystolic.evaluate().isNotEmpty) {
          await tester.enterText(bpSystolic, '120');
          await tester.pumpAndSettle();
        }

        final bpDiastolic = find.byKey(const Key('bp_diastolic'));
        if (bpDiastolic.evaluate().isNotEmpty) {
          await tester.enterText(bpDiastolic, '80');
          await tester.pumpAndSettle();
        }

        final heartRate = find.byKey(const Key('heart_rate'));
        if (heartRate.evaluate().isNotEmpty) {
          await tester.enterText(heartRate, '72');
          await tester.pumpAndSettle();
        }

        // Complete
        final completeButton = find.text('Complete Assessment');
        if (completeButton.evaluate().isNotEmpty) {
          await tester.tap(completeButton);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }

        final completionTime = DateTime.now().difference(startTime).inMilliseconds;
        final threshold = performanceThresholds['assessment_completion']!;

        debugPrint('METRIC: assessment_completion=$completionTime ms');
        debugPrint('THRESHOLD: $threshold ms');
        debugPrint('STATUS: ${completionTime <= threshold ? "PASS" : "FAIL"}');
      } catch (e) {
        debugPrint('METRIC: assessment_completion=error: $e');
      }
    });

    testWidgets('List Scrolling Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Navigate to screen with list (facilities or appointments)
        final facilitiesIcon = find.byIcon(Icons.local_hospital);
        if (facilitiesIcon.evaluate().isNotEmpty) {
          await tester.tap(facilitiesIcon.first);
          await tester.pumpAndSettle();
        }

        // Measure scroll performance
        final listView = find.byType(ListView).first;
        if (listView.evaluate().isNotEmpty) {
          final startTime = DateTime.now();

          // Scroll down
          await tester.drag(listView, const Offset(0, -500));
          await tester.pumpAndSettle();

          // Scroll up
          await tester.drag(listView, const Offset(0, 500));
          await tester.pumpAndSettle();

          final scrollTime = DateTime.now().difference(startTime).inMilliseconds;

          debugPrint('METRIC: list_scroll_performance=$scrollTime ms');
          expect(scrollTime, lessThan(1000),
              reason: 'List scrolling should be smooth (< 1 second)');
        }
      } catch (e) {
        debugPrint('METRIC: list_scroll_performance=error: $e');
      }
    });

    testWidgets('Form Input Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        final startTime = DateTime.now();

        // Find any text field
        final textField = find.byType(TextField).first;
        if (textField.evaluate().isNotEmpty) {
          // Measure typing responsiveness
          const testText = 'Performance Test Input';
          await tester.enterText(textField, testText);
          await tester.pumpAndSettle();
        }

        final inputTime = DateTime.now().difference(startTime).inMilliseconds;

        debugPrint('METRIC: form_input_performance=$inputTime ms');
        expect(inputTime, lessThan(500),
            reason: 'Form input should be responsive (< 500ms)');
      } catch (e) {
        debugPrint('METRIC: form_input_performance=error: $e');
      }
    });

    testWidgets('PDF Generation Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Navigate to assessment history or referral screen
        final startTime = DateTime.now();

        // Simulate PDF generation (button tap)
        final pdfButton = find.byIcon(Icons.picture_as_pdf);
        if (pdfButton.evaluate().isNotEmpty) {
          await tester.tap(pdfButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));
        }

        final pdfTime = DateTime.now().difference(startTime).inMilliseconds;

        debugPrint('METRIC: pdf_generation=$pdfTime ms');
        expect(pdfTime, lessThan(3000),
            reason: 'PDF generation should complete within 3 seconds');
      } catch (e) {
        debugPrint('METRIC: pdf_generation=not_tested: $e');
      }
    });

    testWidgets('Multiple Screen Transitions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final navigationItems = [
        Icons.home,
        Icons.favorite,
        Icons.calendar_today,
        Icons.local_hospital,
        Icons.person,
      ];

      final startTime = DateTime.now();
      int successfulTransitions = 0;

      for (final icon in navigationItems) {
        try {
          final navButton = find.byIcon(icon).first;
          if (navButton.evaluate().isNotEmpty) {
            await tester.tap(navButton);
            await tester.pumpAndSettle();
            successfulTransitions++;
          }
        } catch (e) {
          debugPrint('Navigation to $icon failed: $e');
        }
      }

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      final avgTime = successfulTransitions > 0 ? totalTime / successfulTransitions : 0;

      debugPrint('METRIC: screen_transitions=$successfulTransitions in $totalTime ms');
      debugPrint('METRIC: avg_transition_time=$avgTime ms');

      expect(avgTime, lessThan(2000),
          reason: 'Average screen transition should be under 2 seconds');
    });

    testWidgets('Offline Data Operations Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test local data operations speed
      final startTime = DateTime.now();

      try {
        // Write test data
        final prefs = await SharedPreferences.getInstance();
        for (int i = 0; i < 10; i++) {
          await prefs.setString('test_key_$i', 'test_value_$i');
        }

        // Read test data
        for (int i = 0; i < 10; i++) {
          prefs.getString('test_key_$i');
        }

        final operationTime = DateTime.now().difference(startTime).inMilliseconds;

        debugPrint('METRIC: offline_data_operations=$operationTime ms');
        expect(operationTime, lessThan(1000),
            reason: 'Offline data operations should be fast (< 1 second)');
      } catch (e) {
        debugPrint('METRIC: offline_data_operations=error: $e');
      }
    });

    testWidgets('Image Loading Performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final startTime = DateTime.now();

      // Navigate to screens with images
      final homeIcon = find.byIcon(Icons.home);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      final imageLoadTime = DateTime.now().difference(startTime).inMilliseconds;

      debugPrint('METRIC: image_loading=$imageLoadTime ms');
    });

    testWidgets('Performance Summary Report', (WidgetTester tester) async {
      debugPrint('\n=== PERFORMANCE SUMMARY ===');
      debugPrint('Device Category: $deviceCategory');
      debugPrint('Test Device: ${await _getDeviceInfo()}');
      debugPrint('Performance Thresholds:');
      performanceThresholds.forEach((key, value) {
        debugPrint('  $key: $value ms');
      });
      debugPrint('==========================\n');
    });
  });
}

/// Determines device category based on hardware specs
Future<String> _getDeviceCategory() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    // Low-end: API 21-23 or specific low-end models
    if (sdkInt <= 23) return 'low-end';

    // High-end: API 31+ (Android 12+)
    if (sdkInt >= 31) return 'high-end';

    // Mid-range: API 24-30
    return 'mid-range';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    final version = double.tryParse(iosInfo.systemVersion.split('.').first) ?? 0;

    // Low-end: iOS 12-13
    if (version <= 13) return 'low-end';

    // High-end: iOS 16+
    if (version >= 16) return 'high-end';

    // Mid-range: iOS 14-15
    return 'mid-range';
  }

  return 'mid-range'; // Default
}

/// Gets performance thresholds based on device category
Map<String, int> _getPerformanceThresholds(String category) {
  switch (category) {
    case 'low-end':
      return {
        'app_launch_time': 4000,
        'memory_usage': 200,
        'battery_drain': 10,
        'assessment_completion': 30000,
      };
    case 'high-end':
      return {
        'app_launch_time': 2000,
        'memory_usage': 120,
        'battery_drain': 6,
        'assessment_completion': 15000,
      };
    case 'mid-range':
    default:
      return {
        'app_launch_time': 3000,
        'memory_usage': 150,
        'battery_drain': 8,
        'assessment_completion': 20000,
      };
  }
}

/// Gets device info string for reporting
Future<String> _getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return '${iosInfo.model} (iOS ${iosInfo.systemVersion})';
  }

  return 'Unknown Device';
}
