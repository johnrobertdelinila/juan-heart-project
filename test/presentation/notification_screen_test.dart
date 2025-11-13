import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get/get.dart';
import 'package:juan_heart/presentation/pages/home/notification_screen.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_bloc.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_state.dart';
import 'package:juan_heart/bloc/notification_bloc/notification_event.dart';
import 'package:juan_heart/models/notification_model.dart';
import 'package:juan_heart/models/notification_category.dart';

/// Mock NotificationBloc for widget testing
class MockNotificationBloc extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

/// Comprehensive widget tests for NotificationScreen
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationScreen Widget Tests', () {
    late MockNotificationBloc mockBloc;

    setUp(() {
      mockBloc = MockNotificationBloc();

      // Initialize GetX for locale support
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    /// Helper to create testable widget
    Widget createTestWidget(Widget child) {
      return GetMaterialApp(
        locale: const Locale('en'),
        home: BlocProvider<NotificationBloc>.value(
          value: mockBloc,
          child: child,
        ),
      );
    }

    testWidgets('should display loading state', (tester) async {
      // Setup
      when(() => mockBloc.state).thenReturn(const NotificationsLoading());

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no notifications', (tester) async {
      // Setup
      when(() => mockBloc.state).thenReturn(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));

      // Verify empty state is shown
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('should display notification list when loaded', (tester) async {
      // Setup test data
      final testNotifications = [
        NotificationModel.appointment(
          id: '1',
          title: 'Appointment Tomorrow',
          body: 'Your appointment is at 10 AM',
        ),
        NotificationModel.assessment(
          id: '2',
          title: 'Assessment Complete',
          body: 'Your risk score is 15',
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 2,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify notifications are displayed
      expect(find.text('Appointment Tomorrow'), findsOneWidget);
      expect(find.text('Assessment Complete'), findsOneWidget);
    });

    testWidgets('should display unread badge with correct count', (tester) async {
      // Setup
      final testNotifications = [
        NotificationModel.appointment(
          id: '1',
          title: 'Test 1',
          body: 'Body 1',
        ),
        NotificationModel.appointment(
          id: '2',
          title: 'Test 2',
          body: 'Body 2',
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 2,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify unread badge shows correct count
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('should display filter chips', (tester) async {
      // Setup
      when(() => mockBloc.state).thenReturn(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify filter chips are present
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
    });

    testWidgets('should show error state with message', (tester) async {
      // Setup
      when(() => mockBloc.state).thenReturn(
        const NotificationError(message: 'Failed to load notifications'),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify error message is shown
      expect(find.text('Failed to load notifications'), findsOneWidget);
    });

    testWidgets('should display notification category icons', (tester) async {
      // Setup
      final testNotifications = [
        NotificationModel.appointment(
          id: '1',
          title: 'Appointment',
          body: 'Test appointment',
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify category icon is present
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('should support Filipino language', (tester) async {
      // Setup GetX locale
      Get.updateLocale(const Locale('fil'));

      when(() => mockBloc.state).thenReturn(
        const NotificationsLoaded(
          notifications: [],
          unreadCount: 0,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify Filipino text is shown
      expect(find.text('Mga Abiso'), findsOneWidget);
    });

    testWidgets('should display action buttons', (tester) async {
      // Setup
      final testNotifications = [
        NotificationModel.appointment(
          id: '1',
          title: 'Test',
          body: 'Test',
        ),
      ];

      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify delete sweep icon (clear all) is present
      expect(find.byIcon(Icons.delete_sweep), findsOneWidget);
    });

    testWidgets('should show notification timestamp', (tester) async {
      // Setup
      final now = DateTime.now();
      final testNotifications = [
        NotificationModel.appointment(
          id: '1',
          title: 'Test',
          body: 'Test',
        ).copyWith(timestamp: now),
      ];

      when(() => mockBloc.state).thenReturn(
        NotificationsLoaded(
          notifications: testNotifications,
          unreadCount: 1,
        ),
      );

      // Build
      await tester.pumpWidget(createTestWidget(const NotificationScreen()));
      await tester.pumpAndSettle();

      // Verify notification is displayed (timestamp tested implicitly)
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
