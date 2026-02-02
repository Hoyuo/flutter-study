/// String 확장 메서드
extension StringExtensions on String {
  /// 첫 글자를 대문자로 변환
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 모든 단어의 첫 글자를 대문자로 변환
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// 빈 문자열이거나 공백만 있는지 확인
  bool get isBlank => trim().isEmpty;

  /// 빈 문자열이 아니고 공백만 있지 않은지 확인
  bool get isNotBlank => !isBlank;

  /// 최대 길이로 자르고 말줄임표 추가
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
}

/// Nullable String 확장 메서드
extension NullableStringExtensions on String? {
  /// null이거나 빈 문자열인지 확인
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// null이 아니고 빈 문자열이 아닌지 확인
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// null이거나 빈 문자열이거나 공백만 있는지 확인
  bool get isNullOrBlank => this == null || this!.isBlank;
}
