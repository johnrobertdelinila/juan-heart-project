import 'package:equatable/equatable.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Base class for all notification states.
/// Uses Equatable for efficient state comparison in BLoC.
abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

/// Initial state when BLoC is first created
/// No data loaded yet
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

/// Loading state while fetching notifications
/// Shows loading indicator in UI
class NotificationsLoading extends NotificationState {
  const NotificationsLoading();
}

/// Successfully loaded state with notification data
/// Main state used for displaying notification list
class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final NotificationCategory? activeFilter;

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.activeFilter,
  });

  /// Create a copy with modified fields
  /// Used for optimistic updates without full reload
  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    NotificationCategory? activeFilter,
    bool clearFilter = false,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }

  /// Get filtered notifications based on active filter
  List<NotificationModel> get filteredNotifications {
    if (activeFilter == null) {
      return notifications;
    }
    return notifications
        .where((n) => n.category == activeFilter)
        .toList();
  }

  /// Check if there are any notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Check if there are any unread notifications
  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [notifications, unreadCount, activeFilter];

  @override
  String toString() {
    return 'NotificationsLoaded(count: ${notifications.length}, '
        'unread: $unreadCount, filter: $activeFilter)';
  }
}

/// Action in progress state (marking read, deleting, clearing)
/// Preserves previous state to maintain UI while action executes
class NotificationActionInProgress extends NotificationState {
  final NotificationsLoaded previousState;
  final String actionType;

  const NotificationActionInProgress({
    required this.previousState,
    required this.actionType,
  });

  @override
  List<Object?> get props => [previousState, actionType];

  @override
  String toString() {
    return 'NotificationActionInProgress(action: $actionType)';
  }
}

/// Error state with descriptive message
/// Preserves previous state to show cached data
class NotificationError extends NotificationState {
  final String message;
  final NotificationsLoaded? previousState;

  const NotificationError({
    required this.message,
    this.previousState,
  });

  /// Check if we have cached data to display
  bool get hasCachedData => previousState != null;

  @override
  List<Object?> get props => [message, previousState];

  @override
  String toString() {
    return 'NotificationError(message: $message, '
        'hasCachedData: $hasCachedData)';
  }
}
