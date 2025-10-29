import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/core/constants/enums.dart';
import 'package:juan_heart/helper/local_string.dart';
import 'package:juan_heart/presentation/pages/auth/sign_in_screen.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/presentation/pages/onboarding/onboading.dart';
import 'package:juan_heart/repository/auth_repo/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/appointment_notification_service.dart';
import 'package:juan_heart/services/sync_initialization_service.dart';
import 'package:juan_heart/services/migration_service.dart';
import 'package:juan_heart/services/feature_flag_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './routes/app_routes.dart';

Future main() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, continue without it
    print("No .env file found, continuing without environment variables");
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    // Continue app startup even if Firebase fails
  }

  // Initialize notification service
  try {
    await AppointmentNotificationService().initialize();
  } catch (e) {
    print("Failed to initialize notification service: $e");
  }

  // Initialize sync infrastructure
  try {
    print('🚀 Initializing sync infrastructure...');
    await SyncInitializationService.initialize();
    print('✅ Sync infrastructure ready');
  } catch (e) {
    print("⚠️ Failed to initialize sync infrastructure: $e");
    // Continue app startup even if sync fails
  }

  // Enable AI assessment for testing
  try {
    print('🤖 Enabling AI assessment for testing...');
    await FeatureFlagService.enableAIAssessmentForTesting();
    print('✅ AI assessment enabled (100% rollout)');
  } catch (e) {
    print("⚠️ Failed to enable AI assessment: $e");
  }

  // Run data migration in background
  _runMigrationInBackground();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then(
    (_) {
      runApp(
        const MyApp(),
      );
    },
  );
}

/// Run data migration in background without blocking app startup.
void _runMigrationInBackground() {
  Future.delayed(Duration(seconds: 2), () async {
    try {
      print('🔄 Starting background migration...');
      final result = await MigrationService.migrateAppointments();

      if (result.success && !result.alreadyMigrated) {
        print('✅ Migration completed: ${result.queuedForSync} appointments queued');
      } else if (result.alreadyMigrated) {
        print('ℹ️ Migration already completed previously');
      } else {
        print('❌ Migration failed: ${result.error}');
      }
    } catch (e) {
      print('❌ Background migration error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAuthenticated =
        prefs.getBool(AuthState.authenticated.toString()) ?? false;

    if (isAuthenticated) {
      return const Home();
    } else {
      final bool isNewUser =
          prefs.getBool(AuthState.unknown.toString()) ?? true;

      if (isNewUser) {
        return const OnBoardingScreen();
      } else {
        // Temporarily bypass login screen - go directly to home
        return const Home();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuTheme(
      data: PopupMenuThemeData(
        textStyle: TextStyle(
          color: ColorConstant.bluedark,
        ),
        color: ColorConstant.whiteBackground,
      ),
      child: RepositoryProvider(
        create: (context) => AuthRepository(),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Get.deviceLocale,
          translations: LocalString(),
          title: 'Juan Heart',
          theme: ThemeData(
            primaryColor: Colors.white,
          ),
          initialRoute: "/",
          getPages: [
            GetPage(
              name: "/",
              page: () => FutureBuilder<Widget>(
                  future: _getInitialScreen(),
                  builder:
                      (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    } else {
                      // For showing splash screen during loading
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  }),
            ),
            AppRoutes.homePage,
            AppRoutes.onBoardingPage,
            AppRoutes.signInPage,
            AppRoutes.signUpPage,
            AppRoutes.userDetailsPage,
            AppRoutes.stokeEmergencyPage,
            AppRoutes.heartRiskAssessmentPage,
            AppRoutes.healthCornerPage,
            AppRoutes.bookAppointmentPage,
            // Referral & Care Navigation System routes
            AppRoutes.nextStepsPage,
            AppRoutes.facilityListPage,
            AppRoutes.referralSummaryPage,
          ],
        ),
      ),
    );
  }
}
