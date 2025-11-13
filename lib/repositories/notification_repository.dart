import 'package:hive/hive.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Repository for managing notification persistence using Hive.
/// Implements offline-first architecture for Juan Heart Mobile.
/// Singleton pattern ensures consistent data access.
class NotificationRepository {
  static final NotificationRepository _instance =
      NotificationRepository._internal();

  factory NotificationRepository() => _instance;

  NotificationRepository._internal();

  /// Hive box name for notifications
  static const String _boxName = 'notifications';

  /// Maximum number of notifications to store
  static const int _maxNotifications = 500;

  /// Retention period in days
  static const int _retentionDays = 30;

  Box<NotificationModel>? _box;

  /// Initialize Hive box for notifications.
  /// Must be called before using repository.
  Future<void> initialize() async {
    try {
      if (_box != null && _box!.isOpen) {
        print('NotificationRepository already initialized');
        return;
      }

      _box = await Hive.openBox<NotificationModel>(_boxName);
      print('NotificationRepository initialized with ${_box!.length} notifications');

      // Clean up old notifications on initialization
      await _cleanupOldNotifications();
    } catch (e) {
      print('Error initializing NotificationRepository: $e');
      rethrow;
    }
  }

  /// Ensure box is initialized
  void _ensureInitialized() {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'NotificationRepository not initialized. Call initialize() first.'
      );
    }
  }

  /// Save a notification to storage
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      _ensureInitialized();

      if (!notification.isValid()) {
        throw ArgumentError('Invalid notification data');
      }

      // Check if we need to remove oldest notifications
      if (_box!.length >= _maxNotifications) {
        await _removeOldestNotification();
      }

      await _box!.put(notification.id, notification);
      print('Notification saved: ${notification.id}');
    } catch (e) {
      print('Error saving notification: $e');
      rethrow;
    }
  }

  /// Get all notifications, sorted by timestamp (newest first)
  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      _ensureInitialized();

      final notifications = _box!.values.toList();

      // Sort by timestamp, newest first
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      print('Error getting all notifications: $e');
      return [];
    }
  }

  /// Get unread notifications only
  Future<List<NotificationModel>> getUnreadNotifications() async {
    try {
      _ensureInitialized();

      final notifications = _box!.values
          .where((notification) => !notification.isRead)
          .toList();

      // Sort by timestamp, newest first
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      print('Error getting unread notifications: $e');
      return [];
    }
  }

  /// Get notifications by category
  Future<List<NotificationModel>> getNotificationsByCategory(
    NotificationCategory category,
  ) async {
    try {
      _ensureInitialized();

      final notifications = _box!.values
          .where((notification) => notification.category == category)
          .toList();

      // Sort by timestamp, newest first
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      print('Error getting notifications by category: $e');
      return [];
    }
  }

  /// Get a specific notification by ID
  Future<NotificationModel?> getNotificationById(String id) async {
    try {
      _ensureInitialized();
      return _box!.get(id);
    } catch (e) {
      print('Error getting notification by ID: $e');
      return null;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String id) async {
    try {
      _ensureInitialized();

      final notification = _box!.get(id);
      if (notification != null) {
        final updatedNotification = notification.copyWith(isRead: true);
        await _box!.put(id, updatedNotification);
        print('Notification marked as read: $id');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      _ensureInitialized();

      final notifications = _box!.values.toList();
      for (final notification in notifications) {
        if (!notification.isRead) {
          final updatedNotification = notification.copyWith(isRead: true);
          await _box!.put(notification.id, updatedNotification);
        }
      }

      print('All notifications marked as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a specific notification
  Future<void> deleteNotification(String id) async {
    try {
      _ensureInitialized();
      await _box!.delete(id);
      print('Notification deleted: $id');
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _ensureInitialized();
      await _box!.clear();
      print('All notifications cleared');
    } catch (e) {
      print('Error clearing all notifications: $e');
      rethrow;
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    try {
      _ensureInitialized();
      return _box!.values.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get count of unread notifications by category
  Future<int> getUnreadCountByCategory(
    NotificationCategory category,
  ) async {
    try {
      _ensureInitialized();
      return _box!.values
          .where((n) => !n.isRead && n.category == category)
          .length;
    } catch (e) {
      print('Error getting unread count by category: $e');
      return 0;
    }
  }

  /// Remove oldest notification when limit reached
  Future<void> _removeOldestNotification() async {
    try {
      final notifications = _box!.values.toList();
      if (notifications.isEmpty) return;

      // Sort by timestamp, oldest first
      notifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Remove oldest
      await _box!.delete(notifications.first.id);
      print('Removed oldest notification: ${notifications.first.id}');
    } catch (e) {
      print('Error removing oldest notification: $e');
    }
  }

  /// Clean up notifications older than retention period
  Future<void> _cleanupOldNotifications() async {
    try {
      final cutoffDate = DateTime.now().subtract(
        const Duration(days: _retentionDays)
      );

      final oldNotifications = _box!.values
          .where((notification) => notification.timestamp.isBefore(cutoffDate))
          .toList();

      for (final notification in oldNotifications) {
        await _box!.delete(notification.id);
      }

      if (oldNotifications.isNotEmpty) {
        print('Cleaned up ${oldNotifications.length} old notifications');
      }
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }

  /// Get notification count
  int get notificationCount {
    try {
      _ensureInitialized();
      return _box!.length;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  /// Close the repository and Hive box
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
        _box = null;
        print('NotificationRepository closed');
      }
    } catch (e) {
      print('Error closing NotificationRepository: $e');
    }
  }

  /// Check if repository is initialized
  bool get isInitialized => _box != null && _box!.isOpen;
}
