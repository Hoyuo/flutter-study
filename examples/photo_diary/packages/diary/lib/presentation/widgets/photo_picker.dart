import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 사진 선택 및 미리보기 위젯
///
/// 사진을 추가/제거하고 미리보기를 표시합니다.
class PhotoPicker extends StatelessWidget {
  /// 선택된 사진 URL 목록
  final List<String> photoUrls;

  /// 사진 추가 핸들러 (이미지 경로를 받음)
  final void Function(String)? onAddPhoto;

  /// 사진 제거 핸들러
  final void Function(int index) onRemovePhoto;

  /// 최대 사진 개수
  final int maxPhotos;

  const PhotoPicker({
    super.key,
    required this.photoUrls,
    this.onAddPhoto,
    required this.onRemovePhoto,
    this.maxPhotos = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canAddMore = photoUrls.length < maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Row(
          children: [
            Text(
              '사진',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${photoUrls.length}/$maxPhotos)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 사진 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photoUrls.length + (canAddMore ? 1 : 0),
          itemBuilder: (context, index) {
            // 사진 추가 버튼
            if (index == photoUrls.length) {
              return _buildAddPhotoButton(context);
            }

            // 사진 미리보기
            return _buildPhotoPreview(
              context,
              photoUrls[index],
              index,
            );
          },
        ),
      ],
    );
  }

  /// 사진 추가 버튼 빌드
  Widget _buildAddPhotoButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showPhotoSourceDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              '사진 추가',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사진 미리보기 빌드
  Widget _buildPhotoPreview(BuildContext context, String url, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // 사진
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: colorScheme.surfaceVariant,
                child: Center(
                  child: Icon(
                    Icons.broken_image,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),

        // 삭제 버튼
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => onRemovePhoto(index),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 사진 소스 선택 다이얼로그 표시
  void _showPhotoSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 카메라에서 선택
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.of(context).pop();
                final ImagePicker picker = ImagePicker();
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null && onAddPhoto != null) {
                  onAddPhoto!(photo.path);
                }
              },
            ),

            // 갤러리에서 선택
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.of(context).pop();
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null && onAddPhoto != null) {
                  onAddPhoto!(image.path);
                }
              },
            ),

            // 취소
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('취소'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
