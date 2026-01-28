import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:auth/presentation/bloc/auth_bloc.dart';
import 'package:auth/presentation/bloc/auth_state.dart';

/// 스플래시 화면
///
/// 앱 시작 시 표시되며, 인증 상태를 확인한 후
/// 적절한 화면으로 자동 이동합니다.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  /// 인증 상태 확인 및 자동 네비게이션
  Future<void> _checkAuthAndNavigate() async {
    // 최소 스플래시 표시 시간 (UX 개선)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;

    // 인증 상태에 따라 이동
    switch (authState.status) {
      case AuthStatus.authenticated:
        // 인증된 경우 다이어리 목록으로
        context.go('/diary');
        break;
      case AuthStatus.unauthenticated:
        // 인증되지 않은 경우 로그인 화면으로
        context.go('/auth/login');
        break;
      case AuthStatus.unknown:
        // 초기 상태 또는 로딩 중인 경우 잠시 대기 후 재시도
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _checkAuthAndNavigate();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘
            Icon(
              Icons.photo_camera,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // 앱 이름
            Text(
              'Photo Diary',
              style: Theme.of(context).textTheme.displayLarge,
            ),

            const SizedBox(height: 48),

            // 로딩 인디케이터
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
