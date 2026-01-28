import 'package:flutter/material.dart';

/// 접근성이 적용된 이미지 위젯
///
/// 다음 기능을 자동으로 제공합니다:
/// - Semantics 레이블 자동 적용
/// - 이미지 설명 음성 안내
/// - 스크린 리더 지원
/// - 장식용 이미지 표시 옵션
class AccessibleImage extends StatelessWidget {
  /// 이미지 제공자
  ///
  /// NetworkImage, AssetImage, FileImage 등을 사용할 수 있습니다.
  final ImageProvider image;

  /// 스크린 리더용 이미지 설명
  ///
  /// 이미지의 내용과 의미를 설명하는 텍스트입니다.
  /// 예: "해변에서 찍은 일몰 사진"
  final String semanticLabel;

  /// 이미지 너비
  final double? width;

  /// 이미지 높이
  final double? height;

  /// 이미지 맞춤 방식
  ///
  /// 컨테이너 크기에 맞춰 이미지를 조정하는 방법을 지정합니다.
  final BoxFit? fit;

  /// 장식용 이미지 여부
  ///
  /// true이면 스크린 리더가 이미지를 건너뜁니다.
  /// 의미 없는 장식용 이미지에만 사용하세요.
  final bool isDecorative;

  const AccessibleImage({
    required this.image,
    required this.semanticLabel,
    super.key,
    this.width,
    this.height,
    this.fit,
    this.isDecorative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: isDecorative ? '' : semanticLabel,
      // 장식용 이미지는 스크린 리더에서 제외
      excludeSemantics: isDecorative,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        semanticLabel: isDecorative ? '' : semanticLabel,
      ),
    );
  }
}
