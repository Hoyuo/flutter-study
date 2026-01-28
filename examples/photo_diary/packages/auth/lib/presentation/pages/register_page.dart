import 'package:core/core.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/bloc.dart';

/// 회원가입 화면
///
/// 새로운 사용자가 계정을 생성할 수 있는 화면입니다.
/// 이메일, 비밀번호, 비밀번호 확인, 표시 이름을 입력받습니다.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      // AuthBloc에 회원가입 이벤트 전달
      context.read<AuthBloc>().add(
            AuthEvent.signUpRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _displayNameController.text.trim(),
            ),
          );
    }
  }

  void _navigateToLogin() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocUiEffectListener<AuthBloc, AuthState, AuthUiEffect>(
      listener: (context, effect) {
        effect.when(
          // 에러 메시지 스낵바로 표시
          showError: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
          // 회원가입 성공 시 홈으로 이동
          navigateToHome: () {
            context.go('/');
          },
          // 로그인 화면으로 이동
          navigateToLogin: () {
            context.pop();
          },
          // 성공 스낵바 표시
          showSuccessSnackBar: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('auth.register'.tr()),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
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
                          Icons.person_add_outlined,
                          size: 80,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'auth.create_account'.tr(),
                          style: context.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // 표시 이름 입력 필드
                        Semantics(
                          label: 'auth.display_name_field'.tr(),
                          child: TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration(
                              labelText: 'auth.display_name'.tr(),
                              hintText: 'auth.display_name_hint'.tr(),
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                            enabled: !isSubmitting,
                            validator: (value) =>
                                Validators.required(value, '이름'),
                            autofillHints: const [AutofillHints.name],
                          ),
                        ),
                        const SizedBox(height: 16),

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
                            textInputAction: TextInputAction.next,
                            enabled: !isSubmitting,
                            validator: Validators.password,
                            autofillHints: const [AutofillHints.newPassword],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 비밀번호 확인 입력 필드
                        Semantics(
                          label: 'auth.confirm_password_field'.tr(),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'auth.confirm_password'.tr(),
                              hintText: 'auth.confirm_password_hint'.tr(),
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                tooltip: _obscureConfirmPassword
                                    ? 'auth.show_password'.tr()
                                    : 'auth.hide_password'.tr(),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !isSubmitting,
                            validator: Validators.confirmPassword(
                              _passwordController.text,
                            ),
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 회원가입 버튼
                        Semantics(
                          button: true,
                          label: 'auth.register_button'.tr(),
                          child: FilledButton(
                            onPressed: isSubmitting ? null : _handleRegister,
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
                                  : Text('auth.register'.tr()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 로그인 링크
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('auth.have_account'.tr()),
                            const SizedBox(width: 4),
                            Semantics(
                              button: true,
                              label: 'auth.login_link'.tr(),
                              child: TextButton(
                                onPressed:
                                    isSubmitting ? null : _navigateToLogin,
                                child: Text('auth.login'.tr()),
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
