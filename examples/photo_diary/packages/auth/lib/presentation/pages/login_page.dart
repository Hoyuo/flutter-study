import 'package:core/core.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/bloc.dart';

/// 로그인 화면
///
/// 사용자가 이메일과 비밀번호로 로그인할 수 있는 화면입니다.
/// BlocUiEffectListener를 통해 UI 효과(에러 표시, 네비게이션 등)를 처리합니다.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      // AuthBloc에 로그인 이벤트 전달
      context.read<AuthBloc>().add(
            AuthEvent.signInRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _navigateToRegister() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
    return BlocUiEffectListener<AuthBloc, AuthState, AuthUiEffect>(
      listener: (context, effect) {
        switch (effect) {
          // 에러 메시지 스낵바로 표시
          case AuthShowError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          // 로그인 성공 시 홈으로 이동
          case AuthNavigateToHome():
            context.go('/');
          // 로그인 화면으로 이동
          case AuthNavigateToLogin():
            // 이미 로그인 화면이므로 무시
            break;
          // 성공 스낵바 표시
          case AuthShowSuccessSnackBar(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('auth.login'.tr()),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (prev, curr) => prev.isSubmitting != curr.isSubmitting,
          builder: (context, state) {
            final isSubmitting = state.isSubmitting;

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 앱 로고 또는 타이틀
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 80,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'auth.welcome'.tr(),
                          style: context.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // 이메일 입력 필드
                        Semantics(
                          label: 'auth.email_field'.tr(),
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'auth.email'.tr(),
                              hintText: 'auth.email_hint'.tr(),
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !isSubmitting,
                            validator: Validators.email,
                            autofillHints: const [AutofillHints.email],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 비밀번호 입력 필드
                        Semantics(
                          label: 'auth.password_field'.tr(),
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'auth.password'.tr(),
                              hintText: 'auth.password_hint'.tr(),
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                tooltip: _obscurePassword
                                    ? 'auth.show_password'.tr()
                                    : 'auth.hide_password'.tr(),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isSubmitting,
                            validator: Validators.password,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 로그인 버튼
                        Semantics(
                          button: true,
                          label: 'auth.login_button'.tr(),
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _handleLogin,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('auth.login'.tr()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 회원가입 링크
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('auth.no_account'.tr()),
                            const SizedBox(width: 4),
                            Semantics(
                              button: true,
                              label: 'auth.register_link'.tr(),
                              child: TextButton(
                                onPressed:
                                    isSubmitting ? null : _navigateToRegister,
                                child: Text('auth.register'.tr()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
