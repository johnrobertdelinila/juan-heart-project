import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:juan_heart/models/appointment_model.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class AppointmentNotificationService {
  static final AppointmentNotificationService _instance =
      AppointmentNotificationService._internal();

  factory AppointmentNotificationService() => _instance;

  AppointmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Uuid _uuid = const Uuid();

  bool _initialized = false;

  // Pending notification navigation (for cold-start on iOS)
  // When app is launched from notification, the tap callback fires AFTER
  // the app is initialized. We store the route here and navigate after init.
  String? _pendingRoute;
  Map<String, dynamic>? _pendingArguments;

  /// Check if app was launched by tapping a notification (cold-start)
  ///
  /// MUST be called BEFORE initialize() to get launch details.
  /// Returns a map with 'route' and 'arguments' if launched from notification.
  Future<Map<String, dynamic>?> getNotificationLaunchDetails() async {
    try {
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();

      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails!.notificationResponse?.payload;

        debugPrint('🔔 [AppointmentNotificationService] App launched from notification');
        debugPrint('   Payload: $payload');

        if (payload != null && payload.startsWith('followUp:')) {
          final appointmentId = payload.replaceFirst('followUp:', '');
          debugPrint('   → Follow-up notification for appointment: $appointmentId');

          return {
            'route': AppRoutes.heartRiskAssessmentScreen,
            'arguments': {
              'isFollowUp': true,
              'appointmentId': appointmentId,
            },
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting notification launch details: $e');
      return null;
    }
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Initialize with settings
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request iOS permissions
    await _requestIOSPermissions();

    // Create Android notification channel
    await _createAndroidNotificationChannel();

    _initialized = true;
  }

  /// Request iOS notification permissions
  Future<void> _requestIOSPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Create Android notification channel
  Future<void> _createAndroidNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'appointment_reminders', // id
      'Appointment Reminders', // name
      description:
          'Notifications for upcoming medical appointments', // description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle notification tap
  ///
  /// On iOS, this callback fires AFTER app initialization even for cold-starts.
  /// We try immediate navigation, but if GetX isn't ready, we queue it for later.
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;

      debugPrint('📲 Notification tapped: $payload');

      if (payload != null && payload.startsWith('followUp:')) {
        final appointmentId = payload.replaceFirst('followUp:', '');

        debugPrint('   → Follow-up notification for: $appointmentId');
        debugPrint('   → Attempting navigation...');

        // Try immediate navigation
        try {
          Get.toNamed(AppRoutes.heartRiskAssessmentScreen, arguments: {
            'isFollowUp': true,
            'appointmentId': appointmentId,
          });
          debugPrint('   ✅ Navigation successful');
        } catch (e) {
          // GetX not ready yet (cold-start) - queue for later
          debugPrint('   ⏳ GetX not ready, queuing navigation...');
          _pendingRoute = AppRoutes.heartRiskAssessmentScreen;
          _pendingArguments = {
            'isFollowUp': true,
            'appointmentId': appointmentId,
          };
        }
      } else {
        // Other notification types - navigate to home
        try {
          Get.toNamed(AppRoutes.home);
        } catch (e) {
          _pendingRoute = AppRoutes.home;
          _pendingArguments = null;
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
      _pendingRoute = AppRoutes.home;
      _pendingArguments = null;
    }
  }

  /// Check if there's a pending navigation from notification tap
  ///
  /// Call this after GetX is initialized to process queued notification taps.
  /// Returns true if navigation was performed.
  bool processPendingNavigation() {
    if (_pendingRoute != null) {
      debugPrint('🔄 Processing pending notification navigation');
      debugPrint('   Route: $_pendingRoute');
      debugPrint('   Arguments: $_pendingArguments');

      try {
        Get.toNamed(_pendingRoute!, arguments: _pendingArguments);
        _pendingRoute = null;
        _pendingArguments = null;
        debugPrint('   ✅ Pending navigation completed');
        return true;
      } catch (e) {
        debugPrint('   ❌ Failed to navigate: $e');
        return false;
      }
    }
    return false;
  }

  /// Schedule notifications for an appointment
  /// Creates three notifications: 24 hours before, 1 hour before, and 7-day follow-up
  Future<void> scheduleAppointmentReminders(Appointment appointment) async {
    if (!_initialized) {
      await initialize();
    }

    // Parse appointment time (format: "10:00 AM" or "02:30 PM")
    final timeParts = appointment.appointmentTime.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPM = timeParts[1].toUpperCase() == 'PM';

    // Convert to 24-hour format
    if (isPM && hour != 12) {
      hour += 12;
    } else if (!isPM && hour == 12) {
      hour = 0;
    }

    final appointmentDateTime = DateTime(
      appointment.appointmentDate.year,
      appointment.appointmentDate.month,
      appointment.appointmentDate.day,
      hour,
      minute,
    );

    // Get language preference
    final isFilipino = Get.locale?.languageCode == 'fil';

    // Schedule 24-hour reminder (if appointment is more than 24 hours away)
    final twentyFourHoursBefore =
        appointmentDateTime.subtract(const Duration(hours: 24));
    if (twentyFourHoursBefore.isAfter(DateTime.now())) {
      final title = isFilipino
          ? 'Paalala: Appointment Bukas'
          : 'Reminder: Appointment Tomorrow';
      final body = isFilipino
          ? 'May appointment ka bukas sa ${appointment.facilityName} sa ${appointment.appointmentTime}'
          : 'You have an appointment tomorrow at ${appointment.facilityName} at ${appointment.appointmentTime}';

      await _scheduleNotification(
        id: _generate24HourNotificationId(appointment.id),
        title: title,
        body: body,
        scheduledDate: twentyFourHoursBefore,
        payload: appointment.id,
      );

      // Save to notification repository for inbox
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          await notificationService.showAppointmentNotification(
            title: title,
            body: body,
            appointmentId: appointment.id,
            additionalData: {
              'facilityName': appointment.facilityName,
              'appointmentTime': appointment.appointmentTime,
              'reminderType': '24hour',
            },
          );
        }
      } catch (e) {
        debugPrint('Error saving appointment notification: $e');
      }
    }

    // Schedule 1-hour reminder (if appointment is more than 1 hour away)
    final oneHourBefore = appointmentDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      final title = isFilipino
          ? 'Paalala: Appointment sa 1 Oras'
          : 'Reminder: Appointment in 1 Hour';
      final body = isFilipino
          ? 'Ang iyong appointment sa ${appointment.facilityName} ay magsisimula sa ${appointment.appointmentTime}'
          : 'Your appointment at ${appointment.facilityName} starts at ${appointment.appointmentTime}';

      await _scheduleNotification(
        id: _generate1HourNotificationId(appointment.id),
        title: title,
        body: body,
        scheduledDate: oneHourBefore,
        payload: appointment.id,
      );

      // Save to notification repository for inbox
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          await notificationService.showAppointmentNotification(
            title: title,
            body: body,
            appointmentId: appointment.id,
            additionalData: {
              'facilityName': appointment.facilityName,
              'appointmentTime': appointment.appointmentTime,
              'reminderType': '1hour',
            },
          );
        }
      } catch (e) {
        debugPrint('Error saving appointment notification: $e');
      }
    }

    // Schedule 7-day follow-up reminder
    await scheduleFollowUpReminder(appointment);
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for upcoming medical appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel all notifications for an appointment
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    await _notificationsPlugin.cancel(_generate24HourNotificationId(appointmentId));
    await _notificationsPlugin.cancel(_generate1HourNotificationId(appointmentId));
    await cancelFollowUpReminder(appointmentId);
  }

  /// Reschedule notifications for an appointment
  /// First cancels existing notifications, then schedules new ones
  Future<void> rescheduleAppointmentReminders(Appointment appointment) async {
    await cancelAppointmentReminders(appointment.id);
    await scheduleAppointmentReminders(appointment);
  }

  /// Schedules a 7-day follow-up reminder after appointment completion
  ///
  /// Sends a notification asking "How are you feeling?" and prompts user
  /// to take a reassessment or provide feedback about their visit.
  ///
  /// Parameters:
  ///   - appointment: The completed appointment
  ///
  /// Notification fires at 10:00 AM local time on the 7th day after appointment
  Future<void> scheduleFollowUpReminder(Appointment appointment) async {
    try {
      // Skip follow-up for cancelled or no-show appointments
      if (appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.noShow) {
        debugPrint('⏭️ Skipping follow-up for ${appointment.status} appointment: ${appointment.id}');
        return;
      }

      // Calculate follow-up date (7 days after appointment)
      final followUpDate = appointment.appointmentDate.add(const Duration(days: 7));

      // Set time to 10:00 AM on follow-up date
      final followUpTime = tz.TZDateTime(
        tz.local,
        followUpDate.year,
        followUpDate.month,
        followUpDate.day,
        10, // 10:00 AM
        0,
      );

      // Only schedule if followUpTime is in the future
      if (followUpTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⏭️ Skipping follow-up reminder (date in past): ${appointment.id}');
        return;
      }

      // Get language preference
      final isFilipino = Get.locale?.languageCode == 'fil';

      final title = isFilipino
          ? 'Follow-up: Paano ka na?'
          : 'Follow-up: How are you feeling?';

      final body = isFilipino
          ? 'Nakarating ka na ba sa ${appointment.facilityName}? Gusto naming malaman kung paano ka ngayon. Mag-assessment ulit para sa iyong kalusugan.'
          : 'Did you visit ${appointment.facilityName}? We\'d like to know how you\'re doing. Take a quick health assessment to track your progress.';

      // Schedule local notification
      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: 'Reminders for upcoming appointments and follow-ups',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        _getFollowUpNotificationId(appointment.id),
        title,
        body,
        followUpTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'followUp:${appointment.id}',
      );

      // Save to NotificationService repository for inbox
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          await notificationService.showNotification(
            NotificationModel.followUp(
              id: _uuid.v4(),
              title: title,
              body: body,
              payload: {
                'appointmentId': appointment.id,
                'facilityName': appointment.facilityName,
                'originalDate': appointment.appointmentDate.toIso8601String(),
                'type': 'followUp',
                'screen': 'reassessment',
              },
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving follow-up notification to repository: $e');
      }

      debugPrint('✅ Scheduled 7-day follow-up reminder for appointment ${appointment.id}');
    } catch (e) {
      debugPrint('❌ Error scheduling follow-up reminder: $e');
    }
  }

  /// Cancels the 7-day follow-up reminder for an appointment
  ///
  /// Call this when:
  /// - Appointment is cancelled
  /// - User manually dismisses follow-up
  /// - Appointment is rescheduled (new follow-up will be scheduled)
  Future<void> cancelFollowUpReminder(String appointmentId) async {
    try {
      await _notificationsPlugin.cancel(_getFollowUpNotificationId(appointmentId));
      debugPrint('✅ Cancelled follow-up reminder for appointment $appointmentId');
    } catch (e) {
      debugPrint('❌ Error cancelling follow-up reminder: $e');
    }
  }

  /// FOR TESTING ONLY: Schedules follow-up notification in 10 seconds
  ///
  /// Use this method to test the follow-up notification flow without
  /// waiting 7 days. Not for production use.
  Future<void> testFollowUpReminderImmediately(Appointment appointment) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

      // Get language preference
      final isFilipino = Get.locale?.languageCode == 'fil';

      final title = isFilipino
          ? 'TEST: Follow-up Reminder'
          : 'TEST: Follow-up Reminder';

      final body = isFilipino
          ? 'Ito ay test follow-up notification para sa ${appointment.facilityName}'
          : 'This is a test follow-up notification for ${appointment.facilityName}';

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: 'Reminders for upcoming appointments and follow-ups',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        _getFollowUpNotificationId(appointment.id),
        title,
        body,
        testTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'followUp:${appointment.id}',
      );

      debugPrint('🧪 TEST: Follow-up reminder scheduled for 10 seconds from now');
      debugPrint('   Appointment: ${appointment.id}');
      debugPrint('   Facility: ${appointment.facilityName}');
      debugPrint('   Will fire at: $testTime');
    } catch (e) {
      debugPrint('❌ Error scheduling test follow-up reminder: $e');
    }
  }

  /// Reschedules follow-up reminder based on appointment completion date
  ///
  /// This method is called when an appointment is marked as completed.
  /// It cancels the existing follow-up (scheduled at booking time) and
  /// reschedules a new one based on the actual completion date.
  ///
  /// Hybrid approach:
  /// - Follow-up initially scheduled at booking time (7 days after appointment date)
  /// - When marked as completed, reschedule based on completion time (now + 7 days)
  ///
  /// Parameters:
  ///   - appointment: The completed appointment
  ///
  /// Notification fires at 10:00 AM local time on the 7th day after completion
  Future<void> rescheduleFollowUpOnCompletion(Appointment appointment) async {
    try {
      // Cancel existing follow-up (scheduled at booking time)
      await cancelFollowUpReminder(appointment.id);

      // Calculate follow-up date (7 days from now)
      final completionDate = DateTime.now();
      final followUpDate = completionDate.add(const Duration(days: 7));

      // Set time to 10:00 AM on follow-up date
      final followUpTime = tz.TZDateTime(
        tz.local,
        followUpDate.year,
        followUpDate.month,
        followUpDate.day,
        10, // 10:00 AM
        0,
      );

      // Only schedule if followUpTime is in the future
      if (followUpTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⏭️ Skipping follow-up reminder (date in past): ${appointment.id}');
        return;
      }

      // Get language preference
      final isFilipino = Get.locale?.languageCode == 'fil';

      final title = isFilipino
          ? 'Follow-up: Paano ka na?'
          : 'Follow-up: How are you feeling?';

      final body = isFilipino
          ? 'Nakarating ka na ba sa ${appointment.facilityName}? Gusto naming malaman kung paano ka ngayon. Mag-assessment ulit para sa iyong kalusugan.'
          : 'Did you visit ${appointment.facilityName}? We\'d like to know how you\'re doing. Take a quick health assessment to track your progress.';

      // Schedule local notification
      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: 'Reminders for upcoming appointments and follow-ups',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        _getFollowUpNotificationId(appointment.id),
        title,
        body,
        followUpTime,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'followUp:${appointment.id}',
      );

      // Save to NotificationService repository for inbox
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          await notificationService.showNotification(
            NotificationModel.followUp(
              id: _uuid.v4(),
              title: title,
              body: body,
              payload: {
                'appointmentId': appointment.id,
                'facilityName': appointment.facilityName,
                'completionDate': completionDate.toIso8601String(),
                'type': 'followUp',
                'screen': 'reassessment',
              },
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving follow-up notification to repository: $e');
      }

      debugPrint('✅ Rescheduled 7-day follow-up based on completion date for appointment ${appointment.id}');
      debugPrint('   Original appointment date: ${appointment.appointmentDate}');
      debugPrint('   Completion date: $completionDate');
      debugPrint('   New follow-up date: $followUpDate');
    } catch (e) {
      debugPrint('❌ Error rescheduling follow-up reminder: $e');
    }
  }

  /// Generate a unique notification ID for 24-hour reminder
  int _generate24HourNotificationId(String appointmentId) {
    return appointmentId.hashCode;
  }

  /// Generate a unique notification ID for 1-hour reminder
  int _generate1HourNotificationId(String appointmentId) {
    return appointmentId.hashCode + 1;
  }

  /// Generates unique notification ID for 7-day follow-up reminder
  ///
  /// Uses appointment ID hash + offset to avoid collisions with
  /// 24-hour and 1-hour reminder IDs
  int _getFollowUpNotificationId(String appointmentId) {
    final baseId = appointmentId.hashCode;
    return (baseId + 200).abs() % 2147483647; // Offset by 200 for follow-ups
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Show an immediate notification (for testing purposes)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'appointment_reminders',
      'Appointment Reminders',
      channelDescription: 'Notifications for upcoming medical appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
