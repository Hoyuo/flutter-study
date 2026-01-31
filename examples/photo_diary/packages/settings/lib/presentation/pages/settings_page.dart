import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// 설정 화면
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        buildWhen: (prev, curr) => prev.settings != curr.settings || prev.isLoading != curr.isLoading,
        listener: (context, state) {
          // 에러 처리
          if (state.failure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure!.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.settings == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final settings = state.settings;
          if (settings == null) {
            return const Center(
              child: Text('설정을 불러올 수 없습니다.'),
            );
          }

          return ListView(
            children: [
              // 외관 섹션
              SettingsSection(
                title: '외관',
                children: [
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: '테마',
                    subtitle: _getThemeModeName(settings.themeMode),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _showThemeSelector(context, settings.themeMode),
                  ),
                ],
              ),

              // 언어 섹션
              SettingsSection(
                title: '언어',
                children: [
                  SettingsTile(
                    icon: Icons.language_outlined,
                    title: '언어',
                    subtitle: LocaleSelectorDialog
                            .supportedLocales[settings.languageCode]?['name'] ??
                        '한국어',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLocaleSelector(
                      context,
                      settings.languageCode,
                    ),
                  ),
                ],
              ),

              // 보안 섹션
              SettingsSection(
                title: '보안',
                children: [
                  SettingsTile(
                    icon: Icons.fingerprint_outlined,
                    title: '생체인증',
                    subtitle: '앱 잠금 해제 시 생체인증 사용',
                    trailing: Switch(
                      value: settings.biometricLockEnabled,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                              SettingsEvent.toggleBiometricAuth(value),
                            );
                      },
                    ),
                  ),
                ],
              ),

              // 알림 섹션
              SettingsSection(
                title: '알림',
                children: [
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: '푸시 알림',
                    subtitle: '새로운 소식 및 알림 받기',
                    trailing: Switch(
                      value: settings.notificationsEnabled,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                              SettingsEvent.togglePushNotification(value),
                            );
                      },
                    ),
                  ),
                ],
              ),

              // 앱 정보 섹션
              SettingsSection(
                title: '앱 정보',
                children: [
                  const SettingsTile(
                    icon: Icons.info_outline,
                    title: '버전',
                    subtitle: '1.0.0',
                  ),
                ],
              ),

              // 기타 섹션
              SettingsSection(
                title: '기타',
                children: [
                  SettingsTile(
                    icon: Icons.logout_outlined,
                    title: '로그아웃',
                    onTap: () => _showLogoutDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.restore_outlined,
                    title: '설정 초기화',
                    onTap: () => _showResetDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// 테마 모드 이름 반환
  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '라이트';
      case ThemeMode.dark:
        return '다크';
      case ThemeMode.system:
        return '시스템';
    }
  }

  /// 테마 선택 다이얼로그 표시
  Future<void> _showThemeSelector(
    BuildContext context,
    ThemeMode currentThemeMode,
  ) async {
    final selectedTheme = await ThemeSelectorDialog.show(
      context,
      currentThemeMode: currentThemeMode,
    );

    if (selectedTheme != null && context.mounted) {
      context.read<SettingsBloc>().add(
            SettingsEvent.updateThemeMode(selectedTheme),
          );
    }
  }

  /// 언어 선택 다이얼로그 표시
  Future<void> _showLocaleSelector(
    BuildContext context,
    String currentLanguageCode,
  ) async {
    final selectedLocale = await LocaleSelectorDialog.show(
      context,
      currentLanguageCode: currentLanguageCode,
    );

    if (selectedLocale != null && context.mounted) {
      context.read<SettingsBloc>().add(
            SettingsEvent.updateLocale(selectedLocale),
          );
    }
  }

  /// 로그아웃 확인 다이얼로그 표시
  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: 로그아웃 로직 구현
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃되었습니다.')),
      );
    }
  }

  /// 설정 초기화 확인 다이얼로그 표시
  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('설정 초기화'),
        content: const Text('모든 설정을 초기화하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(
            const SettingsEvent.resetSettings(),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 초기화되었습니다.')),
      );
    }
  }
}
