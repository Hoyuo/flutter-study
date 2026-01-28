import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:diary/diary.dart';
import 'package:photo_diary/core/di/injection.dart';

/// 다이어리 작성/수정 페이지
///
/// 새로운 다이어리를 작성하거나 기존 다이어리를 수정합니다.
class DiaryEditPage extends StatefulWidget {
  const DiaryEditPage({super.key, this.entryId});

  /// null이면 새로 작성, 있으면 수정 모드
  final String? entryId;

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  late final DiaryBloc _diaryBloc;

  bool get isEditMode => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    _diaryBloc = getIt<DiaryBloc>();

    // 수정 모드인 경우 기존 데이터 로드
    if (isEditMode) {
      _diaryBloc.add(DiaryEvent.loadEntry(widget.entryId!));
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _diaryBloc.close();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: DiaryEntry 객체 생성 로직 구현 필요
      // DiaryEvent.createEntry와 updateEntry는 DiaryEntry 객체를 받음
      // 현재는 필요한 모든 필드 (id, userId, title 등)를 알 수 없음
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 기능은 향후 구현 예정입니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _diaryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? '일기 수정' : '새 일기'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _handleSave,
              tooltip: '저장',
            ),
          ],
        ),
        body: BlocConsumer<DiaryBloc, DiaryState>(
          listener: (context, state) {
            // 기존 항목 로드 완료
            if (isEditMode && state.selectedEntry != null && !state.isLoading) {
              _contentController.text = state.selectedEntry!.content;
            }

            // 에러 처리
            if (state.failure != null) {
              final message = state.failure!.when(
                network: (msg, _) => msg,
                server: (msg, _, __) => msg,
                auth: (msg, _) => msg,
                cache: (msg, _) => msg,
                unknown: (msg, _) => msg,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }

            // TODO: 생성/수정 성공 감지 로직 구현 필요 (UiEffect 사용)
          },
          builder: (context, state) {
            final isLoading = state.isLoading;

            return SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 날짜 표시
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // 내용 입력 영역
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            hintText: '오늘은 어떤 일이 있었나요?\n\n사진과 함께 기록해보세요.',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(0),
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlignVertical: TextAlignVertical.top,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '내용을 입력하세요';
                            }
                            return null;
                          },
                          enabled: !isLoading,
                        ),
                      ),
                    ),

                    // 하단 툴바
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera),
                            onPressed: isLoading ? null : _handleAddPhoto,
                            tooltip: '사진 추가',
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library),
                            onPressed: isLoading ? null : _handleAddFromGallery,
                            tooltip: '갤러리에서 선택',
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_on),
                            onPressed: isLoading ? null : _handleAddLocation,
                            tooltip: '위치 추가',
                          ),
                          const Spacer(),
                          if (isLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 $weekday요일';
  }

  void _handleAddPhoto() {
    // TODO: 카메라로 사진 촬영
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('카메라 기능은 곧 추가될 예정입니다')));
  }

  void _handleAddFromGallery() {
    // TODO: 갤러리에서 사진 선택
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('갤러리 기능은 곧 추가될 예정입니다')));
  }

  void _handleAddLocation() {
    // TODO: 위치 정보 추가
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('위치 추가 기능은 곧 추가될 예정입니다')));
  }
}
