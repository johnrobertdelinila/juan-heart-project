import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:juan_heart/presentation/widgets/deferred_loading_indicator.dart';

/// Tests for lazy loading implementation
/// Verifies that deferred imports are properly configured
void main() {
  group('Lazy Loading Routes', () {
    setUp(() {
      // Initialize GetX
      Get.testMode = true;
    });

    testWidgets('DeferredLoadingIndicator displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeferredLoadingIndicator(
            message: 'Loading...',
          ),
        ),
      );

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('DeferredLoadingIndicator without logo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeferredLoadingIndicator(
            message: 'Loading...',
            showLogo: false,
          ),
        ),
      );

      // Verify loading indicator is shown without logo
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('DeferredLoadingError displays correctly', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeferredLoadingError(
            errorMessage: 'Test error',
            onRetry: () {
              retryPressed = true;
            },
          ),
        ),
      );

      // Verify error UI is shown
      expect(find.text('Failed to Load Screen'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('DeferredLoadingError without retry', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DeferredLoadingError(
            errorMessage: 'Test error',
          ),
        ),
      );

      // Verify error UI is shown without retry button
      expect(find.text('Failed to Load Screen'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    test('Analytics route is configured', () {
      expect(AppRoutes.analyticsScreen, equals('/analytics_screen'));
      expect(AppRoutes.analyticsPage, isNotNull);
      expect(AppRoutes.analyticsPage.name, equals('/analytics_screen'));
    });

    test('Educational Content routes are configured', () {
      expect(AppRoutes.educationalContentListScreen,
          equals('/educational_content_list_screen'));
      expect(AppRoutes.educationalContentListPage, isNotNull);
      expect(AppRoutes.educationalContentListPage.name,
          equals('/educational_content_list_screen'));

      expect(AppRoutes.educationalContentViewerScreen,
          equals('/educational-content-viewer'));
      expect(AppRoutes.educationalContentViewerPage, isNotNull);
      expect(AppRoutes.educationalContentViewerPage.name,
          equals('/educational-content-viewer'));
    });

    test('All lazy-loaded routes have proper configuration', () {
      final lazyLoadedRoutes = [
        AppRoutes.analyticsPage,
        AppRoutes.educationalContentListPage,
        AppRoutes.educationalContentViewerPage,
      ];

      for (final route in lazyLoadedRoutes) {
        expect(route.name, isNotEmpty);
        expect(route.page, isNotNull);
        expect(route.transition, equals(Transition.cupertino));
      }
    });
  });

  group('Route Configuration', () {
    test('All routes are accessible', () {
      expect(AppRoutes.splashScreen, isNotEmpty);
      expect(AppRoutes.onBoardingScreen, isNotEmpty);
      expect(AppRoutes.signUpScreen, isNotEmpty);
      expect(AppRoutes.signInScreen, isNotEmpty);
      expect(AppRoutes.userDetailsScreen, isNotEmpty);
      expect(AppRoutes.home, isNotEmpty);
      expect(AppRoutes.strokeEmergencyScreen, isNotEmpty);
      expect(AppRoutes.heartRiskAssessmentScreen, isNotEmpty);
      expect(AppRoutes.healthCornerScreen, isNotEmpty);
      expect(AppRoutes.analyticsScreen, isNotEmpty);
      expect(AppRoutes.medicalTriageAssessmentScreen, isNotEmpty);
      expect(AppRoutes.bookAppointmentScreen, isNotEmpty);
      expect(AppRoutes.nextStepsScreen, isNotEmpty);
      expect(AppRoutes.facilityListScreen, isNotEmpty);
      expect(AppRoutes.referralSummaryScreen, isNotEmpty);
      expect(AppRoutes.educationalContentListScreen, isNotEmpty);
      expect(AppRoutes.educationalContentViewerScreen, isNotEmpty);
    });

    test('All GetPage instances are valid', () {
      final pages = [
        AppRoutes.homePage,
        AppRoutes.onBoardingPage,
        AppRoutes.signUpPage,
        AppRoutes.signInPage,
        AppRoutes.userDetailsPage,
        AppRoutes.stokeEmergencyPage,
        AppRoutes.heartRiskAssessmentPage,
        AppRoutes.healthCornerPage,
        AppRoutes.analyticsPage,
        AppRoutes.medicalTriageAssessmentPage,
        AppRoutes.bookAppointmentPage,
        AppRoutes.nextStepsPage,
        AppRoutes.facilityListPage,
        AppRoutes.referralSummaryPage,
        AppRoutes.educationalContentListPage,
        AppRoutes.educationalContentViewerPage,
      ];

      for (final page in pages) {
        expect(page.name, isNotEmpty, reason: 'Page name should not be empty');
        expect(page.page, isNotNull, reason: 'Page builder should not be null');
      }
    });
  });
}
