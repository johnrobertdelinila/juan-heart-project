import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/core/constants/enums.dart';
import 'package:juan_heart/core/constants/api_constants.dart';
import 'package:juan_heart/core/constants/sync_error_types.dart';
import 'package:juan_heart/helper/local_string.dart';
import 'package:juan_heart/helper/lang_controller.dart';
import 'package:juan_heart/presentation/pages/home/home.dart';
import 'package:juan_heart/presentation/pages/onboarding/onboading.dart';
import 'package:juan_heart/repository/auth_repo/auth_repository.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'package:juan_heart/models/educational_content.dart';
import 'package:juan_heart/models/content_category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/services/appointment_notification_service.dart';
import 'package:juan_heart/services/sync_initialization_service.dart';
import 'package:juan_heart/services/migration_service.dart';
import 'package:juan_heart/services/feature_flag_service.dart';
import 'package:juan_heart/services/push_notification_service.dart';
import 'package:juan_heart/services/deep_link_service.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/services/background_sync_service.dart';
import 'package:juan_heart/services/sync_queue_service.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/services/appointment_sync_service.dart';
import 'package:juan_heart/services/educational_content_service.dart';
import 'package:juan_heart/services/api/educational_content_api_service.dart';
import 'package:juan_heart/services/educational_content_sync_worker.dart';
import 'package:juan_heart/services/assessment_sync_service.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:juan_heart/services/performance_service.dart';
import 'package:juan_heart/services/image_cache_service.dart';
import 'package:juan_heart/themes/jh_font_config.dart';

import './routes/app_routes.dart';

/// Register sync executors for all operation types
///
/// This function registers callback executors that will handle different
/// types of sync operations from the sync queue.
Future<void> _registerSyncExecutors() async {
  final syncQueue = SyncQueueService();

  // Register appointment sync executor
  syncQueue.registerExecutor(
    SyncOperationType.syncAppointment,
    (operation) async {
      debugPrint('[SyncExecutor] Executing syncAppointment: ${operation.id}');

      // Parse appointment data from operation
      final appointment = Appointment.fromJson(operation.data);

      // Sync to backend
      final result = await AppointmentSyncService.syncAppointmentToBackend(appointment);

      if (result['success'] == true) {
        // Update local appointment with backend ID and sync status
        await AppointmentService.updateSyncStatus(
          appointmentId: appointment.id,
          syncStatus: 'synced',
          backendId: result['backendId'] as int?,
        );

        debugPrint('[SyncExecutor] ✅ Appointment synced: ${appointment.id}');
      } else {
        // Update sync status to failed
        await AppointmentService.updateSyncStatus(
          appointmentId: appointment.id,
          syncStatus: 'failed',
          syncErrorMessage: result['message'] as String?,
        );

        throw Exception(result['message'] ?? 'Sync failed');
      }

      return result;
    },
  );

  // Register appointment update executor
  syncQueue.registerExecutor(
    SyncOperationType.updateAppointment,
    (operation) async {
      debugPrint('[SyncExecutor] Executing updateAppointment: ${operation.id}');

      final backendId = operation.data['backendId'] as int?;
      final newStatus = AppointmentStatus.values.firstWhere(
        (e) => e.toString() == operation.data['status'],
        orElse: () => AppointmentStatus.pending,
      );

      if (backendId == null) {
        throw Exception('Backend ID required for update');
      }

      final result = await AppointmentSyncService.updateAppointmentStatus(
        backendId: backendId,
        newStatus: newStatus,
        reason: operation.data['reason'] as String?,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Update failed');
      }

      debugPrint('[SyncExecutor] ✅ Appointment updated: ${operation.id}');
      return result;
    },
  );

  // Register appointment cancellation executor
  syncQueue.registerExecutor(
    SyncOperationType.cancelAppointment,
    (operation) async {
      debugPrint('[SyncExecutor] Executing cancelAppointment: ${operation.id}');

      final backendId = operation.data['backendId'] as int?;
      final reason = operation.data['reason'] as String? ?? 'Cancelled by user';

      if (backendId == null) {
        throw Exception('Backend ID required for cancellation');
      }

      final result = await AppointmentSyncService.cancelAppointmentOnBackend(
        backendId: backendId,
        reason: reason,
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Cancellation failed');
      }

      debugPrint('[SyncExecutor] ✅ Appointment cancelled: ${operation.id}');
      return result;
    },
  );

  // Register assessment sync executor
  syncQueue.registerExecutor(
    SyncOperationType.syncAssessment,
    (operation) async {
      debugPrint('[SyncExecutor] Executing syncAssessment: ${operation.id}');

      try {
        // 1. Convert operation data to AssessmentRecord
        final assessmentData = operation.data;
        final record = AssessmentRecord.fromJson(assessmentData);

        debugPrint('[SyncExecutor] Assessment Record: ${record.id}');
        debugPrint('[SyncExecutor] Risk: ${record.riskCategory} (${record.finalRiskScore})');

        // 2. Call AssessmentSyncService to sync to backend
        final result = await AssessmentSyncService.syncAssessmentToBackend(record);

        // 3. Update local database on success
        if (result['success'] == true) {
          final db = AppDatabase();
          await db.updateAssessment(
            AssessmentsCompanion(
              id: drift.Value(record.id),
              isSynced: drift.Value(true),
              syncedAt: drift.Value(DateTime.now()),
              syncError: drift.Value(null),
            ),
          );

          debugPrint('[SyncExecutor] ✅ Assessment synced and marked in DB: ${record.id}');
        } else {
          // Classify error type for better handling
          final errorMessage = result['message'] as String? ?? 'Unknown error';
          final errorType = SyncErrorClassifier.fromErrorMessage(errorMessage);

          debugPrint('[SyncExecutor] ❌ Assessment sync failed: $errorMessage');
          debugPrint('[SyncExecutor] Error type: ${errorType.name}');

          // Store classified error for user review
          final db = AppDatabase();
          await db.updateAssessment(
            AssessmentsCompanion(
              id: drift.Value(record.id),
              syncError: drift.Value('${errorType.title}: ${errorType.message}'),
            ),
          );

          // Handle specific error types
          if (errorType == SyncErrorType.authentication) {
            debugPrint('[SyncExecutor] 🔐 Authentication error - user may need to re-login');
            // TODO: Trigger re-authentication flow
          } else if (errorType == SyncErrorType.validation) {
            debugPrint('[SyncExecutor] ⚠️ Validation error - check assessment data');
            // Extract validation details if available
            final errorData = result['error'];
            if (errorData != null && errorData is Map<String, dynamic>) {
              final validationErrors = SyncErrorClassifier.extractValidationErrors(errorData);
              if (validationErrors != null) {
                debugPrint('[SyncExecutor] Validation errors: $validationErrors');
              }
            }
          }

          // If max retries exceeded, this will be handled by SyncQueueService
          // and notification will be triggered from there
        }

        return result;
      } catch (e, stackTrace) {
        debugPrint('[SyncExecutor] ❌ Exception syncing assessment: $e');
        debugPrint('[SyncExecutor] Stack trace: $stackTrace');

        // Classify exception for better error handling
        final errorType = e is Exception
            ? SyncErrorClassifier.fromException(e)
            : SyncErrorClassifier.fromErrorMessage(e.toString());

        debugPrint('[SyncExecutor] Exception type: ${errorType.name}');

        // Store classified error in database
        try {
          final assessmentId = operation.data['id'] as String?;
          if (assessmentId != null) {
            final db = AppDatabase();
            await db.updateAssessment(
              AssessmentsCompanion(
                id: drift.Value(assessmentId),
                syncError: drift.Value('${errorType.title}: ${errorType.message}'),
              ),
            );
          }
        } catch (dbError) {
          debugPrint('[SyncExecutor] ⚠️ Could not update error in DB: $dbError');
        }

        return {
          'success': false,
          'message': errorType.message,
          'errorType': errorType.name,
        };
      }
    },
  );

  // Register assessment data fetchers for conflict detection
  syncQueue.registerDataFetchers(
    type: SyncOperationType.syncAssessment,

    // Server fetcher: Fetch from backend by assessment ID
    serverFetcher: (String assessmentId) async {
      try {
        final url = Uri.parse('${APIConstant.baseUrl}${APIConstant.assessmentsEndpoint}/$assessmentId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['data'] as Map<String, dynamic>?;
        } else if (response.statusCode == 404) {
          // Not found on server (new assessment)
          return null;
        } else {
          debugPrint('⚠️ Server fetch failed: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        debugPrint('❌ Error fetching from server: $e');
        return null;
      }
    },

    // Local fetcher: Query Drift database
    localFetcher: (String assessmentId) async {
      try {
        final db = AppDatabase();
        final assessment = await db.getAssessmentById(assessmentId);

        if (assessment == null) return null;

        return {
          'id': assessment.id,
          'user_id': assessment.userId,
          'final_risk_score': assessment.finalRiskScore,
          'risk_category': assessment.riskCategory,
          'created_at': assessment.createdAt.toIso8601String(),
          'updated_at': assessment.updatedAt?.toIso8601String(),
          'is_synced': assessment.isSynced,
        };
      } catch (e) {
        debugPrint('❌ Error fetching from local DB: $e');
        return null;
      }
    },
  );

  debugPrint('📋 Registered sync executors: 4 operation types');
  debugPrint('✅ Assessment sync executors and data fetchers registered');
}

/// Memory pressure observer that handles low memory warnings
/// Clears image cache and performs cleanup when memory is low
class _MemoryPressureObserver extends WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('⚠️ Memory pressure detected');

    try {
      // Clear image cache to free up memory
      ImageCacheService().handleMemoryPressure();

      // Log memory statistics
      ImageCacheService().logCacheStats();
    } catch (e) {
      debugPrint('Error handling memory pressure: $e');
    }
  }
}

/// Convert language code to Locale for GetX
///
/// Maps language codes (en, fil, tl, etc.) to proper Locale objects
/// Defaults to English (en_US) if language code is not recognized
Locale _getLocaleFromLanguageCode(String languageCode) {
  switch (languageCode.toLowerCase()) {
    case 'en':
      return const Locale('en', 'US');
    case 'fil':
    case 'tl':
      return const Locale('tl', 'PH'); // Filipino/Tagalog
    case 'hi':
      return const Locale('hi', 'IN'); // Hindi
    case 'ta':
      return const Locale('ta', 'IN'); // Tamil
    case 'te':
      return const Locale('te', 'IN'); // Telugu
    case 'mr':
      return const Locale('mr', 'IN'); // Marathi
    default:
      return const Locale('en', 'US'); // Default to English
  }
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts to prevent flash of unstyled text (FOUT)
  try {
    await JHFontConfig.preloadFonts();
    debugPrint('✅ Fonts preloaded successfully');
  } catch (e) {
    debugPrint('⚠️ Font preloading failed: $e');
    // Continue app startup even if font preloading fails
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file not found, continue without it
    debugPrint("No .env file found, continuing without environment variables");
  }

  // Initialize Hive for offline data storage
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // Register Hive type adapters
    Hive.registerAdapter(NotificationCategoryAdapter());
    Hive.registerAdapter(NotificationModelAdapter());
    Hive.registerAdapter(ContentCategoryAdapter());
    Hive.registerAdapter(EducationalContentAdapter());

    debugPrint('✅ Hive initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Hive initialization failed: $e');
    // Continue app startup even if Hive fails
  }

  // Initialize language preference from SharedPreferences
  try {
    final savedLanguage = await LangController.getSavedLanguagePreference();
    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      // Set GetX locale based on saved preference
      final locale = _getLocaleFromLanguageCode(savedLanguage);
      Get.updateLocale(locale);
      debugPrint('✅ Language preference loaded: $savedLanguage');
    } else {
      debugPrint('ℹ️  No saved language preference, using device locale');
    }
  } catch (e) {
    debugPrint('⚠️ Language preference loading failed: $e');
    // Continue with device locale if preference loading fails
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Initialize Firebase Performance Monitoring
    try {
      final performance = FirebasePerformance.instance;

      // Enable performance monitoring collection (respects user privacy settings)
      await performance.setPerformanceCollectionEnabled(true);

      debugPrint('✅ Firebase Performance Monitoring initialized');

      // Initialize PerformanceService wrapper
      await PerformanceService.instance.initialize();
      debugPrint('✅ PerformanceService wrapper initialized');
    } catch (performanceError) {
      debugPrint('⚠️ Firebase Performance initialization failed: $performanceError');
      // Continue without performance monitoring (graceful degradation)
    }

    // Initialize Firebase Crashlytics
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Enable Crashlytics collection
      await crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set up Flutter framework error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        // Log to console for debugging
        FlutterError.presentError(details);

        // Send to Crashlytics
        crashlytics.recordFlutterFatalError(details);

        debugPrint('⚠️ Flutter error recorded to Crashlytics: ${details.exception}');
      };

      // Set up platform dispatcher error handler for async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        crashlytics.recordError(error, stack, fatal: true);
        debugPrint('⚠️ Platform error recorded to Crashlytics: $error');
        return true;
      };

      debugPrint('✅ Firebase Crashlytics initialized');
      debugPrint('   - Flutter error handler configured');
      debugPrint('   - Platform error handler configured');
    } catch (crashlyticsError) {
      debugPrint('⚠️ Firebase Crashlytics initialization failed: $crashlyticsError');
      // Continue without crash reporting (graceful degradation)
    }
  } catch (e) {
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue app startup even if Firebase fails
  }

  // Initialize Image Cache Service
  try {
    ImageCacheService();
    debugPrint('✅ Image Cache Service initialized');
  } catch (e) {
    debugPrint('⚠️ Image Cache Service initialization failed: $e');
    // Continue app startup even if image cache fails
  }

  // Add memory pressure observer
  WidgetsBinding.instance.addObserver(_MemoryPressureObserver());

  // =====================================================================
  // CRITICAL: CHECK NOTIFICATION LAUNCH BEFORE INITIALIZING SERVICES
  // =====================================================================
  String? initialRoute;
  Map<String, dynamic>? initialArguments;

  // 1. Check for local notification launch (appointment reminders, follow-ups)
  // Must check BEFORE calling AppointmentNotificationService().initialize()
  try {
    final appointmentNotificationService = AppointmentNotificationService();
    final localNotificationLaunch = await appointmentNotificationService.getNotificationLaunchDetails();

    if (localNotificationLaunch != null) {
      initialRoute = localNotificationLaunch['route'] as String?;
      initialArguments = localNotificationLaunch['arguments'] as Map<String, dynamic>?;
      debugPrint('✅ Local notification cold-start detected');
      debugPrint('   Route: $initialRoute');
      debugPrint('   Arguments: $initialArguments');
    }
  } catch (e) {
    debugPrint('⚠️ Error checking local notification launch: $e');
  }

  // 2. Check for Firebase push notification launch (if no local notification)
  if (initialRoute == null) {
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        debugPrint('🔔 App launched from PUSH notification');
        debugPrint('   Message ID: ${initialMessage.messageId}');
        debugPrint('   Data: ${initialMessage.data}');

        final notificationType = initialMessage.data['type'] as String?;
        final screen = initialMessage.data['screen'] as String?;

        if (notificationType == 'followUp' && screen == 'reassessment') {
          initialRoute = AppRoutes.heartRiskAssessmentScreen;
          initialArguments = {
            'isFollowUp': true,
            'appointmentId': initialMessage.data['appointmentId'],
          };
          debugPrint('   → Routing to Heart Risk Assessment (follow-up)');
        } else if (screen != null) {
          initialRoute = AppRoutes.home;
          initialArguments = initialMessage.data;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error checking Firebase initial message: $e');
    }
  }

  if (initialRoute == null) {
    debugPrint('ℹ️ Normal app launch (no notification)');
  }
  // =====================================================================

  // Initialize DeepLinkService (must be before PushNotificationService)
  try {
    final deepLinkService = Get.put(DeepLinkService());
    await deepLinkService.initialize();
    debugPrint('✅ DeepLinkService initialized');
  } catch (e) {
    debugPrint('⚠️ DeepLinkService initialization failed: $e');
  }

  // Initialize NotificationService (must be after Hive and before push notifications)
  try {
    await NotificationService.instance.initialize();
    debugPrint('✅ NotificationService initialized');
  } catch (e) {
    debugPrint('⚠️ NotificationService initialization failed: $e');
  }

  // Initialize push notification service
  try {
    await PushNotificationService.instance.initialize();
    debugPrint('✅ Push notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Push notification service initialization failed: $e');
  }

  // Initialize local notification service
  // NOTE: This MUST come after getNotificationAppLaunchDetails() check above
  try {
    await AppointmentNotificationService().initialize();
    debugPrint('✅ Local notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Local notification service initialization failed: $e');
  }

  // Initialize educational content service with backend API (NON-BLOCKING)
  // This initialization must not block app startup to prevent white screen on iOS
  _initializeEducationalContentAsync();

  // Initialize sync queue service
  try {
    await SyncQueueService().initialize();
    debugPrint('✅ SyncQueueService initialized');
  } catch (e) {
    debugPrint('⚠️ SyncQueueService initialization failed: $e');
  }

  // Register sync executors BEFORE initializing background sync
  try {
    await _registerSyncExecutors();
    debugPrint('✅ Sync executors registered');
  } catch (e) {
    debugPrint('⚠️ Failed to register sync executors: $e');
  }

  // Initialize background sync service
  try {
    await BackgroundSyncService.instance.initialize();
    await BackgroundSyncService.instance.enableBackgroundSync();
    debugPrint('✅ Background sync initialized and enabled');
  } catch (e) {
    debugPrint('⚠️ Background sync initialization failed: $e');
    // App continues without background sync (graceful degradation)
  }

  // Initialize sync infrastructure
  try {
    debugPrint('🚀 Initializing sync infrastructure...');
    await SyncInitializationService.initialize();
    debugPrint('✅ Sync infrastructure ready');
  } catch (e) {
    debugPrint("⚠️ Failed to initialize sync infrastructure: $e");
    // Continue app startup even if sync fails
  }

  // Run data migration in background
  _runMigrationInBackground();

  // Start app cold start trace (tracks time from app launch to first frame)
  final coldStartTrace = await PerformanceService.instance.startAppStartTrace();

  // NOTE: Cold-start notification detection already happened earlier
  // (lines 263-337) BEFORE notification services were initialized

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then(
    (_) {
      runApp(
        MyApp(
          initialRoute: initialRoute,
          initialArguments: initialArguments,
        ),
      );

      // Stop cold start trace after first frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceService.instance.stopAppStartTrace(coldStartTrace);
      });
    },
  );
}

/// Initialize educational content service in background without blocking app startup.
/// This prevents iOS white screen issue caused by HTTP connection timeout.
void _initializeEducationalContentAsync() {
  Future.delayed(Duration.zero, () async {
    try {
      // Get backend API URL from environment (with fallback to localhost)
      final apiUrl = dotenv.env['EDUCATIONAL_CONTENT_API_URL'] ??
                     'http://localhost:8000/api/v1/mobile';

      debugPrint('📚 [Background] Initializing Educational Content with API: $apiUrl');

      // Create API service with 5-second timeout (short timeout for non-blocking init)
      final contentApiService = EducationalContentApiService(
        baseUrl: apiUrl,
        maxRetries: 2, // Reduced retries for faster failure
        timeout: 5,    // 5-second timeout instead of 30 seconds
      );

      // Initialize service with backend API enabled
      await EducationalContentService.instance.initialize(
        apiService: contentApiService,
        useBackendApi: true, // Backend API mode enabled
      );

      // Initialize sync worker for weekly automatic sync
      await EducationalContentSyncWorker.instance.initialize(
        enableWeeklySync: true, // Automatic sync every Sunday 2 AM
      );

      debugPrint('✅ [Background] Educational content service initialized with backend API');
      debugPrint('✅ [Background] Sync worker initialized (weekly auto-sync enabled)');
    } catch (e) {
      debugPrint('⚠️ [Background] Educational content service initialization failed: $e');
      debugPrint('⚠️ [Background] Falling back to offline mode with hardcoded content');

      // Initialize in offline mode as fallback
      try {
        await EducationalContentService.instance.initialize(
          apiService: null,
          useBackendApi: false, // Offline mode
        );
        debugPrint('✅ [Background] Educational content initialized in offline mode');
      } catch (fallbackError) {
        debugPrint('❌ [Background] Even offline initialization failed: $fallbackError');
      }
    }
  });
}

/// Run data migration in background without blocking app startup.
void _runMigrationInBackground() {
  Future.delayed(const Duration(seconds: 2), () async {
    try {
      debugPrint('🔄 Starting background migration...');
      final result = await MigrationService.migrateAppointments();

      if (result.success && !result.alreadyMigrated) {
        debugPrint('✅ Migration completed: ${result.queuedForSync} appointments queued');
      } else if (result.alreadyMigrated) {
        debugPrint('ℹ️ Migration already completed previously');
      } else {
        debugPrint('❌ Migration failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('❌ Background migration error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  final String? initialRoute;
  final Map<String, dynamic>? initialArguments;

  const MyApp({
    super.key,
    this.initialRoute,
    this.initialArguments,
  });

  Future<Widget> _getInitialScreen() async {
    // If app was launched from notification, skip authentication checks
    // and navigate directly to the notification target screen
    if (initialRoute != null) {
      debugPrint('📱 Using notification initial route: $initialRoute');
      debugPrint('   Arguments: $initialArguments');

      // Navigate to the notification target after a brief delay
      // This ensures GetX routing is fully initialized
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.toNamed(initialRoute!, arguments: initialArguments);
      });

      // Show a loading screen momentarily while navigation is set up
      return const Home();
    }

    // Check for pending notification navigation (iOS callback-based)
    // On iOS, notification taps might register AFTER initialization starts
    Future.delayed(const Duration(milliseconds: 500), () {
      final notificationService = AppointmentNotificationService();
      if (notificationService.processPendingNavigation()) {
        debugPrint('✅ Processed pending notification navigation');
      }
    });

    // Normal app startup flow (no notification launch)
    try {
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
    } catch (e) {
      debugPrint('Error loading initial screen: $e');
      // Fallback to onboarding screen on error
      return const OnBoardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuTheme(
      data: PopupMenuThemeData(
        textStyle: TextStyle(
          color: JHColors.midnightBlue,
        ),
        color: JHColors.cloudWhite,
      ),
      child: RepositoryProvider(
        create: (context) => AuthRepository(),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Get.deviceLocale,
          translations: LocalString(),
          title: 'Juan Heart',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme(
              brightness: Brightness.light,
              primary: JHColors.heartRed,
              onPrimary: JHColors.cloudWhite,
              primaryContainer: JHColors.heartRedLight,
              onPrimaryContainer: JHColors.heartRedDark,
              secondary: JHColors.midnightBlue,
              onSecondary: JHColors.cloudWhite,
              secondaryContainer: JHColors.slate100,
              onSecondaryContainer: JHColors.slate700,
              tertiary: JHColors.info,
              onTertiary: JHColors.cloudWhite,
              tertiaryContainer: JHColors.infoLight,
              onTertiaryContainer: JHColors.infoDark,
              error: JHColors.danger,
              onError: JHColors.cloudWhite,
              errorContainer: JHColors.dangerLight,
              onErrorContainer: JHColors.dangerDark,
              background: JHColors.softGray,
              onBackground: JHColors.slate900,
              surface: JHColors.cloudWhite,
              onSurface: JHColors.midnightBlue,
              surfaceTint: JHColors.cloudWhite,
              surfaceVariant: JHColors.slate100,
              onSurfaceVariant: JHColors.slate700,
              outline: JHColors.slate300,
              outlineVariant: JHColors.slate200,
              inverseSurface: JHColors.midnightBlue,
              onInverseSurface: JHColors.cloudWhite,
              inversePrimary: JHColors.heartRedDark,
              shadow: JHColors.slate900,
              scrim: JHColors.slate900,
            ),
            scaffoldBackgroundColor: JHColors.softGray,
            textTheme: GoogleFonts.interTextTheme(),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: JHColors.midnightBlue,
              contentTextStyle: GoogleFonts.inter(
                color: JHColors.cloudWhite,
              ),
            ),
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
            AppRoutes.medicalTriageAssessmentPage,
            AppRoutes.healthCornerPage,
            AppRoutes.analyticsPage,
            AppRoutes.bookAppointmentPage,
            // Referral & Care Navigation System routes
            AppRoutes.nextStepsPage,
            AppRoutes.facilityListPage,
            AppRoutes.referralSummaryPage,
            // Educational Content routes
            AppRoutes.educationalContentListPage,
            AppRoutes.educationalContentViewerPage,
          ],
        ),
      ),
    );
  }
}
