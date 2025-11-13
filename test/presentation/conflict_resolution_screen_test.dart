import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:juan_heart/presentation/pages/settings/conflict_resolution_screen.dart';
import 'package:juan_heart/services/conflict_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Initialize GetX
    Get.testMode = true;
  });

  tearDown(() async {
    Get.reset();
  });

  group('ConflictResolutionScreen Widget Tests', () {
    testWidgets('Should display empty state when no conflicts exist',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('No Conflicts to Resolve'), findsOneWidget);
      expect(
        find.text('All your data is in sync. Great job!'),
        findsOneWidget,
      );
    });

    testWidgets('Should display conflict count badge in AppBar',
        (WidgetTester tester) async {
      // Create a test conflict
      final testConflict = ConflictItem(
        id: 'test-1',
        entityType: 'user_profile',
        localData: {
          'id': '1',
          'name': 'John Local',
          'email': 'john@local.com',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        serverData: {
          'id': '1',
          'name': 'John Server',
          'email': 'john@server.com',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
        reason: 'Test conflict',
      );

      // Add conflict for manual review
      await ConflictResolver.instance.addConflictForManualReview(testConflict);

      // Build the widget
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      // Wait for conflicts to load
      await tester.pumpAndSettle();

      // Verify conflict count badge is displayed
      expect(find.text('1'), findsWidgets);
      expect(find.text('Resolve Conflicts'), findsOneWidget);
    });

    testWidgets('Should display conflict card with correct information',
        (WidgetTester tester) async {
      // Create a test conflict
      final testConflict = ConflictItem(
        id: 'test-2',
        entityType: 'facility',
        localData: {
          'id': '1',
          'name': 'Local Hospital',
          'address': '123 Local St',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        serverData: {
          'id': '1',
          'name': 'Server Hospital',
          'address': '456 Server Ave',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
        reason: 'Facility data mismatch',
      );

      await ConflictResolver.instance.addConflictForManualReview(testConflict);

      // Build the widget
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify conflict information is displayed
      expect(find.text('Facility'), findsOneWidget);
      expect(find.text('Facility data mismatch'), findsOneWidget);
      expect(find.byIcon(Icons.local_hospital), findsWidgets);
    });

    testWidgets('Should display Local Version and Server Version cards',
        (WidgetTester tester) async {
      final testConflict = ConflictItem(
        id: 'test-3',
        entityType: 'assessment',
        localData: {
          'id': '1',
          'riskScore': '15',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        serverData: {
          'id': '1',
          'riskScore': '20',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(testConflict);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify version cards are displayed
      expect(find.text('Local Version'), findsOneWidget);
      expect(find.text('Server Version'), findsOneWidget);
      expect(find.byIcon(Icons.phone_android), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
    });

    testWidgets('Should display resolution buttons',
        (WidgetTester tester) async {
      final testConflict = ConflictItem(
        id: 'test-4',
        entityType: 'user_profile',
        localData: {
          'id': '1',
          'name': 'Test User',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        serverData: {
          'id': '1',
          'name': 'Test User Updated',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(testConflict);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify resolution buttons
      expect(find.text('Keep Local'), findsOneWidget);
      expect(find.text('Keep Server'), findsOneWidget);
    });

    testWidgets('Should resolve conflict when Keep Local is tapped',
        (WidgetTester tester) async {
      final testConflict = ConflictItem(
        id: 'test-5',
        entityType: 'user_profile',
        localData: {
          'id': '1',
          'name': 'Local Name',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        serverData: {
          'id': '1',
          'name': 'Server Name',
          'updatedAt': DateTime.now().toIso8601String(),
        },
        timestamp: DateTime.now(),
      );

      await ConflictResolver.instance.addConflictForManualReview(testConflict);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Keep Local button
      await tester.tap(find.text('Keep Local'));
      await tester.pump(); // Start the animation
      await tester.pump(const Duration(milliseconds: 100)); // Let loading dialog appear
      await tester.pump(); // Process the resolution
      await tester.pump(const Duration(seconds: 1)); // Wait for operations to complete

      // Verify conflict is resolved
      final conflictsAfter =
          await ConflictResolver.instance.getConflictsRequiringManualReview();
      expect(conflictsAfter.length, 0);
    }, skip: true); // Skip due to GetX snackbar timer issues in tests

    testWidgets('Should handle Filipino language',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          locale: Locale('fil', 'PH'),
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Filipino text is displayed
      expect(find.text('Ayusin ang Salungatan'), findsOneWidget);
      expect(find.text('Walang Salungatan'), findsOneWidget);
    }, skip: true); // Skip due to GetX locale update issues in tests

    testWidgets('Should display close button in AppBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify close button exists
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Should show loading indicator while loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(
          home: ConflictResolutionScreen(),
        ),
      );

      // Before pumpAndSettle, loading should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // After loading, should show content
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ConflictItem Tests', () {
    test('Should correctly identify entity icons', () {
      final userConflict = ConflictItem(
        id: 'test',
        entityType: 'user_profile',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );
      expect(userConflict.getIcon(), Icons.person);

      final facilityConflict = ConflictItem(
        id: 'test',
        entityType: 'facility',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );
      expect(facilityConflict.getIcon(), Icons.local_hospital);

      final assessmentConflict = ConflictItem(
        id: 'test',
        entityType: 'assessment',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );
      expect(assessmentConflict.getIcon(), Icons.monitor_heart);

      final appointmentConflict = ConflictItem(
        id: 'test',
        entityType: 'appointment',
        localData: {},
        serverData: {},
        timestamp: DateTime.now(),
      );
      expect(appointmentConflict.getIcon(), Icons.calendar_today);
    });

    test('Should correctly identify differences between versions', () {
      final conflict = ConflictItem(
        id: 'test',
        entityType: 'user_profile',
        localData: {
          'id': '1',
          'name': 'John Doe',
          'email': 'john@local.com',
          'phone': '123456789',
          'updatedAt': '2024-01-01',
        },
        serverData: {
          'id': '1',
          'name': 'John Doe',
          'email': 'john@server.com',
          'phone': '987654321',
          'updatedAt': '2024-01-02',
        },
        timestamp: DateTime.now(),
      );

      final differences = conflict.getDifferences();

      // Should have 2 differences (email and phone, not updatedAt)
      expect(differences.length, 2);
      expect(differences.any((d) => d.field == 'email'), true);
      expect(differences.any((d) => d.field == 'phone'), true);
      expect(differences.any((d) => d.field == 'updatedAt'), false);
    });

    test('Should serialize and deserialize correctly', () {
      final original = ConflictItem(
        id: 'test-id',
        entityType: 'user_profile',
        localData: {'name': 'Local'},
        serverData: {'name': 'Server'},
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        reason: 'Test reason',
      );

      final json = original.toJson();
      final deserialized = ConflictItem.fromJson(json);

      expect(deserialized.id, original.id);
      expect(deserialized.entityType, original.entityType);
      expect(deserialized.localData, original.localData);
      expect(deserialized.serverData, original.serverData);
      expect(deserialized.reason, original.reason);
      expect(
        deserialized.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
    });
  });
}
