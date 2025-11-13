import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:juan_heart/presentation/pages/auth/user_details_screen.dart';
import 'package:juan_heart/presentation/pages/home/health_corner_screen.dart';
import 'package:juan_heart/presentation/pages/home/heart_risk_assessment_screen.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/presentation/pages/home/stroke_emergency_screen.dart';
import 'package:juan_heart/presentation/pages/home/medical_triage_assessment_screen.dart';
import 'package:juan_heart/presentation/pages/home/book_appointment_screen.dart';
import 'package:juan_heart/presentation/pages/referral/next_steps_screen.dart';
import 'package:juan_heart/presentation/pages/referral/facility_list_screen.dart';
import 'package:juan_heart/presentation/pages/referral/referral_summary_screen.dart';
import 'package:juan_heart/presentation/widgets/deferred_loading_indicator.dart';

// Deferred imports for heavy screens (lazy loading)
import 'package:juan_heart/presentation/pages/home/analytics_screen.dart' deferred as analytics;
import 'package:juan_heart/presentation/pages/education/educational_content_list_screen.dart' deferred as education;
import 'package:juan_heart/presentation/pages/education/content_viewer_screen.dart' deferred as content_viewer;

import '../presentation/pages/auth/sign_in_screen.dart';
import '../presentation/pages/auth/sign_up_screen.dart';
import '../presentation/pages/onboarding/onboading.dart';

class AppRoutes {
  static const String splashScreen = '/splash_screen';
  static const String onBoardingScreen = "/on_boading_screen";
  static const String signUpScreen = "/sign_up_screen";
  static const String signInScreen = "/sign_in_screen";
  static const String userDetailsScreen = "/user_details_screen";
  static const String home = "/home";

  static const String strokeEmergencyScreen = "/stroke_emergency_screen";
  static const String heartRiskAssessmentScreen = "/heart_risk_assessment_screen";
  static const String healthCornerScreen = "/health_corner_screen";
  static const String analyticsScreen = "/analytics_screen";
  static const String medicalTriageAssessmentScreen = "/medical_triage_assessment_screen";
  static const String bookAppointmentScreen = "/book_appointment_screen";

  // Referral & Care Navigation System routes
  static const String nextStepsScreen = "/next_steps_screen";
  static const String facilityListScreen = "/facility_list_screen";
  static const String referralSummaryScreen = "/referral_summary_screen";

  // Educational Content routes
  static const String educationalContentListScreen = "/educational_content_list_screen";
  static const String educationalContentViewerScreen = "/educational-content-viewer";

  static GetPage homePage = GetPage(
    name: home,
    page: () => const Home(),
    transition: Transition.cupertino,
  );

  static GetPage onBoardingPage = GetPage(
    name: onBoardingScreen,
    page: () => const OnBoardingScreen(),
  );

  static GetPage signUpPage = GetPage(
    name: signUpScreen,
    page: () => SignUpScreen(),
    transition: Transition.leftToRight,
  );

  static GetPage signInPage = GetPage(
    name: signInScreen,
    page: () => const SignInScreen(),
    transition: Transition.rightToLeft,
  );

  static GetPage userDetailsPage = GetPage(
    name: userDetailsScreen,
    page: () => const UserDetailsScreen(),
    transition: Transition.leftToRight,
  );

  static GetPage stokeEmergencyPage = GetPage(
    name: strokeEmergencyScreen,
    page: () => const StrokeEmergencyScreen(),
    transition: Transition.cupertino,
  );

  static GetPage heartRiskAssessmentPage = GetPage(
    name: heartRiskAssessmentScreen,
    page: () => const HeartRiskAssessmentScreen(),
    transition: Transition.cupertino,
  );

  static GetPage healthCornerPage = GetPage(
    name: healthCornerScreen,
    page: () => const HealthCornerScreen(),
    transition: Transition.cupertino,
  );

  static GetPage analyticsPage = GetPage(
    name: analyticsScreen,
    page: () => _DeferredAnalyticsScreen(),
    transition: Transition.cupertino,
  );

  static GetPage medicalTriageAssessmentPage = GetPage(
    name: medicalTriageAssessmentScreen,
    page: () => const MedicalTriageAssessmentScreen(),
    transition: Transition.cupertino,
  );

  static GetPage bookAppointmentPage = GetPage(
    name: bookAppointmentScreen,
    page: () => const BookAppointmentScreen(),
    transition: Transition.cupertino,
  );

  // Referral & Care Navigation System pages
  static GetPage nextStepsPage = GetPage(
    name: nextStepsScreen,
    page: () {
      final args = Get.arguments as Map<String, dynamic>;
      return NextStepsScreen(
        recommendation: args['recommendation'],
        assessmentData: args['assessmentData'],
      );
    },
    transition: Transition.cupertino,
  );
  
  static GetPage facilityListPage = GetPage(
    name: facilityListScreen,
    page: () => const FacilityListScreen(),
    transition: Transition.cupertino,
  );
  
  static GetPage referralSummaryPage = GetPage(
    name: referralSummaryScreen,
    page: () => const ReferralSummaryScreen(),
    transition: Transition.cupertino,
  );

  // Educational Content pages
  static GetPage educationalContentListPage = GetPage(
    name: educationalContentListScreen,
    page: () => _DeferredEducationalContentListScreen(),
    transition: Transition.cupertino,
  );

  static GetPage educationalContentViewerPage = GetPage(
    name: educationalContentViewerScreen,
    page: () => _DeferredContentViewerScreen(),
    transition: Transition.cupertino,
  );
}

// Deferred wrapper widgets for lazy-loaded screens

/// Lazy-loaded Analytics Screen (3,973 lines)
class _DeferredAnalyticsScreen extends StatefulWidget {
  const _DeferredAnalyticsScreen();

  @override
  State<_DeferredAnalyticsScreen> createState() => _DeferredAnalyticsScreenState();
}

class _DeferredAnalyticsScreenState extends State<_DeferredAnalyticsScreen> {
  Future<void>? _loadLibrary;

  @override
  void initState() {
    super.initState();
    _loadLibrary = analytics.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadLibrary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return DeferredLoadingError(
              errorMessage: 'Failed to load Analytics screen',
              onRetry: () {
                setState(() {
                  _loadLibrary = analytics.loadLibrary();
                });
              },
            );
          }
          return analytics.AnalyticsScreen();
        }
        return const DeferredLoadingIndicator(
          message: 'Loading Analytics...',
        );
      },
    );
  }
}

/// Lazy-loaded Educational Content List Screen (583 lines)
class _DeferredEducationalContentListScreen extends StatefulWidget {
  const _DeferredEducationalContentListScreen();

  @override
  State<_DeferredEducationalContentListScreen> createState() =>
      _DeferredEducationalContentListScreenState();
}

class _DeferredEducationalContentListScreenState
    extends State<_DeferredEducationalContentListScreen> {
  Future<void>? _loadLibrary;

  @override
  void initState() {
    super.initState();
    _loadLibrary = education.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadLibrary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return DeferredLoadingError(
              errorMessage: 'Failed to load Educational Content',
              onRetry: () {
                setState(() {
                  _loadLibrary = education.loadLibrary();
                });
              },
            );
          }
          return education.EducationalContentListScreen();
        }
        return const DeferredLoadingIndicator(
          message: 'Loading Health Corner...',
        );
      },
    );
  }
}

/// Lazy-loaded Content Viewer Screen
class _DeferredContentViewerScreen extends StatefulWidget {
  const _DeferredContentViewerScreen();

  @override
  State<_DeferredContentViewerScreen> createState() =>
      _DeferredContentViewerScreenState();
}

class _DeferredContentViewerScreenState extends State<_DeferredContentViewerScreen> {
  Future<void>? _loadLibrary;

  @override
  void initState() {
    super.initState();
    _loadLibrary = content_viewer.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadLibrary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return DeferredLoadingError(
              errorMessage: 'Failed to load content viewer',
              onRetry: () {
                setState(() {
                  _loadLibrary = content_viewer.loadLibrary();
                });
              },
            );
          }
          return content_viewer.ContentViewerScreen();
        }
        return const DeferredLoadingIndicator(
          message: 'Loading content...',
        );
      },
    );
  }
}
