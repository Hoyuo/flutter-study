import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 이미지 선택 바텀시트
///
/// 카메라 또는 갤러리에서 이미지를 선택할 수 있는 바텀시트입니다.
class ImagePickerBottomSheet extends StatelessWidget {
  /// 이미지 소스가 선택되었을 때 호출되는 콜백
  final Function(ImageSource source) onSourceSelected;

  const ImagePickerBottomSheet({
    super.key,
    required this.onSourceSelected,
  });

  /// 바텀시트를 표시하고 선택된 ImageSource를 반환합니다.
  ///
  /// [context] BuildContext
  /// Returns null if cancelled
  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ImagePickerBottomSheet(
        onSourceSelected: (source) => Navigator.pop(context, source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // 제목
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '사진 선택'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 카메라 옵션
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: colorScheme.primary,
              ),
              title: Text('카메라'.tr()),
              subtitle: Text('새 사진 촬영'.tr()),
              onTap: () => onSourceSelected(ImageSource.camera),
            ),

            // 갤러리 옵션
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: colorScheme.primary,
              ),
              title: Text('갤러리'.tr()),
              subtitle: Text('기존 사진 선택'.tr()),
              onTap: () => onSourceSelected(ImageSource.gallery),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
