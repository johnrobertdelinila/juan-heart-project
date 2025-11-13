import 'package:flutter/material.dart';

/// Centralized, clinically-approved color system for Juan Heart Mobile.
///
/// All new UI work must reference these semantic colors instead of raw
/// `Color` values to ensure consistent branding, accessibility, and theming.
class JHColors {
  // Brand Identity
  static const Color heartRed = Color(0xFFDC2626);
  static const Color heartRedDark = Color(0xFFB91C1C);
  static const Color heartRedLight = Color(0xFFFECACA);
  static const Color midnightBlue = Color(0xFF1E293B);
  static const Color cloudWhite = Color(0xFFFFFFFF);
  static const Color softGray = Color(0xFFF8FAFC);

  // Semantic Colors - Clinical Risk Stratification
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color dangerDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFE0F2FE);
  static const Color infoDark = Color(0xFF0284C7);

  // Neutral Palette (Slate Scale)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Data Visualization
  static const Color chart1 = Color(0xFFEA7C2E); // Appointments
  static const Color chart2 = Color(0xFF4FB3AC); // Assessments
  static const Color chart3 = Color(0xFF245D89); // Referrals
  static const Color chart4 = Color(0xFFF3CB45); // Pending
  static const Color chart5 = Color(0xFFD89845); // Completed
}
