import 'dart:io';
import 'dart:convert';

/// Memory Profile Analyzer
///
/// This tool analyzes memory profiling test results and generates
/// insights about memory usage patterns, hotspots, and optimization opportunities.
///
/// Run with: dart test/performance/memory_analyzer.dart <test_output_file>
void main(List<String> args) async {
  print('========================================');
  print('Juan Heart - Memory Profile Analyzer');
  print('========================================\n');

  if (args.isEmpty) {
    print('Usage: dart test/performance/memory_analyzer.dart <test_output_file>');
    print('Example: dart test/performance/memory_analyzer.dart test_results/memory_profiling/memory_profile_20250104_120000.txt');
    exit(1);
  }

  final inputFile = File(args[0]);
  if (!await inputFile.exists()) {
    print('Error: File not found: ${args[0]}');
    exit(1);
  }

  print('Analyzing: ${inputFile.path}\n');

  final content = await inputFile.readAsString();
  final analyzer = MemoryAnalyzer(content);

  // Perform analysis
  final report = analyzer.analyze();

  // Display report
  print(report.toString());

  // Save detailed report
  final outputFile = File('MEMORY_PROFILE_BASELINE.md');
  await outputFile.writeAsString(report.toMarkdown());

  print('\n✓ Baseline report saved to: MEMORY_PROFILE_BASELINE.md');
}

class MemoryAnalyzer {
  final String testOutput;

  MemoryAnalyzer(this.testOutput);

  AnalysisReport analyze() {
    final report = AnalysisReport();

    // Parse test output
    _extractMetrics(report);
    _identifyHotspots(report);
    _detectLeaks(report);
    _analyzeRebuilds(report);
    _generateRecommendations(report);

    return report;
  }

  void _extractMetrics(AnalysisReport report) {
    // Extract memory values using regex
    final memoryPattern = RegExp(r'Total: (\d+\.\d+) MB');
    final matches = memoryPattern.allMatches(testOutput);

    final memoryValues = <double>[];
    for (final match in matches) {
      final value = double.tryParse(match.group(1) ?? '0');
      if (value != null) {
        memoryValues.add(value);
      }
    }

    if (memoryValues.isNotEmpty) {
      report.minMemoryMB = memoryValues.reduce((a, b) => a < b ? a : b);
      report.maxMemoryMB = memoryValues.reduce((a, b) => a > b ? a : b);
      report.avgMemoryMB = memoryValues.reduce((a, b) => a + b) / memoryValues.length;
      report.memoryRangeMB = report.maxMemoryMB - report.minMemoryMB;
    }

    // Extract specific test results
    _extractTestResult(report, 'Cold Start Memory Impact', 'coldStartImpactMB');
    _extractTestResult(report, 'Idle Memory Growth', 'idleGrowthMB');
    _extractTestResult(report, 'Memory Retained After Flow', 'assessmentRetainedMB');
    _extractTestResult(report, 'Navigation Overhead', 'navigationOverheadMB');
    _extractTestResult(report, 'Total Growth', 'leakTestGrowthMB');
  }

  void _extractTestResult(AnalysisReport report, String label, String field) {
    final pattern = RegExp('$label: ([\\d.]+) MB');
    final match = pattern.firstMatch(testOutput);
    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '0') ?? 0;
      switch (field) {
        case 'coldStartImpactMB':
          report.coldStartImpactMB = value;
          break;
        case 'idleGrowthMB':
          report.idleGrowthMB = value;
          break;
        case 'assessmentRetainedMB':
          report.assessmentRetainedMB = value;
          break;
        case 'navigationOverheadMB':
          report.navigationOverheadMB = value;
          break;
        case 'leakTestGrowthMB':
          report.leakTestGrowthMB = value;
          break;
      }
    }
  }

  void _identifyHotspots(AnalysisReport report) {
    // Check for memory hotspots
    if (report.coldStartImpactMB > 80) {
      report.hotspots.add(MemoryHotspot(
        location: 'App Cold Start',
        memoryUsageMB: report.coldStartImpactMB,
        severity: Severity.high,
        description: 'Cold start uses excessive memory. Check initial widget tree and service initialization.',
      ));
    }

    if (report.assessmentRetainedMB > 15) {
      report.hotspots.add(MemoryHotspot(
        location: 'Assessment Flow',
        memoryUsageMB: report.assessmentRetainedMB,
        severity: Severity.high,
        description: 'Assessment flow retains too much memory after completion. Check for widget/BLoC disposal.',
      ));
    }

    if (report.navigationOverheadMB > 15) {
      report.hotspots.add(MemoryHotspot(
        location: 'Navigation',
        memoryUsageMB: report.navigationOverheadMB,
        severity: Severity.medium,
        description: 'Navigation retains memory. Verify route disposal and widget cleanup.',
      ));
    }

    // Parse peak memory location
    final peakPattern = RegExp(r'Peak Location: (.+)');
    final peakMatch = peakPattern.firstMatch(testOutput);
    if (peakMatch != null && report.maxMemoryMB > 180) {
      report.hotspots.add(MemoryHotspot(
        location: peakMatch.group(1) ?? 'Unknown',
        memoryUsageMB: report.maxMemoryMB,
        severity: Severity.high,
        description: 'Peak memory exceeds target. Investigate this specific operation.',
      ));
    }
  }

  void _detectLeaks(AnalysisReport report) {
    // Check for memory leaks
    if (report.leakTestGrowthMB > 15) {
      report.leaks.add(MemoryLeak(
        description: '10-minute session memory growth exceeds threshold',
        growthMB: report.leakTestGrowthMB,
        severity: Severity.critical,
        likelySource: 'Event listeners, timers, or streams not disposed',
      ));
    }

    if (report.idleGrowthMB > 10) {
      report.leaks.add(MemoryLeak(
        description: 'Idle state memory growth detected',
        growthMB: report.idleGrowthMB,
        severity: Severity.medium,
        likelySource: 'Background processes or periodic tasks',
      ));
    }

    // Check for trend
    final trendPattern = RegExp(r'Memory Trend: (\w+).*slope: ([\d.-]+)');
    final trendMatch = trendPattern.firstMatch(testOutput);
    if (trendMatch != null) {
      final trend = trendMatch.group(1);
      final slope = double.tryParse(trendMatch.group(2) ?? '0') ?? 0;

      if (trend == 'Increasing' && slope > 1.0) {
        report.leaks.add(MemoryLeak(
          description: 'Memory shows increasing trend over time',
          growthMB: slope * 10, // Projected growth over 10 minutes
          severity: Severity.high,
          likelySource: 'Gradual memory accumulation - check caches and lists',
        ));
      }
    }
  }

  void _analyzeRebuilds(AnalysisReport report) {
    // Extract rebuild counts
    final rebuildPattern = RegExp(r'rebuilds.*?(\d+)');
    final matches = rebuildPattern.allMatches(testOutput.toLowerCase());

    final rebuildCounts = <int>[];
    for (final match in matches) {
      final count = int.tryParse(match.group(1) ?? '0');
      if (count != null && count > 0) {
        rebuildCounts.add(count);
      }
    }

    if (rebuildCounts.isNotEmpty) {
      final maxRebuilds = rebuildCounts.reduce((a, b) => a > b ? a : b);
      final avgRebuilds = rebuildCounts.reduce((a, b) => a + b) / rebuildCounts.length;

      report.maxRebuilds = maxRebuilds;
      report.avgRebuilds = avgRebuilds;

      if (maxRebuilds > 50) {
        report.rebuildIssues.add(
          'Excessive rebuilds detected (max: $maxRebuilds). Check for missing const constructors and BLoC stream usage.'
        );
      }

      if (avgRebuilds > 20) {
        report.rebuildIssues.add(
          'High average rebuild count ($avgRebuilds). Consider using const widgets and Equatable in BLoC states.'
        );
      }
    }

    // Check for const violations
    if (testOutput.contains('const constructor violations')) {
      final violationPattern = RegExp(r'Total unique violations: (\d+)');
      final match = violationPattern.firstMatch(testOutput);
      if (match != null) {
        final count = int.tryParse(match.group(1) ?? '0') ?? 0;
        report.constViolations = count;
        if (count > 0) {
          report.rebuildIssues.add(
            '$count widgets could use const constructors. Add const to reduce rebuilds.'
          );
        }
      }
    }
  }

  void _generateRecommendations(AnalysisReport report) {
    // Generate recommendations based on findings
    if (report.hotspots.isNotEmpty) {
      report.recommendations.add(
        Recommendation(
          priority: Priority.high,
          category: 'Memory Hotspots',
          action: 'Optimize identified memory hotspots',
          details: 'Focus on: ${report.hotspots.map((h) => h.location).join(", ")}',
          expectedImpact: 'Reduce peak memory by 20-40MB',
        )
      );
    }

    if (report.leaks.isNotEmpty) {
      report.recommendations.add(
        Recommendation(
          priority: Priority.critical,
          category: 'Memory Leaks',
          action: 'Fix memory leaks',
          details: report.leaks.map((l) => l.description).join('; '),
          expectedImpact: 'Prevent memory growth over time',
        )
      );
    }

    if (report.constViolations > 10) {
      report.recommendations.add(
        Recommendation(
          priority: Priority.medium,
          category: 'Widget Optimization',
          action: 'Add const constructors to ${report.constViolations} widgets',
          details: 'Use const for StatelessWidgets with immutable properties',
          expectedImpact: 'Reduce rebuilds by 30-50%',
        )
      );
    }

    if (report.coldStartImpactMB > 80) {
      report.recommendations.add(
        Recommendation(
          priority: Priority.high,
          category: 'Startup Optimization',
          action: 'Reduce cold start memory footprint',
          details: 'Defer service initialization, lazy-load widgets, optimize initial route',
          expectedImpact: 'Reduce cold start from ${report.coldStartImpactMB.toStringAsFixed(0)}MB to <70MB',
        )
      );
    }

    if (report.assessmentRetainedMB > 15) {
      report.recommendations.add(
        Recommendation(
          priority: Priority.high,
          category: 'Resource Cleanup',
          action: 'Improve assessment flow cleanup',
          details: 'Ensure BLoC streams are closed, controllers disposed, and listeners removed',
          expectedImpact: 'Reduce retained memory by 10-15MB',
        )
      );
    }

    // Always add general best practices
    report.recommendations.add(
      Recommendation(
        priority: Priority.low,
        category: 'Best Practices',
        action: 'Implement general memory optimizations',
        details: 'Use image caching, pagination for lists, and dispose patterns consistently',
        expectedImpact: 'Improve overall memory stability',
      )
    );
  }
}

class AnalysisReport {
  // Memory metrics
  double minMemoryMB = 0;
  double maxMemoryMB = 0;
  double avgMemoryMB = 0;
  double memoryRangeMB = 0;

  // Test-specific metrics
  double coldStartImpactMB = 0;
  double idleGrowthMB = 0;
  double assessmentRetainedMB = 0;
  double navigationOverheadMB = 0;
  double leakTestGrowthMB = 0;

  // Rebuild metrics
  int maxRebuilds = 0;
  double avgRebuilds = 0;
  int constViolations = 0;

  // Findings
  List<MemoryHotspot> hotspots = [];
  List<MemoryLeak> leaks = [];
  List<String> rebuildIssues = [];
  List<Recommendation> recommendations = [];

  @override
  String toString() {
    final buffer = StringBuffer();

    buffer.writeln('--- ANALYSIS SUMMARY ---\n');

    buffer.writeln('Memory Metrics:');
    buffer.writeln('  Min Memory: ${minMemoryMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Max Memory: ${maxMemoryMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Avg Memory: ${avgMemoryMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Range: ${memoryRangeMB.toStringAsFixed(2)} MB');
    buffer.writeln('');

    buffer.writeln('Test Results:');
    buffer.writeln('  Cold Start Impact: ${coldStartImpactMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Idle Growth (30s): ${idleGrowthMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Assessment Retained: ${assessmentRetainedMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Navigation Overhead: ${navigationOverheadMB.toStringAsFixed(2)} MB');
    buffer.writeln('  Leak Test Growth: ${leakTestGrowthMB.toStringAsFixed(2)} MB');
    buffer.writeln('');

    if (maxRebuilds > 0) {
      buffer.writeln('Rebuild Metrics:');
      buffer.writeln('  Max Rebuilds: $maxRebuilds');
      buffer.writeln('  Avg Rebuilds: ${avgRebuilds.toStringAsFixed(1)}');
      buffer.writeln('  Const Violations: $constViolations');
      buffer.writeln('');
    }

    if (hotspots.isNotEmpty) {
      buffer.writeln('Memory Hotspots:');
      for (final hotspot in hotspots) {
        buffer.writeln('  [${hotspot.severity.name.toUpperCase()}] ${hotspot.location}');
        buffer.writeln('    Usage: ${hotspot.memoryUsageMB.toStringAsFixed(2)} MB');
        buffer.writeln('    ${hotspot.description}');
      }
      buffer.writeln('');
    }

    if (leaks.isNotEmpty) {
      buffer.writeln('Memory Leaks:');
      for (final leak in leaks) {
        buffer.writeln('  [${leak.severity.name.toUpperCase()}] ${leak.description}');
        buffer.writeln('    Growth: ${leak.growthMB.toStringAsFixed(2)} MB');
        buffer.writeln('    Likely Source: ${leak.likelySource}');
      }
      buffer.writeln('');
    }

    if (rebuildIssues.isNotEmpty) {
      buffer.writeln('Rebuild Issues:');
      for (final issue in rebuildIssues) {
        buffer.writeln('  - $issue');
      }
      buffer.writeln('');
    }

    if (recommendations.isNotEmpty) {
      buffer.writeln('Recommendations:');
      recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      for (final rec in recommendations) {
        buffer.writeln('  [${rec.priority.name.toUpperCase()}] ${rec.category}: ${rec.action}');
        buffer.writeln('    Details: ${rec.details}');
        buffer.writeln('    Impact: ${rec.expectedImpact}');
      }
    }

    return buffer.toString();
  }

  String toMarkdown() {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('# Memory Profile Baseline Report');
    buffer.writeln('**Juan Heart Mobile - Performance Optimization Phase 2**\n');
    buffer.writeln('**Generated:** ${now.toIso8601String()}');
    buffer.writeln('**Test Suite:** Memory Profiling v1.0\n');

    buffer.writeln('---\n');

    buffer.writeln('## Executive Summary\n');
    buffer.writeln('This baseline report establishes memory usage metrics for Juan Heart Mobile before optimization.');
    buffer.writeln('Key findings:\n');

    if (maxMemoryMB > 0) {
      final status = maxMemoryMB < 150 ? '✓ GOOD' : maxMemoryMB < 200 ? '⚠️ ACCEPTABLE' : '❌ NEEDS OPTIMIZATION';
      buffer.writeln('- **Peak Memory:** ${maxMemoryMB.toStringAsFixed(2)} MB $status');
    }

    if (leaks.isNotEmpty) {
      buffer.writeln('- **Memory Leaks:** ${leaks.length} detected ❌ CRITICAL');
    } else {
      buffer.writeln('- **Memory Leaks:** None detected ✓ GOOD');
    }

    if (hotspots.isNotEmpty) {
      buffer.writeln('- **Hotspots:** ${hotspots.length} identified');
    }

    buffer.writeln('');

    buffer.writeln('---\n');

    buffer.writeln('## Memory Metrics\n');
    buffer.writeln('### Overall Statistics\n');
    buffer.writeln('| Metric | Value | Target | Status |');
    buffer.writeln('|--------|-------|--------|--------|');
    buffer.writeln('| Min Memory | ${minMemoryMB.toStringAsFixed(2)} MB | - | - |');
    buffer.writeln('| Max Memory | ${maxMemoryMB.toStringAsFixed(2)} MB | <200 MB | ${maxMemoryMB < 200 ? "✓" : "❌"} |');
    buffer.writeln('| Avg Memory | ${avgMemoryMB.toStringAsFixed(2)} MB | <150 MB | ${avgMemoryMB < 150 ? "✓" : "❌"} |');
    buffer.writeln('| Memory Range | ${memoryRangeMB.toStringAsFixed(2)} MB | <100 MB | ${memoryRangeMB < 100 ? "✓" : "❌"} |');
    buffer.writeln('');

    buffer.writeln('### Test-Specific Metrics\n');
    buffer.writeln('| Test | Result | Target | Status |');
    buffer.writeln('|------|--------|--------|--------|');
    buffer.writeln('| Cold Start Impact | ${coldStartImpactMB.toStringAsFixed(2)} MB | <100 MB | ${coldStartImpactMB < 100 ? "✓" : "❌"} |');
    buffer.writeln('| Idle Growth (30s) | ${idleGrowthMB.toStringAsFixed(2)} MB | <10 MB | ${idleGrowthMB < 10 ? "✓" : "❌"} |');
    buffer.writeln('| Assessment Retained | ${assessmentRetainedMB.toStringAsFixed(2)} MB | <20 MB | ${assessmentRetainedMB < 20 ? "✓" : "❌"} |');
    buffer.writeln('| Navigation Overhead | ${navigationOverheadMB.toStringAsFixed(2)} MB | <20 MB | ${navigationOverheadMB < 20 ? "✓" : "❌"} |');
    buffer.writeln('| Leak Test Growth (10min) | ${leakTestGrowthMB.toStringAsFixed(2)} MB | <15 MB | ${leakTestGrowthMB < 15 ? "✓" : "❌"} |');
    buffer.writeln('');

    if (maxRebuilds > 0) {
      buffer.writeln('### Widget Rebuild Metrics\n');
      buffer.writeln('| Metric | Value | Target | Status |');
      buffer.writeln('|--------|-------|--------|--------|');
      buffer.writeln('| Max Rebuilds | $maxRebuilds | <50 | ${maxRebuilds < 50 ? "✓" : "❌"} |');
      buffer.writeln('| Avg Rebuilds | ${avgRebuilds.toStringAsFixed(1)} | <20 | ${avgRebuilds < 20 ? "✓" : "❌"} |');
      buffer.writeln('| Const Violations | $constViolations | 0 | ${constViolations == 0 ? "✓" : "⚠️"} |');
      buffer.writeln('');
    }

    buffer.writeln('---\n');

    if (hotspots.isNotEmpty) {
      buffer.writeln('## Memory Hotspots\n');
      for (final hotspot in hotspots) {
        buffer.writeln('### ${hotspot.location}\n');
        buffer.writeln('- **Severity:** ${hotspot.severity.name.toUpperCase()}');
        buffer.writeln('- **Memory Usage:** ${hotspot.memoryUsageMB.toStringAsFixed(2)} MB');
        buffer.writeln('- **Description:** ${hotspot.description}\n');
      }
      buffer.writeln('---\n');
    }

    if (leaks.isNotEmpty) {
      buffer.writeln('## Memory Leaks\n');
      for (final leak in leaks) {
        buffer.writeln('### ${leak.description}\n');
        buffer.writeln('- **Severity:** ${leak.severity.name.toUpperCase()}');
        buffer.writeln('- **Growth:** ${leak.growthMB.toStringAsFixed(2)} MB');
        buffer.writeln('- **Likely Source:** ${leak.likelySource}\n');
      }
      buffer.writeln('---\n');
    }

    if (rebuildIssues.isNotEmpty) {
      buffer.writeln('## Widget Rebuild Issues\n');
      for (final issue in rebuildIssues) {
        buffer.writeln('- $issue');
      }
      buffer.writeln('\n---\n');
    }

    buffer.writeln('## Optimization Recommendations\n');
    recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    for (final priority in Priority.values.reversed) {
      final recs = recommendations.where((r) => r.priority == priority).toList();
      if (recs.isEmpty) continue;

      buffer.writeln('### ${priority.name.toUpperCase()} Priority\n');
      for (final rec in recs) {
        buffer.writeln('#### ${rec.category}: ${rec.action}\n');
        buffer.writeln('**Details:** ${rec.details}\n');
        buffer.writeln('**Expected Impact:** ${rec.expectedImpact}\n');
      }
    }

    buffer.writeln('---\n');

    buffer.writeln('## Next Steps\n');
    buffer.writeln('1. Address critical memory leaks (if any)');
    buffer.writeln('2. Optimize identified hotspots');
    buffer.writeln('3. Implement const constructor fixes');
    buffer.writeln('4. Re-run profiling to measure improvements');
    buffer.writeln('5. Target: <150MB peak, <10MB idle growth, 0 leaks\n');

    buffer.writeln('---\n');
    buffer.writeln('**Report Generated By:** JH-QA-Guardian Memory Profiler');
    buffer.writeln('**Version:** 1.0');

    return buffer.toString();
  }
}

class MemoryHotspot {
  final String location;
  final double memoryUsageMB;
  final Severity severity;
  final String description;

  MemoryHotspot({
    required this.location,
    required this.memoryUsageMB,
    required this.severity,
    required this.description,
  });
}

class MemoryLeak {
  final String description;
  final double growthMB;
  final Severity severity;
  final String likelySource;

  MemoryLeak({
    required this.description,
    required this.growthMB,
    required this.severity,
    required this.likelySource,
  });
}

class Recommendation {
  final Priority priority;
  final String category;
  final String action;
  final String details;
  final String expectedImpact;

  Recommendation({
    required this.priority,
    required this.category,
    required this.action,
    required this.details,
    required this.expectedImpact,
  });
}

enum Severity { low, medium, high, critical }
enum Priority { low, medium, high, critical }
