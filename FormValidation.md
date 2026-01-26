# Flutter 폼 검증 가이드

## 개요

Flutter의 Form/TextFormField를 사용한 폼 검증 패턴과 Bloc을 활용한 상태 관리 방식을 다룹니다. 실시간 검증, 에러 표시, 제출 처리 등을 구현합니다.

## 기본 폼 검증

### Flutter 기본 Form 사용

```dart
class BasicFormExample extends StatefulWidget {
  const BasicFormExample({super.key});

  @override
  State<BasicFormExample> createState() => _BasicFormExampleState();
}

class _BasicFormExampleState extends State<BasicFormExample> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: '이메일'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이메일을 입력해주세요';
              }
              if (!value.contains('@')) {
                return '올바른 이메일 형식이 아닙니다';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: '비밀번호'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요';
              }
              if (value.length < 8) {
                return '비밀번호는 8자 이상이어야 합니다';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('제출'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // 폼 유효함 - 제출 로직
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
    }
  }
}
```

## Validator 클래스

### 공통 Validator

```dart
// lib/core/validators/validators.dart
class Validators {
  Validators._();

  /// 필수 입력
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName을(를) 입력해주세요' : '필수 입력 항목입니다';
    }
    return null;
  }

  /// 이메일 형식
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  /// 최소 길이
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;

    if (value.length < min) {
      return fieldName != null
          ? '$fieldName은(는) $min자 이상이어야 합니다'
          : '$min자 이상 입력해주세요';
    }
    return null;
  }

  /// 최대 길이
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;

    if (value.length > max) {
      return fieldName != null
          ? '$fieldName은(는) $max자 이하여야 합니다'
          : '$max자 이하로 입력해주세요';
    }
    return null;
  }

  /// 비밀번호 형식 (영문, 숫자, 특수문자 조합)
  static String? password(String? value) {
    if (value == null || value.isEmpty) return null;

    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasLetter || !hasDigit) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다';
    }

    // 특수문자는 선택적으로
    // if (!hasSpecial) {
    //   return '비밀번호는 특수문자를 포함해야 합니다';
    // }

    return null;
  }

  /// 비밀번호 확인
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) return null;

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  /// 전화번호
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;

    // 숫자만 추출
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      return '올바른 전화번호 형식이 아닙니다';
    }
    return null;
  }

  /// 숫자만
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return fieldName != null
          ? '$fieldName은(는) 숫자만 입력 가능합니다'
          : '숫자만 입력해주세요';
    }
    return null;
  }

  /// 범위 검증 (숫자)
  static String? range(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) return null;

    final number = int.tryParse(value);
    if (number == null) return '숫자를 입력해주세요';

    if (min != null && number < min) {
      return '$min 이상의 값을 입력해주세요';
    }
    if (max != null && number > max) {
      return '$max 이하의 값을 입력해주세요';
    }
    return null;
  }

  /// URL 형식
  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;

    final urlRegex = RegExp(
      r'^https?:\/\/[^\s/$.?#].[^\s]*$',
      caseSensitive: false,
    );
    if (!urlRegex.hasMatch(value)) {
      return '올바른 URL 형식이 아닙니다';
    }
    return null;
  }
}
```

### Validator 조합

```dart
// lib/core/validators/validator_builder.dart

typedef ValidatorFunction = String? Function(String?);

class ValidatorBuilder {
  final List<ValidatorFunction> _validators = [];

  ValidatorBuilder required({String? fieldName}) {
    _validators.add((value) => Validators.required(value, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder email() {
    _validators.add(Validators.email);
    return this;
  }

  ValidatorBuilder minLength(int min, {String? fieldName}) {
    _validators.add((value) => Validators.minLength(value, min, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder maxLength(int max, {String? fieldName}) {
    _validators.add((value) => Validators.maxLength(value, max, fieldName: fieldName));
    return this;
  }

  ValidatorBuilder password() {
    _validators.add(Validators.password);
    return this;
  }

  ValidatorBuilder phone() {
    _validators.add(Validators.phone);
    return this;
  }

  ValidatorBuilder custom(ValidatorFunction validator) {
    _validators.add(validator);
    return this;
  }

  /// 빌드된 validator 함수 반환
  ValidatorFunction build() {
    return (value) {
      for (final validator in _validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

// 사용 예시
final emailValidator = ValidatorBuilder()
    .required(fieldName: '이메일')
    .email()
    .build();

final passwordValidator = ValidatorBuilder()
    .required(fieldName: '비밀번호')
    .minLength(8, fieldName: '비밀번호')
    .password()
    .build();
```

## Bloc 기반 폼 검증

### Form State 정의

```dart
// lib/features/auth/presentation/bloc/login_form_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_state.freezed.dart';

@freezed
class LoginFormState with _$LoginFormState {
  const factory LoginFormState({
    @Default('') String email,
    @Default('') String password,
    String? emailError,
    String? passwordError,
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? submitError,
  }) = _LoginFormState;
}

extension LoginFormStateX on LoginFormState {
  bool get isValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;

  bool get canSubmit => isValid && !isSubmitting;
}
```

### Form Event 정의

```dart
// lib/features/auth/presentation/bloc/login_form_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_form_event.freezed.dart';

@freezed
class LoginFormEvent with _$LoginFormEvent {
  const factory LoginFormEvent.emailChanged(String email) = _EmailChanged;
  const factory LoginFormEvent.passwordChanged(String password) = _PasswordChanged;
  const factory LoginFormEvent.submitted() = _Submitted;
}
```

### Form Bloc 구현

```dart
// lib/features/auth/presentation/bloc/login_form_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/validators/validators.dart';
import '../../domain/usecases/login_usecase.dart';
import 'login_form_event.dart';
import 'login_form_state.dart';

class LoginFormBloc extends Bloc<LoginFormEvent, LoginFormState> {
  final LoginUseCase _loginUseCase;

  LoginFormBloc({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase,
        super(const LoginFormState()) {
    on<LoginFormEvent>((event, emit) async {
      await event.when(
        emailChanged: (email) => _onEmailChanged(email, emit),
        passwordChanged: (password) => _onPasswordChanged(password, emit),
        submitted: () => _onSubmitted(emit),
      );
    });
  }

  void _onEmailChanged(String email, Emitter<LoginFormState> emit) {
    final error = _validateEmail(email);
    emit(state.copyWith(
      email: email,
      emailError: error,
      submitError: null,
    ));
  }

  void _onPasswordChanged(String password, Emitter<LoginFormState> emit) {
    final error = _validatePassword(password);
    emit(state.copyWith(
      password: password,
      passwordError: error,
      submitError: null,
    ));
  }

  Future<void> _onSubmitted(Emitter<LoginFormState> emit) async {
    // 최종 검증
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);

    if (emailError != null || passwordError != null) {
      emit(state.copyWith(
        emailError: emailError,
        passwordError: passwordError,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, submitError: null));

    final result = await _loginUseCase(
      email: state.email,
      password: state.password,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        submitError: failure.message,
      )),
      (_) => emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      )),
    );
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return '이메일을 입력해주세요';
    return Validators.email(email);
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return '비밀번호를 입력해주세요';
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다';
    return null;
  }
}
```

### Form UI

```dart
// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_form_bloc.dart';
import '../bloc/login_form_event.dart';
import '../bloc/login_form_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: BlocConsumer<LoginFormBloc, LoginFormState>(
        listenWhen: (prev, curr) =>
            prev.isSuccess != curr.isSuccess ||
            prev.submitError != curr.submitError,
        listener: (context, state) {
          if (state.isSuccess) {
            // 로그인 성공 - 화면 이동
            context.go('/home');
          }
          if (state.submitError != null) {
            // 에러 스낵바
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.submitError!)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이메일 필드
                TextField(
                  decoration: InputDecoration(
                    labelText: '이메일',
                    errorText: state.emailError,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    context.read<LoginFormBloc>().add(
                          LoginFormEvent.emailChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 16),

                // 비밀번호 필드
                TextField(
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    errorText: state.passwordError,
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    context.read<LoginFormBloc>().add(
                          LoginFormEvent.passwordChanged(value),
                        );
                  },
                ),
                const SizedBox(height: 24),

                // 제출 버튼
                ElevatedButton(
                  onPressed: state.canSubmit
                      ? () {
                          context.read<LoginFormBloc>().add(
                                const LoginFormEvent.submitted(),
                              );
                        }
                      : null,
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('로그인'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## 복잡한 폼 예시 (회원가입)

### 회원가입 State

```dart
// lib/features/auth/presentation/bloc/register_form_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_form_state.freezed.dart';

@freezed
class RegisterFormState with _$RegisterFormState {
  const factory RegisterFormState({
    // 필드 값
    @Default('') String email,
    @Default('') String password,
    @Default('') String confirmPassword,
    @Default('') String name,
    @Default('') String phone,
    @Default(false) bool agreeToTerms,
    @Default(false) bool agreeToMarketing,

    // 필드 에러
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? nameError,
    String? phoneError,

    // 상태
    @Default(false) bool isSubmitting,
    @Default(false) bool isSuccess,
    String? submitError,

    // 이메일 중복 확인
    @Default(false) bool isCheckingEmail,
    @Default(false) bool isEmailAvailable,
  }) = _RegisterFormState;
}

extension RegisterFormStateX on RegisterFormState {
  bool get isValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      name.isNotEmpty &&
      agreeToTerms &&
      emailError == null &&
      passwordError == null &&
      confirmPasswordError == null &&
      nameError == null &&
      isEmailAvailable;

  bool get canSubmit => isValid && !isSubmitting;

  double get completionProgress {
    int filled = 0;
    if (email.isNotEmpty) filled++;
    if (password.isNotEmpty) filled++;
    if (confirmPassword.isNotEmpty) filled++;
    if (name.isNotEmpty) filled++;
    if (phone.isNotEmpty) filled++;
    if (agreeToTerms) filled++;
    return filled / 6;
  }
}
```

### 회원가입 Bloc

```dart
// lib/features/auth/presentation/bloc/register_form_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/validators/validators.dart';
import '../../domain/usecases/check_email_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'register_form_event.dart';
import 'register_form_state.dart';

class RegisterFormBloc extends Bloc<RegisterFormEvent, RegisterFormState> {
  final RegisterUseCase _registerUseCase;
  final CheckEmailUseCase _checkEmailUseCase;

  RegisterFormBloc({
    required RegisterUseCase registerUseCase,
    required CheckEmailUseCase checkEmailUseCase,
  })  : _registerUseCase = registerUseCase,
        _checkEmailUseCase = checkEmailUseCase,
        super(const RegisterFormState()) {
    // 이메일 변경에 디바운스 적용 (중복 확인용)
    on<_EmailChanged>(
      _onEmailChanged,
      transformer: debounce(const Duration(milliseconds: 500)),
    );

    on<_PasswordChanged>(_onPasswordChanged);
    on<_ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<_NameChanged>(_onNameChanged);
    on<_PhoneChanged>(_onPhoneChanged);
    on<_AgreeToTermsChanged>(_onAgreeToTermsChanged);
    on<_AgreeToMarketingChanged>(_onAgreeToMarketingChanged);
    on<_Submitted>(_onSubmitted);
  }

  EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
  }

  Future<void> _onEmailChanged(
    _EmailChanged event,
    Emitter<RegisterFormState> emit,
  ) async {
    final email = event.email;
    final error = _validateEmail(email);

    emit(state.copyWith(
      email: email,
      emailError: error,
      isEmailAvailable: false,
      submitError: null,
    ));

    // 유효한 이메일이면 중복 확인
    if (error == null && email.isNotEmpty) {
      emit(state.copyWith(isCheckingEmail: true));

      final result = await _checkEmailUseCase(email);

      result.fold(
        (failure) => emit(state.copyWith(
          isCheckingEmail: false,
          emailError: failure.message,
        )),
        (isAvailable) => emit(state.copyWith(
          isCheckingEmail: false,
          isEmailAvailable: isAvailable,
          emailError: isAvailable ? null : '이미 사용 중인 이메일입니다',
        )),
      );
    }
  }

  void _onPasswordChanged(
    _PasswordChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    final password = event.password;
    final error = _validatePassword(password);

    // 비밀번호 확인도 재검증
    String? confirmError;
    if (state.confirmPassword.isNotEmpty) {
      confirmError = _validateConfirmPassword(state.confirmPassword, password);
    }

    emit(state.copyWith(
      password: password,
      passwordError: error,
      confirmPasswordError: confirmError,
      submitError: null,
    ));
  }

  void _onConfirmPasswordChanged(
    _ConfirmPasswordChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    final confirmPassword = event.confirmPassword;
    final error = _validateConfirmPassword(confirmPassword, state.password);

    emit(state.copyWith(
      confirmPassword: confirmPassword,
      confirmPasswordError: error,
      submitError: null,
    ));
  }

  void _onNameChanged(
    _NameChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    final name = event.name;
    final error = _validateName(name);

    emit(state.copyWith(
      name: name,
      nameError: error,
      submitError: null,
    ));
  }

  void _onPhoneChanged(
    _PhoneChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    final phone = event.phone;
    final error = Validators.phone(phone);

    emit(state.copyWith(
      phone: phone,
      phoneError: error,
      submitError: null,
    ));
  }

  void _onAgreeToTermsChanged(
    _AgreeToTermsChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(agreeToTerms: event.value));
  }

  void _onAgreeToMarketingChanged(
    _AgreeToMarketingChanged event,
    Emitter<RegisterFormState> emit,
  ) {
    emit(state.copyWith(agreeToMarketing: event.value));
  }

  Future<void> _onSubmitted(
    _Submitted event,
    Emitter<RegisterFormState> emit,
  ) async {
    // 모든 필드 검증
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);
    final confirmPasswordError =
        _validateConfirmPassword(state.confirmPassword, state.password);
    final nameError = _validateName(state.name);

    if (emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        nameError != null ||
        !state.agreeToTerms) {
      emit(state.copyWith(
        emailError: emailError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        nameError: nameError,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, submitError: null));

    final result = await _registerUseCase(
      email: state.email,
      password: state.password,
      name: state.name,
      phone: state.phone.isEmpty ? null : state.phone,
      agreeToMarketing: state.agreeToMarketing,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        submitError: failure.message,
      )),
      (_) => emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
      )),
    );
  }

  // Validators
  String? _validateEmail(String email) {
    if (email.isEmpty) return '이메일을 입력해주세요';
    return Validators.email(email);
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return '비밀번호를 입력해주세요';
    return Validators.password(password);
  }

  String? _validateConfirmPassword(String confirmPassword, String password) {
    if (confirmPassword.isEmpty) return '비밀번호 확인을 입력해주세요';
    return Validators.confirmPassword(confirmPassword, password);
  }

  String? _validateName(String name) {
    if (name.isEmpty) return '이름을 입력해주세요';
    if (name.length < 2) return '이름은 2자 이상이어야 합니다';
    return null;
  }
}
```

## 재사용 가능한 폼 필드 위젯

### Custom TextField

```dart
// lib/core/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.controller,
    this.focusNode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
    );
  }
}
```

### Password TextField (토글 가능)

```dart
// lib/core/widgets/password_text_field.dart
import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final String label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const PasswordTextField({
    super.key,
    this.label = '비밀번호',
    this.errorText,
    this.onChanged,
    this.controller,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
      onChanged: widget.onChanged,
    );
  }
}
```

### 비밀번호 강도 표시

```dart
// lib/core/widgets/password_strength_indicator.dart
import 'package:flutter/material.dart';

enum PasswordStrength { weak, fair, good, strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  PasswordStrength get strength {
    if (password.isEmpty) return PasswordStrength.weak;

    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.fair;
    if (score <= 4) return PasswordStrength.good;
    return PasswordStrength.strong;
  }

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.lightGreen;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.weak:
        return '약함';
      case PasswordStrength.fair:
        return '보통';
      case PasswordStrength.good:
        return '좋음';
      case PasswordStrength.strong:
        return '강함';
    }
  }

  double get _progress {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.fair:
        return 0.5;
      case PasswordStrength.good:
        return 0.75;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _label,
              style: TextStyle(
                color: _color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

## 실시간 검증 vs 제출 시 검증

### 실시간 검증 (onChange)

```dart
// 입력할 때마다 검증
TextField(
  onChanged: (value) {
    context.read<FormBloc>().add(FormEvent.fieldChanged(value));
    // Bloc에서 즉시 검증하여 에러 표시
  },
)
```

### 제출 시 검증

```dart
// 포커스 잃을 때만 검증
TextField(
  onEditingComplete: () {
    context.read<FormBloc>().add(FormEvent.fieldValidated());
  },
)

// 또는 제출 버튼 클릭 시에만 검증
ElevatedButton(
  onPressed: () {
    context.read<FormBloc>().add(FormEvent.submitted());
    // Bloc에서 모든 필드 검증
  },
)
```

### 하이브리드 방식 (권장)

```dart
// 1. 입력 시에는 에러만 제거 (UX 향상)
// 2. 포커스 잃을 때 검증
// 3. 제출 시 최종 검증

class FormBloc extends Bloc<FormEvent, FormState> {
  void _onFieldChanged(String value, Emitter emit) {
    // 에러가 있었다면 입력 시 제거 (긍정적 피드백)
    if (state.fieldError != null && _validate(value) == null) {
      emit(state.copyWith(fieldError: null));
    }
    emit(state.copyWith(fieldValue: value));
  }

  void _onFieldBlurred(Emitter emit) {
    // 포커스 잃을 때 검증
    final error = _validate(state.fieldValue);
    emit(state.copyWith(fieldError: error));
  }
}
```

## 테스트

### Bloc 테스트

```dart
void main() {
  late LoginFormBloc bloc;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    bloc = LoginFormBloc(loginUseCase: mockLoginUseCase);
  });

  group('email validation', () {
    blocTest<LoginFormBloc, LoginFormState>(
      'should show error for invalid email',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoginFormEvent.emailChanged('invalid')),
      expect: () => [
        const LoginFormState(
          email: 'invalid',
          emailError: '올바른 이메일 형식이 아닙니다',
        ),
      ],
    );

    blocTest<LoginFormBloc, LoginFormState>(
      'should clear error for valid email',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoginFormEvent.emailChanged('test@test.com')),
      expect: () => [
        const LoginFormState(email: 'test@test.com'),
      ],
    );
  });

  group('form submission', () {
    blocTest<LoginFormBloc, LoginFormState>(
      'should not submit if form is invalid',
      seed: () => const LoginFormState(email: '', password: ''),
      build: () => bloc,
      act: (bloc) => bloc.add(const LoginFormEvent.submitted()),
      expect: () => [
        const LoginFormState(
          emailError: '이메일을 입력해주세요',
          passwordError: '비밀번호를 입력해주세요',
        ),
      ],
      verify: (_) {
        verifyNever(() => mockLoginUseCase(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ));
      },
    );
  });
}
```

## 체크리스트

- [ ] Validators 클래스 구현 (email, password, phone, etc.)
- [ ] ValidatorBuilder로 validator 조합
- [ ] Form State 정의 (필드값, 에러, 상태)
- [ ] Form Event 정의 (필드 변경, 제출)
- [ ] Form Bloc 구현
- [ ] 실시간 검증 vs 제출 시 검증 전략 결정
- [ ] 재사용 가능한 폼 필드 위젯
- [ ] 비밀번호 강도 표시 (필요시)
- [ ] 이메일 중복 확인 등 비동기 검증 (디바운스)
- [ ] 폼 제출 로딩/에러/성공 상태 처리
- [ ] 키보드 액션 (다음 필드 이동, 제출)
- [ ] Bloc 테스트 작성
