# NotificationBloc State Transition Diagram

## State Flow Overview

```
[NotificationInitial]
        |
        | LoadNotifications / LoadUnreadNotifications
        v
[NotificationsLoading]
        |
        +--> Success --> [NotificationsLoaded]
        |
        +--> Error --> [NotificationError]
                              |
                              | (auto-revert)
                              v
                       [NotificationsLoaded (previous)]
```

## Detailed State Transitions

### 1. Initial Load Flow
```
NotificationInitial
  |
  | Event: LoadNotifications
  v
NotificationsLoading
  |
  +-- Success --> NotificationsLoaded(notifications, unreadCount)
  |
  +-- Error --> NotificationError(message)
```

### 2. Mark As Read Flow (Optimistic Update)
```
NotificationsLoaded(unread=5)
  |
  | Event: MarkNotificationAsRead(id)
  v
NotificationsLoaded(unread=4) [optimistic]
  |
  +-- Success --> [stays in NotificationsLoaded]
  |
  +-- Error --> NotificationError(previousState)
                  |
                  | (auto-revert)
                  v
                NotificationsLoaded(unread=5) [restored]
```

### 3. Delete Notification Flow
```
NotificationsLoaded(count=10)
  |
  | Event: DeleteNotification(id)
  v
NotificationActionInProgress(action='deleting', previousState)
  |
  +-- Success --> NotificationsLoaded(count=9)
  |
  +-- Error --> NotificationError(previousState)
                  |
                  | (auto-revert)
                  v
                NotificationsLoaded(count=10) [restored]
```

### 4. Mark All As Read Flow
```
NotificationsLoaded(unread=5)
  |
  | Event: MarkAllNotificationsAsRead
  v
NotificationActionInProgress(action='marking_all_read', previousState)
  |
  +-- Success --> NotificationsLoaded(unread=0)
  |
  +-- Error --> NotificationError(previousState)
                  |
                  | (auto-revert)
                  v
                NotificationsLoaded(unread=5) [restored]
```

### 5. Clear All Flow
```
NotificationsLoaded(count=10)
  |
  | Event: ClearAllNotifications
  v
NotificationActionInProgress(action='clearing', previousState)
  |
  +-- Success --> NotificationsLoaded(count=0, unread=0)
  |
  +-- Error --> NotificationError(previousState)
                  |
                  | (auto-revert)
                  v
                NotificationsLoaded(count=10) [restored]
```

### 6. Refresh Flow (Pull-to-Refresh)
```
NotificationsLoaded(cached data)
  |
  | Event: RefreshNotifications
  v
[No loading state shown - seamless UX]
  |
  +-- Success --> NotificationsLoaded(fresh data)
  |
  +-- Error --> NotificationError(previousState)
                  |
                  | (auto-revert)
                  v
                NotificationsLoaded(cached data) [restored]
```

### 7. Filter By Category Flow
```
NotificationsLoaded(all=10, filter=null)
  |
  | Event: FilterNotificationsByCategory(category)
  v
NotificationsLoaded(filtered=3, filter=category)
  |
  | Event: FilterNotificationsByCategory(null)
  v
NotificationsLoaded(all=10, filter=null)
```

### 8. New Notification Received Flow
```
NotificationsLoaded(count=10, unread=2)
  |
  | Event: NotificationReceived(notification)
  v
NotificationsLoaded(count=11, unread=3)
```

## State Properties

### NotificationInitial
- **Purpose**: Starting state before any data loaded
- **UI**: Show placeholder or trigger initial load
- **Transitions**: → NotificationsLoading

### NotificationsLoading
- **Purpose**: Data fetch in progress
- **UI**: Show loading spinner
- **Transitions**: → NotificationsLoaded, NotificationError

### NotificationsLoaded
- **Purpose**: Main state with notification data
- **Properties**:
  - `notifications`: List<NotificationModel>
  - `unreadCount`: int
  - `activeFilter`: NotificationCategory?
- **Computed**:
  - `filteredNotifications`: Filtered by activeFilter
  - `hasNotifications`: Boolean
  - `hasUnread`: Boolean
- **UI**: Display notification list
- **Transitions**: → All states

### NotificationActionInProgress
- **Purpose**: Long-running action (delete, clear, mark all)
- **Properties**:
  - `previousState`: NotificationsLoaded (preserved)
  - `actionType`: String ('deleting', 'clearing', 'marking_all_read')
- **UI**: Show loading overlay, disable interactions
- **Transitions**: → NotificationsLoaded, NotificationError

### NotificationError
- **Purpose**: Error occurred during operation
- **Properties**:
  - `message`: String (user-friendly error)
  - `previousState`: NotificationsLoaded? (cached data)
- **Computed**:
  - `hasCachedData`: Boolean
- **UI**: Show error snackbar, optionally display cached data
- **Transitions**: → NotificationsLoaded (auto-revert), NotificationsLoading (retry)

## Real-time Updates

### Unread Count Stream
```
NotificationService.unreadCountStream
  |
  | Stream emits new count
  v
[Check if current state is NotificationsLoaded]
  |
  | If count changed
  v
Trigger LoadNotifications event
  |
  v
Update UI with new data
```

## Error Handling Strategy

### Optimistic Updates (Mark As Read)
1. Immediately update UI (decrement unread count)
2. Perform service call in background
3. On error: Show error, revert to previous state
4. On success: Keep optimistic state

### Pessimistic Updates (Delete, Clear)
1. Show action in progress state
2. Perform service call
3. On error: Show error, restore previous state
4. On success: Update state with new data

### State Preservation
- **Error states** preserve `previousState`
- Allows UI to show cached data during errors
- Auto-revert mechanism restores user experience
- Provides "retry" action for failed operations

## Thread Safety

All BLoC operations are sequential:
- Events queued in order received
- One event processed at a time
- State transitions atomic
- No race conditions

## Testing States

### Unit Test Coverage
1. ✓ Initial state is NotificationInitial
2. ✓ LoadNotifications: Loading → Loaded
3. ✓ LoadNotifications error: Loading → Error
4. ✓ MarkAsRead: Optimistic update works
5. ✓ MarkAsRead error: Reverts correctly
6. ✓ DeleteNotification: Updates list
7. ✓ MarkAllAsRead: Sets unread to 0
8. ✓ ClearAll: Empties list
9. ✓ FilterByCategory: Filters correctly
10. ✓ NotificationReceived: Adds to list
11. ✓ RefreshNotifications: Updates without loading
12. ✓ State preservation on errors

### Integration Test Scenarios
1. Load → Filter → Refresh cycle
2. Mark as read → Delete sequence
3. Error → Retry → Success flow
4. Multiple rapid events (debouncing)
5. Stream subscription lifecycle
6. Real-time unread count updates

## Performance Considerations

### Optimizations Implemented
1. **Optimistic updates**: No server roundtrip for mark as read UI
2. **State preservation**: Avoid unnecessary reloads
3. **Filtered computed property**: No duplicate list iterations
4. **Stream efficiency**: Only reload when count actually changes
5. **copyWith**: Efficient immutable updates

### Potential Improvements
- Pagination for large notification lists
- Debouncing rapid filter changes
- Caching filtered results
- Lazy loading of notification details
- Background sync queue

## UI Integration Guidelines

### BlocProvider Setup
```dart
BlocProvider(
  create: (context) => NotificationBloc()
    ..add(const LoadNotifications()),
  child: NotificationScreen(),
)
```

### BlocConsumer Pattern
```dart
BlocConsumer<NotificationBloc, NotificationState>(
  listener: (context, state) {
    // Handle errors
    if (state is NotificationError) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  },
  builder: (context, state) {
    // Build UI based on state
  },
)
```

### Event Dispatch
```dart
context.read<NotificationBloc>().add(
  MarkNotificationAsRead(notificationId: id),
);
```

### State Access
```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    if (state is NotificationsLoaded) {
      return ListView(children: state.notifications.map(...));
    }
    return CircularProgressIndicator();
  },
)
```
