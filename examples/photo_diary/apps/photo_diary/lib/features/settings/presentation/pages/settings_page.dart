import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:settings/settings.dart';
import 'package:auth/auth.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../../../../core/di/injection.dart';

/// 설정 페이지
///
/// 앱 테마, 언어, 알림 등의 설정을 관리합니다.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              // 앱 설정 섹션
              _buildSectionHeader(context, '앱 설정'),

              // 테마 설정
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('테마'),
                subtitle: Text(_getThemeModeLabel(state)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context, state),
              ),

              // 언어 설정
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('언어'),
                subtitle: Text(_getLanguageLabel(state)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, state),
              ),

              const Divider(),

              // 알림 섹션
              _buildSectionHeader(context, '알림'),

              // 알림 활성화
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('알림 허용'),
                subtitle: const Text('새 일기 작성 알림'),
                value: state.settings?.notificationsEnabled ?? true,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.togglePushNotification(value),
                  );
                },
              ),

              const Divider(),

              // 보안 섹션
              _buildSectionHeader(context, '보안'),

              // 생체인증
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('생체인증 잠금'),
                subtitle: const Text('앱 실행 시 생체인증 요구'),
                value: state.settings?.biometricLockEnabled ?? false,
                onChanged: (value) async {
                  // 생체인증 활성화 시, 사용 가능한지 확인
                  if (value) {
                    final biometricService = getIt<BiometricService>();
                    final isAvailable = await biometricService.isAvailable();

                    if (!isAvailable && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('생체인증을 사용할 수 없습니다. 기기 설정을 확인해주세요.'),
                        ),
                      );
                      return;
                    }
                  }

                  if (context.mounted) {
                    context.read<SettingsBloc>().add(
                      SettingsEvent.toggleBiometricAuth(value),
                    );
                  }
                },
              ),

              const Divider(),

              // 데이터 섹션
              _buildSectionHeader(context, '데이터'),

              // 백업
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('백업 및 동기화'),
                subtitle: const Text('데이터를 클라우드에 백업'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBackupDialog(context),
              ),

              // 캐시 삭제
              ListTile(
                leading: const Icon(Icons.delete_sweep),
                title: const Text('캐시 삭제'),
                subtitle: const Text('임시 파일 및 캐시 데이터 삭제'),
                onTap: () => _showClearCacheDialog(context),
              ),

              const Divider(),

              // 정보 섹션
              _buildSectionHeader(context, '정보'),

              // 버전 정보
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('버전 정보'),
                subtitle: const Text('1.0.0'),
              ),

              // 라이선스
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Photo Diary',
                    applicationVersion: '1.0.0',
                  );
                },
              ),

              const Divider(),

              // 계정 섹션
              _buildSectionHeader(context, '계정'),

              // 로그아웃
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () => _handleLogout(context),
              ),

              // 회원탈퇴
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '회원 탈퇴',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _showDeleteAccountDialog(context),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeModeLabel(SettingsState state) {
    // settings가 null이면 기본값 반환
    final themeMode = state.settings?.themeMode ?? ThemeMode.system;

    switch (themeMode) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 설정 따르기';
    }
  }

  String _getLanguageLabel(SettingsState state) {
    final languageCode = state.settings?.languageCode ?? 'ko';

    switch (languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      default:
        return '한국어';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsState state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('라이트 모드'),
              value: ThemeMode.light,
              groupValue: state.settings?.themeMode ?? ThemeMode.system,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateThemeMode(value),
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('다크 모드'),
              value: ThemeMode.dark,
              groupValue: state.settings?.themeMode ?? ThemeMode.system,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateThemeMode(value),
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('시스템 설정 따르기'),
              value: ThemeMode.system,
              groupValue: state.settings?.themeMode ?? ThemeMode.system,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateThemeMode(value),
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsState state) {
    final currentLanguageCode = state.settings?.languageCode ?? 'ko';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('한국어'),
              value: 'ko',
              groupValue: currentLanguageCode,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateLocale(const Locale('ko', 'KR')),
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguageCode,
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsBloc>().add(
                    SettingsEvent.updateLocale(const Locale('en', 'US')),
                  );
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 및 동기화'),
        content: const Text('백업 기능은 곧 추가될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('캐시 삭제'),
        content: const Text('캐시 삭제 기능은 곧 추가될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
              context.go('/auth/login');
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('회원 탈퇴 기능은 곧 추가될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
