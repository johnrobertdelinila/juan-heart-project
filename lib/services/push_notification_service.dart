import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:get/get.dart';
import 'package:juan_heart/services/deep_link_service.dart';

/// Background message handler for Firebase Cloud Messaging.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
}

/// Push notification service for Juan Heart Mobile.
/// Handles Firebase Cloud Messaging (FCM) integration for remote notifications.
/// Singleton pattern ensures single instance throughout app lifecycle.
class PushNotificationService {
  static final PushNotificationService instance =
      PushNotificationService._internal();

  factory PushNotificationService() => instance;

  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Key for storing FCM token in SharedPreferences
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenTimestampKey = 'fcm_token_timestamp';

  /// Initialize push notification service.
  /// Should be called early in app lifecycle, after Firebase initialization.
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('PushNotificationService already initialized');
      return;
    }

    try {
      // Request notification permissions
      await requestPermission();

      // Initialize local notifications for displaying foreground messages
      await _initializeLocalNotifications();

      // Setup background message handler
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler
      );

      // Setup message handlers
      setupMessageHandlers();

      // Get and store FCM token
      await getFCMToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed: ${_maskToken(newToken)}');
        _fcmToken = newToken;
        storeFCMToken(newToken);
      });

      _initialized = true;
      debugPrint('PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher'
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channels
      await _createAndroidChannels();
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
      rethrow;
    }
  }

  /// Create Android notification channels for different categories
  Future<void> _createAndroidChannels() async {
    try {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) return;

      // High importance channel for critical notifications
      const highChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Critical health alerts and emergency notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Default channel for standard notifications
      const defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'Appointment reminders and general updates',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(highChannel);
      await androidPlugin.createNotificationChannel(defaultChannel);
    } catch (e) {
      debugPrint('Error creating Android channels: $e');
    }
  }

  /// Request notification permissions from user.
  /// Required for both Android 13+ and iOS.
  Future<bool> requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final authorized = settings.authorizationStatus ==
          AuthorizationStatus.authorized;
      final provisional = settings.authorizationStatus ==
          AuthorizationStatus.provisional;

      if (authorized || provisional) {
        debugPrint('User granted notification permission');
        return true;
      } else {
        debugPrint('User declined notification permission');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get Firebase Cloud Messaging token.
  /// Returns null if token cannot be obtained.
  Future<String?> getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        debugPrint('FCM Token obtained: ${_maskToken(_fcmToken!)}');
        await storeFCMToken(_fcmToken!);
      } else {
        debugPrint('Failed to obtain FCM token');
      }

      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Refresh FCM token.
  /// Call this if token needs to be regenerated.
  Future<String?> refreshFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await getFCMToken();
    } catch (e) {
      debugPrint('Error refreshing FCM token: $e');
      return null;
    }
  }

  /// Store FCM token in SharedPreferences with timestamp.
  Future<void> storeFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setInt(
        _fcmTokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch
      );
      debugPrint('FCM token stored successfully');
    } catch (e) {
      debugPrint('Error storing FCM token: $e');
    }
  }

  /// Get stored FCM token from SharedPreferences.
  Future<String?> getStoredFCMToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('Error retrieving stored FCM token: $e');
      return null;
    }
  }

  /// Setup message handlers for different app states.
  void setupMessageHandlers() {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_handleForegroundMessage(message)),
      );

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => unawaited(_handleBackgroundMessage(message)),
      );

      // Handle notification tap when app was terminated
      _handleTerminatedMessage();
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  /// Handle messages received while app is in foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Foreground message received: ${message.messageId}');

      final notification = message.notification;
      final data = message.data;

      // Save notification to repository via NotificationService
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          final payload = {
            'id': message.messageId ?? DateTime.now().toString(),
            'title': notification?.title ?? 'Juan Heart',
            'body': notification?.body ?? '',
            ...data,
          };
          await notificationService.handleIncomingNotification(payload);
        }
      } catch (e) {
        debugPrint('Error saving notification to repository: $e');
      }

      if (notification != null) {
        // Display local notification for foreground messages
        await _showLocalNotification(
          title: notification.title ?? 'Juan Heart',
          body: notification.body ?? '',
          payload: jsonEncode(data),
          category: _getCategoryFromData(data),
        );
      }
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  /// Handle messages when app is opened from background.
  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      debugPrint('Background message opened: ${message.messageId}');

      // Save notification to repository
      try {
        final notificationService = NotificationService.instance;
        if (notificationService.isInitialized) {
          final notification = message.notification;
          final data = message.data;
          final payload = {
            'id': message.messageId ?? DateTime.now().toString(),
            'title': notification?.title ?? 'Juan Heart',
            'body': notification?.body ?? '',
            ...data,
          };
          await notificationService.handleIncomingNotification(payload);
        }
      } catch (e) {
        debugPrint('Error saving background notification: $e');
      }

      await handleMessage(message);
    } catch (e) {
      debugPrint('Error handling background message: $e');
    }
  }

  /// Handle messages when app is opened from terminated state.
  ///
  /// NOTE: As of the cold-start navigation fix, initial message handling
  /// is now done in main.dart BEFORE runApp() to ensure proper routing.
  /// This method is kept for backwards compatibility but no longer performs
  /// navigation for terminated state messages.
  Future<void> _handleTerminatedMessage() async {
    try {
      final message = await _firebaseMessaging.getInitialMessage();

      if (message != null) {
        debugPrint('Terminated message detected: ${message.messageId}');
        debugPrint('   → Navigation already handled in main.dart cold-start detection');
        // No need to handle navigation here - main.dart handles it before app builds
        // This prevents race conditions and ensures proper initial routing
      }
    } catch (e) {
      debugPrint('Error checking terminated message: $e');
    }
  }

  /// Display local notification for foreground messages.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
    NotificationCategory category = NotificationCategory.system,
  }) async {
    try {
      // Determine channel based on category
      final channelId = category == NotificationCategory.healthAlert
          ? 'high_importance_channel'
          : 'default_channel';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'high_importance_channel'
            ? 'High Importance Notifications'
            : 'Default Notifications',
        channelDescription: 'Push notifications from Juan Heart',
        importance: category == NotificationCategory.healthAlert
            ? Importance.high
            : Importance.defaultImportance,
        priority: category == NotificationCategory.healthAlert
            ? Priority.high
            : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: category.color,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle notification message and route to appropriate screen.
  /// This method is called by DeepLinkService for navigation.
  Future<void> handleMessage(RemoteMessage message) async {
    try {
      final data = message.data;

      if (data.isEmpty) {
        debugPrint('No data in message, skipping navigation');
        return;
      }

      debugPrint('Handling message data: $data');

      if (!Get.isRegistered<DeepLinkService>()) {
        debugPrint('DeepLinkService not registered yet');
        await Get.toNamed('/home');
        return;
      }

      final deepLinkService = Get.find<DeepLinkService>();
      await deepLinkService.handleNotificationNavigation(data);
    } catch (e) {
      debugPrint('Error handling message: $e');
      // Fallback to home screen
      await Get.toNamed('/home');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        unawaited(
          handleMessage(
            RemoteMessage(data: Map<String, dynamic>.from(data)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
      Get.toNamed('/home');
    }
  }

  /// Extract notification category from message data
  NotificationCategory _getCategoryFromData(Map<String, dynamic> data) {
    try {
      final typeString = data['type'] as String?;
      if (typeString != null) {
        return NotificationCategoryExtension.fromString(typeString);
      }
    } catch (e) {
      debugPrint('Error extracting category from data: $e');
    }
    return NotificationCategory.system;
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Mask token for logging (show only first and last 4 characters)
  String _maskToken(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Get current FCM token
  String? get currentToken => _fcmToken;
}
