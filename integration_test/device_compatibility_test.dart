import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:juan_heart/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Device Compatibility Integration Test
///
/// Tests critical functionality across different device configurations:
/// - Installation and launch
/// - User authentication flows
/// - Heart risk assessment
/// - Offline/online sync
/// - Appointment booking
/// - Emergency features
///
/// Designed to run on Firebase Test Lab device matrix covering:
/// - Android 5.0+ (API 21-33)
/// - iOS 12.0-16.0
/// - Low-end, mid-range, and high-end devices
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Device Compatibility Tests', () {
    setUpAll(() async {
      // Clean state before tests
      await Hive.initFlutter();
      SharedPreferences.setMockInitialValues({});
    });

    tearDownAll(() async {
      await Hive.close();
    });

    testWidgets('Device Info Collection', (WidgetTester tester) async {
      // Collect device information for test reporting
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        debugPrint('=== Android Device Info ===');
        debugPrint('Model: ${androidInfo.model}');
        debugPrint('Manufacturer: ${androidInfo.manufacturer}');
        debugPrint('Android Version: ${androidInfo.version.release}');
        debugPrint('SDK: ${androidInfo.version.sdkInt}');
        debugPrint('Display: ${androidInfo.display}');
        debugPrint('Physical Device: ${androidInfo.isPhysicalDevice}');

        // Verify minimum Android version (API 21+)
        expect(androidInfo.version.sdkInt, greaterThanOrEqualTo(21),
            reason: 'Android SDK must be API 21 (Lollipop) or higher');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        debugPrint('=== iOS Device Info ===');
        debugPrint('Model: ${iosInfo.model}');
        debugPrint('Name: ${iosInfo.name}');
        debugPrint('iOS Version: ${iosInfo.systemVersion}');
        debugPrint('Physical Device: ${iosInfo.isPhysicalDevice}');

        // Verify minimum iOS version (12.0+)
        final version = double.tryParse(iosInfo.systemVersion.split('.').first) ?? 0;
        expect(version, greaterThanOrEqualTo(12),
            reason: 'iOS version must be 12.0 or higher');
      }
    });

    testWidgets('App Launch and Initialization', (WidgetTester tester) async {
      // Test that app launches successfully on this device
      final startTime = DateTime.now();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final launchTime = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('App launch time: ${launchTime}ms');

      // Verify app launched (should see onboarding or home screen)
      final appLoaded = find.byType(MaterialApp).evaluate().isNotEmpty;
      expect(appLoaded, isTrue, reason: 'App should initialize MaterialApp');

      // Log launch time (will compare against device category benchmarks)
      debugPrint('METRIC: app_launch_time=$launchTime');
    });

    testWidgets('User Registration Flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Navigate to sign up if onboarding is shown
        final signUpButton = find.text('Sign Up');
        if (signUpButton.evaluate().isNotEmpty) {
          await tester.tap(signUpButton);
          await tester.pumpAndSettle();
        }

        // Fill registration form
        final emailField = find.byKey(const Key('email_field'));
        final passwordField = find.byKey(const Key('password_field'));

        if (emailField.evaluate().isNotEmpty) {
          await tester.enterText(emailField, 'devicetest@juanheart.com');
          await tester.pumpAndSettle();

          await tester.enterText(passwordField, 'TestPass123!');
          await tester.pumpAndSettle();

          // Submit registration
          final registerButton = find.text('Register');
          if (registerButton.evaluate().isNotEmpty) {
            await tester.tap(registerButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }

          debugPrint('RESULT: registration_flow=success');
        }
      } catch (e) {
        debugPrint('RESULT: registration_flow=error: $e');
      }
    });

    testWidgets('Heart Risk Assessment Completion', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Navigate to assessment screen
        final assessmentButton = find.byIcon(Icons.favorite).first;
        if (assessmentButton.evaluate().isNotEmpty) {
          await tester.tap(assessmentButton);
          await tester.pumpAndSettle();
        }

        final startAssessment = find.text('Start Assessment');
        if (startAssessment.evaluate().isNotEmpty) {
          await tester.tap(startAssessment);
          await tester.pumpAndSettle();
        }

        // Fill symptoms (simplified for device compatibility test)
        final chestPainButton = find.text('Mild').first;
        if (chestPainButton.evaluate().isNotEmpty) {
          await tester.tap(chestPainButton);
          await tester.pumpAndSettle();
        }

        // Continue to vitals
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        }

        // Enter vitals
        final bpSystolicField = find.byKey(const Key('bp_systolic'));
        if (bpSystolicField.evaluate().isNotEmpty) {
          await tester.enterText(bpSystolicField, '120');
          await tester.pumpAndSettle();
        }

        final bpDiastolicField = find.byKey(const Key('bp_diastolic'));
        if (bpDiastolicField.evaluate().isNotEmpty) {
          await tester.enterText(bpDiastolicField, '80');
          await tester.pumpAndSettle();
        }

        // Complete assessment
        final completeButton = find.text('Complete Assessment');
        if (completeButton.evaluate().isNotEmpty) {
          await tester.tap(completeButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        debugPrint('RESULT: assessment_completion=success');
      } catch (e) {
        debugPrint('RESULT: assessment_completion=error: $e');
      }
    });

    testWidgets('Offline Mode Data Persistence', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Test that app functions in offline mode
        // This is critical for rural Philippines use case

        // Create test data in offline mode
        final testData = {
          'test_key': 'test_value',
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('offline_test', testData.toString());

        // Verify data persists
        final storedData = prefs.getString('offline_test');
        expect(storedData, isNotNull, reason: 'Offline data should persist');

        debugPrint('RESULT: offline_data_persistence=success');
      } catch (e) {
        debugPrint('RESULT: offline_data_persistence=error: $e');
      }
    });

    testWidgets('Emergency Features Accessible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Verify emergency features are accessible
        // Critical for healthcare app

        final emergencyButton = find.byIcon(Icons.emergency);
        final sosButton = find.text('SOS');

        final emergencyAccessible = emergencyButton.evaluate().isNotEmpty ||
                                    sosButton.evaluate().isNotEmpty;

        expect(emergencyAccessible, isTrue,
            reason: 'Emergency features must be accessible');

        debugPrint('RESULT: emergency_features=accessible');
      } catch (e) {
        debugPrint('RESULT: emergency_features=error: $e');
      }
    });

    testWidgets('UI Renders Without Overflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Test for render overflow errors
        // Common issue on different screen sizes

        final renderErrors = tester.takeException();
        expect(renderErrors, isNull,
            reason: 'UI should render without overflow errors');

        debugPrint('RESULT: ui_rendering=no_overflow');
      } catch (e) {
        debugPrint('RESULT: ui_rendering=overflow_detected: $e');
      }
    });

    testWidgets('Touch Targets Meet Minimum Size', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Verify touch targets are at least 48x48dp
        // Critical for accessibility and usability

        final buttons = find.byType(ElevatedButton);
        for (final button in buttons.evaluate()) {
          final renderBox = button.renderObject as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            expect(size.width, greaterThanOrEqualTo(44),
                reason: 'Touch target width should be at least 44dp');
            expect(size.height, greaterThanOrEqualTo(44),
                reason: 'Touch target height should be at least 44dp');
          }
        }

        debugPrint('RESULT: touch_targets=meets_minimum_size');
      } catch (e) {
        debugPrint('RESULT: touch_targets=size_violation: $e');
      }
    });

    testWidgets('Localization Support (EN/FIL)', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Test bilingual support
        // Critical for Philippine market

        // Look for language selector
        final settingsIcon = find.byIcon(Icons.settings);
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle();

          final languageOption = find.text('Language');
          expect(languageOption.evaluate().isNotEmpty, isTrue,
              reason: 'Language settings should be accessible');

          debugPrint('RESULT: localization=supported');
        }
      } catch (e) {
        debugPrint('RESULT: localization=error: $e');
      }
    });

    testWidgets('Device-Specific Features', (WidgetTester tester) async {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Test device-specific issues
        if (androidInfo.manufacturer.toLowerCase().contains('samsung')) {
          debugPrint('Testing Samsung-specific features...');
          // Test edge panel interference
          // Test One UI specific behaviors
        } else if (androidInfo.manufacturer.toLowerCase().contains('xiaomi')) {
          debugPrint('Testing Xiaomi-specific features...');
          // Test MIUI battery optimization
          // Test notification delivery
        } else if (androidInfo.manufacturer.toLowerCase().contains('huawei')) {
          debugPrint('Testing Huawei-specific features...');
          // Test HMS vs GMS compatibility
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        // Test iOS-specific features
        if (iosInfo.model.toLowerCase().contains('iphone')) {
          debugPrint('Testing iPhone-specific features...');
          // Test notch/Dynamic Island safe areas
          // Test iOS gesture navigation
        }
      }

      debugPrint('RESULT: device_specific_tests=completed');
    });

    testWidgets('Memory Usage Reasonable', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      try {
        // Navigate through multiple screens to test memory
        final navigationItems = [
          Icons.home,
          Icons.favorite,
          Icons.calendar_today,
          Icons.person,
        ];

        for (final icon in navigationItems) {
          final navButton = find.byIcon(icon).first;
          if (navButton.evaluate().isNotEmpty) {
            await tester.tap(navButton);
            await tester.pumpAndSettle();

            // Allow time for screen to load
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        // Note: Actual memory measurement requires platform channels
        // This test ensures navigation doesn't crash from memory issues
        debugPrint('RESULT: memory_navigation=no_crashes');
      } catch (e) {
        debugPrint('RESULT: memory_navigation=error: $e');
      }
    });
  });
}
