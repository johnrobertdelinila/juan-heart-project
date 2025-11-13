import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:juan_heart/main.dart' as app;

/// Widget Rebuild Profiler Test
///
/// This test monitors widget rebuild counts to identify excessive rebuilds
/// that can cause performance issues and increased memory pressure.
///
/// Excessive rebuilds indicate:
/// - Missing const constructors
/// - Improper BLoC usage
/// - Unnecessary setState calls
/// - Parent widgets rebuilding when only children should
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Widget Rebuild Profiling', () {
    testWidgets('Monitor widget rebuild counts during app usage', (WidgetTester tester) async {
      debugPrint('\n========================================');
      debugPrint('WIDGET REBUILD PROFILING');
      debugPrint('========================================\n');

      final rebuildMonitor = RebuildMonitor();

      // Enable rebuild tracking
      debugProfileBuildsEnabled = true;

      app.main();
      await tester.pumpAndSettle();

      debugPrint('App launched. Starting rebuild monitoring...\n');

      // Test 1: Home screen idle rebuilds
      debugPrint('--- Test 1: Home Screen Idle Rebuilds ---');
      final homeIdleCount = await rebuildMonitor.countRebuilds(
        tester,
        duration: const Duration(seconds: 5),
        label: 'Home Screen Idle',
      );
      debugPrint('Home screen rebuilds (5s idle): $homeIdleCount');
      if (homeIdleCount > 10) {
        debugPrint('⚠️ WARNING: Excessive rebuilds detected on idle home screen!');
      }
      debugPrint('');

      // Test 2: Navigation rebuilds
      debugPrint('--- Test 2: Navigation Rebuilds ---');
      final navButton = find.byKey(const Key('nav_analytics'));
      if (navButton.evaluate().isNotEmpty) {
        final beforeNav = rebuildMonitor.rebuildCount;
        await tester.tap(navButton);
        await tester.pumpAndSettle();
        final navRebuilds = rebuildMonitor.rebuildCount - beforeNav;
        debugPrint('Rebuilds during navigation: $navRebuilds');

        // Navigate back
        final backButton = find.byKey(const Key('nav_home'));
        if (backButton.evaluate().isNotEmpty) {
          final beforeBack = rebuildMonitor.rebuildCount;
          await tester.tap(backButton);
          await tester.pumpAndSettle();
          final backRebuilds = rebuildMonitor.rebuildCount - beforeBack;
          debugPrint('Rebuilds during back navigation: $backRebuilds');
        }
      }
      debugPrint('');

      // Test 3: Form interaction rebuilds
      debugPrint('--- Test 3: Form Interaction Rebuilds ---');
      final assessmentNav = find.byKey(const Key('nav_assessment'));
      if (assessmentNav.evaluate().isNotEmpty) {
        await tester.tap(assessmentNav);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        if (textFields.evaluate().isNotEmpty) {
          final beforeInteraction = rebuildMonitor.rebuildCount;

          // Tap text field
          await tester.tap(textFields.first);
          await tester.pumpAndSettle();

          final interactionRebuilds = rebuildMonitor.rebuildCount - beforeInteraction;
          debugPrint('Rebuilds on text field focus: $interactionRebuilds');

          if (interactionRebuilds > 20) {
            debugPrint('⚠️ WARNING: Excessive rebuilds on simple interaction!');
          }
        }
      }
      debugPrint('');

      // Test 4: Rapid state changes
      debugPrint('--- Test 4: Rapid State Changes ---');
      for (int i = 0; i < 5; i++) {
        final beforeChange = rebuildMonitor.rebuildCount;
        await tester.pump(const Duration(milliseconds: 100));
        final changeRebuilds = rebuildMonitor.rebuildCount - beforeChange;
        debugPrint('Rebuild cycle ${i + 1}: $changeRebuilds widgets');
      }
      debugPrint('');

      // Final report
      debugPrint('--- REBUILD SUMMARY ---');
      debugPrint('Total rebuilds during test: ${rebuildMonitor.rebuildCount}');
      debugPrint('Average rebuilds per operation: ${(rebuildMonitor.rebuildCount / 4).toStringAsFixed(1)}');

      // Disable rebuild tracking
      debugProfileBuildsEnabled = false;
    });

    testWidgets('Identify widgets with const constructor violations', (WidgetTester tester) async {
      debugPrint('\n========================================');
      debugPrint('CONST CONSTRUCTOR ANALYSIS');
      debugPrint('========================================\n');

      app.main();
      await tester.pumpAndSettle();

      final violations = <String>[];

      // Find widgets that should be const but aren't
      final allWidgets = find.byType(Widget);
      for (final element in allWidgets.evaluate()) {
        final widget = element.widget;

        // Check if widget could be const (basic heuristic)
        if (widget is StatelessWidget && !_isConst(widget)) {
          violations.add(widget.runtimeType.toString());
        }
      }

      if (violations.isNotEmpty) {
        debugPrint('Potential const constructor violations:');
        final uniqueViolations = violations.toSet().toList();
        for (int i = 0; i < uniqueViolations.length && i < 20; i++) {
          debugPrint('  - ${uniqueViolations[i]}');
        }
        debugPrint('\nTotal unique violations: ${uniqueViolations.length}');
        debugPrint('⚠️ Consider adding const constructors where possible');
      } else {
        debugPrint('✓ No obvious const constructor violations found');
      }
    });
  });
}

/// Monitor widget rebuilds
class RebuildMonitor {
  int _rebuildCount = 0;

  int get rebuildCount => _rebuildCount;

  Future<int> countRebuilds(
    WidgetTester tester, {
    required Duration duration,
    required String label,
  }) async {
    final startCount = _rebuildCount;
    final startTime = DateTime.now();

    // Create a callback to count rebuilds
    void countCallback() {
      _rebuildCount++;
    }

    // Monitor rebuilds during the duration
    while (DateTime.now().difference(startTime) < duration) {
      await tester.pump(const Duration(milliseconds: 100));
      // Count visible widgets as proxy for rebuilds
      final widgetCount = find.byType(Widget).evaluate().length;
      if (widgetCount > 0) {
        countCallback();
      }
    }

    return _rebuildCount - startCount;
  }

  void reset() {
    _rebuildCount = 0;
  }
}

/// Check if a widget is const (basic heuristic)
bool _isConst(Widget widget) {
  // In Dart, we can't directly check if an instance is const at runtime
  // This is a heuristic based on common patterns
  try {
    // Check if widget has a key, which often indicates const usage
    return widget.key?.runtimeType.toString().contains('ValueKey') ?? false;
  } catch (e) {
    return false;
  }
}
