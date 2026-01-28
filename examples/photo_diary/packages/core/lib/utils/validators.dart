/// 폼 검증 유틸리티 클래스
class Validators {
  Validators._();

  /// 이메일 검증
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  /// 비밀번호 검증 (최소 8자, 영문+숫자)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return '영문을 포함해야 합니다';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return '숫자를 포함해야 합니다';
    }
    return null;
  }

  /// 비밀번호 확인
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value != password) {
        return '비밀번호가 일치하지 않습니다';
      }
      return null;
    };
  }

  /// 필수 입력 검증
  static String? required(String? value, [String fieldName = '필드']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }
    return null;
  }

  /// 최소 길이 검증
  static String? Function(String?) minLength(int length,
      [String fieldName = '입력값']) {
    return (String? value) {
      if (value != null && value.length < length) {
        return '$fieldName은(는) $length자 이상이어야 합니다';
      }
      return null;
    };
  }

  /// 최대 길이 검증
  static String? Function(String?) maxLength(int length,
      [String fieldName = '입력값']) {
    return (String? value) {
      if (value != null && value.length > length) {
        return '$fieldName은(는) $length자 이하여야 합니다';
      }
      return null;
    };
  }
}
