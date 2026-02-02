import 'package:flutter/material.dart';

/// App typography based on DESIGN_SPEC.md
class AppTextStyles {
  AppTextStyles._();

  // Font families
  static const String fontFamilyTitle = 'Plus Jakarta Sans';
  static const String fontFamilyBody = 'Inter';

  // Page Title - 28px Bold
  static const TextStyle pageTitle = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Section Title - 20px Bold
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // Headline Large
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Headline Medium
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Headline Small
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // Title Large
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamilyTitle,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Title Medium
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Title Small
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Body Large - 16px Medium
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Body Medium - 15px Regular
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Body Small - 14px Regular
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label Large - 14px SemiBold
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Label Medium
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Label Small - Caption 13px Regular
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
