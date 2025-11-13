import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:juan_heart/themes/jh_colors.dart';

class ColorConstant {
  static Color lightDarkBlue = JHColors.info;

  static Color lightSkyBlue = JHColors.infoLight;

  static Color lightpink = JHColors.heartRedLight;

  static Color lightPurple = JHColors.chart3;

  static Color bluedark = JHColors.midnightBlue;

  static Color bluelessdark = JHColors.slate800;

  static Color whiteBackground = JHColors.cloudWhite;

  static Color whiteText = JHColors.cloudWhite;

  static Color warningColor = JHColors.warningLight;

  static Color pupuleColor = JHColors.infoDark;

  static Color greenColor = JHColors.success;

  static Color blueColor = JHColors.infoDark;

  static Color lightRed = JHColors.heartRed;

  static Color lightGray = JHColors.slate300;

  static Color gray = JHColors.slate500;

  static Color bluegray9006c = JHColors.slate900.withValues(alpha: 0.42);

  static Color lightBlue = JHColors.infoDark;

  static Color shadowColorBase = JHColors.slate900;
  static Color shadowColor = shadowColorBase.withValues(alpha: 0.08);

  static Color cardShadowColor = JHColors.slate900.withValues(alpha: 0.02);

  // Additional colors for medical assessment
  static Color lightBlueBackground = JHColors.infoLight;
  static Color redLightBackground = JHColors.dangerLight;
  static Color redAccent = JHColors.danger;
  
  // Emotional reassurance colors - warm, calming tones
  static Color calmingBlue = JHColors.info;
  static Color trustBlue = JHColors.midnightBlue;
  static Color reassuringGreen = JHColors.success;
  static Color warmBeige = JHColors.slate50;
  static Color softWhite = JHColors.softGray;
  static Color gentleGray = JHColors.slate600;
  
  // Filipino healthcare colors
  static Color phcRed = JHColors.heartRed; // Philippine Heart Center red
  static Color phcBlue = JHColors.infoDark;
  static Color barangayGreen = JHColors.successDark;
  
  // Gradient colors for emotional backgrounds
  static Color gradientBlueStart = JHColors.infoLight;
  static Color gradientBlueEnd = JHColors.cloudWhite;
  static Color gradientWarmStart = JHColors.warningLight;
  static Color gradientWarmEnd = JHColors.cloudWhite;
  
  // Badge and indicator colors
  static Color emergencyBadge = JHColors.danger;
  static Color urgentBadge = JHColors.warning;
  static Color routineBadge = JHColors.info;
  static Color verifiedBadge = JHColors.success;
  
  // Card and shadow colors with enhanced depth
  static Color cardBackground = JHColors.cloudWhite;
  static Color cardBorder = JHColors.slate200;
  static Color cardShadowLight = JHColors.slate900.withValues(alpha: 0.04);
  static Color cardShadowMedium = JHColors.slate900.withValues(alpha: 0.08);
  
  // Color aliases for referral system
  static Color get white => whiteBackground;
  static Color get grey => gray;
  static Color get bluelight => lightBlue;
  static Color get greenlight => greenColor;
  static Color get orangelight => warningColor;
  static Color get redlight => lightRed;

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
