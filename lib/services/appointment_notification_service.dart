import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:juan_heart/models/appointment_model.dart';
import 'package:get/get.dart';

class AppointmentNotificationService {
  static final AppointmentNotificationService _instance =
      AppointmentNotificationService._internal();

  factory AppointmentNotificationService() => _instance;

  AppointmentNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

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
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to appointments screen when notification is tapped
    Get.toNamed('/home'); // This will open the home screen
    // The user can then navigate to the appointments tab
  }

  /// Schedule notifications for an appointment
  /// Creates two notifications: 24 hours before and 1 hour before
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
      await _scheduleNotification(
        id: _generate24HourNotificationId(appointment.id),
        title: isFilipino
            ? 'Paalala: Appointment Bukas'
            : 'Reminder: Appointment Tomorrow',
        body: isFilipino
            ? 'May appointment ka bukas sa ${appointment.facilityName} sa ${appointment.appointmentTime}'
            : 'You have an appointment tomorrow at ${appointment.facilityName} at ${appointment.appointmentTime}',
        scheduledDate: twentyFourHoursBefore,
        payload: appointment.id,
      );
    }

    // Schedule 1-hour reminder (if appointment is more than 1 hour away)
    final oneHourBefore = appointmentDateTime.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(DateTime.now())) {
      await _scheduleNotification(
        id: _generate1HourNotificationId(appointment.id),
        title: isFilipino
            ? 'Paalala: Appointment sa 1 Oras'
            : 'Reminder: Appointment in 1 Hour',
        body: isFilipino
            ? 'Ang iyong appointment sa ${appointment.facilityName} ay magsisimula sa ${appointment.appointmentTime}'
            : 'Your appointment at ${appointment.facilityName} starts at ${appointment.appointmentTime}',
        scheduledDate: oneHourBefore,
        payload: appointment.id,
      );
    }
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
  }

  /// Reschedule notifications for an appointment
  /// First cancels existing notifications, then schedules new ones
  Future<void> rescheduleAppointmentReminders(Appointment appointment) async {
    await cancelAppointmentReminders(appointment.id);
    await scheduleAppointmentReminders(appointment);
  }

  /// Generate a unique notification ID for 24-hour reminder
  int _generate24HourNotificationId(String appointmentId) {
    return appointmentId.hashCode;
  }

  /// Generate a unique notification ID for 1-hour reminder
  int _generate1HourNotificationId(String appointmentId) {
    return appointmentId.hashCode + 1;
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
