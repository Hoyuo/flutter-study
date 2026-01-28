import 'package:flutter/material.dart';

/// 접근성이 적용된 텍스트 필드
///
/// 다음 기능을 자동으로 제공합니다:
/// - Semantics 레이블 자동 적용
/// - 스크린 리더 지원
/// - 에러 메시지 음성 안내
/// - 힌트 텍스트 접근성 향상
class AccessibleTextField extends StatelessWidget {
  /// 텍스트 컨트롤러
  final TextEditingController? controller;

  /// 레이블 텍스트
  ///
  /// 필드 위에 표시되는 레이블입니다.
  final String labelText;

  /// 힌트 텍스트 (선택사항)
  ///
  /// 필드가 비어있을 때 표시되는 안내 텍스트입니다.
  final String? hintText;

  /// 에러 메시지 (선택사항)
  ///
  /// 유효성 검사 실패 시 표시되는 메시지입니다.
  final String? errorText;

  /// 스크린 리더용 레이블
  ///
  /// 시각적 레이블과 다른 설명이 필요한 경우 사용합니다.
  final String semanticLabel;

  /// 비밀번호 입력 여부
  ///
  /// true이면 입력 내용이 마스킹됩니다.
  final bool obscureText;

  /// 키보드 타입
  ///
  /// 입력받을 데이터 형식에 맞는 키보드를 표시합니다.
  final TextInputType? keyboardType;

  /// 유효성 검사 함수
  final FormFieldValidator<String>? validator;

  const AccessibleTextField({
    required this.labelText,
    required this.semanticLabel,
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel,
      hint: hintText,
      // 에러가 있으면 에러 메시지를 읽어줌
      liveRegion: errorText != null,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: errorText,
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
