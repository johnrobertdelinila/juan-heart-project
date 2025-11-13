import 'package:flutter/material.dart';

/// Juan Heart Border Radius System
/// Consistent border radius constants for UI elements
///
/// Follows Material Design 3 shape guidelines with healthcare-appropriate
/// curvature for professional medical interfaces.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: JHRadius.radiusBase,
///   ),
/// )
///
/// // Or use the value directly
/// BorderRadius.circular(JHRadius.base)
/// ```
class JHRadius {
  JHRadius._(); // Private constructor to prevent instantiation

  // ============================================================
  // RADIUS VALUES (4px increments)
  // ============================================================

  /// No radius (sharp corners)
  /// Usage: Table cells, data grids, strict layouts
  static const double none = 0;

  /// Extra small radius: 4px
  /// Usage: Chips, tags, small indicators
  static const double xs = 4.0;

  /// Small radius: 6px
  /// Usage: Badges, small buttons, compact elements
  static const double sm = 6.0;

  /// Medium radius: 8px
  /// Usage: Input fields, small cards, list items
  static const double md = 8.0;

  /// Base radius: 12px
  /// Usage: Buttons, standard cards, dialogs (PRIMARY STANDARD)
  static const double base = 12.0;

  /// Large radius: 16px
  /// Usage: Large cards, modals, prominent containers
  static const double lg = 16.0;

  /// Extra large radius: 20px
  /// Usage: Bottom sheets, navigation drawers, hero cards
  static const double xl = 20.0;

  /// Double extra large radius: 24px
  /// Usage: Floating action buttons, pill buttons (when combined with full)
  static const double xl2 = 24.0;

  /// Full radius: 999px
  /// Usage: Circular elements, pill buttons, avatars
  /// Note: Use a very large value to create perfect circles/pills
  static const double full = 999.0;

  // ============================================================
  // BORDERRADIUS PRESETS
  // ============================================================

  /// No radius (sharp corners)
  static const BorderRadius radiusNone = BorderRadius.zero;

  /// Extra small radius: 4px
  static BorderRadius radiusXs = BorderRadius.circular(xs);

  /// Small radius: 6px
  static BorderRadius radiusSm = BorderRadius.circular(sm);

  /// Medium radius: 8px
  static BorderRadius radiusMd = BorderRadius.circular(md);

  /// Base radius: 12px (PRIMARY STANDARD)
  static BorderRadius radiusBase = BorderRadius.circular(base);

  /// Large radius: 16px
  static BorderRadius radiusLg = BorderRadius.circular(lg);

  /// Extra large radius: 20px
  static BorderRadius radiusXl = BorderRadius.circular(xl);

  /// Double extra large radius: 24px
  static BorderRadius radiusXl2 = BorderRadius.circular(xl2);

  /// Full radius (circular/pill shape)
  static BorderRadius radiusFull = BorderRadius.circular(full);

  // ============================================================
  // DIRECTIONAL RADIUS PRESETS
  // ============================================================

  /// Top-only radius (for bottom sheets, dropdowns)
  /// Uses XL radius (20px) for prominent top corners
  static const BorderRadius radiusTop = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );

  /// Top-only radius with base value (12px)
  static const BorderRadius radiusTopBase = BorderRadius.only(
    topLeft: Radius.circular(base),
    topRight: Radius.circular(base),
  );

  /// Bottom-only radius (for top bars, headers)
  /// Uses base radius (12px)
  static const BorderRadius radiusBottom = BorderRadius.only(
    bottomLeft: Radius.circular(base),
    bottomRight: Radius.circular(base),
  );

  /// Bottom-only radius with XL value (20px)
  static const BorderRadius radiusBottomXl = BorderRadius.only(
    bottomLeft: Radius.circular(xl),
    bottomRight: Radius.circular(xl),
  );

  /// Left-only radius (for right-side panels)
  static const BorderRadius radiusLeft = BorderRadius.only(
    topLeft: Radius.circular(base),
    bottomLeft: Radius.circular(base),
  );

  /// Right-only radius (for left-side panels)
  static const BorderRadius radiusRight = BorderRadius.only(
    topRight: Radius.circular(base),
    bottomRight: Radius.circular(base),
  );

  // ============================================================
  // COMPONENT-SPECIFIC RADIUS
  // ============================================================

  /// Button radius: 12px
  /// Standard for all button types
  static BorderRadius buttonRadius = radiusBase;

  /// Card radius: 12px
  /// Standard for content cards
  static BorderRadius cardRadius = radiusBase;

  /// Dialog radius: 16px
  /// Larger radius for modals and dialogs
  static BorderRadius dialogRadius = radiusLg;

  /// Bottom sheet radius: 20px (top corners only)
  /// Prominent top corners for bottom sheets
  static const BorderRadius bottomSheetRadius = radiusTop;

  /// Input field radius: 8px
  /// Slightly smaller for form inputs
  static BorderRadius inputRadius = radiusMd;

  /// Chip radius: 20px (pill shape)
  /// Full radius for chip elements
  static BorderRadius chipRadius = radiusXl;

  /// Badge radius: 12px
  /// Base radius for badges
  static BorderRadius badgeRadius = radiusBase;

  /// Avatar radius: Full (circular)
  /// Perfect circle for profile pictures
  static BorderRadius avatarRadius = radiusFull;

  /// Profile card radius: 15px (legacy compatibility)
  /// Matches existing Profile screen design
  /// TODO: Gradually migrate to `base` (12px)
  static BorderRadius profileCardRadius = BorderRadius.circular(15.0);

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Create custom radius for specific corners
  ///
  /// Example:
  /// ```dart
  /// var customRadius = JHRadius.custom(
  ///   topLeft: 12.0,
  ///   topRight: 12.0,
  ///   bottomLeft: 0,
  ///   bottomRight: 0,
  /// );
  /// ```
  static BorderRadius custom({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  /// Create radius for only top corners
  ///
  /// Example:
  /// ```dart
  /// var topRadius = JHRadius.onlyTop(16.0);
  /// ```
  static BorderRadius onlyTop(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Create radius for only bottom corners
  ///
  /// Example:
  /// ```dart
  /// var bottomRadius = JHRadius.onlyBottom(16.0);
  /// ```
  static BorderRadius onlyBottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  /// Create radius for only left corners
  ///
  /// Example:
  /// ```dart
  /// var leftRadius = JHRadius.onlyLeft(16.0);
  /// ```
  static BorderRadius onlyLeft(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }

  /// Create radius for only right corners
  ///
  /// Example:
  /// ```dart
  /// var rightRadius = JHRadius.onlyRight(16.0);
  /// ```
  static BorderRadius onlyRight(double radius) {
    return BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
}

/// Extension on num for convenient radius creation
extension RadiusExtension on num {
  /// Convert number to Radius
  ///
  /// Example:
  /// ```dart
  /// 12.0.toRadius() // Radius.circular(12.0)
  /// ```
  Radius get toRadius => Radius.circular(toDouble());

  /// Convert number to BorderRadius
  ///
  /// Example:
  /// ```dart
  /// 12.0.toBorderRadius() // BorderRadius.circular(12.0)
  /// ```
  BorderRadius get toBorderRadius => BorderRadius.circular(toDouble());
}
