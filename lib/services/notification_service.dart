import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'package:juan_heart/repositories/notification_repository.dart';
import 'package:juan_heart/services/notification_preferences_service.dart';
import 'package:juan_heart/services/deep_link_service.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

/// Centralized notification management service for Juan Heart Mobile.
/// Coordinates between repository, preferences, and notification display.
/// Singleton pattern ensures consistent notification handling.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => instance;

  static NotificationService get instance => _instance;

  NotificationService._internal();

  final NotificationRepository _repository = NotificationRepository();
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();

  bool _initialized = false;
  final Uuid _uuid = const Uuid();

  /// Stream controller for unread count updates
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('NotificationService already initialized');
      return;
    }

    try {
      // Initialize repository
      await _repository.initialize();

      // Load preferences
      await _preferencesService.loadPreferences();

      // Emit initial unread count
      await _updateUnreadCount();

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
      rethrow;
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'NotificationService not initialized. Call initialize() first.'
      );
    }
  }

  /// Show a notification (save to repository and check preferences)
  Future<void> showNotification(NotificationModel notification) async {
    try {
      _ensureInitialized();

      // Check if notification should be shown based on preferences
      final shouldShow = await _preferencesService
          .shouldShowNotification(notification.category);

      if (!shouldShow) {
        debugPrint('Notification blocked by user preferences: ${notification.id}');
        return;
      }

      // Save notification to repository
      await _repository.saveNotification(notification);

      // Update unread count
      await _updateUnreadCount();

      debugPrint('Notification shown and saved: ${notification.id}');
    } catch (e) {
      debugPrint('Error showing notification: $e');
      rethrow;
    }
  }

  /// Handle incoming notification from FCM or local notifications
  Future<void> handleIncomingNotification(
    Map<String, dynamic> payload,
  ) async {
    try {
      _ensureInitialized();

      // Generate unique ID if not provided
      final id = payload['id'] as String? ?? _uuid.v4();

      // Create notification model from payload
      final notification = NotificationModel.fromFCMData(
        id: id,
        data: payload,
      );

      // Save notification
      await showNotification(notification);

      debugPrint('Incoming notification handled: $id');
    } catch (e) {
      debugPrint('Error handling incoming notification: $e');
    }
  }

  /// Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      _ensureInitialized();
      return await _repository.getAllNotifications();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      _ensureInitialized();
      return await _repository.getUnreadNotifications();
    } catch (e) {
      debugPrint('Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get notifications by category
  Future<List<NotificationModel>> getNotificationsByCategory(
    NotificationCategory category,
  ) async {
    try {
      _ensureInitialized();
      return await _repository.getNotificationsByCategory(category);
    } catch (e) {
      debugPrint('Error getting notifications by category: $e');
      return [];
    }
  }

  /// Get notification by ID
  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      _ensureInitialized();
      return await _repository.getNotificationById(id);
    } catch (e) {
      debugPrint('Error getting notification by ID: $e');
      return null;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      _ensureInitialized();
      await _repository.markAsRead(id);
      await _updateUnreadCount();
      debugPrint('Notification marked as read: $id');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _ensureInitialized();
      await _repository.markAllAsRead();
      await _updateUnreadCount();
      debugPrint('All notifications marked as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    try {
      _ensureInitialized();
      await _repository.deleteNotification(id);
      await _updateUnreadCount();
      debugPrint('Notification deleted: $id');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _ensureInitialized();
      await _repository.clearAllNotifications();
      await _updateUnreadCount();
      debugPrint('All notifications cleared');
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      _ensureInitialized();
      return await _repository.getUnreadCount();
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get unread count by category
  Future<int> getUnreadCountByCategory(NotificationCategory category) async {
    try {
      _ensureInitialized();
      return await _repository.getUnreadCountByCategory(category);
    } catch (e) {
      debugPrint('Error getting unread count by category: $e');
      return 0;
    }
  }

  /// Stream of unread count updates
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Update unread count and emit to stream
  Future<void> _updateUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      _unreadCountController.add(count);
    } catch (e) {
      debugPrint('Error updating unread count: $e');
      _unreadCountController.add(0);
    }
  }

  /// Handle notification tap and navigate to appropriate screen
  Future<void> handleNotificationTap(NotificationModel notification) async {
    try {
      await markAsRead(notification.id);

      final deepLinkService = Get.find<DeepLinkService>();

      if (notification.actionUrl != null) {
        await deepLinkService.handleDeepLink(notification.actionUrl!);
      } else if (notification.payload != null) {
        await _navigateFromPayload(notification.payload!, deepLinkService);
      } else {
        await Get.toNamed('/home');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
      await Get.toNamed('/home');
    }
  }

  /// Navigate based on payload data
  Future<void> _navigateFromPayload(
    Map<String, dynamic> payload,
    DeepLinkService deepLinkService,
  ) async {
    try {
      // Check for specific navigation keys
      if (payload.containsKey('appointmentId')) {
        final appointmentId = payload['appointmentId'] as String;
        await deepLinkService.handleDeepLink(
          'juanheart://app/appointments/$appointmentId',
        );
      } else if (payload.containsKey('assessmentId')) {
        final assessmentId = payload['assessmentId'] as String;
        await deepLinkService.handleDeepLink(
          'juanheart://app/assessments/$assessmentId',
        );
      } else if (payload.containsKey('screen')) {
        final screen = payload['screen'] as String;
        await deepLinkService.handleDeepLink('juanheart://app/$screen');
      } else {
        await Get.toNamed('/home');
      }
    } catch (e) {
      debugPrint('Error navigating from payload: $e');
      await Get.toNamed('/home');
    }
  }

  /// Create and show assessment notification
  Future<void> showAssessmentNotification({
    required String title,
    required String body,
    String? assessmentId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (assessmentId != null) 'assessmentId': assessmentId,
        ...?additionalData,
      };

      final notification = NotificationModel.assessment(
        id: _uuid.v4(),
        title: title,
        body: body,
        payload: payload,
      );

      await showNotification(notification);
    } catch (e) {
      debugPrint('Error showing assessment notification: $e');
    }
  }

  /// Create and show appointment notification
  Future<void> showAppointmentNotification({
    required String title,
    required String body,
    String? appointmentId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (appointmentId != null) 'appointmentId': appointmentId,
        ...?additionalData,
      };

      final notification = NotificationModel.appointment(
        id: _uuid.v4(),
        title: title,
        body: body,
        payload: payload,
      );

      await showNotification(notification);
    } catch (e) {
      debugPrint('Error showing appointment notification: $e');
    }
  }

  /// Create and show health alert notification
  Future<void> showHealthAlertNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notification = NotificationModel.healthAlert(
        id: _uuid.v4(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        payload: additionalData,
      );

      await showNotification(notification);
    } catch (e) {
      debugPrint('Error showing health alert notification: $e');
    }
  }

  /// Notify user of assessment sync failures after max retries exceeded
  ///
  /// This notification is shown when assessments fail to sync after 3 attempts.
  /// User can tap the notification to navigate to analytics screen to retry.
  ///
  /// [failedCount] - Number of assessments that failed to sync
  /// [errorMessage] - Optional error message describing the failure reason
  Future<void> notifyAssessmentSyncFailure({
    required int failedCount,
    String? errorMessage,
  }) async {
    try {
      _ensureInitialized();

      // Determine plural form
      final assessmentWord = failedCount == 1 ? 'assessment' : 'assessments';
      final pronoun = failedCount == 1 ? 'it' : 'them';

      // Create notification body based on error type
      String notificationBody;
      if (errorMessage != null && errorMessage.toLowerCase().contains('network')) {
        notificationBody = 'Unable to sync $failedCount $assessmentWord due to network issues. Tap to retry when online.';
      } else if (errorMessage != null && errorMessage.toLowerCase().contains('server')) {
        notificationBody = 'Server error prevented syncing $failedCount $assessmentWord. Tap to retry.';
      } else {
        notificationBody = 'Failed to sync $failedCount $assessmentWord. Tap to review and retry.';
      }

      final notification = NotificationModel.system(
        id: _uuid.v4(),
        title: 'Sync Failed',
        body: notificationBody,
        payload: {
          'failedCount': failedCount,
          'errorMessage': errorMessage ?? 'Unknown error',
          'screen': 'analytics',
          'action': 'retry_sync',
          'timestamp': DateTime.now().toIso8601String(),
        },
        actionUrl: 'juanheart://app/analytics?action=retry_sync',
      );

      await showNotification(notification);

      debugPrint('Sync failure notification created: $failedCount $assessmentWord failed');
    } catch (e) {
      debugPrint('Error creating sync failure notification: $e');
      // Don't rethrow - notification failure shouldn't break sync
    }
  }

  /// Notify user of appointment sync failures
  ///
  /// Similar to assessment sync failures, but for appointment operations
  ///
  /// [failedCount] - Number of appointments that failed to sync
  /// [errorMessage] - Optional error message describing the failure reason
  Future<void> notifyAppointmentSyncFailure({
    required int failedCount,
    String? errorMessage,
  }) async {
    try {
      _ensureInitialized();

      final appointmentWord = failedCount == 1 ? 'appointment' : 'appointments';

      String notificationBody;
      if (errorMessage != null && errorMessage.toLowerCase().contains('network')) {
        notificationBody = 'Unable to sync $failedCount $appointmentWord due to network issues. Tap to retry when online.';
      } else {
        notificationBody = 'Failed to sync $failedCount $appointmentWord. Tap to review and retry.';
      }

      final notification = NotificationModel.system(
        id: _uuid.v4(),
        title: 'Appointment Sync Failed',
        body: notificationBody,
        payload: {
          'failedCount': failedCount,
          'errorMessage': errorMessage ?? 'Unknown error',
          'screen': 'appointments',
          'action': 'retry_sync',
          'timestamp': DateTime.now().toIso8601String(),
        },
        actionUrl: 'juanheart://app/appointments?action=retry_sync',
      );

      await showNotification(notification);

      debugPrint('Appointment sync failure notification created: $failedCount $appointmentWord failed');
    } catch (e) {
      debugPrint('Error creating appointment sync failure notification: $e');
    }
  }

  /// Notify user of successful sync after retries
  ///
  /// Shows a success notification when previously failed syncs complete
  ///
  /// [syncedCount] - Number of items successfully synced
  /// [type] - Type of sync ('assessment' or 'appointment')
  Future<void> notifySyncSuccess({
    required int syncedCount,
    required String type,
  }) async {
    try {
      _ensureInitialized();

      final itemWord = syncedCount == 1 ? type : '${type}s';

      final notification = NotificationModel.system(
        id: _uuid.v4(),
        title: 'Sync Successful',
        body: 'Successfully synced $syncedCount $itemWord to the server.',
        payload: {
          'syncedCount': syncedCount,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await showNotification(notification);

      debugPrint('Sync success notification created: $syncedCount $itemWord synced');
    } catch (e) {
      debugPrint('Error creating sync success notification: $e');
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    return await _preferencesService.loadPreferences();
  }

  /// Update notification preferences
  Future<void> updatePreferences(NotificationPreferences preferences) async {
    await _preferencesService.savePreferences(preferences);
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Dispose resources
  void dispose() {
    _unreadCountController.close();
  }
}
