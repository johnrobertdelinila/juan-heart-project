/// SAMPLE USAGE: NotificationBloc UI Integration Examples
/// This file demonstrates how to use NotificationBloc in UI components.
/// DO NOT IMPORT IN PRODUCTION - REFERENCE ONLY

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:juan_heart/models/notification_category.dart';
import 'notification_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// Example 1: Notification List Screen with BLoC
class NotificationListScreenExample extends StatelessWidget {
  const NotificationListScreenExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc()..add(const LoadNotifications()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            // Mark all as read button
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationsLoaded && state.hasUnread) {
                  return IconButton(
                    icon: const Icon(Icons.done_all),
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                            const MarkAllNotificationsAsRead(),
                          );
                    },
                    tooltip: 'Mark all as read',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<NotificationBloc, NotificationState>(
          // Listen for errors and show snackbar
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      context.read<NotificationBloc>().add(
                            const LoadNotifications(),
                          );
                    },
                  ),
                ),
              );
            }
          },
          // Build UI based on state
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationError && !state.hasCachedData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NotificationBloc>().add(
                              const LoadNotifications(),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Get notifications from loaded state or error with cached data
            final notifications = state is NotificationsLoaded
                ? state.notifications
                : (state as NotificationError).previousState!.notifications;

            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notifications yet'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(
                      const RefreshNotifications(),
                    );
                // Wait for state to update
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      context.read<NotificationBloc>().add(
                            DeleteNotification(notificationId: notification.id),
                          );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notification.category.color,
                        child: Icon(
                          notification.category.iconData,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification.body),
                      trailing: !notification.isRead
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        if (!notification.isRead) {
                          context.read<NotificationBloc>().add(
                                MarkNotificationAsRead(
                                  notificationId: notification.id,
                                ),
                              );
                        }
                        // Navigate to detail screen
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Example 2: Unread Badge Widget
class UnreadBadgeExample extends StatelessWidget {
  const UnreadBadgeExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;

        if (unreadCount == 0) {
          return const Icon(Icons.notifications);
        }

        return Stack(
          children: [
            const Icon(Icons.notifications),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Example 3: Category Filter Chips
class CategoryFilterExample extends StatelessWidget {
  const CategoryFilterExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final activeFilter =
            state is NotificationsLoaded ? state.activeFilter : null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // All filter
              FilterChip(
                label: const Text('All'),
                selected: activeFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    context.read<NotificationBloc>().add(
                          const FilterNotificationsByCategory(category: null),
                        );
                  }
                },
              ),
              const SizedBox(width: 8),
              // Category filters
              ...NotificationCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.displayNameEn),
                    avatar: Icon(category.iconData, size: 16),
                    selected: activeFilter == category,
                    onSelected: (selected) {
                      if (selected) {
                        context.read<NotificationBloc>().add(
                              FilterNotificationsByCategory(category: category),
                            );
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

/// Example 4: Clear All Confirmation Dialog
Future<void> showClearAllDialogExample(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clear All Notifications'),
      content: const Text(
        'Are you sure you want to delete all notifications? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Clear All'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    context.read<NotificationBloc>().add(const ClearAllNotifications());
  }
}

/// Example 5: Action In Progress Overlay
class ActionOverlayExample extends StatelessWidget {
  final Widget child;

  const ActionOverlayExample({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state is NotificationActionInProgress)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Example 6: Notification received handler (in main app or service)
void listenForNewNotificationsExample(NotificationBloc bloc) {
  // This would be called from NotificationService when new notification arrives
  // Example:
  // notificationService.onNotificationReceived((notification) {
  //   bloc.add(NotificationReceived(notification: notification));
  // });
}
