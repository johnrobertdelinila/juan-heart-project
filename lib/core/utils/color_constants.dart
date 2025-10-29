import 'dart:ui';
import 'package:flutter/material.dart';

class ColorConstant {
  static Color lightDarkBlue = fromHex("#92A3FD");

  static Color lightSkyBlue = fromHex("#9DCEFF");

  static Color lightpink = fromHex("#EEA4CE");

  static Color lightPurple = fromHex("#C58BF2");

  static Color bluedark = fromHex('#21243D');

  static Color bluelessdark = fromHex('#2d3152');

  static Color whiteBackground = fromHex("#ffffff");

  static Color whiteText = fromHex("#ffffff");

  static Color warningColor = fromHex("#FBDC8E");

  static Color pupuleColor = fromHex("#7042C9");

  static Color greenColor = fromHex("#0DB1AD");

  static Color blueColor = fromHex("#197BD2");

  static Color lightRed = fromHex("#FC6565");

  static Color lightGray = fromHex("#C4C1C1");

  static Color gray = fromHex("#9F9F9F");

  static Color bluegray9006c = fromHex('#6c20233c');

  static Color lightBlue = fromHex('#1353CF');

  static Color shadowColorBase = fromHex('#233565');
  static Color shadowColor = shadowColorBase.withOpacity(0.08);

  static Color cardShadowColor = fromHex('#000000').withOpacity(0.02);

  // Additional colors for medical assessment
  static Color lightBlueBackground = fromHex('#E3F2FD');
  static Color redLightBackground = fromHex('#FFEBEE');
  static Color redAccent = fromHex('#F44336');
  
  // Emotional reassurance colors - warm, calming tones
  static Color calmingBlue = fromHex('#4A90E2');
  static Color trustBlue = fromHex('#2C5F99');
  static Color reassuringGreen = fromHex('#10B981');
  static Color warmBeige = fromHex('#F5F1ED');
  static Color softWhite = fromHex('#FAFAFA');
  static Color gentleGray = fromHex('#6B7280');
  
  // Filipino healthcare colors
  static Color phcRed = fromHex('#C62828'); // Philippine Heart Center red
  static Color phcBlue = fromHex('#1565C0');
  static Color barangayGreen = fromHex('#059669');
  
  // Gradient colors for emotional backgrounds
  static Color gradientBlueStart = fromHex('#E0F2FE');
  static Color gradientBlueEnd = fromHex('#FFFFFF');
  static Color gradientWarmStart = fromHex('#FEF3C7');
  static Color gradientWarmEnd = fromHex('#FFFFFF');
  
  // Badge and indicator colors
  static Color emergencyBadge = fromHex('#DC2626');
  static Color urgentBadge = fromHex('#F59E0B');
  static Color routineBadge = fromHex('#3B82F6');
  static Color verifiedBadge = fromHex('#10B981');
  
  // Card and shadow colors with enhanced depth
  static Color cardBackground = fromHex('#FFFFFF');
  static Color cardBorder = fromHex('#E5E7EB');
  static Color cardShadowLight = fromHex('#000000').withOpacity(0.04);
  static Color cardShadowMedium = fromHex('#000000').withOpacity(0.08);
  
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
