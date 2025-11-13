import 'package:flutter/material.dart';

/// Juan Heart Responsive Grid System
/// Material Design 3 compliant grid system with breakpoints
///
/// Usage:
/// ```dart
/// // Get column width for a 2-column span
/// double width = JHGrid.columnWidth(context, 2);
///
/// // Check if device is tablet
/// bool isTablet = JHGrid.isTablet(context);
///
/// // Get responsive value
/// double padding = JHGrid.responsive(
///   context,
///   mobile: 16.0,
///   tablet: 24.0,
/// );
/// ```
class JHGrid {
  JHGrid._(); // Private constructor to prevent instantiation

  // Grid Configuration

  /// Standard gutter width between columns
  static const double gutter = 16.0;

  /// Number of columns for phone layouts
  static const int columnsPhone = 4;

  /// Number of columns for tablet layouts
  static const int columnsTablet = 8;

  /// Number of columns for desktop layouts
  static const int columnsDesktop = 12;

  // Breakpoints (Material Design 3)

  /// Small phone breakpoint (compact)
  static const double breakpointCompact = 0;

  /// Medium phone/small tablet breakpoint
  static const double breakpointMedium = 600;

  /// Tablet/small desktop breakpoint
  static const double breakpointExpanded = 840;

  /// Desktop/large screen breakpoint
  static const double breakpointLarge = 1200;

  /// Extra large screen breakpoint
  static const double breakpointExtraLarge = 1600;

  // Column Width Calculation

  /// Calculate the width of a column span based on screen size
  ///
  /// [context] - BuildContext for MediaQuery access
  /// [span] - Number of columns to span (1 to max columns)
  ///
  /// Returns the calculated width including gutters
  static double columnWidth(BuildContext context, int span) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = _getColumns(screenWidth);
    final gutterTotal = gutter * (columns - 1);
    final columnWidth = (screenWidth - gutterTotal) / columns;
    return columnWidth * span + (gutter * (span - 1));
  }

  /// Get number of columns based on screen width
  static int _getColumns(double screenWidth) {
    if (screenWidth >= breakpointLarge) {
      return columnsDesktop;
    } else if (screenWidth >= breakpointMedium) {
      return columnsTablet;
    } else {
      return columnsPhone;
    }
  }

  /// Get current number of columns for the screen
  static int getColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return _getColumns(screenWidth);
  }

  // Responsive Helpers

  /// Check if device is in compact layout (phone)
  static bool isCompact(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < breakpointMedium;
  }

  /// Check if device is in medium layout (large phone/small tablet)
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointMedium && width < breakpointExpanded;
  }

  /// Check if device is in expanded layout (tablet)
  static bool isExpanded(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointExpanded && width < breakpointLarge;
  }

  /// Check if device is in large layout (desktop)
  static bool isLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointLarge && width < breakpointExtraLarge;
  }

  /// Check if device is in extra large layout
  static bool isExtraLarge(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointExtraLarge;
  }

  /// Simplified tablet check (medium or larger)
  static bool isTablet(BuildContext context) {
    return !isCompact(context);
  }

  /// Simplified desktop check (expanded or larger)
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= breakpointExpanded;
  }

  // Responsive Value Helpers

  /// Get a responsive value based on screen size
  ///
  /// Provides different values for mobile, tablet, and desktop
  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsive(
      context: context,
      mobile: const EdgeInsets.all(16.0),
      tablet: const EdgeInsets.all(24.0),
      desktop: const EdgeInsets.all(32.0),
    );
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    return responsive(
      context: context,
      mobile: const EdgeInsets.symmetric(horizontal: 16.0),
      tablet: const EdgeInsets.symmetric(horizontal: 24.0),
      desktop: const EdgeInsets.symmetric(horizontal: 32.0),
    );
  }

  /// Get responsive content width (max width for centered content)
  static double? responsiveContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200.0; // Max width for desktop
    } else if (isTablet(context)) {
      return 840.0; // Max width for tablet
    }
    return null; // Full width for mobile
  }

  // Grid Margin (Outer margins)

  /// Get responsive grid margin
  static EdgeInsets gridMargin(BuildContext context) {
    return responsive(
      context: context,
      mobile: const EdgeInsets.symmetric(horizontal: 16.0),
      tablet: const EdgeInsets.symmetric(horizontal: 24.0),
      desktop: const EdgeInsets.symmetric(horizontal: 32.0),
    );
  }

  // Common Layout Helpers

  /// Get crossAxisCount for GridView based on screen size
  static int gridCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    return responsive(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile * 2,
      desktop: desktop ?? tablet ?? mobile * 3,
    );
  }

  /// Get childAspectRatio for GridView based on screen size
  static double gridChildAspectRatio(BuildContext context, {
    double mobile = 1.0,
    double? tablet,
    double? desktop,
  }) {
    return responsive(
      context: context,
      mobile: mobile,
      tablet: tablet ?? mobile,
      desktop: desktop ?? tablet ?? mobile,
    );
  }

  /// Get number of columns for a responsive row
  static int rowColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  /// Calculate item width for responsive lists
  static double listItemWidth(BuildContext context) {
    final columns = rowColumns(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final margins = gridMargin(context).horizontal;
    final totalGutters = gutter * (columns - 1);
    return (screenWidth - margins - totalGutters) / columns;
  }
}

/// Extension on BuildContext for convenient grid access
extension GridExtension on BuildContext {
  /// Check if current layout is compact (mobile)
  bool get isCompact => JHGrid.isCompact(this);

  /// Check if current layout is medium (large phone/small tablet)
  bool get isMedium => JHGrid.isMedium(this);

  /// Check if current layout is expanded (tablet)
  bool get isExpanded => JHGrid.isExpanded(this);

  /// Check if current layout is large (desktop)
  bool get isLarge => JHGrid.isLarge(this);

  /// Check if current layout is tablet or larger
  bool get isTablet => JHGrid.isTablet(this);

  /// Check if current layout is desktop or larger
  bool get isDesktop => JHGrid.isDesktop(this);

  /// Get responsive grid margin
  EdgeInsets get gridMargin => JHGrid.gridMargin(this);

  /// Get responsive padding
  EdgeInsets get responsivePadding => JHGrid.responsivePadding(this);

  /// Get current number of grid columns
  int get gridColumns => JHGrid.getColumns(this);
}
