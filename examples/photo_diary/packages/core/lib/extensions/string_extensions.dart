/// String 확장 메서드
extension StringExtensions on String {
  /// 유효한 이메일인지 확인
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// 첫 글자만 대문자로 변환
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// 각 단어의 첫 글자를 대문자로 변환
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// 빈 문자열이거나 공백만 포함하는지 확인
  bool get isBlank => trim().isEmpty;

  /// 빈 문자열이 아니고 공백만 포함하지 않는지 확인
  bool get isNotBlank => !isBlank;

  /// 지정된 길이로 문자열 자르기
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// 모든 공백 제거
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// snake_case로 변환
  String get toSnakeCase {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// camelCase로 변환
  String get toCamelCase {
    final words = split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return this;

    return words.first.toLowerCase() +
        words.skip(1).map((word) => word.capitalize).join();
  }

  /// 숫자만 포함하는지 확인
  bool get isNumeric => RegExp(r'^\d+$').hasMatch(this);

  /// 알파벳만 포함하는지 확인
  bool get isAlpha => RegExp(r'^[a-zA-Z]+$').hasMatch(this);

  /// 영숫자만 포함하는지 확인
  bool get isAlphanumeric => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);

  /// int로 파싱 (실패 시 null 반환)
  int? get toIntOrNull => int.tryParse(this);

  /// double로 파싱 (실패 시 null 반환)
  double? get toDoubleOrNull => double.tryParse(this);
}
