import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App theme configuration using Material 3
class AppTheme {
  AppTheme._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.light,
      error: AppColors.errorLight,
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
          color: AppColors.onBackgroundLight,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onBackgroundLight,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onBackgroundLight,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.onSurfaceLight,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onSurfaceLight,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      error: AppColors.errorDark,
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
          color: AppColors.onBackgroundDark,
        ),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.onBackgroundDark,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.onBackgroundDark,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: AppColors.onSurfaceDark,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
