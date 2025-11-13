import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_heart/core/app_exports.dart';
import 'package:juan_heart/themes/jh_text_styles.dart';

/// Legacy AppStyle class - DEPRECATED
///
/// This class is maintained for backward compatibility during the typography migration.
/// All styles now map to JHTextStyles for consistent typography across the application.
///
/// MIGRATION STATUS: Phase 2 - Deprecation Aliases
/// - All txt* styles are deprecated
/// - Use JHTextStyles.* directly in new code
/// - These aliases will be removed in a future release
///
/// Usage:
/// ```dart
/// // OLD (Deprecated)
/// Text('Hello', style: AppStyle.txtPoppinsSemiBold24Dark)
///
/// // NEW (Recommended)
/// Text('Hello', style: JHTextStyles.h3.copyWith(color: JHColors.slate900))
/// ```
class AppStyle {
  // ============================================================
  // DEPRECATED ALIASES - Use JHTextStyles instead
  // ============================================================

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle txtPoppinsWithDefaultSizeW500 = JHTextStyles.bodyBase.copyWith(
    color: ColorConstant.bluedark,
    fontWeight: FontWeight.w500,
  );

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle txtPoppinsWithDefaultSizeLightGrayW500 = JHTextStyles.bodyBase.copyWith(
    color: ColorConstant.gray.withValues(alpha: 0.9),
    fontWeight: FontWeight.w500,
  );

  /// @deprecated Use JHTextStyles.h2 instead
  @Deprecated('Use JHTextStyles.h2 with appropriate color')
  static TextStyle txtDMSanBold27 = JHTextStyles.h2.copyWith(
    color: ColorConstant.bluedark,
    fontSize: getFontSize(27),
  );

  /// @deprecated Use JHTextStyles.h3 instead
  @Deprecated('Use JHTextStyles.h3 with appropriate color')
  static TextStyle txtPoppinsSemiBold22Dark = JHTextStyles.h3.copyWith(
    color: ColorConstant.bluedark,
    fontSize: getFontSize(22),
  );

  /// @deprecated Use JHTextStyles.h3 instead
  @Deprecated('Use JHTextStyles.h3 with appropriate color')
  static TextStyle txtPoppinsSemiBold22Light = JHTextStyles.h3.copyWith(
    color: ColorConstant.bluedark,
    fontSize: getFontSize(22),
    fontWeight: FontWeight.w500,
  );

  /// @deprecated Use JHTextStyles.h3 instead
  @Deprecated('Use JHTextStyles.h3 with appropriate color')
  static TextStyle txtPoppinsSemiBold24Dark = JHTextStyles.h3.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.h2 instead
  @Deprecated('Use JHTextStyles.h2 with appropriate color')
  static TextStyle txtPoppinsSemiBold28Light = JHTextStyles.h2.copyWith(
    color: ColorConstant.bluedark,
    fontSize: getFontSize(28),
  );

  /// @deprecated Use JHTextStyles.h2 instead
  @Deprecated('Use JHTextStyles.h2 with appropriate color')
  static TextStyle txtPoppinsBold28Dark = JHTextStyles.h2.copyWith(
    color: ColorConstant.bluedark,
    fontSize: getFontSize(28),
    fontWeight: FontWeight.w600,
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsSemiBold18Light = JHTextStyles.h5.copyWith(
    color: ColorConstant.bluedark.withValues(alpha: 0.8),
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsSemiBold18Dark = JHTextStyles.h5.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsSemiBold18LightGray = JHTextStyles.h5.copyWith(
    color: ColorConstant.lightGray,
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsSemiBold17Light = JHTextStyles.h5.copyWith(
    color: ColorConstant.bluedark.withValues(alpha: 0.8),
    fontSize: getFontSize(17),
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsBold18Dark = JHTextStyles.h5.copyWith(
    color: ColorConstant.bluedark,
    fontWeight: FontWeight.w600,
  );

  /// @deprecated Use JHTextStyles.bodySmall instead
  @Deprecated('Use JHTextStyles.bodySmall with appropriate color')
  static TextStyle txtPoppinsSemiBold14Dark = JHTextStyles.bodySmall.copyWith(
    color: ColorConstant.bluedark,
    fontWeight: FontWeight.w600,
  );

  /// @deprecated Use JHTextStyles.bodySmall instead
  @Deprecated('Use JHTextStyles.bodySmall with appropriate color')
  static TextStyle txtPoppinsSemiBold14LightGray = JHTextStyles.bodySmall.copyWith(
    color: ColorConstant.bluedark.withValues(alpha: 0.5),
  );

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle txtPoppinsSemiBold16DarkGray = JHTextStyles.bodyBase.copyWith(
    fontWeight: FontWeight.w600,
    color: ColorConstant.bluedark.withValues(alpha: 0.8),
  );

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle txtPoppinsSemiBold16Dark = JHTextStyles.bodyBase.copyWith(
    color: ColorConstant.bluedark,
    fontWeight: FontWeight.w600,
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle txtPoppinsSemiBold18LightBlue = JHTextStyles.h5.copyWith(
    color: ColorConstant.lightBlue.withValues(alpha: 0.7),
  );

  /// @deprecated Use JHTextStyles.h4 instead
  @Deprecated('Use JHTextStyles.h4 with appropriate color')
  static TextStyle txtPoppinsSemiBold20Dark = JHTextStyles.h4.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.bodyLarge instead
  @Deprecated('Use JHTextStyles.bodyLarge with appropriate color')
  static TextStyle txtPoppinsMedium17Bluegray9006c = JHTextStyles.bodyLarge.copyWith(
    color: ColorConstant.bluegray9006c,
    fontSize: getFontSize(17),
  );

  // ============================================================
  // ADDITIONAL DEPRECATED STYLES (Common usage patterns)
  // ============================================================

  /// @deprecated Use JHTextStyles.caption instead
  @Deprecated('Use JHTextStyles.caption with appropriate color')
  static TextStyle get txtPoppinsRegular12 => JHTextStyles.caption.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.bodySmall instead
  @Deprecated('Use JHTextStyles.bodySmall with appropriate color')
  static TextStyle get txtPoppinsRegular14 => JHTextStyles.bodySmall.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle get txtPoppinsRegular16 => JHTextStyles.bodyBase.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.bodyLarge instead
  @Deprecated('Use JHTextStyles.bodyLarge with appropriate color')
  static TextStyle get txtPoppinsRegular18 => JHTextStyles.bodyLarge.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.bodyBase instead
  @Deprecated('Use JHTextStyles.bodyBase with appropriate color')
  static TextStyle get txtPoppinsMedium16 => JHTextStyles.bodyBase.copyWith(
    color: ColorConstant.bluedark,
    fontWeight: FontWeight.w500,
  );

  /// @deprecated Use JHTextStyles.h5 instead
  @Deprecated('Use JHTextStyles.h5 with appropriate color')
  static TextStyle get txtPoppinsMedium18 => JHTextStyles.h5.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.h4 instead
  @Deprecated('Use JHTextStyles.h4 with appropriate color')
  static TextStyle get txtPoppinsSemiBold20 => JHTextStyles.h4.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.h3 instead
  @Deprecated('Use JHTextStyles.h3 with appropriate color')
  static TextStyle get txtPoppinsSemiBold24 => JHTextStyles.h3.copyWith(
    color: ColorConstant.bluedark,
  );

  /// @deprecated Use JHTextStyles.h1 instead
  @Deprecated('Use JHTextStyles.h1 with appropriate color')
  static TextStyle get txtPoppinsBold36 => JHTextStyles.h1.copyWith(
    color: ColorConstant.bluedark,
  );

  // ============================================================
  // MIGRATION HELPER METHODS
  // ============================================================

  /// Get text style with dark color
  /// @deprecated Use JHTextStyles with JHColors.slate900 instead
  @Deprecated('Use JHTextStyles with JHColors.slate900')
  static TextStyle withDarkColor(TextStyle style) {
    return style.copyWith(color: ColorConstant.bluedark);
  }

  /// Get text style with light color
  /// @deprecated Use JHTextStyles with JHColors.slate500 instead
  @Deprecated('Use JHTextStyles with JHColors.slate500')
  static TextStyle withLightColor(TextStyle style) {
    return style.copyWith(color: ColorConstant.bluedark.withValues(alpha: 0.7));
  }

  /// Get text style with gray color
  /// @deprecated Use JHTextStyles with JHColors.slate400 instead
  @Deprecated('Use JHTextStyles with JHColors.slate400')
  static TextStyle withGrayColor(TextStyle style) {
    return style.copyWith(color: ColorConstant.gray);
  }
}
