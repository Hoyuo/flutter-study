# Flutter 테마 관리 가이드

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. **Material 3 기반 테마**(라이트/다크)를 설계하고 `ColorScheme.fromSeed`를 활용할 수 있다
2. **ThemeExtension**으로 앱 전용 커스텀 색상을 추가하고 `BuildContext` 확장으로 편리하게 접근할 수 있다
3. **AppTypography, AppSpacing, AppRadius** 등 디자인 토큰을 체계적으로 정의하고 사용할 수 있다
4. **ThemeBloc + SharedPreferences**로 테마 전환 기능을 구현하고 사용자 설정을 저장할 수 있다
5. 다크모드 대응 이미지/아이콘 처리와 컴포넌트별 스타일링 패턴을 적용할 수 있다

---

## 개요

일관된 디자인 시스템을 위한 테마 관리 패턴을 다룹니다. Material 3 테마, 다크모드, 커스텀 색상/타이포그래피, 테마 전환을 구현합니다.

## 기본 테마 설정

### Material 3 테마

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// 라이트 테마
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 다크 테마
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

### main.dart에서 테마 적용

```dart
// lib/main.dart
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,  // 시스템 설정 따름
      home: const HomePage(),
    );
  }
}
```

## 커스텀 색상 시스템

### 앱 색상 정의

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// 앱 전용 색상 (ColorScheme 외 추가 색상)
class AppColors {
  AppColors._();

  // 브랜드 색상
  static const primary = Color(0xFF2196F3);
  static const primaryLight = Color(0xFF64B5F6);
  static const primaryDark = Color(0xFF1976D2);

  static const secondary = Color(0xFF4CAF50);
  static const secondaryLight = Color(0xFF81C784);
  static const secondaryDark = Color(0xFF388E3C);

  // 시맨틱 색상
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);
  static const info = Color(0xFF2196F3);

  // 중립 색상
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // 텍스트 색상 (라이트 모드)
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);
  static const textDisabled = Color(0xFF9E9E9E);

  // 텍스트 색상 (다크 모드)
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xB3FFFFFF);  // 70%
  static const textHintDark = Color(0x80FFFFFF);  // 50%
  static const textDisabledDark = Color(0x61FFFFFF);  // 38%

  // 배경 색상
  static const backgroundLight = Color(0xFFFAFAFA);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E1E);
}
```

### Theme Extension으로 커스텀 색상 추가

```dart
// lib/core/theme/app_color_extension.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ThemeExtension으로 커스텀 색상 추가
@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  final Color success;
  final Color warning;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color cardBackground;
  final Color divider;

  const AppColorExtension({
    required this.success,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.cardBackground,
    required this.divider,
  });

  /// 라이트 모드 색상
  static const light = AppColorExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textHint: AppColors.textHint,
    cardBackground: AppColors.surfaceLight,
    divider: AppColors.grey200,
  );

  /// 다크 모드 색상
  static const dark = AppColorExtension(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textHint: AppColors.textHintDark,
    cardBackground: AppColors.surfaceDark,
    divider: AppColors.grey800,
  );

  @override
  AppColorExtension copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? cardBackground,
    Color? divider,
  }) {
    return AppColorExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      cardBackground: cardBackground ?? this.cardBackground,
      divider: divider ?? this.divider,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// BuildContext 확장으로 편리하게 접근
extension AppColorExtensionX on BuildContext {
  AppColorExtension get appColors {
    return Theme.of(this).extension<AppColorExtension>() ??
        AppColorExtension.light;
  }
}
```

### 테마에 Extension 추가

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      extensions: const [
        AppColorExtension.light,  // 커스텀 색상 추가
      ],
      // ... 기타 설정
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      extensions: const [
        AppColorExtension.dark,  // 커스텀 색상 추가
      ],
      // ... 기타 설정
    );
  }
}
```

### 사용 예시

```dart
// 표준 ColorScheme 색상
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onPrimary
Theme.of(context).colorScheme.surface

// 커스텀 색상 (Extension)
context.appColors.success
context.appColors.warning
context.appColors.textSecondary
```

## 타이포그래피 시스템

### 앱 타이포그래피 정의

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const _fontFamily = 'Pretendard';  // 또는 null로 시스템 폰트

  /// Material 3 TextTheme
  static TextTheme get textTheme {
    return const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
      ),

      // Headline
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Body
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }
}
```

### 테마에 적용

```dart
static ThemeData get light {
  return ThemeData(
    useMaterial3: true,
    textTheme: AppTypography.textTheme,
    // ...
  );
}
```

### 타이포그래피 사용

```dart
// Theme에서 가져오기
Text(
  'Title',
  style: Theme.of(context).textTheme.titleLarge,
)

// 색상 오버라이드
Text(
  'Subtitle',
  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    color: context.appColors.textSecondary,
  ),
)
```

## 간격 및 크기 시스템

### 디자인 토큰

```dart
// lib/core/theme/app_spacing.dart
class AppSpacing {
  AppSpacing._();

  // 기본 간격
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // 패딩
  static const pagePadding = EdgeInsets.all(md);
  static const cardPadding = EdgeInsets.all(md);
  static const listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // 갭
  static const verticalGapXs = SizedBox(height: xs);
  static const verticalGapSm = SizedBox(height: sm);
  static const verticalGapMd = SizedBox(height: md);
  static const verticalGapLg = SizedBox(height: lg);

  static const horizontalGapXs = SizedBox(width: xs);
  static const horizontalGapSm = SizedBox(width: sm);
  static const horizontalGapMd = SizedBox(width: md);
  static const horizontalGapLg = SizedBox(width: lg);
}

// lib/core/theme/app_radius.dart
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static final borderRadiusXs = BorderRadius.circular(xs);
  static final borderRadiusSm = BorderRadius.circular(sm);
  static final borderRadiusMd = BorderRadius.circular(md);
  static final borderRadiusLg = BorderRadius.circular(lg);
  static final borderRadiusXl = BorderRadius.circular(xl);
  static final borderRadiusFull = BorderRadius.circular(full);
}

// lib/core/theme/app_shadows.dart
class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
```

### 사용 예시

```dart
Container(
  padding: AppSpacing.cardPadding,
  decoration: BoxDecoration(
    color: context.appColors.cardBackground,
    borderRadius: AppRadius.borderRadiusMd,
    boxShadow: AppShadows.sm,
  ),
  child: Column(
    children: [
      Text('Title', style: Theme.of(context).textTheme.titleMedium),
      AppSpacing.verticalGapSm,
      Text('Description'),
    ],
  ),
)
```

## 테마 전환 (Bloc)

### Theme State

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

### Theme Event

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

### Theme Bloc

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

### Theme 저장/로드

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

### App에 적용

```dart
// lib/main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: state.themeMode,
          // ...
        );
      },
    );
  }
}
```

### 테마 설정 UI

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

## 컴포넌트 스타일링

### 버튼 스타일

```dart
// lib/core/theme/component_styles.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

class AppButtonStyles {
  AppButtonStyles._();

  /// Primary 버튼
  static ButtonStyle primary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      elevation: 0,
    );
  }

  /// Secondary 버튼
  static ButtonStyle secondary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      side: BorderSide(color: colorScheme.primary),
    );
  }

  /// Danger 버튼
  static ButtonStyle danger(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderRadiusMd,
      ),
      elevation: 0,
    );
  }

  /// Ghost 버튼
  static ButtonStyle ghost(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.styleFrom(
      foregroundColor: colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
```

### 사용 예시

```dart
ElevatedButton(
  style: AppButtonStyles.primary(context),
  onPressed: () {},
  child: const Text('확인'),
)

OutlinedButton(
  style: AppButtonStyles.secondary(context),
  onPressed: () {},
  child: const Text('취소'),
)

ElevatedButton(
  style: AppButtonStyles.danger(context),
  onPressed: () {},
  child: const Text('삭제'),
)
```

## 다크모드 대응 이미지

### 이미지 에셋 처리

```dart
// lib/core/utils/theme_image.dart
import 'package:flutter/material.dart';

class ThemeImage extends StatelessWidget {
  final String lightAsset;
  final String darkAsset;
  final double? width;
  final double? height;

  const ThemeImage({
    super.key,
    required this.lightAsset,
    required this.darkAsset,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      isDark ? darkAsset : lightAsset,
      width: width,
      height: height,
    );
  }
}

// 사용
ThemeImage(
  lightAsset: 'assets/images/logo_light.png',
  darkAsset: 'assets/images/logo_dark.png',
  width: 120,
)
```

### 아이콘 색상 대응

```dart
Icon(
  Icons.favorite,
  color: Theme.of(context).colorScheme.primary,
)

// 또는 커스텀 색상
Icon(
  Icons.warning,
  color: context.appColors.warning,
)
```

## 테스트

### 테마 테스트

```dart
void main() {
  group('AppTheme', () {
    test('light theme should have correct brightness', () {
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('dark theme should have correct brightness', () {
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('light theme should contain color extension', () {
      final extension = AppTheme.light.extension<AppColorExtension>();
      expect(extension, isNotNull);
    });
  });
}
```

### 위젯 테마 테스트

```dart
testWidgets('should apply dark theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: Builder(
        builder: (context) => Container(
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    ),
  );

  final context = tester.element(find.byType(Container));
  expect(Theme.of(context).brightness, Brightness.dark);
});
```

## 체크리스트

- [ ] AppTheme 클래스 (light, dark)
- [ ] AppColors 색상 상수
- [ ] AppColorExtension (ThemeExtension)
- [ ] AppTypography 타이포그래피
- [ ] AppSpacing, AppRadius, AppShadows 디자인 토큰
- [ ] ThemeBloc으로 테마 전환
- [ ] SharedPreferences로 테마 저장
- [ ] 테마 설정 UI
- [ ] 컴포넌트별 스타일 (버튼, 카드 등)
- [ ] 다크모드 대응 이미지/아이콘
- [ ] BuildContext 확장으로 편리한 접근

---

## 실습 과제

### 과제 1: 브랜드 컬러 기반 테마 시스템 구축
자신만의 브랜드 색상(seed color)을 선택하여 라이트/다크 테마를 구성하세요.
- `ColorScheme.fromSeed`로 기본 테마 생성
- `AppColorExtension`에 success, warning, info, 배지(badge) 색상 추가
- `BuildContext` 확장 메서드로 접근 가능하게 구현하세요.

### 과제 2: 테마 전환 기능 완성
`ThemeBloc`을 구현하여 라이트/다크/시스템 3가지 모드 전환을 완성하세요.
- `SharedPreferences`로 사용자 선택을 저장/로드
- 설정 화면에서 `RadioListTile`로 선택 UI 구현
- 앱 재시작 시에도 마지막 선택이 유지되는지 확인하세요.

### 과제 3: 디자인 토큰 적용 카드 컴포넌트
`AppSpacing`, `AppRadius`, `AppShadows`, `AppTypography`를 모두 활용하여 상품 카드 위젯을 구현하세요.
- 하드코딩된 값 없이 디자인 토큰만 사용
- 라이트/다크 모드에서 모두 올바르게 표시되는지 확인하세요.

---

## Self-Check 퀴즈

학습한 내용을 점검해 보세요:

- [ ] `ColorScheme.fromSeed`와 직접 `ColorScheme`을 정의하는 방식의 차이를 설명할 수 있는가?
- [ ] `ThemeExtension`의 `lerp` 메서드가 필요한 이유를 설명할 수 있는가? (테마 전환 애니메이션)
- [ ] `Theme.of(context).colorScheme.primary`와 `context.appColors.success`의 차이(표준 vs 커스텀)를 구분할 수 있는가?
- [ ] 다크모드에서 텍스트 색상의 opacity(70%, 50%, 38%)가 각각 어떤 용도인지 설명할 수 있는가?
- [ ] `AppSpacing`에서 `SizedBox` 상수를 미리 정의하는 이유(const 최적화)를 설명할 수 있는가?
