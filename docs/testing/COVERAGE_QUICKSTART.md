# Test Coverage Quick Start Guide

**Status:** NOT VERIFIED AND TESTED

Quick reference for developers working with test coverage in Juan Heart Mobile.

---

## One-Line Commands

```bash
# Generate coverage report and open in browser
./scripts/generate_coverage.sh --html --open

# Check if coverage meets thresholds
./scripts/coverage_check.sh

# Generate badge for README
./scripts/coverage_badge.sh

# Generate HTML report only
./scripts/coverage_html.sh --open
```

---

## Common Workflows

### Before Creating a PR

```bash
# 1. Run all tests
flutter test --exclude-tags=integration

# 2. Generate coverage
./scripts/generate_coverage.sh

# 3. Check thresholds
./scripts/coverage_check.sh

# 4. Review coverage report
./scripts/coverage_html.sh --open
```

### Adding Tests for New Code

```bash
# 1. Create test file
touch test/services/my_new_service_test.dart

# 2. Write tests (see template below)

# 3. Run specific test
flutter test test/services/my_new_service_test.dart

# 4. Check coverage
./scripts/generate_coverage.sh --html --open

# 5. Find your file in the HTML report
```

### Improving Low Coverage

```bash
# 1. Generate HTML report
./scripts/generate_coverage.sh --html --open

# 2. Navigate to file with low coverage

# 3. View uncovered lines (highlighted in red)

# 4. Write tests for uncovered code

# 5. Re-run coverage to verify
./scripts/generate_coverage.sh --html --open
```

---

## Test File Template

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Import the class under test
import 'package:juan_heart/services/my_service.dart';

// Create mocks for dependencies
class MockDependency extends Mock implements SomeDependency {}

void main() {
  group('MyService', () {
    late MyService service;
    late MockDependency mockDependency;

    setUp(() {
      mockDependency = MockDependency();
      service = MyService(dependency: mockDependency);
    });

    tearDown(() {
      // Clean up if needed
    });

    group('someMethod', () {
      test('should return success when given valid input', () async {
        // Arrange
        const input = 'valid';
        when(() => mockDependency.someCall(input))
            .thenAnswer((_) async => 'success');

        // Act
        final result = await service.someMethod(input);

        // Assert
        expect(result, equals('success'));
        verify(() => mockDependency.someCall(input)).called(1);
      });

      test('should throw exception when given invalid input', () async {
        // Arrange
        const input = 'invalid';
        when(() => mockDependency.someCall(input))
            .thenThrow(Exception('Invalid input'));

        // Act & Assert
        expect(
          () => service.someMethod(input),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:juan_heart/presentation/pages/my_screen.dart';
import 'package:juan_heart/bloc/my_bloc.dart';

class MockMyBloc extends Mock implements MyBloc {}

void main() {
  group('MyScreen Widget Tests', () {
    late MockMyBloc mockBloc;

    setUp(() {
      mockBloc = MockMyBloc();
      when(() => mockBloc.state).thenReturn(MyInitialState());
      when(() => mockBloc.stream).thenAnswer((_) => Stream.empty());
    });

    testWidgets('should display title when widget loads', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MyBloc>(
            create: (_) => mockBloc,
            child: MyScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('My Screen Title'), findsOneWidget);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      // Arrange
      when(() => mockBloc.state).thenReturn(MyLoadingState());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<MyBloc>(
            create: (_) => mockBloc,
            child: MyScreen(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

---

## Coverage Thresholds

| Level | Minimum | What It Means |
|-------|---------|---------------|
| Critical Paths | 80% | Authentication, Sync, Emergency |
| Services | 75% | Business logic layer |
| UI Widgets | 60% | Presentation layer |
| Overall | 70% | Entire project |

---

## Interpreting Coverage Reports

### HTML Report Colors

- 🟢 **Green** (≥80%) - Good coverage
- 🟡 **Yellow** (60-79%) - Acceptable, but could improve
- 🔴 **Red** (<60%) - Needs attention

### Common Coverage Patterns

| Pattern | What It Means | Action |
|---------|---------------|--------|
| All green | Excellent coverage | Maintain quality |
| Service red | Missing business logic tests | Priority: Write unit tests |
| UI yellow | Widget tests needed | Add widget tests |
| Model red | Serialization untested | Add model tests |

---

## Excluding Code from Coverage

### When to Exclude

- Generated code (already excluded automatically)
- Unreachable code (genuinely impossible to test)
- Platform-specific code that requires manual testing
- Debug-only code

### How to Exclude

```dart
// coverage:ignore-start
void debugOnlyFunction() {
  // This code won't be counted in coverage
}
// coverage:ignore-end

// Single line exclusion
void someFunction() {
  print('Debug message'); // coverage:ignore-line
}
```

**Note:** Use sparingly! Most code should be testable.

---

## Troubleshooting

### "Coverage file not found"

```bash
# Solution: Generate coverage first
flutter test --coverage
./scripts/generate_coverage.sh
```

### "lcov command not found"

```bash
# macOS
brew install lcov

# Linux
sudo apt-get install lcov
```

### "Tests failing"

```bash
# Run tests to see failures
flutter test

# Run specific test file
flutter test test/path/to/failing_test.dart

# Run with verbose output
flutter test --reporter=expanded
```

### "Coverage below threshold"

```bash
# Generate HTML report to see gaps
./scripts/generate_coverage.sh --html --open

# Focus on critical paths first
# Check: docs/testing/coverage_report.md
```

---

## CI/CD Coverage

### PR Coverage Comments

Every PR automatically gets a coverage comment showing:
- Overall coverage percentage
- Coverage delta vs base branch
- Threshold validation status
- Link to full report

### Viewing CI Coverage

1. Go to PR in GitHub
2. Click "Checks" tab
3. Find "Coverage Report" workflow
4. Click "Summary"
5. Download "coverage-report" artifact
6. Extract and open `index.html`

---

## Best Practices

### ✅ Do

- Write tests before or alongside code (TDD)
- Test edge cases and error conditions
- Mock external dependencies
- Focus on behavior, not implementation
- Keep tests simple and readable

### ❌ Don't

- Skip tests for "simple" code
- Test implementation details
- Write brittle tests that break with refactoring
- Aim for 100% at the expense of quality
- Exclude code without good reason

---

## Resources

- [Full Coverage Guide](./coverage_guide.md)
- [Coverage Report & Analysis](./coverage_report.md)
- [Testing Standards](../../.claude/docs/testing-standards.md)
- [Flutter Testing Docs](https://flutter.dev/docs/testing)

---

## Quick Checklist

Before submitting a PR:

- [ ] All new code has unit tests
- [ ] Critical paths maintain ≥80% coverage
- [ ] `flutter test` passes
- [ ] `./scripts/coverage_check.sh` passes
- [ ] Coverage delta is positive or neutral
- [ ] No untested edge cases

---

**Need Help?**

- Review test examples in `test/` directory
- Check existing tests for patterns
- See [Coverage Guide](./coverage_guide.md) for detailed instructions
- Ask team for guidance on complex testing scenarios
