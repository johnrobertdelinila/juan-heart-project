import 'package:flutter/material.dart';
import '../../core/utils/color_constants.dart';
import '../../themes/jh_text_styles.dart';
import '../../themes/jh_spacing.dart';
import '../../themes/jh_radius.dart';
import '../../themes/jh_shadows.dart';

/// Standard card widget following Profile screen design pattern
///
/// Design specs:
/// - White background (or subtle colored for accents)
/// - 12px border radius (JHRadius.base) - migrating from legacy 15px
/// - Material Design 3 shadow system (JHShadows.md)
/// - No borders
/// - Standard padding from JHSpacing
/// - Uses Juan Heart design tokens (JHRadius, JHShadows, JHSpacing)
class StandardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const StandardCard({
    Key? key,
    required this.child,
    this.padding = JHSpacing.cardPadding,
    this.margin,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: JHRadius.cardRadius,
        boxShadow: JHShadows.md,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: JHRadius.cardRadius,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Accent card variant for small informational cards
///
/// Used for: vitals, health tips, stat cards
/// Supports subtle colored backgrounds while maintaining consistent shadow/radius
class AccentCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final VoidCallback? onTap;

  const AccentCard({
    Key? key,
    required this.child,
    required this.accentColor,
    this.padding = JHSpacing.cardPaddingCompact,
    this.margin,
    this.width,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      width: width,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: JHRadius.cardRadius,
        boxShadow: JHShadows.sm,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: JHRadius.cardRadius,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// Section card with header following Profile screen pattern
///
/// Used for: Account section, Preferences section, etc.
class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.margin = const EdgeInsets.symmetric(vertical: JHSpacing.md),
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      margin: margin,
      padding: padding ?? JHSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: JHTextStyles.h5.copyWith(
              color: ColorConstant.bluedark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: JHSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
