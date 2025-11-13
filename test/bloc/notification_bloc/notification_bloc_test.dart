import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_bloc.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_event.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_state.dart';
import 'package:juan_heart/services/notification_service.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Mock NotificationService for testing
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late NotificationBloc notificationBloc;
  late MockNotificationService mockNotificationService;

  // Test data
  final testNotification1 = NotificationModel.assessment(
    id: '1',
    title: 'Assessment Complete',
    body: 'Your CVD risk assessment is ready',
    payload: const {'assessmentId': 'a1'},
  );

  final testNotification2 = NotificationModel.appointment(
    id: '2',
    title: 'Appointment Reminder',
    body: 'Your appointment is tomorrow at 10 AM',
    payload: const {'appointmentId': 'apt1'},
  );

  final testNotifications = [testNotification1, testNotification2];

  setUp(() {
    mockNotificationService = MockNotificationService();
    // Setup default stub for unreadCountStream
    when(() => mockNotificationService.unreadCountStream)
        .thenAnswer((_) => Stream.value(2));

    notificationBloc = NotificationBloc(
      notificationService: mockNotificationService,
    );
  });

  tearDown(() {
    notificationBloc.close();
  });

  group('NotificationBloc', () {
    test('initial state is NotificationInitial', () {
      expect(notificationBloc.state, const NotificationInitial());
    });

    blocTest<NotificationBloc, NotificationState>(
      'emits [NotificationsLoading, NotificationsLoaded] when LoadNotifications succeeds',
      build: () {
        when(() => mockNotificationService.getNotifications())
            .thenAnswer((_) async => testNotifications);
        when(() => mockNotificationService.getUnreadCount())
            .thenAnswer((_) async => 2);
        return notificationBloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 2,
        ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.getNotifications()).called(1);
        verify(() => mockNotificationService.getUnreadCount()).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError when LoadNotifications fails',
      build: () {
        when(() => mockNotificationService.getNotifications())
            .thenThrow(Exception('Database error'));
        return notificationBloc;
      },
      act: (bloc) => bloc.add(const LoadNotifications()),
      expect: () => [
        const NotificationsLoading(),
        isA<NotificationError>(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'marks notification as read optimistically',
      build: () {
        when(() => mockNotificationService.markAsRead(any()))
            .thenAnswer((_) async => {});
        return notificationBloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const MarkNotificationAsRead(notificationId: '1')),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'unreadCount', 1),
      ],
      verify: (_) {
        verify(() => mockNotificationService.markAsRead('1')).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'deletes notification and updates list',
      build: () {
        when(() => mockNotificationService.deleteNotification(any()))
            .thenAnswer((_) async => {});
        return notificationBloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const DeleteNotification(notificationId: '1')),
      expect: () => [
        isA<NotificationActionInProgress>(),
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'notifications length', 1),
      ],
      verify: (_) {
        verify(() => mockNotificationService.deleteNotification('1')).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'marks all notifications as read',
      build: () {
        when(() => mockNotificationService.markAllAsRead())
            .thenAnswer((_) async => {});
        return notificationBloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const MarkAllNotificationsAsRead()),
      expect: () => [
        isA<NotificationActionInProgress>(),
        isA<NotificationsLoaded>()
            .having((s) => s.unreadCount, 'unreadCount', 0),
      ],
      verify: (_) {
        verify(() => mockNotificationService.markAllAsRead()).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'clears all notifications',
      build: () {
        when(() => mockNotificationService.clearAllNotifications())
            .thenAnswer((_) async => {});
        return notificationBloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const ClearAllNotifications()),
      expect: () => [
        isA<NotificationActionInProgress>(),
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.clearAllNotifications()).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'filters notifications by category',
      build: () {
        when(() => mockNotificationService.getNotifications())
            .thenAnswer((_) async => testNotifications);
        when(() => mockNotificationService.getUnreadCount())
            .thenAnswer((_) async => 1);
        return notificationBloc;
      },
      act: (bloc) => bloc.add(
        const FilterNotificationsByCategory(
          category: NotificationCategory.assessment,
        ),
      ),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.activeFilter, 'activeFilter',
                NotificationCategory.assessment)
            .having((s) => s.notifications.length, 'filtered count', 1),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'adds new notification to list when received',
      build: () => notificationBloc,
      seed: () => NotificationsLoaded(
        notifications: [testNotification2],
        unreadCount: 1,
      ),
      act: (bloc) => bloc.add(NotificationReceived(notification: testNotification1)),
      expect: () => [
        isA<NotificationsLoaded>()
            .having((s) => s.notifications.length, 'notifications length', 2)
            .having((s) => s.unreadCount, 'unreadCount', 2),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'refreshes notifications without showing loading',
      build: () {
        when(() => mockNotificationService.getNotifications())
            .thenAnswer((_) async => testNotifications);
        when(() => mockNotificationService.getUnreadCount())
            .thenAnswer((_) async => 2);
        return notificationBloc;
      },
      seed: () => const NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      ),
      act: (bloc) => bloc.add(const RefreshNotifications()),
      expect: () => [
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 2,
        ),
      ],
      verify: (_) {
        verify(() => mockNotificationService.getNotifications()).called(1);
        verify(() => mockNotificationService.getUnreadCount()).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'preserves state on error and reverts',
      build: () {
        when(() => mockNotificationService.markAsRead(any()))
            .thenThrow(Exception('Network error'));
        return notificationBloc;
      },
      seed: () => NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      ),
      act: (bloc) => bloc.add(const MarkNotificationAsRead(notificationId: '1')),
      expect: () => [
        isA<NotificationsLoaded>(),
        isA<NotificationError>().having(
          (s) => s.previousState,
          'previousState',
          isNotNull,
        ),
        isA<NotificationsLoaded>().having(
          (s) => s.unreadCount,
          'restored unreadCount',
          2,
        ),
      ],
    );
  });

  group('NotificationsLoaded', () {
    test('copyWith creates new instance with updated fields', () {
      const state = NotificationsLoaded(
        notifications: [],
        unreadCount: 5,
      );

      final newState = state.copyWith(unreadCount: 3);

      expect(newState.unreadCount, 3);
      expect(newState.notifications, []);
    });

    test('filteredNotifications returns all when no filter', () {
      final state = NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      );

      expect(state.filteredNotifications, testNotifications);
    });

    test('filteredNotifications filters by category', () {
      final state = NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
        activeFilter: NotificationCategory.assessment,
      );

      expect(state.filteredNotifications.length, 1);
      expect(state.filteredNotifications.first.category,
          NotificationCategory.assessment);
    });

    test('hasNotifications returns correct boolean', () {
      const emptyState = NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      );
      final loadedState = NotificationsLoaded(
        notifications: testNotifications,
        unreadCount: 2,
      );

      expect(emptyState.hasNotifications, false);
      expect(loadedState.hasNotifications, true);
    });

    test('hasUnread returns correct boolean', () {
      const noUnreadState = NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
      );
      const hasUnreadState = NotificationsLoaded(
        notifications: [],
        unreadCount: 3,
      );

      expect(noUnreadState.hasUnread, false);
      expect(hasUnreadState.hasUnread, true);
    });
  });

  group('NotificationError', () {
    test('hasCachedData returns true when previousState exists', () {
      const error = NotificationError(
        message: 'Error',
        previousState: NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      );

      expect(error.hasCachedData, true);
    });

    test('hasCachedData returns false when previousState is null', () {
      const error = NotificationError(message: 'Error');

      expect(error.hasCachedData, false);
    });
  });
}
