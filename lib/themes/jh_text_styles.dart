import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_heart/themes/jh_font_config.dart';

/// Juan Heart Typography System
///
/// Complete typography hierarchy using DM Sans (primary) and JetBrains Mono (medical data)
/// Follows Material Design 3 type scale with Juan Heart customizations
///
/// Design System Standards:
/// - Display: 48sp Bold (Hero sections)
/// - H1: 36sp Bold (Page titles)
/// - H2: 30sp Bold (Major sections)
/// - H3: 24sp Bold (Section headers)
/// - H4: 20sp Bold (Subsections)
/// - H5: 18sp Medium (Minor headings)
/// - Body Large: 18sp Regular (Emphasized body)
/// - Body Base: 16sp Regular (Standard body)
/// - Body Small: 14sp Regular (Secondary body)
/// - Caption: 12sp Regular (Supporting text)
/// - Label: 14sp Medium (Form labels)
/// - Button: 16sp Medium (Button text)
/// - Medical Data: 16sp JetBrains Mono (BP, HR, SpO2, dates, times, medical codes)
///
/// Accessibility:
/// - Minimum font size: 14sp (before scaling)
/// - Line height: 1.2 for headers, 1.5 for body text
/// - Supports text scaling from 14pt to 24pt
/// - Color contrast: 4.5:1 for normal text, 3:1 for large text
class JHTextStyles {
  // Private constructor to prevent instantiation
  JHTextStyles._();

  // ============================================================
  // DISPLAY & HEADINGS
  // ============================================================

  /// Display text - 48sp Bold
  /// Usage: Hero sections, splash screens, onboarding headlines
  static const TextStyle display = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 48,
    fontWeight: JHFontConfig.semibold,
    height: 1.0,
    letterSpacing: -0.96,
  );

  /// H1 - 36sp Bold
  /// Usage: Page titles, main screen headers
  static const TextStyle h1 = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 36,
    fontWeight: JHFontConfig.semibold,
    height: 1.1,
    letterSpacing: -0.72,
  );

  /// H2 - 30sp Bold
  /// Usage: Major sections, modal titles
  static const TextStyle h2 = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 30,
    fontWeight: JHFontConfig.semibold,
    height: 1.2,
    letterSpacing: -0.6,
  );

  /// H3 - 24sp Bold
  /// Usage: Section headers, card titles
  static const TextStyle h3 = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 24,
    fontWeight: JHFontConfig.semibold,
    height: 1.3,
    letterSpacing: -0.36,
  );

  /// H4 - 20sp Medium
  /// Usage: Subsections, list headers
  static const TextStyle h4 = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 20,
    fontWeight: JHFontConfig.medium,
    height: 1.4,
    letterSpacing: -0.2,
  );

  /// H5 - 18sp Medium
  /// Usage: Minor headings, emphasized content
  static const TextStyle h5 = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 18,
    fontWeight: JHFontConfig.medium,
    height: 1.5,
    letterSpacing: 0,
  );

  // ============================================================
  // BODY TEXT
  // ============================================================

  /// Body Large - 18sp Regular
  /// Usage: Emphasized body text, important descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 18,
    fontWeight: JHFontConfig.regular,
    height: 1.6,
    letterSpacing: 0,
  );

  /// Body Base - 16sp Regular
  /// Usage: Standard body text, descriptions, content
  static const TextStyle bodyBase = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 16,
    fontWeight: JHFontConfig.regular,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Body Small - 14sp Regular
  /// Usage: Secondary body text, helper text
  static const TextStyle bodySmall = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 14,
    fontWeight: JHFontConfig.regular,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Caption - 12sp Regular
  /// Usage: Supporting text, timestamps, metadata
  static const TextStyle caption = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 12,
    fontWeight: JHFontConfig.regular,
    height: 1.4,
    letterSpacing: 0,
  );

  // ============================================================
  // SPECIALIZED TEXT
  // ============================================================

  /// Label - 12sp Medium (Uppercase)
  /// Usage: Form labels, input field labels, chips, tags
  static const TextStyle label = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 12,
    fontWeight: JHFontConfig.medium,
    height: 1.2,
    letterSpacing: 0.6,
  );

  /// Button - 16sp Medium
  /// Usage: Button text, call-to-action text
  static const TextStyle button = TextStyle(
    fontFamily: JHFontConfig.primaryFont,
    fontSize: 16,
    fontWeight: JHFontConfig.medium,
    height: 1.0,
    letterSpacing: 0,
  );

  /// Medical Data - 16sp JetBrains Mono
  /// Usage: Blood pressure, heart rate, SpO2, dates, times, medical codes
  /// Monospace font for improved readability of numeric medical data
  static TextStyle medicalData = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );

  /// Medical Data Small - 14sp JetBrains Mono
  /// Usage: Compact medical data displays, inline vitals
  static TextStyle medicalDataSmall = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
  );

  /// Medical Data Large - 20sp JetBrains Mono
  /// Usage: Prominent medical readings, vital signs displays
  static TextStyle medicalDataLarge = GoogleFonts.jetBrainsMono(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  // ============================================================
  // SEMANTIC VARIANTS (For backward compatibility with AppStyle)
  // ============================================================

  /// Page Title - Alias for h1
  static TextStyle pageTitle = h1;

  /// Section Header - Alias for h3
  static TextStyle sectionHeader = h3;

  /// Subsection - Alias for h5
  static TextStyle subsection = h5;

  /// Body Text - Alias for bodyBase
  static TextStyle bodyText = bodyBase;

  /// Secondary Text - Alias for bodySmall
  static TextStyle secondaryText = bodySmall;

  // ============================================================
  // UTILITY METHODS
  // ============================================================

  /// Apply color to a TextStyle
  ///
  /// Example:
  /// ```dart
  /// Text('Hello', style: JHTextStyles.withColor(JHTextStyles.h1, Colors.red))
  /// ```
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to a TextStyle
  ///
  /// Example:
  /// ```dart
  /// Text('Hello', style: JHTextStyles.withWeight(JHTextStyles.bodyBase, FontWeight.bold))
  /// ```
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size to a TextStyle
  ///
  /// Example:
  /// ```dart
  /// Text('Hello', style: JHTextStyles.withSize(JHTextStyles.bodyBase, 20))
  /// ```
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size);
  }
}
