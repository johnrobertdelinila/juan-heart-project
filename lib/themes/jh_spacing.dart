import 'package:flutter/material.dart';

/// Juan Heart Spacing System
/// 4px-based spacing scale following Material Design 3 principles
///
/// Usage:
/// - Use predefined constants for consistent spacing
/// - Prefer semantic padding patterns (buttonPadding, cardPadding, etc.)
/// - For custom spacing, use multiples of 4px
class JHSpacing {
  JHSpacing._(); // Private constructor to prevent instantiation

  // Base Spacing Scale (4px increments)
  static const double xs = 4.0;    // Tight spacing
  static const double sm = 8.0;    // Compact spacing
  static const double md = 12.0;   // Default spacing
  static const double base = 16.0; // Standard spacing (1rem equivalent)
  static const double lg = 20.0;   // Medium spacing
  static const double xl = 24.0;   // Large spacing
  static const double xl2 = 32.0;  // Extra large spacing
  static const double xl3 = 40.0;  // Section spacing
  static const double xl4 = 48.0;  // Major section spacing
  static const double xl5 = 64.0;  // Page-level spacing

  // Common Padding Patterns

  /// Standard button padding: 24px horizontal, 12px vertical
  /// Ensures minimum 44x44 touch target when combined with text
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 12.0,
  );

  /// Large button padding for primary actions
  static const EdgeInsets buttonPaddingLarge = EdgeInsets.symmetric(
    horizontal: 32.0,
    vertical: 16.0,
  );

  /// Small button padding for secondary/tertiary actions
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );

  /// Standard card padding: 20px all around
  /// Provides comfortable spacing for card content
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);

  /// Compact card padding for dense layouts
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(16.0);

  /// Large card padding for prominent cards
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);

  /// Screen padding: 16px horizontal
  /// Applied to screen edges for content containment
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);

  /// Screen padding horizontal only
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: 16.0,
  );

  /// Screen padding vertical only
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: 16.0,
  );

  /// List item padding: 16px horizontal, 12px vertical
  /// Standard padding for list items and tiles
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 12.0,
  );

  /// Dense list item padding for compact lists
  static const EdgeInsets listItemPaddingDense = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8.0,
  );

  /// Form field padding: 12px horizontal, 16px vertical
  static const EdgeInsets formFieldPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 16.0,
  );

  /// Dialog padding: 24px all around
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);

  /// Dialog content padding (excludes title and actions)
  static const EdgeInsets dialogContentPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 20.0,
  );

  /// Bottom sheet padding: 16px all around
  static const EdgeInsets bottomSheetPadding = EdgeInsets.all(16.0);

  /// App bar padding: 16px horizontal
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
  );

  /// Section padding: 24px vertical spacing between major sections
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    vertical: 24.0,
  );

  // Gap Helpers (for use with Gap widget or SizedBox)

  /// Extra small gap: 4px
  static const double gapXs = xs;

  /// Small gap: 8px
  static const double gapSm = sm;

  /// Medium gap: 12px
  static const double gapMd = md;

  /// Base gap: 16px
  static const double gapBase = base;

  /// Large gap: 24px
  static const double gapLg = xl;

  /// Extra large gap: 32px
  static const double gapXl = xl2;

  // Minimum Touch Target Size (Accessibility)

  /// Minimum touch target size per Material Design (44x44)
  static const double minTouchTarget = 44.0;

  /// Recommended touch target size for primary actions (48x48)
  static const double touchTargetRecommended = 48.0;

  // Common Combinations

  /// Standard spacing between form fields
  static const double formFieldSpacing = xl;

  /// Standard spacing between sections
  static const double sectionSpacing = xl3;

  /// Standard spacing between content items
  static const double contentItemSpacing = base;

  /// Standard spacing for list item separation
  static const double listItemSpacing = sm;
}
