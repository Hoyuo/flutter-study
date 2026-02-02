import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme configuration using Material 3
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      error: AppColors.error,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // Text theme
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryTextLight,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.secondaryTextLight,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.tertiaryTextLight,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.onBackgroundLight,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.tertiaryTextLight,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        shape: const CircleBorder(),
        side: BorderSide(
          color: AppColors.tertiaryTextLight,
          width: 2,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // Text theme
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryTextDark,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.secondaryTextDark,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.secondaryTextDark,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.onBackgroundDark,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.secondaryTextDark,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        shape: const CircleBorder(),
        side: BorderSide(
          color: AppColors.secondaryTextDark,
          width: 2,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.modalBackgroundDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
      ),
    );
  }
}
