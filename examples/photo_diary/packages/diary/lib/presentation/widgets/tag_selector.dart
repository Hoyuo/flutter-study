import 'package:flutter/material.dart';
import 'package:core/core.dart';
import '../../domain/entities/tag.dart';

/// 태그 선택 위젯
///
/// 여러 태그를 선택하고 새 태그를 추가할 수 있습니다.
class TagSelector extends StatelessWidget {
  /// 사용 가능한 모든 태그 목록
  final List<Tag> availableTags;

  /// 현재 선택된 태그 ID 목록
  final List<String> selectedTagIds;

  /// 태그 선택/해제 핸들러
  final void Function(Tag tag) onTagToggle;

  /// 새 태그 추가 핸들러
  final VoidCallback? onAddTag;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTagIds,
    required this.onTagToggle,
    this.onAddTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          '태그',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // 태그 목록
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 기존 태그들
            ...availableTags.map((tag) {
              final isSelected = selectedTagIds.contains(tag.id);
              final tagColor = ColorUtils.parseHex(tag.colorHex);

              return FilterChip(
                label: Text(tag.name),
                selected: isSelected,
                onSelected: (_) => onTagToggle(tag),
                backgroundColor: tagColor.withValues(alpha: 0.1),
                selectedColor: tagColor.withValues(alpha: 0.3),
                checkmarkColor: colorScheme.onSurface,
              );
            }),

            // 새 태그 추가 버튼
            if (onAddTag != null)
              ActionChip(
                label: const Text('태그 추가'),
                avatar: Icon(
                  Icons.add,
                  size: 18,
                  color: colorScheme.primary,
                ),
                onPressed: onAddTag,
                side: BorderSide(
                  color: colorScheme.outline,
                  width: 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 새 태그 추가 다이얼로그
class AddTagDialog extends StatefulWidget {
  /// 태그 생성 핸들러
  final void Function(String name, String colorHex) onCreateTag;

  const AddTagDialog({
    super.key,
    required this.onCreateTag,
  });

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedColor = 'FF5252'; // 기본 빨간색

  // 사용 가능한 색상 팔레트
  static const List<String> _colorPalette = [
    'FF5252', // 빨강
    'FF4081', // 핑크
    '9C27B0', // 보라
    '673AB7', // 진보라
    '3F51B5', // 인디고
    '2196F3', // 파랑
    '03A9F4', // 하늘색
    '00BCD4', // 청록색
    '009688', // 청록
    '4CAF50', // 초록
    '8BC34A', // 연두
    'CDDC39', // 라임
    'FFEB3B', // 노랑
    'FFC107', // 호박색
    'FF9800', // 주황
    'FF5722', // 진주황
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('새 태그 추가'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 태그 이름 입력
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '태그 이름',
                hintText: '예: 여행, 일상, 음식',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '태그 이름을 입력해주세요';
                }
                if (value.length > 20) {
                  return '태그 이름은 20자 이하로 입력해주세요';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // 색상 선택
            Text(
              '색상 선택',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorPalette.map((colorHex) {
                final color = Color(int.parse('FF$colorHex', radix: 16));
                final isSelected = _selectedColor == colorHex;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedColor = colorHex;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: colorScheme.primary,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: colorScheme.onPrimary,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        // 취소 버튼
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),

        // 생성 버튼
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onCreateTag(
                _nameController.text.trim(),
                _selectedColor,
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('생성'),
        ),
      ],
    );
  }
}
