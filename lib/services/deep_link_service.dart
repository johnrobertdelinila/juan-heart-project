import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/models/assessment_history_model.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'package:juan_heart/presentation/pages/analytics/assessment_details_screen.dart';
import 'package:juan_heart/presentation/pages/home/appointment_details_screen.dart';
import 'package:juan_heart/services/analytics_service.dart';
import 'package:juan_heart/services/appointment_service.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:uni_links/uni_links.dart';

/// Deep link service for handling notification navigation and custom schemes.
/// Routes users to appropriate screens based on notification payload or URI.
/// Supports app states: foreground, background, and terminated.
class DeepLinkService extends GetxService {
  static DeepLinkService get instance => Get.find<DeepLinkService>();

  static const String _scheme = 'juanheart';
  static const String _host = 'app';

  StreamSubscription<Uri?>? _linkSubscription;
  bool _isInitialized = false;

  /// Initialize URI listeners for platform deep links.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        await _handleUri(initialUri, source: 'initial_link');
      }

      _linkSubscription = uriLinkStream.listen(
        (uri) async {
          if (uri != null) {
            await _handleUri(uri, source: 'uri_stream');
          }
        },
        onError: (err) {
          debugPrint('DeepLinkService stream error: $err');
        },
      );

      _isInitialized = true;
      debugPrint('DeepLinkService initialized');
    } catch (e) {
      debugPrint('Error initializing DeepLinkService: $e');
    }
  }

  /// Handle simple deep link string (e.g., "juanheart://app/appointments/123").
  Future<void> handleDeepLink(String deepLink) async {
    try {
      debugPrint('DeepLinkService: Handling deep link: $deepLink');
      final normalized = _normalizeDeepLink(deepLink);
      await _handleUri(Uri.parse(normalized), source: 'manual_link');
    } catch (e) {
      debugPrint('Error handling deep link: $e');
      await _navigateToHome();
    }
  }

  /// Handle notification navigation based on payload data.
  ///
  /// Payload format:
  /// {
  ///   "type": "assessment|appointment|healthAlert|followUp|system",
  ///   "screen": "target_screen_route",
  ///   "data": {"appointmentId": "...", ...}
  /// }
  Future<void> handleNotificationNavigation(Map<String, dynamic> data) async {
    try {
      debugPrint('DeepLinkService: Handling notification navigation');
      final typeString = data['type'] as String?;
      final screen = data['screen'] as String?;
      final additionalData = data['data'] as Map<String, dynamic>? ?? data;

      if (typeString == null) {
        debugPrint('No notification type specified, navigating to home');
        await _navigateToHome();
        return;
      }

      final category = NotificationCategoryExtension.fromString(typeString);

      switch (category) {
        case NotificationCategory.assessment:
          await _handleAssessmentNavigation(screen, additionalData);
          break;
        case NotificationCategory.appointment:
          await _handleAppointmentNavigation(screen, additionalData);
          break;
        case NotificationCategory.healthAlert:
          await _handleHealthAlertNavigation(screen, additionalData);
          break;
        case NotificationCategory.followUp:
          await _handleFollowUpNavigation(screen, additionalData);
          break;
        case NotificationCategory.system:
          await _handleSystemNavigation(screen, additionalData);
          break;
        default:
          await _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error handling notification navigation: $e');
      await _navigateToHome();
    }
  }

  /// Handle assessment-related notifications or deep links.
  Future<void> _handleAssessmentNavigation(
    String? screen,
    Map<String, dynamic>? data,
  ) async {
    try {
      final assessmentId = data?['assessmentId'] as String?;

      if (assessmentId != null) {
        await _openAssessmentById(assessmentId);
        return;
      }

      if (screen == 'heart_risk_assessment') {
        await Get.toNamed(AppRoutes.heartRiskAssessmentScreen, arguments: data);
      } else if (screen == 'medical_triage') {
        await Get.toNamed(AppRoutes.medicalTriageAssessmentScreen);
      } else if (screen == 'assessment_results') {
        await _navigateToAnalyticsTab();
      } else {
        await Get.toNamed(AppRoutes.heartRiskAssessmentScreen);
      }
    } catch (e) {
      debugPrint('Error in assessment navigation: $e');
      await _navigateToHome();
    }
  }

  /// Handle appointment-related notifications or deep links.
  Future<void> _handleAppointmentNavigation(
    String? screen,
    Map<String, dynamic>? data,
  ) async {
    try {
      final appointmentId = data?['appointmentId'] as String?;

      if (appointmentId != null) {
        await _openAppointmentById(appointmentId);
        return;
      }

      if (screen == 'book_appointment') {
        await Get.toNamed(AppRoutes.bookAppointmentScreen);
      } else {
        await _navigateToAppointmentsTab();
      }
    } catch (e) {
      debugPrint('Error in appointment navigation: $e');
      await _navigateToHome();
    }
  }

  /// Handle health alert notifications.
  Future<void> _handleHealthAlertNavigation(
    String? screen,
    Map<String, dynamic>? data,
  ) async {
    try {
      final alertType = data?['alertType'] as String?;

      if (screen == 'stroke_emergency' || screen == 'emergency_services') {
        await Get.toNamed('/stokeEmergency');
      } else if (alertType == 'high_risk') {
        await _navigateToAnalyticsTab(showRiskWarning: true);
      } else if (screen == 'facility_referral') {
        await Get.toNamed(AppRoutes.facilityListScreen, arguments: data);
      } else {
        await _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error in health alert navigation: $e');
      await _navigateToHome();
    }
  }

  /// Handle follow-up notifications.
  Future<void> _handleFollowUpNavigation(
    String? screen,
    Map<String, dynamic>? data,
  ) async {
    try {
      final followUpType = data?['followUpType'] as String?;

      if (screen == 'reassessment') {
        await Get.toNamed(AppRoutes.heartRiskAssessmentScreen, arguments: {
          'isFollowUp': true,
          ...?data,
        });
      } else if (screen == 'appointment_booking') {
        await Get.toNamed(AppRoutes.bookAppointmentScreen, arguments: data);
      } else if (followUpType == 'post_appointment') {
        await _navigateToAppointmentsTab(showFollowUpDialog: true);
      } else {
        await _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error in follow-up navigation: $e');
      await _navigateToHome();
    }
  }

  /// Handle system notifications.
  Future<void> _handleSystemNavigation(
    String? screen,
    Map<String, dynamic>? data,
  ) async {
    try {
      if (screen == 'notifications') {
        await _navigateToHome(openNotifications: true);
      } else if (screen == 'profile') {
        await _navigateToHome(initialTab: 3);
      } else if (screen == 'settings') {
        await _navigateToHome();
      } else if (screen == 'health_corner') {
        await Get.toNamed('/healthCorner');
      } else {
        await _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error in system navigation: $e');
      await _navigateToHome();
    }
  }

  /// Normalize arbitrary deep link strings into full URIs.
  String _normalizeDeepLink(String link) {
    if (link.startsWith('$_scheme://')) {
      return link;
    }

    if (link.startsWith('http://') || link.startsWith('https://')) {
      return link;
    }

    final sanitized = link.startsWith('/') ? link.substring(1) : link;
    return '$_scheme://$_host/$sanitized';
  }

  /// Handle parsed URI from platform or notifications.
  Future<void> _handleUri(Uri uri, {required String source}) async {
    try {
      debugPrint('DeepLinkService: $_scheme handler [$source] -> $uri');

      if (uri.scheme.isNotEmpty && uri.scheme != _scheme) {
        debugPrint('Unsupported scheme ${uri.scheme}, navigating home');
        await _navigateToHome();
        return;
      }

      final segments = _resolveSegments(uri);
      if (segments.isEmpty) {
        await _navigateToHome();
        return;
      }

      switch (segments.first) {
        case 'appointments':
          final appointmentId =
              _extractIdentifier(segments, uri.queryParameters, 'appointmentId');
          if (appointmentId != null) {
            await _openAppointmentById(appointmentId);
          } else {
            await _navigateToAppointmentsTab();
          }
          break;
        case 'assessments':
          final assessmentId =
              _extractIdentifier(segments, uri.queryParameters, 'assessmentId');
          if (assessmentId != null) {
            await _openAssessmentById(assessmentId);
          } else {
            await _navigateToAnalyticsTab();
          }
          break;
        case 'reassessment':
          await Get.toNamed(AppRoutes.heartRiskAssessmentScreen);
          break;
        case 'home':
          await _navigateToHome();
          break;
        default:
          await _navigateToHome();
      }
    } catch (e) {
      debugPrint('Error handling URI: $e');
      await _navigateToHome();
    }
  }

  /// Resolve segments regardless of host/path arrangement.
  List<String> _resolveSegments(Uri uri) {
    final segments = <String>[];

    if (uri.host.isNotEmpty && uri.host != _host) {
      segments.add(uri.host);
      segments.addAll(uri.pathSegments);
    } else {
      segments.addAll(uri.pathSegments);
    }

    if (segments.isEmpty && uri.queryParameters.containsKey('screen')) {
      segments.add(uri.queryParameters['screen']!);
    }

    return segments;
  }

  /// Extract identifier from path segments or query parameters.
  String? _extractIdentifier(
    List<String> segments,
    Map<String, String> query,
    String queryKey,
  ) {
    if (segments.length >= 2) {
      return segments[1];
    }
    return query[queryKey];
  }

  /// Navigate to Home route with optional arguments.
  Future<void> _navigateToHome({
    int? initialTab,
    bool openNotifications = false,
  }) async {
    try {
      await Get.toNamed(AppRoutes.home, arguments: {
        if (initialTab != null) 'initialTab': initialTab,
        if (openNotifications) 'openNotifications': true,
      });
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      await Get.offAllNamed('/');
    }
  }

  Future<void> _navigateToAppointmentsTab({
    bool showFollowUpDialog = false,
  }) async {
    await _navigateToHome(
      initialTab: 2,
    );
    if (showFollowUpDialog) {
      Get.snackbar(
        'Follow-up Reminder',
        'Please review your appointment follow-up tasks.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _navigateToAnalyticsTab({bool showRiskWarning = false}) async {
    await _navigateToHome(initialTab: 1);
    if (showRiskWarning) {
      Get.snackbar(
        'Risk Alert',
        'Latest assessment indicates elevated risk. Please review.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _openAppointmentById(String appointmentId) async {
    try {
      final appointment =
          await AppointmentService.getAppointmentById(appointmentId);

      if (appointment == null) {
        _showNotFoundMessage(
          title: 'Appointment Not Found',
          message: 'We could not find appointment $appointmentId.',
        );
        await _navigateToAppointmentsTab();
        return;
      }

      await Get.to(() => AppointmentDetailsScreen(appointment: appointment));
    } catch (e) {
      debugPrint('Error opening appointment: $e');
      await _navigateToAppointmentsTab();
    }
  }

  Future<void> _openAssessmentById(String assessmentId) async {
    try {
      final record =
          await AnalyticsService.getAssessmentById(assessmentId);

      if (record == null) {
        _showNotFoundMessage(
          title: 'Assessment Not Found',
          message: 'We could not find assessment $assessmentId.',
        );
        await _navigateToAnalyticsTab();
        return;
      }

      await Get.to(() => AssessmentDetailsScreen(record: record));
    } catch (e) {
      debugPrint('Error opening assessment: $e');
      await _navigateToAnalyticsTab();
    }
  }

  void _showNotFoundMessage({
    required String title,
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  /// Parse JSON string payload to Map.
  Map<String, dynamic>? parsePayload(String? payloadString) {
    if (payloadString == null || payloadString.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(payloadString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing payload: $e');
      return null;
    }
  }

  /// Build notification payload for sending.
  Map<String, dynamic> buildNotificationPayload({
    required NotificationCategory category,
    required String screen,
    Map<String, dynamic>? data,
  }) {
    return {
      'type': category.value,
      'screen': screen,
      'data': data ?? {},
    };
  }

  /// Validate notification payload structure.
  bool isValidPayload(Map<String, dynamic> payload) {
    try {
      if (!payload.containsKey('type')) {
        debugPrint('Invalid payload: missing type');
        return false;
      }

      final typeString = payload['type'] as String?;
      if (typeString == null || typeString.isEmpty) {
        debugPrint('Invalid payload: invalid type');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error validating payload: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
