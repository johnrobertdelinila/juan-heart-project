# Juan Heart Mobile - Redesign Implementation Plan

> **Transform the mobile experience to surpass the web application**
> Version 1.0 | January 2025
> Aligned with Juan Heart Mobile Style Guide v1.0

---

## 📋 Executive Summary

### Vision
Create a **mobile-first healthcare experience** that leverages native capabilities, delivers superior UX through thoughtful animations and interactions, and becomes the preferred platform for both patients and healthcare workers.

### Current State Analysis
**Strengths:**
- Solid foundation with Flutter & Dart 3.0+
- Comprehensive features (assessments, appointments, referrals)
- Offline-first architecture with Drift/SQLite
- Firebase integration for real-time features
- BLoC pattern for state management

**Critical Gaps vs. Style Guide:**
- **Typography:** Using Poppins/DMSans instead of Inter (style guide standard)
- **Colors:** Inconsistent palette - mix of legacy colors vs. style guide colors
- **Spacing:** Ad-hoc spacing instead of 4px-based system
- **Components:** Custom widgets don't follow style guide specifications
- **Animations:** Minimal motion design, missing micro-interactions
- **Performance:** No lazy loading, unoptimized images, excessive rebuilds

### Success Metrics
| Metric | Current | Target | Impact |
|--------|---------|--------|--------|
| App Load Time | ~3.5s | <2s | 43% faster |
| Assessment Completion | 65% | 85%+ | 20% increase |
| User Satisfaction | 7.2/10 | 9.0/10 | 25% improvement |
| Frame Drop Rate | 8% | <2% | 75% smoother |
| Bundle Size | 28MB | <20MB | 29% smaller |
| Weekly Active Users | - | +40% | Retention boost |

---

## 🎯 Current State vs. Target State

### Design System Comparison

| Element | Current | Target (Style Guide) | Priority |
|---------|---------|---------------------|----------|
| **Primary Font** | Poppins | Inter (Google Fonts) | P0 |
| **Monospace Font** | DMSans | JetBrains Mono | P1 |
| **Primary Color** | `#FC6565` (lightRed) | `#DC2626` (heartRed) | P0 |
| **Background** | `#FFFFFF` | `#F8FAFC` (softGray) | P1 |
| **Card Radius** | 15px | 12px (base) | P1 |
| **Button Height** | 50px | 48px (min touch target) | P2 |
| **Spacing System** | Inconsistent | 4px-based scale | P0 |
| **Shadows** | Custom | JHShadows (xs-xl) | P1 |
| **Risk Badges** | Basic | Clinical stratification | P0 |

### Component Inventory

#### ✅ Existing Components (Need Refactor)
- StandardButton (70% aligned)
- StandardCard (60% aligned)
- CustomTextFormField (40% aligned)
- SyncStatusBadge (80% aligned)
- CustomBottomNavigationBar (50% aligned)

#### ❌ Missing Components
- JHPrimaryButton, JHSecondaryButton
- JHTextField with validation states
- JHRiskBadge (clinical indicators)
- JHBottomSheet
- JHTouchTarget wrapper
- JHOfflineBanner
- Data table components
- Chart wrappers (fl_chart integration)

---

## 🚀 Phase 1: Foundation & Design System (Weeks 1-2)

**Goal:** Establish the design system foundation that all future work builds upon.

### 1.1 Typography Migration ✅ COMPLETE (VERIFIED)
**Effort:** 3 days | **Impact:** High | **Priority:** P0 | **Status:** ✅ Complete & Verified (Jan 31, 2025)

#### Tasks
- [x] Add `google_fonts: ^6.1.0` to pubspec.yaml
- [x] Create `lib/themes/jh_text_styles.dart` with Inter font family
- [x] Add JetBrains Mono for medical data (BP, HR, codes)
- [x] Create text style constants matching style guide
- [x] Update `app_styles.dart` to use new styles
- [x] Run find-replace across codebase (safe with version control)
- [x] Migrate ALL files with Poppins references (9 critical screens)
- [x] Replace ALL 65 legacy Poppins references across codebase
- [x] Remove unused app_styles.dart imports (8 files)
- [x] Fix all compile errors and warnings (0 errors in presentation layer)

#### Verification Results (Jan 31, 2025)
- ✅ **Zero Poppins references** remaining in codebase (verified via grep)
- ✅ **9 critical screens migrated:**
  - medical_triage_assessment_screen.dart (5 instances)
  - analytics_screen.dart (18 instances)
  - user_profile_screen.dart (20 instances)
  - educational_content_list_screen.dart (13 instances)
  - analytics_screen_redesigned.dart (4 instances)
  - pre_consultation_screen.dart (1 instance)
  - user_details_screen.dart (2 instances)
  - facility_list_screen.dart (1 instance)
  - content_viewer_screen.dart (1 instance)
- ✅ **Flutter analyze clean:** No errors in lib/ directory
- ✅ **JHTextStyles adoption:** 40 files, 714+ usages across presentation layer

#### Implementation
```dart
// lib/themes/jh_text_styles.dart
import 'package:google_fonts/google_fonts.dart';

class JHTextStyles {
  // Display - Hero sections
  static TextStyle display = GoogleFonts.inter(
    fontSize: 48, height: 1.0, fontWeight: FontWeight.w600, 
    letterSpacing: -0.96,
  );

  // Headings
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 36, height: 1.1, fontWeight: FontWeight.w600,
    letterSpacing: -0.72,
  );
  
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 30, height: 1.2, fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
  );
  
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 24, height: 1.3, fontWeight: FontWeight.w600,
    letterSpacing: -0.36,
  );
  
  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 20, height: 1.4, fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );
  
  static TextStyle h5 = GoogleFonts.inter(
    fontSize: 18, height: 1.5, fontWeight: FontWeight.w500,
  );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 18, height: 1.6, fontWeight: FontWeight.w400,
  );
  
  static TextStyle bodyBase = GoogleFonts.inter(
    fontSize: 16, height: 1.5, fontWeight: FontWeight.w400,
  );
  
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 14, height: 1.5, fontWeight: FontWeight.w400,
  );
  
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12, height: 1.4, fontWeight: FontWeight.w400,
  );

  // Specialized
  static TextStyle label = GoogleFonts.inter(
    fontSize: 12, height: 1.2, fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );
  
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w500,
  );
  
  static TextStyle medicalData = GoogleFonts.jetBrainsMono(
    fontSize: 16, height: 1.4, fontWeight: FontWeight.w500,
  );
}
```

#### Migration Strategy
1. **Phase 1a:** Update `lib/themes/` directory
2. **Phase 1b:** Update `lib/presentation/widgets/` (reusable components)
3. **Phase 1c:** Update `lib/presentation/pages/` (screens)
4. **Phase 1d:** Test on multiple devices (iOS/Android, various sizes)

**Testing:** Visual regression testing, ensure no layout breaks

---

### 1.2 Color System Unification ✅ COMPLETE (VERIFIED)
**Effort:** 1 day (Foundation) + 2 days (Migration) | **Impact:** High | **Priority:** P0 | **Status:** ✅ Complete & Verified (Jan 31, 2025)

#### Tasks
- [x] Create `lib/themes/jh_colors.dart` with unified palette
- [x] Map existing colors to new system
- [x] Update `color_constants.dart` with aliases for backward compatibility
- [x] Eliminate ALL hardcoded Color(0x) from presentation layer (218 → 0)
- [x] Migrate hardcoded colors in services/ and models/ (26 → 0)
- [x] Audit screens for color consistency across 11 critical files
- [x] Flutter analyze clean (zero color-related errors)

#### Verification Results (Jan 31, 2025)
**Phase 1 - Hardcoded Color Elimination:**
- ✅ **Zero hardcoded `Color(0x...)` outside jh_colors.dart** (was 277 total)
- ✅ **11 critical screens migrated:**
  - analytics_screen.dart (92 colors → JHColors)
  - assessment_widgets.dart (44 colors → JHColors)
  - home_screen.dart (32 colors → JHColors)
  - analytics_screen_redesigned.dart (22 colors → JHColors)
  - heart_risk_assessment_screen.dart (15 colors → JHColors)
  - appointments_screen.dart (3 colors → JHColors)
  - medical_triage_assessment_screen.dart (2 colors → JHColors)
  - next_steps_screen.dart (3 colors → JHColors)
  - pre_consultation_screen.dart (5 colors → JHColors)
  - analytics_service.dart (11 colors → JHColors)
  - Models: assessment_history + appointment (15 colors → JHColors)

**Phase 2 - System Adoption:**
- ✅ **355 JHColors instances** across lib/ (up from 111 initially, +220% increase)
- ✅ **15 files importing jh_colors** (up from 2 initially)
- ✅ **ColorConstant backward compatibility maintained** (1,149 legacy uses via aliases)
- ✅ **ThemeData fully migrated** to JHColors (35 references in main.dart)
- ✅ **Core widgets migrated:** StandardButton, AppDecoration, AppStyles

**Impact:**
- Zero hardcoded colors in presentation/pages/ directory
- Consistent semantic color usage across all critical screens
- 100% backward compatibility via ColorConstant aliases
- Future-proof color system ready for theming/dark mode
- Reduced code duplication and improved maintainability

**Status:** The new JHColors palette now drives ThemeData, all critical screens, shared widgets, services, and data models. Legacy ColorConstant entries remain as aliases to JHColors for backward compatibility, ensuring zero breaking changes while new code uses semantic colors directly.

#### Implementation
```dart
// lib/themes/jh_colors.dart
import 'package:flutter/material.dart';

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
```

#### Color Migration Map
```dart
// Update color_constants.dart for backward compatibility
class ColorConstant {
  // Legacy aliases (gradually deprecate)
  static Color lightRed = JHColors.heartRed;
  static Color bluedark = JHColors.midnightBlue;
  static Color whiteBackground = JHColors.cloudWhite;
  static Color gray = JHColors.slate500;
  static Color lightGray = JHColors.slate400;
  // ... etc
}
```

---

### 1.3 Spacing & Layout System
**Effort:** 1 day | **Impact:** Medium | **Priority:** P0

#### Tasks
- [ ] Create `lib/themes/jh_spacing.dart` with 4px-based scale
- [ ] Define common padding patterns
- [ ] Create responsive grid helper
- [ ] Update existing components to use spacing constants

#### Implementation
```dart
// lib/themes/jh_spacing.dart
class JHSpacing {
  static const double xs = 4.0;    // Tight
  static const double sm = 8.0;    // Compact
  static const double md = 12.0;   // Default
  static const double base = 16.0; // Standard
  static const double lg = 20.0;   // Medium
  static const double xl = 24.0;   // Large
  static const double xl2 = 32.0;  // Extra large
  static const double xl3 = 40.0;  // Section
  static const double xl4 = 48.0;  // Major section
  static const double xl5 = 64.0;  // Page-level

  // Common Padding Patterns
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 24.0, vertical: 12.0,
  );
  
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16.0, vertical: 12.0,
  );
}

// lib/themes/jh_grid.dart
class JHGrid {
  static const double gutter = 16.0;
  static const int columnsPhone = 4;
  static const int columnsTablet = 8;

  static double columnWidth(BuildContext context, int span) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = screenWidth < 600 ? columnsPhone : columnsTablet;
    final gutterTotal = gutter * (columns - 1);
    final columnWidth = (screenWidth - gutterTotal) / columns;
    return columnWidth * span + (gutter * (span - 1));
  }
}
```

---

### 1.4 Shadows & Radius System
**Effort:** 0.5 days | **Impact:** Medium | **Priority:** P1

#### Tasks
- [ ] Create `lib/themes/jh_shadows.dart` with elevation system
- [ ] Create `lib/themes/jh_radius.dart` with border radius constants
- [ ] Update card and button components

#### Implementation
```dart
// lib/themes/jh_shadows.dart
class JHShadows {
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 2.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 3.0,
      spreadRadius: 1.0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6.0,
      spreadRadius: -1.0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 15.0,
      spreadRadius: -3.0,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      blurRadius: 25.0,
      spreadRadius: -5.0,
      offset: Offset(0, 20),
    ),
  ];
}

// lib/themes/jh_radius.dart
class JHRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double base = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  static BorderRadius radiusXs = BorderRadius.circular(xs);
  static BorderRadius radiusSm = BorderRadius.circular(sm);
  static BorderRadius radiusMd = BorderRadius.circular(md);
  static BorderRadius radiusBase = BorderRadius.circular(base);
  static BorderRadius radiusLg = BorderRadius.circular(lg);
  static BorderRadius radiusXl = BorderRadius.circular(xl);
  static BorderRadius radiusFull = BorderRadius.circular(full);

  // Top only (for bottom sheets)
  static BorderRadius radiusTop = const BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}
```

---

### 1.5 Theme Configuration
**Effort:** 1 day | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Create `lib/themes/juan_heart_theme.dart` with complete Material 3 theme
- [ ] Configure ColorScheme using JHColors
- [ ] Set up component themes (buttons, inputs, cards)
- [ ] Update `main.dart` to use new theme

#### Implementation
```dart
// lib/themes/juan_heart_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'jh_colors.dart';
import 'jh_text_styles.dart';
import 'jh_spacing.dart';
import 'jh_radius.dart';

class JuanHeartTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      primary: JHColors.heartRed,
      onPrimary: JHColors.cloudWhite,
      primaryContainer: JHColors.heartRedLight,
      onPrimaryContainer: JHColors.heartRedDark,
      secondary: JHColors.midnightBlue,
      onSecondary: JHColors.cloudWhite,
      error: JHColors.danger,
      onError: JHColors.cloudWhite,
      errorContainer: JHColors.dangerLight,
      onErrorContainer: JHColors.dangerDark,
      background: JHColors.softGray,
      onBackground: JHColors.slate900,
      surface: JHColors.cloudWhite,
      onSurface: JHColors.slate900,
      surfaceVariant: JHColors.slate100,
      onSurfaceVariant: JHColors.slate700,
      outline: JHColors.slate300,
      outlineVariant: JHColors.slate200,
    ),

    textTheme: TextTheme(
      displayLarge: JHTextStyles.display,
      displayMedium: JHTextStyles.h1,
      displaySmall: JHTextStyles.h2,
      headlineLarge: JHTextStyles.h1,
      headlineMedium: JHTextStyles.h2,
      headlineSmall: JHTextStyles.h3,
      titleLarge: JHTextStyles.h4,
      titleMedium: JHTextStyles.h5,
      titleSmall: JHTextStyles.bodyLarge,
      bodyLarge: JHTextStyles.bodyBase,
      bodyMedium: JHTextStyles.bodyBase,
      bodySmall: JHTextStyles.bodySmall,
      labelLarge: JHTextStyles.button,
      labelMedium: JHTextStyles.label,
      labelSmall: JHTextStyles.caption,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: JHColors.heartRed,
        foregroundColor: JHColors.cloudWhite,
        elevation: 0,
        padding: JHSpacing.buttonPadding,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: JHRadius.radiusMd,
        ),
        textStyle: JHTextStyles.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JHColors.cloudWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0, vertical: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: JHRadius.radiusMd,
        borderSide: const BorderSide(color: JHColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: JHRadius.radiusMd,
        borderSide: const BorderSide(
          color: JHColors.heartRed, width: 2.0,
        ),
      ),
    ),

    cardTheme: CardTheme(
      color: JHColors.cloudWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: JHRadius.radiusBase,
        side: BorderSide(
          color: JHColors.slate200.withOpacity(0.6),
          width: 1.0,
        ),
      ),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: JHColors.cloudWhite,
      foregroundColor: JHColors.slate900,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: JHTextStyles.h4.copyWith(
        color: JHColors.slate900,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}
```

---

## 🎨 Phase 2: Core Components (Weeks 3-4)

**Goal:** Refactor existing components and create missing ones to match style guide.

### 2.1 Button System
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Update `standard_button.dart` to match JHPrimaryButton specs
- [ ] Add all button variants (primary, secondary, outline, ghost, icon)
- [ ] Add loading states with animations
- [ ] Add disabled states with proper opacity
- [ ] Test touch targets (48x48px minimum)

#### Implementation
```dart
// lib/presentation/widgets/jh_button.dart
class JHButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final JHButtonVariant variant;

  const JHButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = JHButtonVariant.primary,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _getBackgroundColor(),
      borderRadius: JHRadius.radiusMd,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: JHRadius.radiusMd,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 48.0, // WCAG touch target
            minWidth: 48.0,
          ),
          padding: JHSpacing.buttonPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      _getForegroundColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 20, color: _getForegroundColor()),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: JHTextStyles.button.copyWith(
                  color: _getForegroundColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case JHButtonVariant.primary:
        return JHColors.heartRed;
      case JHButtonVariant.secondary:
        return JHColors.slate100;
      case JHButtonVariant.outline:
        return Colors.transparent;
      case JHButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor() {
    switch (variant) {
      case JHButtonVariant.primary:
        return JHColors.cloudWhite;
      case JHButtonVariant.secondary:
        return JHColors.slate700;
      case JHButtonVariant.outline:
      case JHButtonVariant.ghost:
        return JHColors.heartRed;
    }
  }
}

enum JHButtonVariant { primary, secondary, outline, ghost }
```

---

### 2.2 Card System
**Effort:** 1.5 days | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Update `standard_card.dart` to match JHCard specs (12px radius, proper shadows)
- [ ] Create JHAccentCard for colored backgrounds
- [ ] Add hover/press states
- [ ] Ensure consistent elevation

#### Implementation
```dart
// lib/presentation/widgets/jh_card.dart
class JHCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final JHCardVariant variant;

  const JHCard({
    required this.child,
    this.padding,
    this.onTap,
    this.variant = JHCardVariant.standard,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JHColors.cloudWhite,
      borderRadius: JHRadius.radiusBase,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: JHRadius.radiusBase,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: JHColors.slate200.withOpacity(0.6),
              width: 1.0,
            ),
            borderRadius: JHRadius.radiusBase,
            boxShadow: variant == JHCardVariant.elevated 
              ? JHShadows.md 
              : JHShadows.xs,
          ),
          padding: padding ?? JHSpacing.cardPadding,
          child: child,
        ),
      ),
    );
  }
}

enum JHCardVariant { standard, elevated }
```

---

### 2.3 Form Input System
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Update `custom_text_form_field.dart` to match JHTextField
- [ ] Add validation states (error, success)
- [ ] Add prefix/suffix icon support
- [ ] Add focus states with proper borders
- [ ] Test with screen readers

#### Implementation
```dart
// lib/presentation/widgets/jh_text_field.dart
class JHTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int? maxLines;

  const JHTextField({
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: JHTextStyles.bodySmall.copyWith(
            color: JHColors.slate700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: JHColors.cloudWhite,
            borderRadius: JHRadius.radiusMd,
            border: Border.all(
              color: hasError ? JHColors.danger : JHColors.slate200,
              width: 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: JHTextStyles.bodyBase.copyWith(
              color: JHColors.slate900,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: JHTextStyles.bodyBase.copyWith(
                color: JHColors.slate400,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: JHTextStyles.caption.copyWith(
              color: JHColors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
```

---

### 2.4 Badge System (Clinical Risk Indicators)
**Effort:** 1 day | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Create JHRiskBadge for clinical risk levels (High, Moderate, Low)
- [ ] Add proper icons and colors per risk level
- [ ] Create JHStatusBadge for appointment/referral status
- [ ] Add accessibility labels

#### Implementation
```dart
// lib/presentation/widgets/jh_risk_badge.dart
class JHRiskBadge extends StatelessWidget {
  final String level; // 'high', 'moderate', 'low'

  const JHRiskBadge({required this.level, super.key});

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(level);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: JHRadius.radiusSm,
        border: Border.all(
          color: config.borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 14,
            color: config.textColor,
          ),
          const SizedBox(width: 4),
          Text(
            config.text,
            style: JHTextStyles.label.copyWith(
              color: config.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(String level) {
    switch (level.toLowerCase()) {
      case 'high':
      case 'critical':
        return _BadgeConfig(
          bgColor: JHColors.dangerLight,
          textColor: JHColors.danger,
          borderColor: JHColors.danger.withOpacity(0.2),
          text: 'HIGH RISK',
          icon: Icons.warning_rounded,
        );
      case 'moderate':
      case 'mild':
        return _BadgeConfig(
          bgColor: JHColors.warningLight,
          textColor: JHColors.warningDark,
          borderColor: JHColors.warning.withOpacity(0.2),
          text: 'MODERATE',
          icon: Icons.info_outline_rounded,
        );
      default:
        return _BadgeConfig(
          bgColor: JHColors.successLight,
          textColor: JHColors.successDark,
          borderColor: JHColors.success.withOpacity(0.2),
          text: 'LOW RISK',
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }
}

class _BadgeConfig {
  final Color bgColor;
  final Color textColor;
  final Color borderColor;
  final String text;
  final IconData icon;

  _BadgeConfig({
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
    required this.text,
    required this.icon,
  });
}
```

---

### 2.5 Bottom Navigation
**Effort:** 1 day | **Impact:** Medium | **Priority:** P1

#### Tasks
- [ ] Update `custom_bottom_navigation_bar.dart` to match JHBottomNav
- [ ] Use proper icon set (lucide_icons matching web)
- [ ] Add smooth transitions between tabs
- [ ] Test touch targets and spacing

---

### 2.6 Bottom Sheet System
**Effort:** 1 day | **Impact:** Medium | **Priority:** P1

#### Tasks
- [ ] Create JHBottomSheet with handle bar
- [ ] Add modal and persistent variants
- [ ] Implement drag-to-dismiss
- [ ] Add snap points for half/full height

---

## 🎭 Phase 3: Advanced Components & Animations (Weeks 5-6)

**Goal:** Implement complex components and add micro-interactions to elevate UX.

### 3.1 Animation System Setup
**Effort:** 2 days | **Impact:** Very High | **Priority:** P0

#### Required Packages
```yaml
dependencies:
  flutter_animate: ^4.5.0  # Declarative animations
  animations: ^2.0.11       # Material motion
  lottie: ^3.1.0            # Complex animations
  rive: ^0.13.0             # Interactive graphics
```

#### Animation Principles
1. **Purposeful Motion:** Every animation serves a function
2. **Smooth & Natural:** 60fps minimum, ease-in-out curves
3. **Performant:** Use Transform instead of layout changes
4. **Interruptible:** User can cancel mid-animation
5. **Accessible:** Respect prefers-reduced-motion

#### Core Animation Configurations
```dart
// lib/core/animations/animation_config.dart
class AnimationConfig {
  // Duration presets
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curves
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;

  // Clinical-specific animations
  static const Duration heartbeatPulse = Duration(milliseconds: 800);
  static const Duration riskIndicatorFade = Duration(milliseconds: 400);
  static const Duration vitalSignUpdate = Duration(milliseconds: 600);
}
```

---

### 3.2 Micro-Interactions Library
**Effort:** 3 days | **Impact:** Very High | **Priority:** P1

#### Button Press Animation
```dart
// lib/core/animations/button_press_animation.dart
class ButtonPressAnimation extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const ButtonPressAnimation({
    required this.child,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child.animate(
        onPlay: (controller) => controller.repeat(reverse: true),
      ).scaleXY(
        begin: 1.0,
        end: 0.95,
        duration: AnimationConfig.fast,
        curve: AnimationConfig.easeInOut,
      ),
    );
  }
}
```

#### Card Entry Animation
```dart
// Staggered list animation
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return JHCard(
      child: Text(items[index]),
    ).animate().fadeIn(
      delay: Duration(milliseconds: index * 50),
      duration: AnimationConfig.normal,
    ).slideY(
      begin: 0.1,
      end: 0,
      curve: AnimationConfig.easeOut,
    );
  },
);
```

#### Heart Pulse Animation (Risk Badge)
```dart
class HeartPulseAnimation extends StatefulWidget {
  final Widget child;
  final bool shouldPulse;

  const HeartPulseAnimation({
    required this.child,
    this.shouldPulse = true,
    super.key,
  });

  @override
  State<HeartPulseAnimation> createState() => _HeartPulseAnimationState();
}

class _HeartPulseAnimationState extends State<HeartPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.heartbeatPulse,
    );
    if (widget.shouldPulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      ),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### Vital Sign Update Animation
```dart
// Animated number counter for vitals
class AnimatedVitalValue extends StatelessWidget {
  final String oldValue;
  final String newValue;
  final TextStyle style;

  const AnimatedVitalValue({
    required this.oldValue,
    required this.newValue,
    required this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: double.tryParse(oldValue) ?? 0.0,
        end: double.tryParse(newValue) ?? 0.0,
      ),
      duration: AnimationConfig.vitalSignUpdate,
      curve: AnimationConfig.easeOut,
      builder: (context, value, child) {
        return Text(
          value.toStringAsFixed(0),
          style: style,
        );
      },
    );
  }
}
```

---

### 3.3 Page Transitions
**Effort:** 1 day | **Impact:** High | **Priority:** P1

#### Implementation
```dart
// lib/core/animations/page_transitions.dart
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end)
                .chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: AnimationConfig.normal,
        );
}

// Usage
Navigator.push(
  context,
  SlideUpPageRoute(page: AssessmentDetailScreen()),
);
```

---

### 3.4 Loading States & Skeletons
**Effort:** 2 days | **Impact:** High | **Priority:** P1

#### Shimmer Loading
```dart
// Use existing shimmer package
import 'package:shimmer/shimmer.dart';

class JHCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: JHColors.slate200,
      highlightColor: JHColors.slate100,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: JHRadius.radiusBase,
        ),
      ),
    );
  }
}
```

#### Circular Progress with Percentage
```dart
class JHCircularProgress extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;

  const JHCircularProgress({
    required this.progress,
    required this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: JHColors.slate200,
            valueColor: AlwaysStoppedAnimation(
              JHColors.heartRed,
            ),
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: JHTextStyles.h4.copyWith(
            color: JHColors.slate900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
```

---

### 3.5 Data Visualization Components
**Effort:** 3 days | **Impact:** High | **Priority:** P1

#### Chart Wrapper (fl_chart)
```dart
// lib/presentation/widgets/jh_line_chart.dart
class JHLineChart extends StatelessWidget {
  final List<FlSpot> data;
  final String title;
  final Color lineColor;

  const JHLineChart({
    required this.data,
    required this.title,
    this.lineColor = JHColors.heartRed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return JHCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: JHTextStyles.h4.copyWith(
              color: JHColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: lineColor.withOpacity(0.1),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: JHColors.slate200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: JHTextStyles.caption.copyWith(
                            color: JHColors.slate500,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: JHTextStyles.caption.copyWith(
                            color: JHColors.slate500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📱 Phase 4: Screen Redesigns (Weeks 7-9)

**Goal:** Apply design system and animations to all screens, creating cohesive experience.

### 4.1 Onboarding Flow
**Effort:** 2 days | **Impact:** High | **Priority:** P1

#### Features
- Interactive Lottie animations explaining app features
- Smooth liquid_swipe transitions (keep existing)
- Trust-building visuals (PHC partnership, security badges)
- Skip option with clear progress indicators

#### Implementation Checklist
- [ ] Update typography to Inter
- [ ] Apply JHColors palette
- [ ] Add fade-in animations for text
- [ ] Optimize images (WebP format)
- [ ] Add accessibility labels

---

### 4.2 Authentication Screens
**Effort:** 2 days | **Impact:** Medium | **Priority:** P1

#### sign_in_screen.dart
- [ ] Update to JHTextField components
- [ ] Use JHButton variants
- [ ] Add form validation animations (shake on error)
- [ ] Loading states during authentication
- [ ] Biometric prompt with icon animation

#### sign_up_screen.dart
- [ ] Progressive disclosure for form fields
- [ ] Real-time validation with success/error icons
- [ ] Password strength indicator with color
- [ ] Terms & privacy with expandable sections

---

### 4.3 Home Screen (Dashboard)
**Effort:** 3 days | **Impact:** Very High | **Priority:** P0

#### Current Issues
- No visual hierarchy
- Inconsistent card designs
- Static data presentation
- No empty states

#### Redesign Features
1. **Hero Section** - "Your Heart Today"
   - Large gradient card with latest risk assessment
   - Pulse animation on heart icon
   - One-tap to start assessment

2. **Vitals Grid** (2x2)
   - Animated value transitions
   - Color-coded status indicators
   - Tap to see detailed history

3. **Progress Chart**
   - Line chart showing 30-day risk trend
   - Smooth animation on load
   - Swipe to change time range

4. **Quick Actions**
   - Floating action button cluster
   - Ripple animation on press
   - Haptic feedback

#### Implementation
```dart
// home_screen.dart - Redesigned structure
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AssessmentRecord? _latestAssessment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Simulate network delay for demo
    await Future.delayed(Duration(milliseconds: 500));
    final data = await AnalyticsService.getAssessmentHistory();
    setState(() {
      _latestAssessment = data.isNotEmpty ? data.last : null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JHColors.softGray,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? _buildLoadingSkeleton()
            : SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildHeartTodayCard(),
                    _buildVitalsGrid(),
                    _buildProgressChart(),
                    _buildRecommendations(),
                    SizedBox(height: 100), // FAB clearance
                  ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
                ),
              ),
      ),
      floatingActionButton: _buildQuickActions(),
    );
  }

  Widget _buildHeartTodayCard() {
    return Container(
      margin: EdgeInsets.all(JHSpacing.base),
      child: JHCard(
        child: Column(
          children: [
            Row(
              children: [
                HeartPulseAnimation(
                  child: Icon(
                    Icons.favorite,
                    color: _getRiskColor(),
                    size: 48,
                  ),
                ),
                SizedBox(width: JHSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Heart Today',
                        style: JHTextStyles.h3,
                      ),
                      SizedBox(height: 4),
                      JHRiskBadge(
                        level: _latestAssessment?.riskCategory ?? 'unknown',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: JHSpacing.base),
            JHButton(
              text: 'Check My Heart',
              onPressed: _startAssessment,
              variant: JHButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsGrid() {
    return Container(
      margin: EdgeInsets.all(JHSpacing.base),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        mainAxisSpacing: JHSpacing.md,
        crossAxisSpacing: JHSpacing.md,
        childAspectRatio: 1.2,
        children: [
          _buildVitalCard('BP', '120/80', 'Normal', Icons.monitor_heart),
          _buildVitalCard('HR', '72', 'Normal', Icons.favorite),
          _buildVitalCard('SpO₂', '98', 'Normal', Icons.air),
          _buildVitalCard('Temp', '36.8', 'Normal', Icons.thermostat),
        ],
      ),
    );
  }

  Widget _buildVitalCard(String label, String value, String status, IconData icon) {
    return JHCard(
      onTap: () {
        // Navigate to detailed analytics
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: JHColors.slate500, size: 20),
              SizedBox(width: 4),
              Text(
                label,
                style: JHTextStyles.caption.copyWith(
                  color: JHColors.slate500,
                ),
              ),
            ],
          ),
          AnimatedVitalValue(
            oldValue: '0',
            newValue: value,
            style: JHTextStyles.h2.copyWith(
              fontFamily: 'JetBrainsMono',
              color: JHColors.slate900,
            ),
          ),
          Text(
            status,
            style: JHTextStyles.caption.copyWith(
              color: JHColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        SizedBox(height: 100),
        JHCardSkeleton(),
        SizedBox(height: JHSpacing.base),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: JHSpacing.md,
          crossAxisSpacing: JHSpacing.md,
          childAspectRatio: 1.2,
          children: List.generate(4, (_) => JHCardSkeleton()),
        ),
      ],
    );
  }
}
```

---

### 4.4 Assessment Screens
**Effort:** 4 days | **Impact:** Very High | **Priority:** P0

#### medical_triage_assessment_screen.dart
- [ ] Multi-step form with progress indicator
- [ ] Smooth transitions between steps
- [ ] Input validation with inline feedback
- [ ] Auto-save to local storage
- [ ] Exit confirmation with bottom sheet

#### Features
1. **Progress Bar** - Animated as user completes steps
2. **Question Cards** - Swipe to next question
3. **Input Assistance** - Dropdown suggestions, range sliders
4. **Review Screen** - Summary before submission
5. **Result Animation** - Heart animation revealing risk level

---

### 4.5 Analytics Screen
**Effort:** 3 days | **Impact:** High | **Priority:** P1

#### analytics_screen.dart Redesign
- [ ] Replace existing charts with JHLineChart/JHBarChart
- [ ] Add time range selector (7d, 30d, 90d, 1y)
- [ ] Animated chart transitions
- [ ] Export to PDF button
- [ ] Empty state for new users

---

### 4.6 Appointments Screen
**Effort:** 3 days | **Impact:** High | **Priority:** P1

#### appointments_screen.dart
- [ ] Calendar view with event markers
- [ ] List view with status badges
- [ ] Pull-to-refresh with loading animation
- [ ] Swipe to reschedule/cancel
- [ ] QR code for check-in (animated reveal)

---

### 4.7 Referral Screens
**Effort:** 3 days | **Impact:** High | **Priority:** P1

#### facility_list_screen.dart
- [ ] Map view with custom markers
- [ ] List view with distance sorting
- [ ] Filter bottom sheet
- [ ] Real-time availability indicators
- [ ] Directions integration

#### referral_summary_screen.dart
- [ ] Timeline of referral process
- [ ] Document viewer with pinch-to-zoom
- [ ] Status updates with notifications
- [ ] Contact facility button

---

### 4.8 Settings & Profile
**Effort:** 2 days | **Impact:** Medium | **Priority:** P2

#### user_profile_screen.dart
- [ ] Avatar with edit overlay
- [ ] Section cards for account, preferences, privacy
- [ ] Toggle switches with animations
- [ ] Language switcher with flags
- [ ] Logout confirmation

---

## 🚀 Phase 5: Mobile-Exclusive Innovation Features (Weeks 10-11)

**Goal:** Implement features that make mobile app superior to web version.

### 5.1 Native Capabilities

#### 5.1.1 Biometric Authentication
**Effort:** 2 days | **Impact:** High | **Priority:** P1

```yaml
dependencies:
  local_auth: ^2.2.0
```

**Features:**
- Face ID / Touch ID for quick login
- Secure assessment data with biometrics
- Settings to enable/disable

**Implementation:**
```dart
// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    return await _auth.canCheckBiometrics;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Juan Heart',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
```

---

#### 5.1.2 Smart Notifications
**Effort:** 2 days | **Impact:** High | **Priority:** P1

**Features:**
- Medication reminders with custom sounds
- Appointment reminders (24h, 1h, 15min)
- Health tip of the day
- Risk level change alerts
- Assessment streak reminders

**Enhanced with:**
- Rich media (images, charts)
- Action buttons (View, Snooze, Mark Done)
- Custom notification sounds (heartbeat pulse)

```dart
// lib/services/smart_notification_service.dart
class SmartNotificationService {
  static const String channelId = 'juan_heart_reminders';
  static const String channelName = 'Health Reminders';

  Future<void> scheduleAssessmentReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: channelId,
        title: 'Time for Your Heart Check',
        body: 'It\'s been a week since your last assessment. Let\'s check in!',
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/images/heart_checkup.png',
        actionType: ActionType.Default,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'START',
          label: 'Start Assessment',
          actionType: ActionType.Default,
        ),
        NotificationActionButton(
          key: 'LATER',
          label: 'Remind Later',
          actionType: ActionType.DismissAction,
        ),
      ],
    );
  }

  Future<void> sendRiskAlertNotification(String riskLevel) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: channelId,
        title: 'Risk Level Update',
        body: 'Your risk level has changed to $riskLevel. Tap to learn more.',
        category: NotificationCategory.Status,
        color: _getRiskColor(riskLevel),
        autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'VIEW',
          label: 'View Details',
        ),
        NotificationActionButton(
          key: 'FIND_CLINIC',
          label: 'Find Clinic',
        ),
      ],
    );
  }
}
```

---

#### 5.1.3 Offline Mode with Smart Sync
**Effort:** 3 days | **Impact:** Very High | **Priority:** P0

**Features:**
- Fully functional offline (assessments, viewing history)
- Visual sync status indicator
- Conflict resolution UI
- Background sync with workmanager
- Optimistic updates with rollback

**Enhanced Sync Status Badge:**
```dart
// Updated lib/presentation/widgets/sync_status_badge.dart
class EnhancedSyncStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: SyncService.instance.statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data ?? SyncStatus.synced;
        
        return GestureDetector(
          onTap: () {
            if (status == SyncStatus.syncing) {
              // Show sync progress sheet
              _showSyncProgressSheet(context);
            } else if (status == SyncStatus.error) {
              // Show retry options
              _showSyncErrorSheet(context);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: JHRadius.radiusFull,
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == SyncStatus.syncing)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        _getStatusColor(status),
                      ),
                    ),
                  )
                else
                  Icon(
                    _getStatusIcon(status),
                    size: 14,
                    color: _getStatusColor(status),
                  ),
                SizedBox(width: 4),
                Text(
                  _getStatusText(status),
                  style: JHTextStyles.caption.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).animate(
          onPlay: (controller) {
            if (status == SyncStatus.syncing) {
              controller.repeat();
            }
          },
        ).shimmer(
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.3),
        );
      },
    );
  }
}
```

---

#### 5.1.4 Camera-Based Features
**Effort:** 3 days | **Impact:** High | **Priority:** P2

```yaml
dependencies:
  camera: ^0.10.5
  image_picker: ^1.2.0
  google_ml_kit: ^0.16.0
```

**Features:**
1. **Document Scanner** - Scan medical records, prescriptions
   - Auto-crop and enhance
   - OCR text extraction
   - PDF generation

2. **Medication Scanner** - Scan pill bottles to log medications
   - Barcode/QR detection
   - Drug database lookup
   - Set reminders automatically

3. **Vitals via Camera** (Future enhancement)
   - Heart rate via finger on camera
   - Respiratory rate via chest movement

---

#### 5.1.5 Voice Commands & Accessibility
**Effort:** 2 days | **Impact:** High | **Priority:** P1

```yaml
dependencies:
  speech_to_text: ^6.6.0
  flutter_tts: ^3.8.3
```

**Features:**
- "Start assessment" voice command
- Read assessment results aloud
- Voice input for form fields
- Screen reader optimizations

---

### 5.2 Mobile-Optimized UX Patterns

#### 5.2.1 Gesture-Based Navigation
**Effort:** 2 days | **Impact:** High | **Priority:** P1

**Features:**
- Swipe back from edge to go back
- Long-press for contextual menus
- Pull-down to refresh (global)
- Swipe-to-action on list items (delete, archive, share)

```dart
// lib/core/gestures/swipe_actions.dart
class SwipeActionListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      background: _buildActionBackground(
        Icons.delete,
        JHColors.danger,
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildActionBackground(
        Icons.archive,
        JHColors.info,
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd && onDelete != null) {
          return await _showDeleteConfirmation(context);
        }
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onDelete?.call();
        } else {
          onArchive?.call();
        }
        
        // Show undo snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action completed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                // Undo action
              },
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildActionBackground(
    IconData icon,
    Color color,
    Alignment alignment,
  ) {
    return Container(
      color: color,
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Icon(
        icon,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
```

---

#### 5.2.2 Haptic Feedback System
**Effort:** 1 day | **Impact:** Medium | **Priority:** P2

```dart
// lib/core/haptics/haptic_service.dart
import 'package:flutter/services.dart';

class HapticService {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void error() {
    HapticFeedback.vibrate();
  }

  static void success() {
    // Custom pattern for success
    HapticFeedback.lightImpact();
    Future.delayed(Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
  }
}
```

**Usage:**
- Button press: light
- Swipe action: medium
- Error: vibrate
- Success (assessment complete): custom pattern
- Selection (toggle, radio): selection click

---

#### 5.2.3 Smart Forms with Auto-Complete
**Effort:** 2 days | **Impact:** High | **Priority:** P1

**Features:**
- Auto-fill from previous assessments
- Smart suggestions based on age/gender
- Validation as you type
- Save draft automatically
- Pre-populated facility search based on location

---

#### 5.2.4 Contextual Help & Tooltips
**Effort:** 1 day | **Impact:** Medium | **Priority:** P2

```dart
// lib/presentation/widgets/jh_tooltip.dart
class JHTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticService.light();
        _showTooltip(context);
      },
      child: child,
    );
  }

  void _showTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => JHBottomSheet(
        title: 'Help',
        content: Text(
          message,
          style: JHTextStyles.bodyBase,
        ),
        actions: [
          JHButton(
            text: 'Got it',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
```

---

#### 5.2.5 Quick Actions Menu
**Effort:** 1 day | **Impact:** High | **Priority:** P1

**Floating Action Button with Speed Dial:**
```dart
// lib/presentation/widgets/jh_quick_actions.dart
class JHQuickActions extends StatefulWidget {
  @override
  State<JHQuickActions> createState() => _JHQuickActionsState();
}

class _JHQuickActionsState extends State<JHQuickActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConfig.normal,
    );
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
      HapticService.light();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Background overlay
        if (_isOpen)
          GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ).animate().fadeIn(),

        // Action buttons
        ..._buildActionButtons(),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: JHColors.heartRed,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons() {
    final actions = [
      _ActionButton(
        icon: Icons.favorite,
        label: 'New Assessment',
        onPressed: () => _handleAction('assessment'),
      ),
      _ActionButton(
        icon: Icons.calendar_today,
        label: 'Book Appointment',
        onPressed: () => _handleAction('appointment'),
      ),
      _ActionButton(
        icon: Icons.local_hospital,
        label: 'Find Clinic',
        onPressed: () => _handleAction('clinic'),
      ),
      _ActionButton(
        icon: Icons.phone,
        label: 'Emergency',
        onPressed: () => _handleAction('emergency'),
      ),
    ];

    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;
      
      return Positioned(
        bottom: 80.0 + (index * 70),
        right: 0,
        child: action.animate(
          delay: Duration(milliseconds: index * 50),
        ).fadeIn().slideX(begin: 0.2, end: 0),
      );
    }).toList();
  }

  void _handleAction(String action) {
    _toggle();
    // Navigate to appropriate screen
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: JHRadius.radiusMd,
            boxShadow: JHShadows.md,
          ),
          child: Text(
            label,
            style: JHTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 8),
        FloatingActionButton(
          mini: true,
          onPressed: onPressed,
          backgroundColor: JHColors.cloudWhite,
          foregroundColor: JHColors.heartRed,
          child: Icon(icon),
        ),
      ],
    );
  }
}
```

---

### 5.3 Health Device Integration
**Effort:** 4 days | **Impact:** Very High | **Priority:** P1

```yaml
dependencies:
  health: ^10.1.0  # iOS HealthKit & Android Health Connect
```

**Features:**
1. **Sync Vitals** from wearables (Apple Watch, Fitbit, Samsung Health)
   - Heart rate
   - Blood pressure
   - Steps
   - Sleep data

2. **Auto-Assessment Suggestions** based on wearable data
   - Alert if BP spikes detected
   - Suggest assessment if HR irregular

3. **Export Data** to health apps

**Implementation:**
```dart
// lib/services/health_device_service.dart
import 'package:health/health.dart';

class HealthDeviceService {
  final HealthFactory health = HealthFactory();

  Future<bool> requestAuthorization() async {
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BODY_TEMPERATURE,
    ];

    return await health.requestAuthorization(types);
  }

  Future<Map<String, dynamic>?> getLatestVitals() async {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    try {
      final data = await health.getHealthDataFromTypes(
        yesterday,
        now,
        [
          HealthDataType.HEART_RATE,
          HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
          HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        ],
      );

      if (data.isEmpty) return null;

      // Parse and return latest values
      return {
        'heartRate': _getLatestValue(data, HealthDataType.HEART_RATE),
        'systolic': _getLatestValue(data, HealthDataType.BLOOD_PRESSURE_SYSTOLIC),
        'diastolic': _getLatestValue(data, HealthDataType.BLOOD_PRESSURE_DIASTOLIC),
      };
    } catch (e) {
      print('Error fetching health data: $e');
      return null;
    }
  }

  double? _getLatestValue(List<HealthDataPoint> data, HealthDataType type) {
    final filtered = data.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return null;
    
    filtered.sort((a, b) => b.dateTo.compareTo(a.dateTo));
    return filtered.first.value.toDouble();
  }
}
```

---

### 5.4 Gamification & Engagement
**Effort:** 3 days | **Impact:** High | **Priority:** P2

**Features:**
1. **Assessment Streak** - Track consecutive weeks/months
   - Visual flame icon with count
   - Milestone rewards (badges)
   - Social sharing

2. **Health Score** - Aggregate metric (0-100)
   - Algorithm based on assessments, vitals, consistency
   - Progress bar with level-up animation

3. **Achievements System**
   - "First Step" - Complete first assessment
   - "Consistent Care" - 4 weeks in a row
   - "Heart Hero" - Share app with 3 friends
   - "Data Donor" - Export health report

4. **Challenge Mode** (Future)
   - Weekly health challenges
   - Compete with friends (anonymized)
   - Leaderboards

**Implementation:**
```dart
// lib/services/gamification_service.dart
class GamificationService {
  static const String _prefsKey = 'gamification_data';

  Future<int> getAssessmentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonDecode(prefs.getString(_prefsKey) ?? '{}');
    return data['streak'] ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonDecode(prefs.getString(_prefsKey) ?? '{}');
    
    final lastAssessment = DateTime.parse(
      data['lastAssessment'] ?? '2000-01-01',
    );
    final now = DateTime.now();
    final daysSince = now.difference(lastAssessment).inDays;

    int streak = data['streak'] ?? 0;
    if (daysSince <= 7) {
      streak++;
      _checkStreakMilestone(streak);
    } else {
      streak = 1;
    }

    data['streak'] = streak;
    data['lastAssessment'] = now.toIso8601String();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  void _checkStreakMilestone(int streak) {
    if (streak == 4) {
      _unlockAchievement('consistent_care');
    } else if (streak == 12) {
      _unlockAchievement('yearly_warrior');
    }
  }

  Future<void> _unlockAchievement(String achievementId) async {
    // Show achievement unlock animation
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100,
        channelKey: 'achievements',
        title: '🏆 Achievement Unlocked!',
        body: _getAchievementMessage(achievementId),
        category: NotificationCategory.Status,
      ),
    );

    // Save to profile
    final prefs = await SharedPreferences.getInstance();
    final achievements = jsonDecode(
      prefs.getString('achievements') ?? '[]',
    ) as List;
    if (!achievements.contains(achievementId)) {
      achievements.add(achievementId);
      await prefs.setString('achievements', jsonEncode(achievements));
    }
  }
}
```

---

### 5.5 Telemedicine Features
**Effort:** 5 days | **Impact:** Very High | **Priority:** P2

**Features:**
1. **Video Consultation** - Integrated video calls with doctors
2. **Chat Support** - Real-time messaging with clinic staff
3. **Document Sharing** - Send/receive medical documents
4. **E-Prescriptions** - Digital prescriptions with QR codes

**Note:** Requires backend API support. Mobile app provides optimized UI.

---

## 🔧 Phase 6: Performance Optimization (Week 12)

**Goal:** Ensure app runs smoothly, loads fast, and consumes minimal resources.

### 6.1 Image Optimization
**Effort:** 1 day | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Convert all PNGs to WebP format (50-80% smaller)
- [ ] Implement cached_network_image for remote images
- [ ] Add loading skeletons for images
- [ ] Lazy load off-screen images
- [ ] Use appropriate image resolutions (1x, 2x, 3x)

```dart
// lib/presentation/widgets/jh_cached_image.dart
class JHCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const JHCachedImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: JHColors.slate200,
        highlightColor: JHColors.slate100,
        child: Container(
          color: Colors.white,
          width: width,
          height: height,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: JHColors.slate100,
        child: Icon(
          Icons.error_outline,
          color: JHColors.slate400,
        ),
      ),
    );
  }
}
```

---

### 6.2 Widget Optimization
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Tasks
- [ ] Audit build() methods for heavy computations
- [ ] Move calculations to initState() or separate functions
- [ ] Use const constructors wherever possible
- [ ] Implement RepaintBoundary for complex widgets
- [ ] Use ListView.builder instead of ListView for long lists

#### Before/After Example
```dart
// ❌ BAD: Computation in build()
Widget build(BuildContext context) {
  final riskScore = calculateRiskScore(data); // Recalculates on every build!
  return Text('Risk: $riskScore');
}

// ✅ GOOD: Computation in didUpdateWidget()
class RiskDisplay extends StatefulWidget {
  final AssessmentData data;
  
  @override
  State<RiskDisplay> createState() => _RiskDisplayState();
}

class _RiskDisplayState extends State<RiskDisplay> {
  late int _riskScore;

  @override
  void initState() {
    super.initState();
    _riskScore = calculateRiskScore(widget.data);
  }

  @override
  void didUpdateWidget(RiskDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _riskScore = calculateRiskScore(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text('Risk: $_riskScore'); // No computation!
  }
}
```

---

### 6.3 State Management Optimization
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Current State: BLoC Pattern
- Already good foundation
- Ensure proper stream disposal
- Avoid unnecessary state emissions

#### Optimization Checklist
- [ ] Audit all BLoCs for memory leaks (dispose streams)
- [ ] Use BlocBuilder only where needed, not entire screens
- [ ] Implement BlocSelector for specific state properties
- [ ] Add equatable to state classes for efficient comparison

```dart
// lib/bloc/assessment_bloc/assessment_state.dart
import 'package:equatable/equatable.dart';

abstract class AssessmentState extends Equatable {
  const AssessmentState();
  
  @override
  List<Object?> get props => [];
}

class AssessmentLoaded extends AssessmentState {
  final List<AssessmentRecord> assessments;
  final RiskTrendStats stats;

  const AssessmentLoaded({
    required this.assessments,
    required this.stats,
  });

  @override
  List<Object?> get props => [assessments, stats];
}
```

---

### 6.4 Build Size Optimization
**Effort:** 1 day | **Impact:** Medium | **Priority:** P1

#### Tasks
- [ ] Run `flutter build apk --analyze-size` to identify large dependencies
- [ ] Remove unused packages from pubspec.yaml
- [ ] Enable tree-shaking: `flutter build apk --tree-shake-icons`
- [ ] Split APK by ABI: `flutter build apk --split-per-abi`
- [ ] Enable ProGuard/R8 for Android (already in build.gradle)

#### Expected Results
- Current: ~28 MB
- Target: <20 MB (29% reduction)

---

### 6.5 Network Optimization
**Effort:** 1 day | **Impact:** High | **Priority:** P1

#### Tasks
- [ ] Implement request debouncing for search
- [ ] Cache API responses with Dio interceptor
- [ ] Use pagination for large lists
- [ ] Compress images before upload
- [ ] Prefetch next page data

```dart
// lib/core/network/cache_interceptor.dart
class CacheInterceptor extends Interceptor {
  final Dio dio;
  final Duration maxAge;

  CacheInterceptor(this.dio, {this.maxAge = const Duration(minutes: 5)});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['cache'] == true) {
      final cachedResponse = _getCachedResponse(options.uri.toString());
      if (cachedResponse != null) {
        return handler.resolve(cachedResponse);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.extra['cache'] == true) {
      _cacheResponse(
        response.requestOptions.uri.toString(),
        response,
      );
    }
    handler.next(response);
  }

  Response? _getCachedResponse(String url) {
    // Implement cache logic (Hive/SharedPreferences)
    return null;
  }

  void _cacheResponse(String url, Response response) {
    // Implement cache storage
  }
}
```

---

### 6.6 Performance Monitoring
**Effort:** 1 day | **Impact:** Medium | **Priority:** P1

#### Tasks
- [ ] Set up Firebase Performance Monitoring (already added)
- [ ] Add custom traces for key user flows
- [ ] Monitor network request times
- [ ] Track screen rendering times
- [ ] Set up alerts for performance regressions

```dart
// lib/services/performance_monitoring.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceMonitoring {
  static Future<void> trackScreenLoad(String screenName) async {
    final trace = FirebasePerformance.instance.newTrace('screen_$screenName');
    await trace.start();
    
    // Stop trace after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await trace.stop();
    });
  }

  static Future<void> trackApiCall(String endpoint) async {
    final metric = FirebasePerformance.instance
        .newHttpMetric(endpoint, HttpMethod.Get);
    await metric.start();
    
    // ... make API call ...
    
    await metric.stop();
  }
}
```

---

## 📊 Phase 7: Testing & Quality Assurance (Week 13)

**Goal:** Ensure reliability, accessibility, and excellent user experience.

### 7.1 Automated Testing
**Effort:** 3 days | **Impact:** High | **Priority:** P0

#### Test Coverage Goals
- Unit Tests: 80%+ coverage
- Widget Tests: Key components
- Integration Tests: Critical user flows

```dart
// test/widgets/jh_button_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JHButton', () {
    testWidgets('renders correctly with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JHButton(
              text: 'Click Me',
              onPressed: () {},
              variant: JHButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JHButton(
              text: 'Click Me',
              onPressed: () => pressed = true,
              variant: JHButtonVariant.primary,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(JHButton));
      expect(pressed, true);
    });

    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JHButton(
              text: 'Click Me',
              onPressed: () {},
              isLoading: true,
              variant: JHButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('meets minimum touch target size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JHButton(
              text: 'Click Me',
              onPressed: () {},
              variant: JHButtonVariant.primary,
            ),
          ),
        ),
      );

      final button = tester.widget<Container>(
        find.descendant(
          of: find.byType(JHButton),
          matching: find.byType(Container),
        ).first,
      );

      expect(
        button.constraints?.minHeight,
        greaterThanOrEqualTo(48.0),
      );
    });
  });
}
```

---

### 7.2 Accessibility Audit
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Checklist
- [ ] All interactive elements have semantic labels
- [ ] Touch targets >= 48x48px
- [ ] Text contrast ratios meet WCAG AA
- [ ] Screen reader support tested
- [ ] Keyboard navigation (external keyboard)
- [ ] Dynamic type support
- [ ] Color is not the only indicator (icons + text)

#### Tools
- Flutter DevTools Accessibility Scanner
- Android Accessibility Scanner
- iOS Accessibility Inspector

---

### 7.3 Device Testing Matrix
**Effort:** 2 days | **Impact:** High | **Priority:** P0

#### Test Devices
**Android:**
- Samsung Galaxy A series (mid-range)
- Pixel 7 (flagship)
- Older device (Android 9)

**iOS:**
- iPhone 12/13 (common)
- iPhone SE (small screen)
- iPad Air (tablet)

#### Test Scenarios
- [ ] Different screen sizes (5", 6", 6.7", 10")
- [ ] Different OS versions (Android 9-14, iOS 14-17)
- [ ] Low-end devices (performance)
- [ ] Network conditions (slow 3G, offline)
- [ ] Battery usage
- [ ] Memory usage

---

### 7.4 User Acceptance Testing
**Effort:** 3 days | **Impact:** Very High | **Priority:** P0

#### Test Group
- 10 healthcare workers
- 20 patients (varied age groups)
- 5 elderly users (accessibility focus)

#### Metrics
- Task completion rate
- Time to complete key tasks
- Error rate
- Satisfaction score (SUS)
- NPS (Net Promoter Score)

---

## 📅 Implementation Timeline

### Summary Table

| Phase | Duration | Priority | Dependencies |
|-------|----------|----------|--------------|
| Phase 1: Foundation | 2 weeks | P0 | None |
| Phase 2: Core Components | 2 weeks | P0 | Phase 1 |
| Phase 3: Advanced Components | 2 weeks | P1 | Phase 2 |
| Phase 4: Screen Redesigns | 3 weeks | P0 | Phase 3 |
| Phase 5: Mobile-Exclusive Features | 2 weeks | P1 | Phase 4 |
| Phase 6: Performance Optimization | 1 week | P0 | Phase 5 |
| Phase 7: Testing & QA | 1 week | P0 | Phase 6 |
| **Total** | **13 weeks** | | |

### Parallel Work Opportunities
- Typography migration (Phase 1) can start immediately
- Testing (Phase 7) can be ongoing throughout
- Performance monitoring setup can start early

---

## 🎯 10 Innovation Features That Surpass Web App

### 1. **Biometric Quick Access**
- Face ID/Touch ID for instant login
- Secure assessment data without passwords
- **Web can't do this:** Browser limitations on biometric APIs

### 2. **Health Device Integration**
- Auto-import vitals from Apple Health, Google Fit
- Real-time heart rate monitoring from wearables
- **Web can't do this:** No access to HealthKit/Health Connect

### 3. **Offline-First Architecture**
- Complete assessments without internet
- Smart background sync with conflict resolution
- **Web can't do this:** Service workers have limitations

### 4. **Native Camera Features**
- Document scanner for medical records
- Medication scanner (pill bottle barcodes)
- **Web can't do this:** Limited camera API access

### 5. **Context-Aware Notifications**
- Location-based reminders (near clinic)
- Time-based medication alerts
- Smart assessment prompts based on wearable data
- **Web can't do this:** Push notifications require active browser

### 6. **Gesture-Rich Navigation**
- Swipe-to-delete, long-press menus
- Pull-to-refresh global
- Haptic feedback on interactions
- **Web can't do this:** Limited gesture APIs, no haptics

### 7. **Voice Commands & Accessibility**
- "Hey Juan Heart, start assessment"
- Read results aloud for visually impaired
- **Web can't do this:** Web Speech API less reliable

### 8. **Native Performance**
- 60fps smooth animations
- Instant screen transitions
- Optimized memory usage
- **Web can't do this:** Browser overhead, garbage collection pauses

### 9. **App Shortcuts & Widgets**
- Home screen widgets showing latest vitals
- Quick action shortcuts (iOS 3D Touch, Android long-press)
- **Web can't do this:** No home screen presence

### 10. **Seamless OS Integration**
- Share to other apps (Messages, Email)
- Calendar integration for appointments
- Contacts integration for emergency contacts
- **Web can't do this:** Limited Web Share API

---

## 🛠️ Technology Recommendations

### Essential Packages (Already Added)
```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.2
  equatable: ^2.0.5
  
  # UI & Animations
  flutter_animate: ^4.5.0
  animations: ^2.0.11
  shimmer: ^3.0.0
  flutter_slidable: ^3.0.0
  
  # Networking
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Local Storage
  drift: ^2.14.0
  hive_flutter: ^1.1.0
  shared_preferences: ^2.0.18
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_performance: ^0.9.3+7
  firebase_analytics: ^10.8.0
  firebase_messaging: ^14.7.9
  
  # Charts
  fl_chart: ^0.68.0
```

### Recommended Additions
```yaml
dependencies:
  # Typography
  google_fonts: ^6.1.0
  
  # Advanced Animations
  lottie: ^3.1.0
  rive: ^0.13.0
  
  # Biometrics
  local_auth: ^2.2.0
  
  # Health Devices
  health: ^10.1.0
  
  # Camera
  camera: ^0.10.5
  image_picker: ^1.2.0
  
  # Voice
  speech_to_text: ^6.6.0
  flutter_tts: ^3.8.3
  
  # Notifications (enhanced)
  awesome_notifications: ^0.9.0
  
  # Image Optimization
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.3.1
  
  # Forms
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  
  # Icons (matching web)
  lucide_icons: ^0.288.0
```

---

## 📈 Success Metrics & KPIs

### Performance Metrics
| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| App Load Time | 3.5s | <2s | Firebase Performance |
| Frame Drop Rate | 8% | <2% | Flutter DevTools |
| Bundle Size | 28MB | <20MB | Build output |
| Memory Usage | 180MB | <120MB | DevTools Memory |
| Network Requests | 15/screen | <8/screen | Dio interceptor |

### User Experience Metrics
| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| Assessment Completion | 65% | 85%+ | Analytics events |
| User Satisfaction (SUS) | 7.2/10 | 9.0/10 | User surveys |
| Daily Active Users | - | +40% | Firebase Analytics |
| Session Duration | 4.5min | 8min+ | Analytics |
| Error Rate | 3.2% | <1% | Crashlytics |

### Business Metrics
| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| App Store Rating | - | 4.5+ stars | Store reviews |
| Referrals (Share Rate) | - | 15%+ | Share events |
| Appointment Bookings | - | +60% | Backend API |
| User Retention (30d) | - | 70%+ | Analytics cohorts |

---

## 🚨 Risk Mitigation

### Technical Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Animation performance issues | Medium | High | Extensive device testing, fallback to simpler animations |
| Health device API incompatibility | Low | Medium | Graceful degradation, manual input fallback |
| Offline sync conflicts | Medium | High | Robust conflict resolution UI, user control |
| Large bundle size | Low | Medium | Regular size audits, lazy loading |

### User Adoption Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Resistance to change | High | Medium | Gradual rollout, onboarding tutorials |
| Learning curve | Medium | Medium | Contextual help, tooltips, video guides |
| Technical literacy barrier | Medium | High | Simplified flows, voice commands, accessibility |

---

## 📚 Documentation & Training

### Developer Documentation
- [ ] Design system documentation (Storybook-style)
- [ ] Component usage guides
- [ ] Animation guidelines
- [ ] Performance best practices
- [ ] Testing guidelines

### User Documentation
- [ ] In-app tutorials (interactive)
- [ ] Video guides (YouTube)
- [ ] FAQ section
- [ ] Accessibility guide
- [ ] Troubleshooting guide

---

## 🎉 Launch Strategy

### Soft Launch (Weeks 14-15)
1. **Beta Testing**
   - TestFlight (iOS) / Internal Testing (Android)
   - 50 beta users (healthcare workers + patients)
   - Collect feedback via in-app surveys

2. **Bug Fixes & Refinements**
   - Address critical issues
   - Polish based on feedback

### Public Launch (Week 16)
1. **Phased Rollout**
   - 10% of users (Week 16)
   - 50% of users (Week 17)
   - 100% of users (Week 18)

2. **Marketing**
   - App Store optimization (ASO)
   - Social media campaign
   - Email announcement to existing users
   - Press release

3. **Monitoring**
   - Crash rate
   - Performance metrics
   - User feedback
   - Support tickets

---

## 🔄 Post-Launch Roadmap (Weeks 17+)

### v1.1 - Advanced Analytics (Week 20)
- Predictive health insights using ML
- Personalized recommendations
- Family health tracking

### v1.2 - Telemedicine (Week 24)
- In-app video consultations
- Chat with healthcare providers
- E-prescriptions

### v1.3 - Social Features (Week 28)
- Health communities
- Support groups
- Anonymous Q&A

### v2.0 - AI Assistant (Week 32)
- "Juan" - AI health companion
- Natural language assessment guidance
- Proactive health recommendations

---

## 📝 Appendix

### A. Style Guide Quick Reference
```dart
// Colors
JHColors.heartRed       // Primary CTA
JHColors.midnightBlue   // Text
JHColors.cloudWhite     // Backgrounds
JHColors.slate600       // Icons
JHColors.success        // Low risk
JHColors.warning        // Moderate risk
JHColors.danger         // High risk

// Typography
JHTextStyles.h1         // Page titles
JHTextStyles.h3         // Section headings
JHTextStyles.bodyBase   // Body text (16px)
JHTextStyles.medicalData // Vitals (JetBrains Mono)

// Spacing
JHSpacing.base          // 16px - Most common
JHSpacing.xl            // 24px - Between sections
JHSpacing.xl3           // 40px - Major sections

// Shadows
JHShadows.xs            // Subtle cards
JHShadows.md            // Elevated cards
JHShadows.lg            // Modals

// Radius
JHRadius.radiusMd       // Buttons (8px)
JHRadius.radiusBase     // Cards (12px)
JHRadius.radiusTop      // Bottom sheets (20px top)
```

### B. Animation Timing Reference
```dart
AnimationConfig.fast    // 150ms - Button press
AnimationConfig.normal  // 300ms - Page transitions
AnimationConfig.slow    // 500ms - Complex animations
AnimationConfig.heartbeatPulse // 800ms - Risk indicator
```

### C. Device Support Matrix
| Platform | Minimum Version | Recommended |
|----------|----------------|-------------|
| Android | 9.0 (API 28) | 12+ |
| iOS | 14.0 | 16+ |
| Flutter | 3.16.0 | 3.19+ |
| Dart | 3.0.0 | 3.2+ |

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Ready for Implementation  
**Estimated Completion:** April 2025 (13 weeks)

---

*This plan is a living document. Updates will be made as implementation progresses.*
