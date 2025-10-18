import 'package:get/get.dart';
import 'package:juan_heart/presentation/pages/auth/user_details_screen.dart';
import 'package:juan_heart/presentation/pages/home/health_corner_screen.dart';
import 'package:juan_heart/presentation/pages/home/heart_risk_assessment_screen.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/presentation/pages/home/stroke_emergency_screen.dart';

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
    page: () => SignInScreen(),
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
}
