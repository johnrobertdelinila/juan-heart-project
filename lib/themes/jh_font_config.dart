import 'package:flutter/material.dart';

/// Centralized font configuration for Juan Heart Mobile
///
/// This class provides a single source of truth for all font-related configuration.
/// To change the app's font globally, update the [primaryFont] constant.
///
/// Example usage:
/// ```dart
/// Text(
///   'Hello',
///   style: TextStyle(
///     fontFamily: JHFontConfig.primaryFont,
///     fontWeight: JHFontConfig.semibold,
///   ),
/// )
/// ```
class JHFontConfig {
  JHFontConfig._(); // Private constructor to prevent instantiation

  // ============================================
  // Font Families
  // ============================================

  /// Primary font family used throughout the app
  ///
  /// Current: DM Sans - Modern geometric sans-serif with warmth
  /// - Healthcare-friendly (professional yet approachable)
  /// - Excellent readability at all sizes
  /// - Slightly wider than Inter for better legibility
  /// - Rounded terminals create friendly feel
  ///
  /// To switch fonts: Change this constant and the app updates globally
  static const String primaryFont = 'DMSans';

  /// Monospace font for medical data, metrics, and code
  ///
  /// Current: JetBrains Mono - Professional monospace font
  /// - Used for vital signs, lab values, medical IDs
  /// - Excellent digit differentiation (1, l, I clearly distinct)
  /// - Matches web app's monospace font choice
  static const String monospaceFont = 'JetBrains Mono';

  // ============================================
  // Font Weights
  // ============================================

  /// Light weight (300) - Subtle text, secondary information
  static const FontWeight light = FontWeight.w300;

  /// Regular weight (400) - Body text, default weight
  static const FontWeight regular = FontWeight.w400;

  /// Medium weight (500) - Emphasized text, labels, buttons
  static const FontWeight medium = FontWeight.w500;

  /// Semibold weight (600) - Subheadings, important labels
  static const FontWeight semibold = FontWeight.w600;

  /// Bold weight (700) - Headings, strong emphasis, alerts
  static const FontWeight bold = FontWeight.w700;

  // ============================================
  // Typography Scale Configuration
  // ============================================

  /// Whether to use responsive font sizing
  ///
  /// When true, font sizes adapt to screen size:
  /// - Phone: Base sizes
  /// - Tablet: 1.1x base sizes
  /// - Desktop: 1.2x base sizes
  static const bool useResponsiveSizing = true;

  /// Base font size multiplier for phone layouts
  static const double phoneFontScale = 1.0;

  /// Base font size multiplier for tablet layouts
  static const double tabletFontScale = 1.1;

  /// Base font size multiplier for desktop layouts
  static const double desktopFontScale = 1.2;

  // ============================================
  // Font Preloading
  // ============================================

  /// Preload critical fonts to prevent flash of unstyled text (FOUT)
  ///
  /// Call this in main() before runApp():
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await JHFontConfig.preloadFonts();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> preloadFonts() async {
    // DM Sans is loaded via assets, no preloading needed
    // JetBrains Mono is loaded via google_fonts package
    // Preloading happens automatically when first used

    // If using google_fonts for DM Sans in the future:
    // await GoogleFonts.pendingFonts([
    //   GoogleFonts.dmSans(),
    // ]);

    // For now, this is a no-op but provides API for future optimization
    return Future.value();
  }

  // ============================================
  // Fallback Fonts
  // ============================================

  /// System fallback fonts if custom fonts fail to load
  static const List<String> fallbackFonts = [
    'Roboto',           // Android default
    'SF Pro Text',      // iOS default
    '-apple-system',    // iOS system font
    'BlinkMacSystemFont', // macOS system font
    'Segoe UI',         // Windows default
    'Helvetica Neue',   // Older iOS/macOS
    'Arial',            // Universal fallback
    'sans-serif',       // Generic fallback
  ];

  /// Get primary font with fallbacks
  static String get primaryFontWithFallbacks {
    return '$primaryFont, ${fallbackFonts.join(", ")}';
  }

  /// Get monospace font with fallbacks
  static String get monospaceFontWithFallbacks {
    return '$monospaceFont, Courier New, Courier, monospace';
  }

  // ============================================
  // Theme Integration
  // ============================================

  /// Get TextTheme configured with DM Sans
  ///
  /// Used in ThemeData to apply font globally:
  /// ```dart
  /// ThemeData(
  ///   textTheme: JHFontConfig.textTheme,
  /// )
  /// ```
  static TextTheme get textTheme {
    return const TextTheme(
      // Display styles
      displayLarge: TextStyle(fontFamily: primaryFont, fontWeight: bold),
      displayMedium: TextStyle(fontFamily: primaryFont, fontWeight: bold),
      displaySmall: TextStyle(fontFamily: primaryFont, fontWeight: bold),

      // Headline styles
      headlineLarge: TextStyle(fontFamily: primaryFont, fontWeight: bold),
      headlineMedium: TextStyle(fontFamily: primaryFont, fontWeight: bold),
      headlineSmall: TextStyle(fontFamily: primaryFont, fontWeight: semibold),

      // Title styles
      titleLarge: TextStyle(fontFamily: primaryFont, fontWeight: semibold),
      titleMedium: TextStyle(fontFamily: primaryFont, fontWeight: medium),
      titleSmall: TextStyle(fontFamily: primaryFont, fontWeight: medium),

      // Body styles
      bodyLarge: TextStyle(fontFamily: primaryFont, fontWeight: regular),
      bodyMedium: TextStyle(fontFamily: primaryFont, fontWeight: regular),
      bodySmall: TextStyle(fontFamily: primaryFont, fontWeight: regular),

      // Label styles
      labelLarge: TextStyle(fontFamily: primaryFont, fontWeight: medium),
      labelMedium: TextStyle(fontFamily: primaryFont, fontWeight: medium),
      labelSmall: TextStyle(fontFamily: primaryFont, fontWeight: medium),
    );
  }

  // ============================================
  // Documentation
  // ============================================

  /// Font change guide:
  ///
  /// To switch from DM Sans to another font:
  ///
  /// 1. Add new font files to assets/fonts/YourFont/
  /// 2. Declare font in pubspec.yaml
  /// 3. Update [primaryFont] constant above (e.g., 'YourFont')
  /// 4. Run `flutter clean && flutter pub get`
  /// 5. Hot restart app (hot reload won't update fonts)
  ///
  /// Example for switching to Manrope:
  /// ```dart
  /// static const String primaryFont = 'Manrope';
  /// ```
  ///
  /// Available font weights:
  /// - DM Sans: 300 (Light), 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold) + Italics
  /// - JetBrains Mono: 400 (Regular), 500 (Medium) via google_fonts
  ///
  /// All DM Sans weights are included in the app bundle via assets/fonts/DMSans/
}
