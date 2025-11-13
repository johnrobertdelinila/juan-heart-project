import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// NotificationBloc manages notification state for Juan Heart Mobile.
/// Implements BLoC pattern with Equatable for efficient state management.
/// Coordinates with NotificationService for data operations.
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  StreamSubscription<int>? _unreadCountSubscription;

  NotificationBloc({
    NotificationService? notificationService,
  })  : _notificationService =
            notificationService ?? NotificationService.instance,
        super(const NotificationInitial()) {
    // Register event handlers
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUnreadNotifications>(_onLoadUnreadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAll);
    on<RefreshNotifications>(_onRefresh);
    on<FilterNotificationsByCategory>(_onFilterByCategory);
    on<NotificationReceived>(_onNotificationReceived);

    // Listen to unread count stream for real-time updates
    _subscribeToUnreadCount();
  }

  /// Load all notifications from repository
  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationsLoading());

      final notifications = await _notificationService.getNotifications();
      final unreadCount = await _notificationService.getUnreadCount();

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to load notifications: ${e.toString()}',
      ));
    }
  }

  /// Load only unread notifications
  Future<void> _onLoadUnreadNotifications(
    LoadUnreadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(const NotificationsLoading());

      final notifications = await _notificationService.getUnreadNotifications();
      final unreadCount = notifications.length;

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to load unread notifications: ${e.toString()}',
      ));
    }
  }

  /// Mark single notification as read
  /// Uses optimistic update strategy for better UX
  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    try {
      // Optimistic update: Update UI immediately
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnreadCount =
          updatedNotifications.where((n) => !n.isRead).length;

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));

      // Perform actual update
      await _notificationService.markAsRead(event.notificationId);
    } catch (e) {
      // Revert on error
      emit(NotificationError(
        message: 'Failed to mark notification as read: ${e.toString()}',
        previousState: currentState,
      ));

      // Restore previous state after error
      emit(currentState);
    }
  }

  /// Mark all notifications as read
  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    try {
      // Show action in progress
      emit(NotificationActionInProgress(
        previousState: currentState,
        actionType: 'marking_all_read',
      ));

      // Perform operation
      await _notificationService.markAllAsRead();

      // Optimistic update: Mark all as read
      final updatedNotifications = currentState.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to mark all notifications as read: ${e.toString()}',
        previousState: currentState,
      ));

      // Restore previous state
      emit(currentState);
    }
  }

  /// Delete single notification
  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    try {
      // Show action in progress
      emit(NotificationActionInProgress(
        previousState: currentState,
        actionType: 'deleting',
      ));

      // Perform deletion
      await _notificationService.deleteNotification(event.notificationId);

      // Update state by removing notification
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != event.notificationId)
          .toList();

      final newUnreadCount =
          updatedNotifications.where((n) => !n.isRead).length;

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to delete notification: ${e.toString()}',
        previousState: currentState,
      ));

      // Restore previous state
      emit(currentState);
    }
  }

  /// Clear all notifications
  Future<void> _onClearAll(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded) return;

    try {
      // Show action in progress
      emit(NotificationActionInProgress(
        previousState: currentState,
        actionType: 'clearing',
      ));

      // Perform operation
      await _notificationService.clearAllNotifications();

      // Emit empty loaded state
      emit(const NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to clear all notifications: ${e.toString()}',
        previousState: currentState,
      ));

      // Restore previous state
      emit(currentState);
    }
  }

  /// Refresh notifications (pull-to-refresh)
  Future<void> _onRefresh(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    NotificationsLoaded? previousState;

    if (currentState is NotificationsLoaded) {
      previousState = currentState;
    }

    try {
      // Don't show loading spinner for refresh
      final notifications = await _notificationService.getNotifications();
      final unreadCount = await _notificationService.getUnreadCount();

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
        activeFilter: previousState?.activeFilter,
      ));
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to refresh notifications: ${e.toString()}',
        previousState: previousState,
      ));

      // Restore previous state if available
      if (previousState != null) {
        emit(previousState);
      }
    }
  }

  /// Filter notifications by category
  Future<void> _onFilterByCategory(
    FilterNotificationsByCategory event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;

    try {
      if (event.category == null) {
        // Show all notifications
        final notifications = await _notificationService.getNotifications();
        final unreadCount = await _notificationService.getUnreadCount();

        emit(NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
          activeFilter: null,
        ));
      } else {
        // Filter by category
        final allNotifications = await _notificationService.getNotifications();
        final filteredNotifications = allNotifications
            .where((n) => n.category == event.category)
            .toList();
        final unreadCount = await _notificationService.getUnreadCount();

        emit(NotificationsLoaded(
          notifications: filteredNotifications,
          unreadCount: unreadCount,
          activeFilter: event.category,
        ));
      }
    } catch (e) {
      emit(NotificationError(
        message: 'Failed to filter notifications: ${e.toString()}',
        previousState:
            currentState is NotificationsLoaded ? currentState : null,
      ));

      // Restore previous state
      if (currentState is NotificationsLoaded) {
        emit(currentState);
      }
    }
  }

  /// Handle new notification received
  /// Adds to list and updates unread count
  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;

    if (currentState is NotificationsLoaded) {
      // Add new notification to the beginning of list
      final updatedNotifications = [
        event.notification,
        ...currentState.notifications,
      ];

      // Increment unread count if notification is unread
      final newUnreadCount = event.notification.isRead
          ? currentState.unreadCount
          : currentState.unreadCount + 1;

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ));
    } else {
      // If no state yet, trigger load
      add(const LoadNotifications());
    }
  }

  /// Subscribe to unread count stream for real-time updates
  void _subscribeToUnreadCount() {
    _unreadCountSubscription =
        _notificationService.unreadCountStream.listen(
      (count) {
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          // Only update if count changed
          if (currentState.unreadCount != count) {
            add(const LoadNotifications());
          }
        }
      },
      onError: (error) {
        // Log error silently (backend logging handles this)
      },
    );
  }

  @override
  Future<void> close() {
    _unreadCountSubscription?.cancel();
    return super.close();
  }
}
