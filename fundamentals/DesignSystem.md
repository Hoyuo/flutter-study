# Flutter 디자인 시스템 구축 가이드

> **난이도**: 중급 | **카테고리**: fundamentals
> **선행 학습**: [WidgetFundamentals](./WidgetFundamentals.md), [LayoutSystem](./LayoutSystem.md)
> **예상 학습 시간**: 2h

> 이 문서는 Flutter 프로젝트에서 확장 가능하고 일관된 디자인 시스템을 구축하는 방법을 다룹니다. Design Tokens, ThemeExtension, Atomic Design 원칙을 활용하여 재사용 가능한 컴포넌트 라이브러리를 설계하고, Figma와의 협업 워크플로우를 구축하는 방법을 학습합니다.

> **학습 목표**:
> 1. Design Tokens를 정의하고 ThemeExtension을 활용하여 커스텀 테마 시스템을 구축할 수 있다
> 2. Atomic Design 원칙에 따라 Atom, Molecule, Organism 단위의 재사용 가능한 컴포넌트를 설계하고 구현할 수 있다
> 3. 라이트/다크 모드를 지원하고, Widgetbook을 활용하여 컴포넌트 카탈로그를 구축할 수 있다

---

## 목차

1. [디자인 시스템이란](#1-디자인-시스템이란)
2. [Design Tokens 정의](#2-design-tokens-정의)
3. [ThemeData 확장](#3-themedata-확장)
4. [색상 시스템](#4-색상-시스템)
5. [타이포그래피 시스템](#5-타이포그래피-시스템)
6. [아이콘 시스템](#6-아이콘-시스템)
7. [Atomic Design 컴포넌트](#7-atomic-design-컴포넌트)
8. [Figma-to-Flutter 워크플로우](#8-figma-to-flutter-워크플로우)
9. [다크 모드 구현](#9-다크-모드-구현)
10. [Widgetbook으로 컴포넌트 카탈로그 구축](#10-widgetbook으로-컴포넌트-카탈로그-구축)

---

## 1. 디자인 시스템이란

### 1.1 디자인 시스템의 필요성

디자인 시스템은 일관된 사용자 경험을 제공하기 위한 **재사용 가능한 컴포넌트와 규칙의 집합**입니다.

**장점**:
- 개발 속도 향상 (재사용 가능한 컴포넌트)
- 일관된 UI/UX
- 유지보수 용이성
- 디자이너-개발자 협업 효율화

### 1.2 디자인 시스템의 구성 요소

```dart
/// 디자인 시스템 계층 구조
///
/// 1. Design Tokens (원자 단위)
///    - 색상, 타이포그래피, 스페이싱, 라디어스, 그림자 등
///
/// 2. Foundation Components (Atom)
///    - 버튼, 인풋, 체크박스, 라디오, 칩 등
///
/// 3. Composite Components (Molecule)
///    - 카드, 리스트 타일, 폼 필드 등
///
/// 4. Pattern Components (Organism)
///    - 네비게이션 바, 앱 바, 폼, 리스트 등
///
/// 5. Templates
///    - 페이지 레이아웃, 스크린 템플릿
```

### 1.3 Atomic Design 원칙

Brad Frost의 Atomic Design 방법론을 Flutter에 적용:

```dart
// Atoms: 가장 작은 단위의 컴포넌트
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// Molecules: Atom을 조합한 컴포넌트
class FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;

  const FormField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label), // Atom
        const SizedBox(height: 8), // Atom (spacing)
        TextField(controller: controller), // Atom
        if (errorText != null) Text(errorText!), // Atom
      ],
    );
  }
}

// Organisms: Molecule을 조합한 복잡한 컴포넌트
class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormField(
          label: '이메일',
          controller: emailController,
        ), // Molecule
        const SizedBox(height: 16),
        FormField(
          label: '비밀번호',
          controller: passwordController,
        ), // Molecule
        const SizedBox(height: 24),
        AppButton(
          label: '로그인',
          onPressed: onLogin,
        ), // Atom
      ],
    );
  }
}
```

---

## 2. Design Tokens 정의

### 2.1 색상 토큰

```dart
/// 색상 팔레트
///
/// Flutter 3.27+: Color(int) 생성자는 deprecated → Color.fromARGB32(int) 사용
class ColorTokens {
  // Primary Colors
  static const primary50 = Color.fromARGB32(0xFFE3F2FD);
  static const primary100 = Color.fromARGB32(0xFFBBDEFB);
  static const primary200 = Color.fromARGB32(0xFF90CAF9);
  static const primary300 = Color.fromARGB32(0xFF64B5F6);
  static const primary400 = Color.fromARGB32(0xFF42A5F5);
  static const primary500 = Color.fromARGB32(0xFF2196F3); // Main
  static const primary600 = Color.fromARGB32(0xFF1E88E5);
  static const primary700 = Color.fromARGB32(0xFF1976D2);
  static const primary800 = Color.fromARGB32(0xFF1565C0);
  static const primary900 = Color.fromARGB32(0xFF0D47A1);

  // Secondary Colors
  static const secondary50 = Color.fromARGB32(0xFFF3E5F5);
  static const secondary100 = Color.fromARGB32(0xFFE1BEE7);
  static const secondary200 = Color.fromARGB32(0xFFCE93D8);
  static const secondary300 = Color.fromARGB32(0xFFBA68C8);
  static const secondary400 = Color.fromARGB32(0xFFAB47BC);
  static const secondary500 = Color.fromARGB32(0xFF9C27B0); // Main
  static const secondary600 = Color.fromARGB32(0xFF8E24AA);
  static const secondary700 = Color.fromARGB32(0xFF7B1FA2);
  static const secondary800 = Color.fromARGB32(0xFF6A1B9A);
  static const secondary900 = Color.fromARGB32(0xFF4A148C);

  // Neutral Colors (Grayscale)
  static const neutral0 = Color.fromARGB32(0xFFFFFFFF);
  static const neutral50 = Color.fromARGB32(0xFFFAFAFA);
  static const neutral100 = Color.fromARGB32(0xFFF5F5F5);
  static const neutral200 = Color.fromARGB32(0xFFEEEEEE);
  static const neutral300 = Color.fromARGB32(0xFFE0E0E0);
  static const neutral400 = Color.fromARGB32(0xFFBDBDBD);
  static const neutral500 = Color.fromARGB32(0xFF9E9E9E);
  static const neutral600 = Color.fromARGB32(0xFF757575);
  static const neutral700 = Color.fromARGB32(0xFF616161);
  static const neutral800 = Color.fromARGB32(0xFF424242);
  static const neutral900 = Color.fromARGB32(0xFF212121);
  static const neutral1000 = Color.fromARGB32(0xFF000000);

  // Semantic Colors
  static const success = Color.fromARGB32(0xFF4CAF50);
  static const successLight = Color.fromARGB32(0xFFE8F5E9);
  static const successDark = Color.fromARGB32(0xFF2E7D32);

  static const error = Color.fromARGB32(0xFFF44336);
  static const errorLight = Color.fromARGB32(0xFFFFEBEE);
  static const errorDark = Color.fromARGB32(0xFFC62828);

  static const warning = Color.fromARGB32(0xFFFF9800);
  static const warningLight = Color.fromARGB32(0xFFFFF3E0);
  static const warningDark = Color.fromARGB32(0xFFE65100);

  static const info = Color.fromARGB32(0xFF2196F3);
  static const infoLight = Color.fromARGB32(0xFFE3F2FD);
  static const infoDark = Color.fromARGB32(0xFF1565C0);
}
```

### 2.2 타이포그래피 토큰

```dart
/// 타이포그래피 토큰
class TypographyTokens {
  // Font Families
  static const String fontFamilyPrimary = 'Pretendard';
  static const String fontFamilySecondary = 'NotoSans';
  static const String fontFamilyMono = 'RobotoMono';

  // Font Sizes
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  static const double fontSize32 = 32.0;
  static const double fontSize36 = 36.0;
  static const double fontSize48 = 48.0;

  // Font Weights
  static const FontWeight fontWeightThin = FontWeight.w100;
  static const FontWeight fontWeightExtraLight = FontWeight.w200;
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // Line Heights
  static const double lineHeight1_2 = 1.2;
  static const double lineHeight1_4 = 1.4;
  static const double lineHeight1_5 = 1.5;
  static const double lineHeight1_6 = 1.6;
  static const double lineHeight1_8 = 1.8;
  static const double lineHeight2_0 = 2.0;

  // Letter Spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingExtraWide = 1.0;
}
```

### 2.3 스페이싱 토큰

```dart
/// 스페이싱 토큰 (4px 기반 그리드)
class SpacingTokens {
  static const double space0 = 0.0;
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;

  // Named Spacing
  static const double spacingXxs = space4;
  static const double spacingXs = space8;
  static const double spacingSm = space12;
  static const double spacingMd = space16;
  static const double spacingLg = space24;
  static const double spacingXl = space32;
  static const double spacingXxl = space48;
}
```

### 2.4 라디어스와 그림자 토큰

```dart
/// 라디어스 토큰
class RadiusTokens {
  static const double radiusNone = 0.0;
  static const double radiusXs = 2.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999.0;

  // Border Radius
  static final BorderRadius borderRadiusNone = BorderRadius.circular(radiusNone);
  static final BorderRadius borderRadiusXs = BorderRadius.circular(radiusXs);
  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(radiusXxl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(radiusFull);
}

/// 그림자 토큰
class ShadowTokens {
  static const List<BoxShadow> shadowNone = [];

  static final List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}
```

---

## 3. ThemeData 확장

### 3.1 ThemeExtension 기본

```dart
/// 커스텀 테마 확장
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color primaryGradientStart;
  final Color primaryGradientEnd;
  final Color cardBackground;
  final Color cardBorder;
  final Color inputBackground;
  final Color inputBorder;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppColors({
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.cardBackground,
    required this.cardBorder,
    required this.inputBackground,
    required this.inputBorder,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? primaryGradientStart,
    Color? primaryGradientEnd,
    Color? cardBackground,
    Color? cardBorder,
    Color? inputBackground,
    Color? inputBorder,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppColors(
      primaryGradientStart: primaryGradientStart ?? this.primaryGradientStart,
      primaryGradientEnd: primaryGradientEnd ?? this.primaryGradientEnd,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) return this;

    return AppColors(
      primaryGradientStart: Color.lerp(primaryGradientStart, other.primaryGradientStart, t)!,
      primaryGradientEnd: Color.lerp(primaryGradientEnd, other.primaryGradientEnd, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }

  // Light Theme
  static const light = AppColors(
    primaryGradientStart: ColorTokens.primary500,
    primaryGradientEnd: ColorTokens.primary700,
    cardBackground: ColorTokens.neutral0,
    cardBorder: ColorTokens.neutral200,
    inputBackground: ColorTokens.neutral50,
    inputBorder: ColorTokens.neutral300,
    divider: ColorTokens.neutral200,
    shimmerBase: ColorTokens.neutral200,
    shimmerHighlight: ColorTokens.neutral50,
  );

  // Dark Theme
  static const dark = AppColors(
    primaryGradientStart: ColorTokens.primary400,
    primaryGradientEnd: ColorTokens.primary600,
    cardBackground: ColorTokens.neutral800,
    cardBorder: ColorTokens.neutral700,
    inputBackground: ColorTokens.neutral900,
    inputBorder: ColorTokens.neutral600,
    divider: ColorTokens.neutral700,
    shimmerBase: ColorTokens.neutral800,
    shimmerHighlight: ColorTokens.neutral700,
  );
}

// 사용법
extension AppColorsExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
```

### 3.2 여러 ThemeExtension 조합

```dart
/// 스페이싱 테마 확장
@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  @override
  ThemeExtension<AppSpacing> copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  ThemeExtension<AppSpacing> lerp(
    ThemeExtension<AppSpacing>? other,
    double t,
  ) {
    if (other is! AppSpacing) return this;

    return AppSpacing(
      xs: (xs + (other.xs - xs) * t),
      sm: (sm + (other.sm - sm) * t),
      md: (md + (other.md - md) * t),
      lg: (lg + (other.lg - lg) * t),
      xl: (xl + (other.xl - xl) * t),
    );
  }

  static const standard = AppSpacing(
    xs: SpacingTokens.spacingXs,
    sm: SpacingTokens.spacingSm,
    md: SpacingTokens.spacingMd,
    lg: SpacingTokens.spacingLg,
    xl: SpacingTokens.spacingXl,
  );
}

/// 라디어스 테마 확장
@immutable
class AppRadius extends ThemeExtension<AppRadius> {
  final BorderRadius sm;
  final BorderRadius md;
  final BorderRadius lg;
  final BorderRadius full;

  const AppRadius({
    required this.sm,
    required this.md,
    required this.lg,
    required this.full,
  });

  @override
  ThemeExtension<AppRadius> copyWith({
    BorderRadius? sm,
    BorderRadius? md,
    BorderRadius? lg,
    BorderRadius? full,
  }) {
    return AppRadius(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      full: full ?? this.full,
    );
  }

  @override
  ThemeExtension<AppRadius> lerp(
    ThemeExtension<AppRadius>? other,
    double t,
  ) {
    if (other is! AppRadius) return this;

    return AppRadius(
      sm: BorderRadius.lerp(sm, other.sm, t)!,
      md: BorderRadius.lerp(md, other.md, t)!,
      lg: BorderRadius.lerp(lg, other.lg, t)!,
      full: BorderRadius.lerp(full, other.full, t)!,
    );
  }

  static final standard = AppRadius(
    sm: RadiusTokens.borderRadiusSm,
    md: RadiusTokens.borderRadiusMd,
    lg: RadiusTokens.borderRadiusLg,
    full: RadiusTokens.borderRadiusFull,
  );
}

// 확장 메서드
extension AppSpacingExtension on BuildContext {
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
}

extension AppRadiusExtension on BuildContext {
  AppRadius get radius => Theme.of(this).extension<AppRadius>()!;
}
```

### 3.3 통합 테마 생성

```dart
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorTokens.primary500,
        brightness: Brightness.light,
      ),
      extensions: [
        AppColors.light,
        AppSpacing.standard,
        AppRadius.standard,
      ],
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(false),
      cardTheme: _buildCardTheme(false),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorTokens.primary500,
        brightness: Brightness.dark,
      ),
      extensions: [
        AppColors.dark,
        AppSpacing.standard,
        AppRadius.standard,
      ],
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(true),
      cardTheme: _buildCardTheme(true),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: TypographyTokens.fontSize48,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeight1_2,
      ),
      displayMedium: TextStyle(
        fontSize: TypographyTokens.fontSize36,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeight1_2,
      ),
      displaySmall: TextStyle(
        fontSize: TypographyTokens.fontSize32,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeight1_2,
      ),
      headlineLarge: TextStyle(
        fontSize: TypographyTokens.fontSize28,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeight1_4,
      ),
      headlineMedium: TextStyle(
        fontSize: TypographyTokens.fontSize24,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeight1_4,
      ),
      headlineSmall: TextStyle(
        fontSize: TypographyTokens.fontSize20,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeight1_4,
      ),
      titleLarge: TextStyle(
        fontSize: TypographyTokens.fontSize18,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_5,
      ),
      titleMedium: TextStyle(
        fontSize: TypographyTokens.fontSize16,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_5,
      ),
      titleSmall: TextStyle(
        fontSize: TypographyTokens.fontSize14,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_5,
      ),
      bodyLarge: TextStyle(
        fontSize: TypographyTokens.fontSize16,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeight1_6,
      ),
      bodyMedium: TextStyle(
        fontSize: TypographyTokens.fontSize14,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeight1_6,
      ),
      bodySmall: TextStyle(
        fontSize: TypographyTokens.fontSize12,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeight1_6,
      ),
      labelLarge: TextStyle(
        fontSize: TypographyTokens.fontSize14,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_4,
      ),
      labelMedium: TextStyle(
        fontSize: TypographyTokens.fontSize12,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_4,
      ),
      labelSmall: TextStyle(
        fontSize: TypographyTokens.fontSize10,
        fontWeight: TypographyTokens.fontWeightMedium,
        height: TypographyTokens.lineHeight1_4,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.spacingLg,
          vertical: SpacingTokens.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.borderRadiusMd,
        ),
        textStyle: const TextStyle(
          fontSize: TypographyTokens.fontSize16,
          fontWeight: TypographyTokens.fontWeightSemiBold,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.spacingLg,
          vertical: SpacingTokens.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: RadiusTokens.borderRadiusMd,
        ),
        side: const BorderSide(width: 1.5),
        textStyle: const TextStyle(
          fontSize: TypographyTokens.fontSize16,
          fontWeight: TypographyTokens.fontWeightSemiBold,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? ColorTokens.neutral900 : ColorTokens.neutral50,
      border: OutlineInputBorder(
        borderRadius: RadiusTokens.borderRadiusMd,
        borderSide: BorderSide(
          color: isDark ? ColorTokens.neutral600 : ColorTokens.neutral300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.borderRadiusMd,
        borderSide: BorderSide(
          color: isDark ? ColorTokens.neutral600 : ColorTokens.neutral300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.borderRadiusMd,
        borderSide: const BorderSide(
          color: ColorTokens.primary500,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: RadiusTokens.borderRadiusMd,
        borderSide: const BorderSide(
          color: ColorTokens.error,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spacingMd,
        vertical: SpacingTokens.spacingMd,
      ),
    );
  }

  static CardTheme _buildCardTheme(bool isDark) {
    return CardTheme(
      color: isDark ? ColorTokens.neutral800 : ColorTokens.neutral0,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: RadiusTokens.borderRadiusLg,
        side: BorderSide(
          color: isDark ? ColorTokens.neutral700 : ColorTokens.neutral200,
        ),
      ),
    );
  }
}
```

---

## 4. 색상 시스템

### 4.1 시맨틱 컬러

```dart
/// 시맨틱 컬러 (의미 기반 색상)
class SemanticColors {
  // Text Colors
  static const Color textPrimary = ColorTokens.neutral900;
  static const Color textSecondary = ColorTokens.neutral600;
  static const Color textTertiary = ColorTokens.neutral500;
  static const Color textDisabled = ColorTokens.neutral400;
  static const Color textInverse = ColorTokens.neutral0;

  static const Color textPrimaryDark = ColorTokens.neutral50;
  static const Color textSecondaryDark = ColorTokens.neutral300;
  static const Color textTertiaryDark = ColorTokens.neutral400;
  static const Color textDisabledDark = ColorTokens.neutral600;
  static const Color textInverseDark = ColorTokens.neutral900;

  // Background Colors
  static const Color backgroundPrimary = ColorTokens.neutral0;
  static const Color backgroundSecondary = ColorTokens.neutral50;
  static const Color backgroundTertiary = ColorTokens.neutral100;

  static const Color backgroundPrimaryDark = ColorTokens.neutral900;
  static const Color backgroundSecondaryDark = ColorTokens.neutral800;
  static const Color backgroundTertiaryDark = ColorTokens.neutral700;

  // Border Colors
  static const Color borderPrimary = ColorTokens.neutral300;
  static const Color borderSecondary = ColorTokens.neutral200;
  static const Color borderFocus = ColorTokens.primary500;

  static const Color borderPrimaryDark = ColorTokens.neutral600;
  static const Color borderSecondaryDark = ColorTokens.neutral700;
  static const Color borderFocusDark = ColorTokens.primary400;

  // Status Colors
  static const Color statusSuccess = ColorTokens.success;
  static const Color statusError = ColorTokens.error;
  static const Color statusWarning = ColorTokens.warning;
  static const Color statusInfo = ColorTokens.info;
}

extension SemanticColorsExtension on BuildContext {
  Color get textPrimary =>
      Theme.of(this).brightness == Brightness.light
          ? SemanticColors.textPrimary
          : SemanticColors.textPrimaryDark;

  Color get textSecondary =>
      Theme.of(this).brightness == Brightness.light
          ? SemanticColors.textSecondary
          : SemanticColors.textSecondaryDark;

  Color get backgroundPrimary =>
      Theme.of(this).brightness == Brightness.light
          ? SemanticColors.backgroundPrimary
          : SemanticColors.backgroundPrimaryDark;
}
```

### 4.2 색상 유틸리티

```dart
extension ColorExtensions on Color {
  /// 색상 밝기 조절
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// 색상 투명도 조절
  ///
  /// > ⚠️ **Flutter 3.27+**: Color 클래스에 `withAlpha(int alpha)` 메서드가 이미 존재하므로,
  /// > extension으로 정의하면 인스턴스 메서드가 우선되어 이 extension은 호출되지 않습니다.
  /// >
  /// > **권장 사용법:**
  /// > - Flutter 3.27+: `color.withValues(alpha: 0.5)` (0.0~1.0 범위)
  /// > - 또는 기존 메서드: `color.withAlpha(128)` (0~255 범위)
  ///
  /// 참고: 아래 코드는 교육 목적으로만 남겨두었습니다.
  // Color withAlpha(int alpha) {
  //   return Color.fromARGB(alpha, red, green, blue);
  // }

  /// 색상 대비 텍스트 색상 반환
  Color get onColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  /// HEX 문자열로 변환
  String toHex() {
    return '#${value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

/// HEX 문자열에서 색상 생성
extension ColorFromHex on String {
  Color toColor() {
    String hex = replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color.fromARGB32(int.parse(hex, radix: 16));
  }
}
```

---

## 5. 타이포그래피 시스템

### 5.1 한글 폰트 설정

```dart
// pubspec.yaml
/*
fonts:
  - family: Pretendard
    fonts:
      - asset: assets/fonts/Pretendard-Thin.otf
        weight: 100
      - asset: assets/fonts/Pretendard-ExtraLight.otf
        weight: 200
      - asset: assets/fonts/Pretendard-Light.otf
        weight: 300
      - asset: assets/fonts/Pretendard-Regular.otf
        weight: 400
      - asset: assets/fonts/Pretendard-Medium.otf
        weight: 500
      - asset: assets/fonts/Pretendard-SemiBold.otf
        weight: 600
      - asset: assets/fonts/Pretendard-Bold.otf
        weight: 700
      - asset: assets/fonts/Pretendard-ExtraBold.otf
        weight: 800
      - asset: assets/fonts/Pretendard-Black.otf
        weight: 900
*/

class AppFonts {
  static const String pretendard = 'Pretendard';

  static TextTheme get pretendardTextTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontFamily: pretendard),
      displayMedium: TextStyle(fontFamily: pretendard),
      displaySmall: TextStyle(fontFamily: pretendard),
      headlineLarge: TextStyle(fontFamily: pretendard),
      headlineMedium: TextStyle(fontFamily: pretendard),
      headlineSmall: TextStyle(fontFamily: pretendard),
      titleLarge: TextStyle(fontFamily: pretendard),
      titleMedium: TextStyle(fontFamily: pretendard),
      titleSmall: TextStyle(fontFamily: pretendard),
      bodyLarge: TextStyle(fontFamily: pretendard),
      bodyMedium: TextStyle(fontFamily: pretendard),
      bodySmall: TextStyle(fontFamily: pretendard),
      labelLarge: TextStyle(fontFamily: pretendard),
      labelMedium: TextStyle(fontFamily: pretendard),
      labelSmall: TextStyle(fontFamily: pretendard),
    );
  }
}
```

### 5.2 Google Fonts 활용

```dart
// pubspec.yaml
/*
dependencies:
  google_fonts: ^8.0.1
*/

import 'package:google_fonts/google_fonts.dart';

class AppThemeWithGoogleFonts {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorTokens.primary500,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      // 또는 특정 폰트만
      // textTheme: TextTheme(
      //   headlineLarge: GoogleFonts.poppins(
      //     fontSize: 32,
      //     fontWeight: FontWeight.bold,
      //   ),
      // ),
    );
  }
}
```

### 5.3 타이포그래피 유틸리티

```dart
extension TextStyleExtensions on TextStyle {
  /// 폰트 크기 변경
  TextStyle size(double fontSize) => copyWith(fontSize: fontSize);

  /// 폰트 두께 변경
  TextStyle weight(FontWeight fontWeight) => copyWith(fontWeight: fontWeight);

  /// 색상 변경
  TextStyle colored(Color color) => copyWith(color: color);

  /// 행간 변경
  TextStyle height(double height) => copyWith(height: height);

  /// 자간 변경
  TextStyle spacing(double letterSpacing) => copyWith(letterSpacing: letterSpacing);

  /// Bold
  TextStyle get bold => weight(FontWeight.bold);

  /// SemiBold
  TextStyle get semiBold => weight(FontWeight.w600);

  /// Medium
  TextStyle get medium => weight(FontWeight.w500);

  /// Regular
  TextStyle get regular => weight(FontWeight.w400);

  /// Light
  TextStyle get light => weight(FontWeight.w300);

  /// Italic
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  /// Underline
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
}

// 사용 예제
class TypographyExample extends StatelessWidget {
  const TypographyExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '제목',
          style: theme.textTheme.headlineLarge?.bold.colored(Colors.blue),
        ),
        Text(
          '부제목',
          style: theme.textTheme.titleMedium?.semiBold.height(1.5),
        ),
        Text(
          '본문',
          style: theme.textTheme.bodyMedium?.regular.spacing(0.5),
        ),
      ],
    );
  }
}
```

---

## 6. 아이콘 시스템

### 6.1 커스텀 아이콘 폰트

```dart
// pubspec.yaml
/*
fonts:
  - family: CustomIcons
    fonts:
      - asset: assets/fonts/CustomIcons.ttf
*/

class CustomIcons {
  CustomIcons._();

  static const String _fontFamily = 'CustomIcons';

  static const IconData home = IconData(0xe900, fontFamily: _fontFamily);
  static const IconData search = IconData(0xe901, fontFamily: _fontFamily);
  static const IconData settings = IconData(0xe902, fontFamily: _fontFamily);
  static const IconData profile = IconData(0xe903, fontFamily: _fontFamily);
  static const IconData notification = IconData(0xe904, fontFamily: _fontFamily);
}

// 사용 예제
Icon(CustomIcons.home, size: 24, color: Colors.blue)
```

### 6.2 SVG 아이콘 관리

```dart
// pubspec.yaml
/*
dependencies:
  flutter_svg: ^2.2.3
*/

import 'package:flutter_svg/flutter_svg.dart';

class SvgIcons {
  static const String _basePath = 'assets/icons';

  static const String home = '$_basePath/home.svg';
  static const String search = '$_basePath/search.svg';
  static const String settings = '$_basePath/settings.svg';
}

class AppIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;

  const AppIcon(
    this.assetPath, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

// 사용 예제
AppIcon(SvgIcons.home, size: 24, color: Colors.blue)
```

---

## 7. Atomic Design 컴포넌트

### 7.1 Atoms (원자)

```dart
/// Primary Button (Atom)
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonSize size;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(64, _getHeight(size)),
        padding: EdgeInsets.symmetric(
          horizontal: _getHorizontalPadding(size),
          vertical: _getVerticalPadding(size),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: _getIconSize(size),
              height: _getIconSize(size),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _getIconSize(size)),
                  SizedBox(width: spacing.xs),
                ],
                Text(label),
              ],
            ),
    );
  }

  double _getHeight(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => 36,
      ButtonSize.medium => 48,
      ButtonSize.large => 56,
    };
  }

  double _getHorizontalPadding(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => SpacingTokens.spacingMd,
      ButtonSize.medium => SpacingTokens.spacingLg,
      ButtonSize.large => SpacingTokens.spacingXl,
    };
  }

  double _getVerticalPadding(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => SpacingTokens.spacingXs,
      ButtonSize.medium => SpacingTokens.spacingMd,
      ButtonSize.large => SpacingTokens.spacingLg,
    };
  }

  double _getIconSize(ButtonSize size) {
    return switch (size) {
      ButtonSize.small => 16,
      ButtonSize.medium => 20,
      ButtonSize.large => 24,
    };
  }
}

enum ButtonSize { small, medium, large }

/// Input Field (Atom)
class AppTextField extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;

  const AppTextField({
    super.key,
    this.label,
    this.placeholder,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: SpacingTokens.spacingXs),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
```

### 7.2 Molecules (분자)

```dart
/// Card with Image (Molecule)
class ImageCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const ImageCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final radius = context.radius;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: ColorTokens.neutral200,
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: spacing.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List Item with Avatar (Molecule)
class AvatarListTile extends StatelessWidget {
  final String avatarUrl;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AvatarListTile({
    super.key,
    required this.avatarUrl,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: const Icon(Icons.person),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
```

### 7.3 Organisms (유기체)

```dart
/// Login Form (Organism)
class LoginFormOrganism extends StatefulWidget {
  final ValueChanged<LoginCredentials> onLogin;

  const LoginFormOrganism({
    super.key,
    required this.onLogin,
  });

  @override
  State<LoginFormOrganism> createState() => _LoginFormOrganismState();
}

class _LoginFormOrganismState extends State<LoginFormOrganism> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: '이메일',
          placeholder: 'example@email.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        SizedBox(height: spacing.lg),
        AppTextField(
          label: '비밀번호',
          placeholder: '비밀번호를 입력하세요',
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          errorText: _passwordError,
          prefixIcon: const Icon(Icons.lock_outlined),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
          ),
        ),
        SizedBox(height: spacing.xl),
        PrimaryButton(
          label: '로그인',
          onPressed: _handleLogin,
          icon: Icons.login,
        ),
        SizedBox(height: spacing.md),
        TextButton(
          onPressed: () {},
          child: const Text('비밀번호를 잊으셨나요?'),
        ),
      ],
    );
  }

  void _handleLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = '이메일을 입력하세요');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = '올바른 이메일 형식이 아닙니다');
      return;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = '비밀번호를 입력하세요');
      return;
    }

    if (password.length < 8) {
      setState(() => _passwordError = '비밀번호는 8자 이상이어야 합니다');
      return;
    }

    widget.onLogin(LoginCredentials(email: email, password: password));
  }
}

class LoginCredentials {
  final String email;
  final String password;

  const LoginCredentials({
    required this.email,
    required this.password,
  });
}
```

---

## 8. Figma-to-Flutter 워크플로우

### 8.1 디자인 토큰 동기화

Figma에서 Design Tokens 추출 및 Flutter 코드 생성:

```dart
// Figma Tokens 플러그인 사용
// JSON 내보내기 → Dart 코드 생성

// figma_tokens.json
/*
{
  "colors": {
    "primary": {
      "500": { "value": "#2196F3", "type": "color" }
    }
  },
  "spacing": {
    "md": { "value": "16px", "type": "dimension" }
  }
}
*/

// 자동 생성된 Dart 코드
class FigmaTokens {
  static const primary500 = Color.fromARGB32(0xFF2196F3);
  static const spacingMd = 16.0;
}
```

### 8.2 컴포넌트 매핑

```dart
/// Figma 컴포넌트 → Flutter 위젯 매핑
///
/// Figma Component Name: Button/Primary/Medium
/// Flutter Widget: PrimaryButton(size: ButtonSize.medium)
///
/// Naming Convention:
/// - Category/Variant/Size
/// - Button/Primary/Medium → PrimaryButton
/// - Input/Text/Default → AppTextField
```

---

## 9. 다크 모드 구현

### 9.1 테마 전환

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}

// main.dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const HomePage(),
    );
  }
}
```

### 9.2 시스템 설정 연동

```dart
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('테마 설정')),
      body: ListView(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('라이트 모드'),
            value: ThemeMode.light,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('다크 모드'),
            value: ThemeMode.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('시스템 설정 따르기'),
            value: ThemeMode.system,
            groupValue: themeProvider.themeMode,
            onChanged: (mode) => themeProvider.setThemeMode(mode!),
          ),
        ],
      ),
    );
  }
}
```

### 9.3 테마 전환 (Bloc 패턴)

Bloc 패턴과 SharedPreferences를 활용한 테마 전환 구현입니다. 사용자 설정을 영구 저장하고, 시스템 테마 감지 + 수동 전환을 모두 지원합니다.

#### Theme State

```dart
// lib/features/settings/presentation/bloc/theme_state.dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_state.freezed.dart';

@freezed
class ThemeState with _$ThemeState {
  const factory ThemeState({
    required ThemeMode themeMode,
  }) = _ThemeState;

  factory ThemeState.initial() => const ThemeState(
        themeMode: ThemeMode.system,
      );
}
```

#### Theme Event

```dart
// lib/features/settings/presentation/bloc/theme_event.dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_event.freezed.dart';

@freezed
class ThemeEvent with _$ThemeEvent {
  const factory ThemeEvent.changed(ThemeMode themeMode) = _Changed;
  const factory ThemeEvent.loaded() = _Loaded;
}
```

#### Theme Bloc

```dart
// lib/features/settings/presentation/bloc/theme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_theme_mode_usecase.dart';
import '../../domain/usecases/save_theme_mode_usecase.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemeModeUseCase _getThemeModeUseCase;
  final SaveThemeModeUseCase _saveThemeModeUseCase;

  ThemeBloc({
    required GetThemeModeUseCase getThemeModeUseCase,
    required SaveThemeModeUseCase saveThemeModeUseCase,
  })  : _getThemeModeUseCase = getThemeModeUseCase,
        _saveThemeModeUseCase = saveThemeModeUseCase,
        super(ThemeState.initial()) {
    on<ThemeEvent>((event, emit) async {
      await event.when(
        changed: (themeMode) => _onChanged(themeMode, emit),
        loaded: () => _onLoaded(emit),
      );
    });
  }

  Future<void> _onLoaded(Emitter<ThemeState> emit) async {
    final result = await _getThemeModeUseCase();

    result.fold(
      (failure) => null,  // 실패 시 기본값 유지
      (themeMode) => emit(state.copyWith(themeMode: themeMode)),
    );
  }

  Future<void> _onChanged(
    ThemeMode themeMode,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(themeMode: themeMode));
    await _saveThemeModeUseCase(themeMode);
  }
}
```

#### Theme 저장/로드 (Repository)

```dart
// lib/features/settings/data/repositories/theme_repository_impl.dart
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final SharedPreferences _prefs;

  static const _themeModeKey = 'theme_mode';

  ThemeRepositoryImpl(this._prefs);

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final value = _prefs.getString(_themeModeKey);

      final themeMode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      return Right(themeMode);
    } catch (e) {
      return Left(Failure.cache(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode themeMode) async {
    try {
      final value = switch (themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

      await _prefs.setString(_themeModeKey, value);
      return const Right(null);
    } catch (e) {
      return Left(Failure.cache(message: e.toString()));
    }
  }
}
```

#### App에 ThemeBloc 적용

```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: state.themeMode,
          // ...
        );
      },
    );
  }
}
```

#### 테마 설정 UI (Bloc 버전)

```dart
class ThemeSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('테마 설정')),
          body: ListView(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('시스템 설정'),
                subtitle: const Text('기기 설정에 따라 자동 변경'),
                value: ThemeMode.system,
                groupValue: state.themeMode,
                onChanged: (value) {
                  context.read<ThemeBloc>().add(ThemeEvent.changed(value!));
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('라이트 모드'),
                value: ThemeMode.light,
                groupValue: state.themeMode,
                onChanged: (value) {
                  context.read<ThemeBloc>().add(ThemeEvent.changed(value!));
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('다크 모드'),
                value: ThemeMode.dark,
                groupValue: state.themeMode,
                onChanged: (value) {
                  context.read<ThemeBloc>().add(ThemeEvent.changed(value!));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

---

## 10. Widgetbook으로 컴포넌트 카탈로그 구축

### 10.1 Widgetbook 설정

```dart
// pubspec.yaml
/*
dev_dependencies:
  widgetbook: ^3.20.2
  widgetbook_annotation: ^3.1.0
  build_runner: ^2.4.15
  widgetbook_generator: ^3.20.0
*/

// widgetbook/widgetbook.dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook(
      appBuilder: (context, child) {
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: child,
        );
      },
      directories: [
        WidgetbookCategory(
          name: 'Atoms',
          children: [
            WidgetbookComponent(
              name: 'Buttons',
              useCases: [
                WidgetbookUseCase(
                  name: 'Primary Button',
                  builder: (context) => Center(
                    child: PrimaryButton(
                      label: context.knobs.string(
                        label: 'Label',
                        initialValue: 'Primary Button',
                      ),
                      onPressed: () {},
                      size: context.knobs.list(
                        label: 'Size',
                        options: ButtonSize.values,
                        initialOption: ButtonSize.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
```

### 10.2 Widgetbook 실행

```bash
flutter run -t widgetbook/widgetbook.dart -d chrome
```

---

## 실습 과제

### 과제 1: 완전한 디자인 시스템 구축

다음 요구사항을 만족하는 디자인 시스템을 구축하세요:

1. **Design Tokens**
   - 색상 팔레트 (Primary, Secondary, Neutral, Semantic)
   - 타이포그래피 (5단계 크기, 3단계 두께)
   - 스페이싱 (8px 그리드 기반)
   - 라디어스, 그림자

2. **ThemeExtension**
   - AppColors, AppSpacing, AppRadius 구현
   - 라이트/다크 테마 지원

3. **Foundation Components**
   - 버튼 (Primary, Secondary, Text)
   - 인풋 (Text, Password, Search)
   - 체크박스, 라디오, 스위치

**추가 요구사항**:
- 모든 컴포넌트 재사용 가능하게 설계
- 접근성 고려 (Semantics, 충분한 터치 영역)
- 애니메이션 추가

### 과제 2: Atomic Design 적용

Atomic Design 원칙에 따라 다음 컴포넌트를 구현하세요:

1. **Atoms**
   - Avatar
   - Badge
   - Chip
   - Icon Button

2. **Molecules**
   - Search Bar (Input + Icon + Clear Button)
   - Product Card (Image + Title + Price + Button)
   - User Profile Header (Avatar + Name + Bio)

3. **Organisms**
   - Navigation Bar (Logo + Menu Items + Actions)
   - Product List (Filter + Sort + Grid of Product Cards)
   - Comment Section (Input + List of Comments)

**추가 요구사항**:
- 각 컴포넌트를 별도 파일로 분리
- 디자인 시스템 토큰 활용
- Storybook/Widgetbook 추가

### 과제 3: 다크 모드와 컴포넌트 카탈로그

다음 요구사항을 만족하는 테마 시스템을 구축하세요:

1. **다크 모드**
   - 라이트/다크/시스템 모드 전환
   - SharedPreferences로 설정 저장
   - 부드러운 테마 전환 애니메이션

2. **Widgetbook 통합**
   - 모든 Atom/Molecule 컴포넌트 등록
   - Knobs로 속성 조정 가능
   - 다크/라이트 모드 프리뷰

3. **테마 커스터마이징**
   - 사용자가 Primary 색상 선택 가능
   - 폰트 크기 배율 조정 (0.8x ~ 1.2x)
   - 라디어스 스타일 선택 (Sharp, Rounded, Circular)

**추가 요구사항**:
- ThemeExtension 활용
- 실시간 테마 프리뷰
- 설정 초기화 기능

---

## Self-Check

다음 항목을 모두 이해하고 구현할 수 있는지 확인하세요:

- [ ] Design Tokens (색상, 타이포그래피, 스페이싱, 라디어스, 그림자)를 정의하고, 일관된 디자인 시스템을 구축할 수 있다
- [ ] ThemeExtension을 활용하여 커스텀 테마 속성을 추가하고, context에서 쉽게 접근할 수 있는 확장 메서드를 구현할 수 있다
- [ ] Semantic Colors를 정의하여 의미 기반 색상 시스템을 구축하고, 라이트/다크 모드에 따라 적절한 색상을 반환할 수 있다
- [ ] Atomic Design 원칙에 따라 Atom, Molecule, Organism 단위로 컴포넌트를 분류하고 설계할 수 있다
- [ ] 재사용 가능한 Foundation Components (버튼, 인풋, 체크박스 등)를 구현하고, 크기와 변형을 지원할 수 있다
- [ ] Figma 디자인 토큰을 Flutter 코드로 변환하고, 디자이너와 협업할 수 있는 워크플로우를 이해한다
- [ ] 라이트 모드와 다크 모드를 지원하는 ThemeData를 구축하고, ThemeMode 전환 기능을 구현할 수 있다
- [ ] 시스템 설정과 연동하여 자동으로 다크 모드를 전환하고, 사용자 설정을 저장할 수 있다
- [ ] Widgetbook을 설정하고, 모든 컴포넌트를 카탈로그에 등록하여 독립적으로 개발하고 테스트할 수 있다
- [ ] 한글 폰트(Pretendard, Noto Sans) 또는 Google Fonts를 프로젝트에 통합하고, 타이포그래피 시스템을 구축할 수 있다

---

## 관련 문서

**선행 학습**:
- [WidgetFundamentals](./WidgetFundamentals.md) - Widget 기본기와 InheritedWidget
- [LayoutSystem](./LayoutSystem.md) - 레이아웃 시스템과 반응형 디자인

**병행 학습**:
- [DevToolsProfiling](../system/DevToolsProfiling.md) - 컴포넌트 성능 최적화

**실전 적용**:
- [Bloc](../core/Bloc.md) - 테마 상태 관리 (Bloc 패턴)
- [core/Architecture](../core/Architecture.md) - 디자인 시스템을 Clean Architecture에 통합

---

**Package Versions**
- google_fonts: ^8.0.1
- flutter_svg: ^2.2.3
- widgetbook: ^3.20.2
- widgetbook_generator: ^3.20.0
- flutter_bloc: ^9.1.1
- freezed: ^3.2.4
- fpdart: ^1.2.0
- go_router: ^17.0.1
