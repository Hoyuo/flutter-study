import 'package:flutter/material.dart';

/// BuildContext 확장 메서드
extension BuildContextExtensions on BuildContext {
  /// 현재 테마 가져오기
  ThemeData get theme => Theme.of(this);

  /// 현재 컬러 스킴 가져오기
  ColorScheme get colorScheme => theme.colorScheme;

  /// 현재 텍스트 테마 가져오기
  TextTheme get textTheme => theme.textTheme;

  /// MediaQuery 데이터 가져오기
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// 화면 크기 가져오기
  Size get screenSize => mediaQuery.size;

  /// 안전 영역 패딩 가져오기
  EdgeInsets get padding => mediaQuery.padding;

  /// 스낵바 표시
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }
}
