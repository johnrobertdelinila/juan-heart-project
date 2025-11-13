import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_heart/themes/jh_colors.dart';
import 'package:juan_heart/themes/jh_spacing.dart';
import 'package:juan_heart/themes/jh_radius.dart';

/// Standard button widget following Profile screen and dialog design pattern
///
/// Design specs based on Profile "Edit" button and "Take a Heart Risk Assessment?" dialog:
/// - Clean, minimalist aesthetic
/// - Text-only (no icons)
/// - Consistent sizing and styling
/// - Material Design 3 elevation system (JHShadows)
/// - 12px border radius from JHRadius.base
/// - Inter font family (migrated from Poppins)
/// - Uses Juan Heart design tokens (JHColors, JHSpacing, JHRadius, JHShadows)
///
/// Usage:
/// ```dart
/// StandardButton.primary(
///   text: "Book Appointment",
///   onPressed: () {},
/// )
///
/// StandardButton.secondary(
///   text: "Cancel",
///   onPressed: () {},
/// )
///
/// StandardButton.outline(
///   text: "Learn More",
///   onPressed: () {},
/// )
///
/// StandardButton.compact(
///   text: "Edit",
///   onPressed: () {},
/// )
/// ```
class StandardButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double height;
  final double? width;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;
  final BorderSide? border;
  final bool isLoading;
  final double fontSize;
  final FontWeight fontWeight;

  const StandardButton._({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.height,
    this.width,
    required this.padding,
    required this.borderRadius,
    required this.elevation,
    this.border,
    this.isLoading = false,
    required this.fontSize,
    required this.fontWeight,
  }) : super(key: key);

  /// Primary action button (red background)
  /// Used for main CTAs like booking, submitting, confirming
  factory StandardButton.primary({
    required String text,
    required VoidCallback? onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: JHColors.heartRed,
      foregroundColor: JHColors.cloudWhite,
      height: 50,
      width: width,
      padding: JHSpacing.buttonPadding,
      borderRadius: JHRadius.base,
      elevation: 2,
      isLoading: isLoading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Secondary action button (blue background)
  /// Used for navigation, info actions, secondary confirmations
  factory StandardButton.secondary({
    required String text,
    required VoidCallback? onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: JHColors.infoDark,
      foregroundColor: JHColors.cloudWhite,
      height: 50,
      width: width,
      padding: JHSpacing.buttonPadding,
      borderRadius: JHRadius.base,
      elevation: 2,
      isLoading: isLoading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Tertiary action button (dark blue background)
  /// Used for compact buttons, Profile screen style
  factory StandardButton.tertiary({
    required String text,
    required VoidCallback? onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: JHColors.midnightBlue,
      foregroundColor: JHColors.cloudWhite,
      height: 50,
      width: width,
      padding: JHSpacing.buttonPadding,
      borderRadius: JHRadius.base,
      elevation: 2,
      isLoading: isLoading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Outline button (transparent background with colored border)
  /// Matches "SosButton" outline variant from dialog
  factory StandardButton.outline({
    required String text,
    required VoidCallback? onPressed,
    Color? color,
    double? width,
    bool isLoading = false,
  }) {
    final buttonColor = color ?? JHColors.heartRed;
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: buttonColor,
      height: 50,
      width: width,
      padding: JHSpacing.buttonPadding,
      borderRadius: JHRadius.base,
      elevation: 0, // No elevation for outline buttons
      border: BorderSide(color: buttonColor, width: 2),
      isLoading: isLoading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  /// Compact button (35px height)
  /// Used in Profile screen and other space-constrained contexts
  factory StandardButton.compact({
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
    double? width,
    bool isLoading = false,
  }) {
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? JHColors.midnightBlue,
      foregroundColor: foregroundColor ?? JHColors.cloudWhite,
      height: 35,
      width: width,
      padding: JHSpacing.buttonPaddingSmall,
      borderRadius: JHRadius.base,
      elevation: 2,
      isLoading: isLoading,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  /// Grey button for less important actions
  /// Used for Previous/Back buttons
  factory StandardButton.grey({
    required String text,
    required VoidCallback? onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return StandardButton._(
      text: text,
      onPressed: onPressed,
      backgroundColor: JHColors.slate200,
      foregroundColor: JHColors.midnightBlue,
      height: 50,
      width: width,
      padding: JHSpacing.buttonPadding,
      borderRadius: JHRadius.base,
      elevation: 1,
      isLoading: isLoading,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = width ?? double.infinity;

    if (border != null) {
      // Outline button variant
      return SizedBox(
        width: buttonWidth,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: foregroundColor,
            padding: padding,
            side: border,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Text(text),
        ),
      );
    }

    // Filled button variant
    return SizedBox(
      width: buttonWidth,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding,
          elevation: elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Text(text),
      ),
    );
  }
}
