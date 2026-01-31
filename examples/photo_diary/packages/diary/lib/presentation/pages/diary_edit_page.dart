import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart' hide State;
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// 일기 작성/수정 화면
///
/// Form validation, 사진 추가, 태그 선택, 날씨 정보 표시 기능을 제공합니다.
class DiaryEditPage extends StatefulWidget {
  /// 수정할 일기 ID (null이면 새로 작성)
  final String? entryId;

  const DiaryEditPage({
    super.key,
    this.entryId,
  });

  @override
  State<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends State<DiaryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final List<String> _photoUrls = [];
  final List<String> _selectedTagIds = [];
  WeatherInfo? _currentWeather;

  bool get _isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // 수정 모드: 기존 데이터 로드
      context.read<DiaryBloc>().add(DiaryEvent.loadEntry(widget.entryId!));
    } else {
      // 작성 모드: 현재 날씨 정보 가져오기
      _fetchCurrentWeather();
    }

    // 태그 목록 로드
    // TODO: TagBloc 구현 후 태그 로드
    // context.read<TagBloc>().add(const TagEvent.loadTags());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 현재 날씨 정보 가져오기
  Future<void> _fetchCurrentWeather() async {
    // TODO: 날씨 API 연동
    // 임시 날씨 데이터
    setState(() {
      _currentWeather = const WeatherInfo(
        condition: '맑음',
        temperature: 22.0,
        iconUrl: '',
        humidity: 60.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocUiEffectListener<DiaryBloc, DiaryState, DiaryUiEffect>(
        listener: _handleUiEffect,
        child: BlocListener<DiaryBloc, DiaryState>(
          listener: (context, state) {
            // 수정 모드: 데이터 로드 완료 시 폼 초기화
            if (_isEditing &&
                state.selectedEntry != null &&
                _titleController.text.isEmpty) {
              _initializeForm(state.selectedEntry!);
            }
          },
          child: _buildBody(context),
        ),
      ),
    );
  }

  /// 폼 초기화 (수정 모드)
  void _initializeForm(DiaryEntry entry) {
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    setState(() {
      _photoUrls.clear();
      _photoUrls.addAll(entry.photoUrls);
      _selectedTagIds.clear();
      _selectedTagIds.addAll(entry.tags.map((tag) => tag.id));
      _currentWeather = entry.weather;
    });
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(_isEditing ? '일기 수정' : '일기 작성'),
      actions: [
        // 저장 버튼
        BlocBuilder<DiaryBloc, DiaryState>(
          builder: (context, state) {
            return TextButton(
              onPressed: state.isLoading ? null : _handleSave,
              child: Text(
                '저장',
                style: TextStyle(
                  color: state.isLoading
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Body 빌드
  Widget _buildBody(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      buildWhen: (prev, curr) => prev.isLoading != curr.isLoading || prev.selectedEntry != curr.selectedEntry,
      builder: (context, state) {
        // 로딩 중 (수정 모드 데이터 로드)
        if (_isEditing && state.isLoading && state.selectedEntry == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목 입력
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '일기 제목을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => Validators.required(value, '제목'),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),

                // 사진 추가
                PhotoPicker(
                  photoUrls: _photoUrls,
                  onAddPhoto: _handleAddPhoto,
                  onRemovePhoto: (index) {
                    setState(() {
                      _photoUrls.removeAt(index);
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 내용 입력
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '오늘의 이야기를 기록하세요',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => Validators.required(value, '내용'),
                  maxLines: 10,
                  minLines: 5,
                  maxLength: 10000,
                ),
                const SizedBox(height: 16),

                // 날씨 정보
                if (_currentWeather != null) ...[
                  WeatherInfoCard(weather: _currentWeather!),
                  const SizedBox(height: 16),
                ],

                // 태그 선택
                // TODO: TagBloc 구현 후 실제 태그 목록 사용
                // 태그 기능이 준비되면 TagSelector 표시
                if (_getMockTags().isNotEmpty) ...[
                  TagSelector(
                    availableTags: _getMockTags(),
                    selectedTagIds: _selectedTagIds,
                    onTagToggle: (tag) {
                      setState(() {
                        if (_selectedTagIds.contains(tag.id)) {
                          _selectedTagIds.remove(tag.id);
                        } else {
                          _selectedTagIds.add(tag.id);
                        }
                      });
                    },
                    onAddTag: () => _showAddTagDialog(context),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 저장 처리
  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      // AuthBloc에서 현재 사용자 ID 가져오기
      final authState = context.read<AuthBloc>().state;
      final userId = authState.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('로그인이 필요합니다'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      // TODO: 실제 태그 객체 가져오기 (TagBloc에서)
      final tags = _getMockTags()
          .where((tag) => _selectedTagIds.contains(tag.id))
          .toList();

      if (_isEditing) {
        // 수정
        final state = context.read<DiaryBloc>().state;
        final originalCreatedAt = state.selectedEntry?.createdAt ?? DateTime.now();

        final entry = DiaryEntry(
          id: widget.entryId!,
          userId: userId,
          title: title,
          content: content,
          photoUrls: _photoUrls,
          tags: tags,
          weather: _currentWeather,
          createdAt: originalCreatedAt,
          updatedAt: DateTime.now(),
        );
        context.read<DiaryBloc>().add(DiaryEvent.updateEntry(entry));
      } else {
        // 생성
        final entry = DiaryEntry(
          id: '', // 서버에서 생성
          userId: userId,
          title: title,
          content: content,
          photoUrls: _photoUrls,
          tags: tags,
          weather: _currentWeather,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        context.read<DiaryBloc>().add(DiaryEvent.createEntry(entry));
      }
    }
  }

  /// 사진 추가 처리
  void _handleAddPhoto(String imagePath) {
    setState(() {
      _photoUrls.add(imagePath);
    });
  }

  /// 새 태그 추가 다이얼로그 표시
  void _showAddTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTagDialog(
        onCreateTag: (name, colorHex) {
          // TODO: TagBloc으로 태그 생성
          // context.read<TagBloc>().add(
          //   TagEvent.createTag(name: name, colorHex: colorHex),
          // );
        },
      ),
    );
  }

  /// UI 이펙트 처리
  void _handleUiEffect(BuildContext context, DiaryUiEffect effect) {
    switch (effect) {
      case DiaryShowError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case DiaryShowSuccess(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      case DiaryNavigateToDetail():
        // 저장 성공 후 상세 페이지로 이동
        Navigator.of(context).pop();
        // TODO: 상세 페이지로 이동
        // context.push('/diary/$entryId');
      case DiaryNavigateBack():
        Navigator.of(context).pop();
      case DiaryConfirmDelete():
        // 이 페이지에서는 사용하지 않음
        break;
    }
  }

  /// 태그 목록 가져오기
  ///
  /// TODO: TagBloc 구현 후 실제 태그 목록으로 대체
  /// 현재는 빈 리스트를 반환하여 태그 선택 UI를 숨김
  List<Tag> _getMockTags() {
    return [];
  }
}
