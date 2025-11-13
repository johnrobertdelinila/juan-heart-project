# NotificationBloc Quick Reference

## Setup

```dart
import 'package:juan_heart/bloc/notification_bloc/notification_bloc.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_event.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_state.dart';

BlocProvider(
  create: (context) => NotificationBloc()
    ..add(const LoadNotifications()),
  child: YourScreen(),
)
```

## Common Operations

### Load All Notifications
```dart
context.read<NotificationBloc>().add(const LoadNotifications());
```

### Load Unread Only
```dart
context.read<NotificationBloc>().add(const LoadUnreadNotifications());
```

### Mark As Read
```dart
context.read<NotificationBloc>().add(
  MarkNotificationAsRead(notificationId: id),
);
```

### Mark All As Read
```dart
context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
```

### Delete Notification
```dart
context.read<NotificationBloc>().add(
  DeleteNotification(notificationId: id),
);
```

### Clear All
```dart
context.read<NotificationBloc>().add(const ClearAllNotifications());
```

### Refresh
```dart
context.read<NotificationBloc>().add(const RefreshNotifications());
```

### Filter By Category
```dart
// Show only assessments
context.read<NotificationBloc>().add(
  FilterNotificationsByCategory(
    category: NotificationCategory.assessment,
  ),
);

// Show all
context.read<NotificationBloc>().add(
  const FilterNotificationsByCategory(category: null),
);
```

### Handle New Notification
```dart
context.read<NotificationBloc>().add(
  NotificationReceived(notification: newNotification),
);
```

## State Handling

### Display List
```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    if (state is NotificationsLoading) {
      return CircularProgressIndicator();
    }

    if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return EmptyState();
      }

      return ListView.builder(
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          return NotificationTile(
            notification: state.notifications[index],
          );
        },
      );
    }

    if (state is NotificationError) {
      return ErrorWidget(message: state.message);
    }

    return Container();
  },
)
```

### Show Unread Count
```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    final count = state is NotificationsLoaded
      ? state.unreadCount
      : 0;

    if (count == 0) return Icon(Icons.notifications);

    return Badge(
      label: Text('$count'),
      child: Icon(Icons.notifications),
    );
  },
)
```

### Handle Errors
```dart
BlocConsumer<NotificationBloc, NotificationState>(
  listener: (context, state) {
    if (state is NotificationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
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
  builder: (context, state) {
    // Build UI
    return YourWidget();
  },
)
```

### Pull-to-Refresh
```dart
RefreshIndicator(
  onRefresh: () async {
    context.read<NotificationBloc>().add(
      const RefreshNotifications(),
    );
    await Future.delayed(Duration(seconds: 1));
  },
  child: NotificationList(),
)
```

### Swipe-to-Delete
```dart
Dismissible(
  key: Key(notification.id),
  direction: DismissDirection.endToStart,
  onDismissed: (direction) {
    context.read<NotificationBloc>().add(
      DeleteNotification(notificationId: notification.id),
    );
  },
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    child: Icon(Icons.delete),
  ),
  child: NotificationTile(notification: notification),
)
```

### Loading Overlay
```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    return Stack(
      children: [
        YourContent(),
        if (state is NotificationActionInProgress)
          Container(
            color: Colors.black26,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  },
)
```

## State Properties

### NotificationsLoaded
```dart
state.notifications          // List<NotificationModel>
state.unreadCount           // int
state.activeFilter          // NotificationCategory?
state.filteredNotifications // List<NotificationModel> (computed)
state.hasNotifications      // bool (computed)
state.hasUnread            // bool (computed)
```

### NotificationError
```dart
state.message          // String
state.previousState    // NotificationsLoaded?
state.hasCachedData    // bool (computed)
```

### NotificationActionInProgress
```dart
state.previousState    // NotificationsLoaded
state.actionType       // String ('deleting', 'clearing', 'marking_all_read')
```

## Testing

```dart
blocTest<NotificationBloc, NotificationState>(
  'loads notifications successfully',
  build: () {
    when(() => mockService.getNotifications())
        .thenAnswer((_) async => testNotifications);
    when(() => mockService.getUnreadCount())
        .thenAnswer((_) async => 2);
    return NotificationBloc(notificationService: mockService);
  },
  act: (bloc) => bloc.add(const LoadNotifications()),
  expect: () => [
    const NotificationsLoading(),
    NotificationsLoaded(
      notifications: testNotifications,
      unreadCount: 2,
    ),
  ],
);
```

## Debugging

### Print Current State
```dart
print('Current state: ${context.read<NotificationBloc>().state}');
```

### Listen to State Changes
```dart
BlocListener<NotificationBloc, NotificationState>(
  listener: (context, state) {
    print('State changed to: $state');
  },
  child: YourWidget(),
)
```

### Monitor Unread Count Stream
```dart
NotificationService.instance.unreadCountStream.listen((count) {
  print('Unread count: $count');
});
```

## Best Practices

1. ✅ Always use `const` for events without parameters
2. ✅ Use `BlocConsumer` for both listening and building
3. ✅ Show cached data in error states when available
4. ✅ Implement pull-to-refresh for better UX
5. ✅ Use optimistic updates for mark as read
6. ✅ Confirm destructive actions (delete, clear)
7. ✅ Dispose BLoC properly (automatic with BlocProvider)
8. ✅ Mock service in tests, not BLoC
9. ✅ Test state transitions, not implementation
10. ✅ Use state properties instead of filtering manually

## Common Mistakes

❌ **Don't** directly modify state
```dart
// WRONG
state.notifications.add(newNotification);
```

✅ **Do** dispatch events
```dart
// CORRECT
bloc.add(NotificationReceived(notification: newNotification));
```

❌ **Don't** create multiple BLoC instances
```dart
// WRONG
NotificationBloc()..add(event);
NotificationBloc()..add(anotherEvent);
```

✅ **Do** use context.read
```dart
// CORRECT
final bloc = context.read<NotificationBloc>();
bloc.add(event);
bloc.add(anotherEvent);
```

❌ **Don't** forget to provide BLoC
```dart
// WRONG - BLoC not provided
Builder(builder: (context) {
  context.read<NotificationBloc>(); // Error!
});
```

✅ **Do** wrap with BlocProvider
```dart
// CORRECT
BlocProvider(
  create: (_) => NotificationBloc(),
  child: YourWidget(),
);
```

## Performance Tips

1. Use `const` constructors for events
2. Avoid rebuilding entire screen on state changes
3. Use `BlocBuilder` only where needed
4. Implement `buildWhen` for selective rebuilds
5. Keep notification list <1000 items
6. Use `ListView.builder` for large lists
7. Implement virtual scrolling if needed

## Troubleshooting

### BLoC not updating UI
- Check if BlocProvider is in widget tree
- Verify events are being dispatched
- Ensure state implements Equatable properly

### Memory leak
- Verify BLoC is disposed (BlocProvider handles this)
- Check stream subscriptions are canceled in close()
- Don't keep references to closed BLoCs

### Tests failing
- Mock NotificationService, not BLoC
- Use bloc_test package
- Verify all state properties in expectations

### Real-time updates not working
- Check if unread count stream is active
- Verify NotificationService is initialized
- Ensure stream subscription is created in BLoC

---

**Need Help?** See `IMPLEMENTATION_SUMMARY.md` or `STATE_TRANSITION_DIAGRAM.md`
