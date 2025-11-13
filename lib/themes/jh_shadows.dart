import 'package:flutter/material.dart';

/// Juan Heart Shadow System
/// Material Design 3 elevation system with clinically-appropriate shadows
///
/// Shadows provide depth hierarchy and visual separation for UI elements.
/// All shadows follow Material Design 3 elevation specifications with
/// adjustments for healthcare readability.
///
/// Usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     color: Colors.white,
///     borderRadius: BorderRadius.circular(12),
///     boxShadow: JHShadows.md,
///   ),
/// )
/// ```
class JHShadows {
  JHShadows._(); // Private constructor to prevent instantiation

  // ============================================================
  // ELEVATION LEVELS (Material Design 3)
  // ============================================================

  /// No shadow (Elevation 0)
  /// Usage: Inline elements, text, icons
  static const List<BoxShadow> none = [];

  /// Extra small shadow (Elevation 1)
  /// Usage: Chips, tags, small cards
  /// Opacity: 5% black
  /// Blur: 2px, Offset: (0, 1)
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 2.0,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Small shadow (Elevation 2)
  /// Usage: Buttons, compact cards, list items
  /// Opacity: 10% black
  /// Blur: 3px, Spread: 1px, Offset: (0, 1)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 3.0,
      spreadRadius: 1.0,
      offset: Offset(0, 1),
    ),
  ];

  /// Medium shadow (Elevation 3)
  /// Usage: Standard cards, dropdowns, tooltips
  /// Opacity: 10% black
  /// Blur: 6px, Spread: -1px, Offset: (0, 4)
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 6.0,
      spreadRadius: -1.0,
      offset: Offset(0, 4),
    ),
  ];

  /// Large shadow (Elevation 4)
  /// Usage: Dialogs, modals, floating action buttons
  /// Opacity: 15% black
  /// Blur: 15px, Spread: -3px, Offset: (0, 10)
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 15.0,
      spreadRadius: -3.0,
      offset: Offset(0, 10),
    ),
  ];

  /// Extra large shadow (Elevation 5)
  /// Usage: Navigation drawers, bottom sheets, prominent modals
  /// Opacity: 20% black
  /// Blur: 25px, Spread: -5px, Offset: (0, 20)
  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      blurRadius: 25.0,
      spreadRadius: -5.0,
      offset: Offset(0, 20),
    ),
  ];

  // ============================================================
  // SPECIALIZED SHADOWS
  // ============================================================

  /// Profile screen card shadow (legacy compatibility)
  /// Blur: 15px, Spread: 5px, Offset: (5, 5)
  /// Opacity: 8% black
  ///
  /// Used in existing Profile screen design. Gradually migrate to `md` or `lg`.
  static final List<BoxShadow> profileCard = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 15.0,
      spreadRadius: 5.0,
      offset: const Offset(5, 5),
    ),
  ];

  /// Clinical alert shadow (for critical warnings)
  /// Enhanced visibility with slight red tint
  /// Usage: Emergency alerts, critical risk indicators
  static final List<BoxShadow> critical = [
    BoxShadow(
      color: const Color(0xFFDC2626).withValues(alpha: 0.15), // Red tint, 15% opacity
      blurRadius: 12.0,
      spreadRadius: 2.0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Success state shadow (for confirmations)
  /// Subtle green tint for positive feedback
  /// Usage: Success messages, completed actions
  static final List<BoxShadow> success = [
    BoxShadow(
      color: const Color(0xFF16A34A).withValues(alpha: 0.12), // Green tint, 12% opacity
      blurRadius: 8.0,
      spreadRadius: 1.0,
      offset: const Offset(0, 2),
    ),
  ];

  /// Info state shadow (for informational elements)
  /// Subtle blue tint for informational content
  /// Usage: Info banners, tooltips, help sections
  static final List<BoxShadow> info = [
    BoxShadow(
      color: const Color(0xFF0EA5E9).withValues(alpha: 0.10), // Blue tint, 10% opacity
      blurRadius: 6.0,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  // ============================================================
  // DIRECTIONAL SHADOWS
  // ============================================================

  /// Inner shadow (inset effect)
  /// Usage: Depressed buttons, active states, form inputs
  ///
  /// Note: Flutter doesn't support inset shadows directly.
  /// Use with Stack and custom painting for true inset effects.
  static const List<BoxShadow> inner = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 4.0,
      offset: Offset(0, 2),
      spreadRadius: -2.0,
    ),
  ];

  /// Top shadow (upward floating)
  /// Usage: Bottom sheets, bottom navigation bars
  static const List<BoxShadow> top = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 8.0,
      offset: Offset(0, -4),
      spreadRadius: 0,
    ),
  ];

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Create a custom shadow with specified parameters
  ///
  /// Example:
  /// ```dart
  /// var customShadow = JHShadows.custom(
  ///   color: Colors.red,
  ///   opacity: 0.2,
  ///   blur: 10.0,
  ///   offset: Offset(0, 5),
  /// );
  /// ```
  static List<BoxShadow> custom({
    required Color color,
    required double opacity,
    required double blur,
    required Offset offset,
    double spread = 0,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  /// Combine multiple shadow levels for layered depth
  ///
  /// Example:
  /// ```dart
  /// var layeredShadow = JHShadows.combine([
  ///   JHShadows.sm,
  ///   JHShadows.md,
  /// ]);
  /// ```
  static List<BoxShadow> combine(List<List<BoxShadow>> shadows) {
    return shadows.expand((shadow) => shadow).toList();
  }
}
