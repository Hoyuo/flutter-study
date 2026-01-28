import 'package:core/core.dart' hide State, AppLifecycleListener;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 생체인증 화면
///
/// 앱 잠금 해제 시 사용자에게 생체인증을 요청하는 화면입니다.
/// Face ID, 지문 인식 등 디바이스에서 지원하는 생체인증을 사용합니다.
class BiometricAuthPage extends StatefulWidget {
  /// BiometricService 인스턴스
  final BiometricService biometricService;

  /// 인증 성공 시 이동할 경로 (기본값: '/')
  final String? successRoute;

  const BiometricAuthPage({
    super.key,
    required this.biometricService,
    this.successRoute,
  });

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  bool _isAuthenticating = false;
  String? _errorMessage;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: _onAppResume,
    );
    // 화면이 로드되면 자동으로 생체인증 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAppResume() {
    // 앱이 다시 foreground로 돌아올 때 재인증
    if (!_isAuthenticating) {
      _authenticate();
    }
  }

  /// 생체인증 수행
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // 생체인증 사용 가능 여부 확인
      final isAvailable = await widget.biometricService.isAvailable();

      if (!isAvailable) {
        setState(() {
          _errorMessage = 'auth.biometric_not_available'.tr();
          _isAuthenticating = false;
        });
        return;
      }

      // 생체인증 수행
      final success = await widget.biometricService.authenticate(
        localizedReason: 'auth.biometric_reason'.tr(),
      );

      if (!mounted) return;

      if (success) {
        // 인증 성공 - 메인 화면으로 이동
        final route = widget.successRoute ?? '/';
        context.go(route);
      } else {
        // 인증 실패 또는 취소
        setState(() {
          _errorMessage = 'auth.biometric_failed'.tr();
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'auth.biometric_error'.tr();
        _isAuthenticating = false;
      });

      // 에러 로깅
      AppLogger.e(
        'Biometric authentication error',
        e,
        StackTrace.current,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 잠금 아이콘
              Icon(
                Icons.lock_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // 타이틀
              Text(
                'auth.biometric_title'.tr(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 설명 텍스트
              Text(
                'auth.biometric_description'.tr(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // 에러 메시지
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 인증 버튼
              ElevatedButton.icon(
                onPressed: _isAuthenticating ? null : _authenticate,
                icon: _isAuthenticating
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(Icons.fingerprint),
                label: Text(
                  _isAuthenticating
                      ? 'auth.authenticating'.tr()
                      : 'auth.retry_biometric'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
