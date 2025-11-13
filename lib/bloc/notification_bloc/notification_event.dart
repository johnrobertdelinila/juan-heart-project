import 'package:equatable/equatable.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Base class for all notification events.
/// Uses Equatable for value comparison in BLoC state management.
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Load all notifications from repository
/// Triggered on initial screen load or after major changes
class LoadNotifications extends NotificationEvent {
  const LoadNotifications();
}

/// Event: Load only unread notifications
/// Used for filtering unread messages in UI
class LoadUnreadNotifications extends NotificationEvent {
  const LoadUnreadNotifications();
}

/// Event: Mark a specific notification as read
/// Triggered when user taps on notification card
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Event: Mark all notifications as read
/// Bulk operation triggered by "Mark all as read" button
class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

/// Event: Delete a specific notification
/// Triggered by swipe-to-delete or delete button
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Event: Clear all notifications
/// Destructive operation - requires confirmation in UI
class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

/// Event: Refresh notifications (pull-to-refresh)
/// Reloads data from repository, updates unread count
class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

/// Event: Filter notifications by category
/// Pass null to show all categories
class FilterNotificationsByCategory extends NotificationEvent {
  final NotificationCategory? category;

  const FilterNotificationsByCategory({this.category});

  @override
  List<Object?> get props => [category];
}

/// Event: New notification received from FCM or local
/// Triggered by NotificationService when new notification arrives
class NotificationReceived extends NotificationEvent {
  final NotificationModel notification;

  const NotificationReceived({required this.notification});

  @override
  List<Object?> get props => [notification];
}
