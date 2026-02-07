# Flutter 패키지 개발 & 배포 가이드

> Flutter 패키지 및 플러그인 개발부터 Pub.dev 배포, 유지보수까지의 전체 프로세스를 다루는 실무 가이드입니다. Dart Package, Flutter Plugin, FFI Plugin의 개발 방법과 API 설계, 테스트, CI/CD, 버전 관리 전략을 포함합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Dart Package와 Flutter Plugin을 개발할 수 있다
> - Pub.dev에 패키지를 배포하고 Semantic Versioning을 관리할 수 있다
> - Federated Plugin 구조로 플랫폼별 확장을 구현할 수 있다

---

## 1. 개요

### 1.1 패키지 종류

Flutter 생태계에서 제공할 수 있는 패키지는 크게 세 가지로 분류됩니다.

| 패키지 종류 | 설명 | Platform 의존성 | 사용 사례 |
|------------|------|----------------|----------|
| **Dart Package** | 순수 Dart 코드로만 구성 | 없음 | 유틸리티, 상태 관리, 데이터 모델 |
| **Flutter Plugin** | Platform Channel로 네이티브 연동 | 있음 | 카메라, 센서, 위치, 결제 |
| **FFI Plugin** | dart:ffi로 C/C++ 직접 호출 | 있음 | 고성능 연산, 레거시 라이브러리 |

### 1.2 패키지 vs 플러그인

- **Package**: 플랫폼 코드 없이 Dart/Flutter만 사용
- **Plugin**: Android/iOS/Web/Desktop 네이티브 코드 포함

---

## 2. Dart Package 만들기

### 2.1 프로젝트 생성

```bash
# Dart Package 생성
flutter create --template=package my_utils

# 생성된 구조
my_utils/
├── lib/
│   └── my_utils.dart          # barrel 파일
├── test/
│   └── my_utils_test.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### 2.2 pubspec.yaml 구성

```yaml
# pubspec.yaml
name: my_utils
description: A comprehensive utility library for Flutter applications
version: 1.0.0
homepage: https://github.com/username/my_utils
repository: https://github.com/username/my_utils
issue_tracker: https://github.com/username/my_utils/issues
documentation: https://pub.dev/documentation/my_utils/latest/

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  # 필요 시 의존성 추가
  meta: ^1.15.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  test: ^1.25.0

# 플랫폼 제약이 없는 순수 Dart 패키지
platforms:
  android:
  ios:
  linux:
  macos:
  web:
  windows:
```

### 2.3 라이브러리 코드 작성

```dart
// lib/my_utils.dart (barrel 파일)
library my_utils;

export 'src/string_utils.dart';
export 'src/date_utils.dart';
export 'src/validators.dart';

// lib/src/string_utils.dart
/// String 관련 유틸리티 함수 모음
class StringUtils {
  StringUtils._(); // 인스턴스화 방지

  /// 문자열을 카멜케이스로 변환
  ///
  /// ```dart
  /// StringUtils.toCamelCase('hello_world'); // 'helloWorld'
  /// ```
  static String toCamelCase(String input) {
    if (input.isEmpty) return input;

    final words = input.split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return input;

    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return first + rest.join();
  }

  /// 문자열을 스네이크케이스로 변환
  static String toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'^_'), '');
  }

  /// 문자열 앞뒤 공백 제거 및 중간 공백 정규화
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}

// lib/src/validators.dart
import 'package:meta/meta.dart';

/// 커스텀 검증 함수 타입
typedef ValidatorFunction = bool Function(String value);

/// 입력 값 검증을 위한 유틸리티
class Validators {
  Validators._();

  /// 이메일 형식 검증
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 한국 휴대폰 번호 검증
  static bool isValidKoreanPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneRegex = RegExp(r'^01[0-9]{8,9}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// 비밀번호 강도 검증 (8자 이상, 영문+숫자+특수문자)
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits && hasSpecialChars;
  }

  /// 여러 검증 함수를 조합
  static ValidatorFunction combine(List<ValidatorFunction> validators) {
    return (String value) {
      return validators.every((validator) => validator(value));
    };
  }
}
```

---

## 3. Flutter Plugin 만들기

### 3.1 플러그인 프로젝트 생성

```bash
# Flutter Plugin 생성 (Android, iOS 지원)
flutter create --template=plugin --platforms=android,ios my_plugin

# 모든 플랫폼 지원
flutter create --template=plugin --platforms=android,ios,web,linux,macos,windows my_plugin
```

### 3.2 Platform Channel 구조

```dart
// lib/my_plugin.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'my_plugin_platform_interface.dart';

/// 배터리 정보를 가져오는 플러그인
class MyPlugin {
  /// MethodChannel을 통한 네이티브 호출
  Future<int?> getBatteryLevel() {
    return MyPluginPlatform.instance.getBatteryLevel();
  }

  /// EventChannel을 통한 스트림 구독
  Stream<int> get batteryLevelStream {
    return MyPluginPlatform.instance.batteryLevelStream;
  }
}

// lib/my_plugin_platform_interface.dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'my_plugin_method_channel.dart';

abstract class MyPluginPlatform extends PlatformInterface {
  MyPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static MyPluginPlatform _instance = MethodChannelMyPlugin();

  static MyPluginPlatform get instance => _instance;

  static set instance(MyPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int?> getBatteryLevel();
  Stream<int> get batteryLevelStream;
}

// lib/my_plugin_method_channel.dart
import 'package:flutter/services.dart';
import 'my_plugin_platform_interface.dart';

class MethodChannelMyPlugin extends MyPluginPlatform {
  final _methodChannel = const MethodChannel('com.example.my_plugin/methods');
  final _eventChannel = const EventChannel('com.example.my_plugin/events');

  @override
  Future<int?> getBatteryLevel() async {
    try {
      final int? batteryLevel = await _methodChannel.invokeMethod('getBatteryLevel');
      return batteryLevel;
    } on PlatformException catch (e) {
      throw Exception('Failed to get battery level: ${e.message}');
    }
  }

  @override
  Stream<int> get batteryLevelStream {
    return _eventChannel.receiveBroadcastStream().map((dynamic event) => event as int);
  }
}
```

### 3.3 Android 구현

```kotlin
// android/src/main/kotlin/com/example/my_plugin/MyPlugin.kt
package com.example.my_plugin

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MyPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    methodChannel = MethodChannel(binding.binaryMessenger, "com.example.my_plugin/methods")
    methodChannel.setMethodCallHandler(this)

    eventChannel = EventChannel(binding.binaryMessenger, "com.example.my_plugin/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getBatteryLevel" -> {
        val batteryLevel = getBatteryLevel()
        if (batteryLevel != -1) {
          result.success(batteryLevel)
        } else {
          result.error("UNAVAILABLE", "Battery level not available.", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun getBatteryLevel(): Int {
    val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    // 실제로는 BroadcastReceiver 등록하여 배터리 변경 감지
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
```

### 3.4 iOS 구현

```swift
// ios/Classes/MyPlugin.swift
import Flutter
import UIKit

public class MyPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "com.example.my_plugin/methods",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "com.example.my_plugin/events",
      binaryMessenger: registrar.messenger()
    )

    let instance = MyPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getBatteryLevel":
      getBatteryLevel(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getBatteryLevel(result: FlutterResult) {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = Int(UIDevice.current.batteryLevel * 100)

    if batteryLevel >= 0 {
      result(batteryLevel)
    } else {
      result(FlutterError(
        code: "UNAVAILABLE",
        message: "Battery level not available.",
        details: nil
      ))
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    UIDevice.current.isBatteryMonitoringEnabled = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(batteryLevelDidChange),
      name: UIDevice.batteryLevelDidChangeNotification,
      object: nil
    )
    return nil
  }

  @objc private func batteryLevelDidChange() {
    let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
    eventSink?(batteryLevel)
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    NotificationCenter.default.removeObserver(self)
    return nil
  }
}
```

---

## 4. Federated Plugin

### 4.1 Federated Plugin 구조

```
my_plugin/                          # 인터페이스 패키지
├── my_plugin_android/              # Android 구현
├── my_plugin_ios/                  # iOS 구현
├── my_plugin_web/                  # Web 구현
└── my_plugin_platform_interface/   # 공통 인터페이스
```

### 4.2 Platform Interface 패키지

```yaml
# my_plugin_platform_interface/pubspec.yaml
name: my_plugin_platform_interface
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.1.8
```

```dart
// my_plugin_platform_interface/lib/my_plugin_platform_interface.dart
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class MyPluginPlatform extends PlatformInterface {
  MyPluginPlatform() : super(token: _token);

  static final Object _token = Object();
  static MyPluginPlatform? _instance;

  static MyPluginPlatform get instance => _instance!;

  static set instance(MyPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 플랫폼별로 구현해야 하는 메서드
  Future<String> getPlatformVersion();

  Future<void> initialize(Map<String, dynamic> config);

  Stream<Map<String, dynamic>> get dataStream;
}
```

### 4.3 플랫폼별 패키지

```yaml
# my_plugin_android/pubspec.yaml
name: my_plugin_android
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  my_plugin_platform_interface: ^1.0.0

flutter:
  plugin:
    implements: my_plugin
    platforms:
      android:
        package: com.example.my_plugin_android
        pluginClass: MyPluginAndroid
```

```dart
// my_plugin_android/lib/my_plugin_android.dart
import 'package:flutter/services.dart';
import 'package:my_plugin_platform_interface/my_plugin_platform_interface.dart';

class MyPluginAndroid extends MyPluginPlatform {
  final _methodChannel = const MethodChannel('my_plugin_android');

  static void registerWith() {
    MyPluginPlatform.instance = MyPluginAndroid();
  }

  @override
  Future<String> getPlatformVersion() async {
    final version = await _methodChannel.invokeMethod<String>('getPlatformVersion');
    return version ?? 'Unknown Android version';
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    await _methodChannel.invokeMethod('initialize', config);
  }

  @override
  Stream<Map<String, dynamic>> get dataStream {
    // EventChannel 구현
    throw UnimplementedError();
  }
}
```

---

## 5. FFI Plugin

### 5.1 FFI Plugin 구조

```bash
flutter create --template=plugin_ffi my_ffi_plugin
```

### 5.2 C 라이브러리 작성

```c
// src/my_ffi_plugin.h
#ifndef MY_FFI_PLUGIN_H
#define MY_FFI_PLUGIN_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 간단한 덧셈 함수
int32_t add(int32_t a, int32_t b);

// 복잡한 연산 (배열 처리)
void process_array(int32_t* array, int32_t length);

// 문자열 처리
char* to_uppercase(const char* input);

#ifdef __cplusplus
}
#endif

#endif // MY_FFI_PLUGIN_H
```

```c
// src/my_ffi_plugin.c
#include "my_ffi_plugin.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int32_t add(int32_t a, int32_t b) {
    return a + b;
}

void process_array(int32_t* array, int32_t length) {
    for (int32_t i = 0; i < length; i++) {
        array[i] = array[i] * 2;
    }
}

char* to_uppercase(const char* input) {
    size_t len = strlen(input);
    char* result = (char*)malloc(len + 1);

    for (size_t i = 0; i < len; i++) {
        result[i] = toupper(input[i]);
    }
    result[len] = '\0';

    return result;
}
```

### 5.3 FFI 바인딩 생성

```yaml
# pubspec.yaml
dev_dependencies:
  ffigen: ^14.0.0
```

```yaml
# ffigen.yaml
name: MyFfiPlugin
description: FFI bindings for my_ffi_plugin
output: 'lib/src/ffi_bindings.dart'
headers:
  entry-points:
    - 'src/my_ffi_plugin.h'
```

```bash
# 바인딩 생성
dart run ffigen --config ffigen.yaml
```

### 5.4 Dart에서 FFI 사용

```dart
// lib/my_ffi_plugin.dart
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'src/ffi_bindings.dart';

class MyFfiPlugin {
  static final MyFfiPlugin _instance = MyFfiPlugin._internal();
  factory MyFfiPlugin() => _instance;
  MyFfiPlugin._internal();

  late final MyFfiPluginBindings _bindings;

  void initialize() {
    final dylib = _loadLibrary();
    _bindings = MyFfiPluginBindings(dylib);
  }

  ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return ffi.DynamicLibrary.open('libmy_ffi_plugin.so');
    } else if (Platform.isIOS || Platform.isMacOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('my_ffi_plugin.dll');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// 간단한 덧셈
  int add(int a, int b) {
    return _bindings.add(a, b);
  }

  /// 배열 처리
  List<int> processArray(List<int> input) {
    final length = input.length;
    final pointer = calloc<ffi.Int32>(length);

    try {
      // Dart List -> C array
      for (var i = 0; i < length; i++) {
        pointer[i] = input[i];
      }

      // C 함수 호출
      _bindings.process_array(pointer, length);

      // C array -> Dart List
      return List.generate(length, (i) => pointer[i]);
    } finally {
      calloc.free(pointer);
    }
  }

  /// 문자열 처리
  String toUppercase(String input) {
    final inputPointer = input.toNativeUtf8();

    try {
      final resultPointer = _bindings.to_uppercase(inputPointer.cast());
      final result = resultPointer.cast<Utf8>().toDartString();

      // C에서 malloc한 메모리 해제
      calloc.free(resultPointer);

      return result;
    } finally {
      calloc.free(inputPointer);
    }
  }
}
```

---

## 6. API 설계

### 6.1 Public API 원칙

```dart
// ❌ 나쁜 예: 내부 구현 노출
// lib/my_package.dart
export 'src/internal_helper.dart'; // 내부 헬퍼까지 노출

// ✅ 좋은 예: 명시적 export
// lib/my_package.dart
library my_package;

export 'src/models/user.dart';
export 'src/services/auth_service.dart';
export 'src/widgets/custom_button.dart';

// 특정 클래스만 export
export 'src/utils/validators.dart' show EmailValidator, PasswordValidator;

// lib/src/internal_helper.dart는 export하지 않음 (내부용)
```

### 6.2 Barrel 파일 전략

```dart
// lib/my_package.dart (메인 진입점)
library my_package;

// Core exports
export 'src/core/config.dart';
export 'src/core/exceptions.dart';

// Feature exports
export 'src/features/auth/auth.dart';
export 'src/features/profile/profile.dart';

// lib/src/features/auth/auth.dart (feature barrel)
export 'models/auth_user.dart';
export 'services/auth_service.dart';
export 'providers/auth_provider.dart';
```

### 6.3 Versioned API

```dart
// lib/src/api/v1/client.dart
/// API 버전 1 (안정화)
class ApiClientV1 {
  Future<User> getUser(String id) async {
    // 구현
  }
}

// lib/src/api/v2/client.dart
/// API 버전 2 (새로운 기능)
class ApiClientV2 {
  Future<UserV2> getUser(String id) async {
    // 개선된 구현
  }

  Future<List<UserV2>> searchUsers(String query) async {
    // 새로운 기능
  }
}

// lib/my_package.dart
export 'src/api/v1/client.dart' show ApiClientV1;
export 'src/api/v2/client.dart' show ApiClientV2;
```

### 6.4 Extension API

```dart
// lib/src/extensions/string_extensions.dart
/// String 확장 메서드
extension StringExtensions on String {
  /// 첫 글자를 대문자로 변환
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// 이메일 형식 검증
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }
}

// lib/src/extensions/list_extensions.dart
extension ListExtensions<T> on List<T> {
  /// 리스트를 청크로 분할
  List<List<T>> chunk(int size) {
    return [
      for (var i = 0; i < length; i += size)
        sublist(i, i + size > length ? length : i + size),
    ];
  }
}
```

---

## 7. 문서화

### 7.1 Dartdoc 주석

```dart
/// 사용자 인증을 처리하는 서비스 클래스
///
/// 이 클래스는 로그인, 로그아웃, 회원가입 등의 인증 관련 기능을 제공합니다.
/// 모든 메서드는 비동기로 동작하며, 실패 시 [AuthException]을 발생시킵니다.
///
/// **사용 예시:**
/// ```dart
/// final authService = AuthService();
///
/// try {
///   final user = await authService.login(
///     email: 'user@example.com',
///     password: 'password123',
///   );
///   print('Logged in: ${user.name}');
/// } on AuthException catch (e) {
///   print('Login failed: ${e.message}');
/// }
/// ```
///
/// **참고:**
/// - [User] 모델에 대한 자세한 정보
/// - [AuthException] 예외 처리 가이드
class AuthService {
  /// 이메일과 비밀번호로 로그인
  ///
  /// [email]과 [password]가 유효하면 [User] 객체를 반환합니다.
  ///
  /// **파라미터:**
  /// - [email]: 사용자 이메일 주소 (필수)
  /// - [password]: 사용자 비밀번호 (필수)
  /// - [rememberMe]: 로그인 상태 유지 여부 (선택, 기본값: false)
  ///
  /// **반환값:**
  /// 로그인에 성공한 [User] 객체
  ///
  /// **예외:**
  /// - [InvalidCredentialsException]: 이메일 또는 비밀번호가 잘못된 경우
  /// - [NetworkException]: 네트워크 연결 실패
  /// - [ServerException]: 서버 오류 (5xx)
  Future<User> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    // 구현
    throw UnimplementedError();
  }

  /// 현재 로그인된 사용자 정보를 가져옵니다.
  ///
  /// 로그인되지 않은 경우 `null`을 반환합니다.
  Future<User?> getCurrentUser() async {
    // 구현
    throw UnimplementedError();
  }
}
```

### 7.2 README.md 템플릿

```markdown
# my_package

[![pub package](https://img.shields.io/pub/v/my_package.svg)](https://pub.dev/packages/my_package)
[![popularity](https://img.shields.io/pub/popularity/my_package?logo=dart)](https://pub.dev/packages/my_package/score)
[![likes](https://img.shields.io/pub/likes/my_package?logo=dart)](https://pub.dev/packages/my_package/score)
[![pub points](https://img.shields.io/pub/points/my_package?logo=dart)](https://pub.dev/packages/my_package/score)

A powerful utility library for Flutter developers.

## Features

- 🚀 High-performance string utilities
- ✅ Comprehensive input validators
- 📅 Advanced date manipulation
- 🎨 Customizable widgets

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  my_package: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:my_package/my_package.dart';

void main() {
  // String utilities
  final camelCase = StringUtils.toCamelCase('hello_world');
  print(camelCase); // 'helloWorld'

  // Validators
  if (Validators.isValidEmail('test@example.com')) {
    print('Valid email!');
  }
}
```

## Advanced Usage

### Custom Validators

```dart
final customValidator = Validators.combine([
  (value) => value.length >= 8,
  (value) => value.contains(RegExp(r'[A-Z]')),
  (value) => value.contains(RegExp(r'[0-9]')),
]);

if (customValidator('MyPassword123')) {
  print('Password meets all requirements');
}
```

## Platform Support

| Platform | Supported |
|----------|-----------|
| Android  | ✅        |
| iOS      | ✅        |
| Web      | ✅        |
| macOS    | ✅        |
| Windows  | ✅        |
| Linux    | ✅        |

## Additional information

- [API Documentation](https://pub.dev/documentation/my_package/latest/)
- [Issue Tracker](https://github.com/username/my_package/issues)
- [Contributing Guidelines](https://github.com/username/my_package/blob/main/CONTRIBUTING.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
```

### 7.3 CHANGELOG.md

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-15

### Added
- `StringUtils.truncate()` method for string truncation
- Support for custom validators via `Validators.combine()`
- Example app demonstrating all features

### Changed
- Improved performance of `StringUtils.toCamelCase()` by 30%
- Updated minimum Dart SDK to 3.6.0

### Deprecated
- `StringUtils.oldMethod()` - use `newMethod()` instead

### Fixed
- `Validators.isValidEmail()` now correctly handles international domains
- Crash when passing null to `StringUtils.normalizeWhitespace()`

### Security
- Fixed potential XSS vulnerability in `StringUtils.sanitize()`

## [1.1.0] - 2026-01-20

### Added
- Korean phone number validator
- Password strength checker

## [1.0.0] - 2025-12-10

### Added
- Initial release
- Basic string utilities
- Email validator
```

### 7.4 Example App

```dart
// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:my_package/my_package.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Package Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('My Package Demo')),
        body: const DemoPage(),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _emailController = TextEditingController();
  String _validationResult = '';

  void _validateEmail() {
    final email = _emailController.text;
    final isValid = Validators.isValidEmail(email);

    setState(() {
      _validationResult = isValid ? '✅ Valid email' : '❌ Invalid email';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter email address',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _validateEmail,
            child: const Text('Validate'),
          ),
          const SizedBox(height: 16),
          Text(
            _validationResult,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. 테스트

### 8.1 단위 테스트

```dart
// test/string_utils_test.dart
import 'package:test/test.dart';
import 'package:my_package/my_package.dart';

void main() {
  group('StringUtils', () {
    group('toCamelCase', () {
      test('converts snake_case to camelCase', () {
        expect(StringUtils.toCamelCase('hello_world'), equals('helloWorld'));
        expect(StringUtils.toCamelCase('foo_bar_baz'), equals('fooBarBaz'));
      });

      test('handles single word', () {
        expect(StringUtils.toCamelCase('hello'), equals('hello'));
      });

      test('handles empty string', () {
        expect(StringUtils.toCamelCase(''), equals(''));
      });

      test('handles mixed separators', () {
        expect(StringUtils.toCamelCase('hello-world_foo'), equals('helloWorldFoo'));
      });
    });

    group('toSnakeCase', () {
      test('converts camelCase to snake_case', () {
        expect(StringUtils.toSnakeCase('helloWorld'), equals('hello_world'));
        expect(StringUtils.toSnakeCase('fooBarBaz'), equals('foo_bar_baz'));
      });
    });
  });

  group('Validators', () {
    group('isValidEmail', () {
      test('validates correct email addresses', () {
        expect(Validators.isValidEmail('test@example.com'), isTrue);
        expect(Validators.isValidEmail('user.name@company.co.kr'), isTrue);
      });

      test('rejects invalid email addresses', () {
        expect(Validators.isValidEmail('invalid'), isFalse);
        expect(Validators.isValidEmail('test@'), isFalse);
        expect(Validators.isValidEmail('@example.com'), isFalse);
      });
    });

    group('isStrongPassword', () {
      test('validates strong passwords', () {
        expect(Validators.isStrongPassword('MyPass123!'), isTrue);
      });

      test('rejects weak passwords', () {
        expect(Validators.isStrongPassword('short'), isFalse);
        expect(Validators.isStrongPassword('nouppercase123!'), isFalse);
        expect(Validators.isStrongPassword('NOLOWERCASE123!'), isFalse);
        expect(Validators.isStrongPassword('NoNumbers!'), isFalse);
      });
    });
  });
}
```

### 8.2 Widget 테스트

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_package/my_package.dart';

void main() {
  group('CustomButton', () {
    testWidgets('displays text correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('triggers onPressed callback', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Click Me',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('disables when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);
    });
  });
}
```

### 8.3 통합 테스트

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_package_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('email validation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 이메일 입력
      await tester.enterText(
        find.byType(TextField),
        'test@example.com',
      );

      // Validate 버튼 클릭
      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      // 검증 결과 확인
      expect(find.text('✅ Valid email'), findsOneWidget);

      // 잘못된 이메일 입력
      await tester.enterText(
        find.byType(TextField),
        'invalid-email',
      );

      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      expect(find.text('❌ Invalid email'), findsOneWidget);
    });
  });
}
```

### 8.4 Mock을 사용한 테스트

```dart
// test/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_package/my_package.dart';

// Mock 클래스 생성
@GenerateMocks([HttpClient, SecureStorage])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockHttpClient mockHttpClient;
  late MockSecureStorage mockStorage;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    authService = AuthService(
      httpClient: mockHttpClient,
      storage: mockStorage,
    );
  });

  group('AuthService', () {
    test('login success returns user', () async {
      // Arrange
      when(mockHttpClient.post(any, body: anyNamed('body')))
          .thenAnswer((_) async => {
                'id': '123',
                'name': 'Test User',
                'email': 'test@example.com',
              });

      // Act
      final user = await authService.login(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(user.id, equals('123'));
      expect(user.name, equals('Test User'));
      verify(mockHttpClient.post(any, body: anyNamed('body'))).called(1);
    });

    test('login failure throws AuthException', () async {
      // Arrange
      when(mockHttpClient.post(any, body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => authService.login(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
```

---

## 9. CI/CD

### 9.1 GitHub Actions 워크플로우

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.28.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze project source
        run: dart analyze --fatal-infos

      - name: Check for outdated dependencies
        run: flutter pub outdated

  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        flutter-version: ['3.28.0', '3.27.0']

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ matrix.flutter-version }}
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test --coverage

      - name: Upload coverage to Codecov
        if: matrix.os == 'ubuntu-latest' && matrix.flutter-version == '3.28.0'
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage/lcov.info

  pana:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.28.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Install pana
        run: dart pub global activate pana

      - name: Run pana
        run: dart pub global run pana --no-warning --exit-code-threshold 0
```

### 9.2 자동 배포 워크플로우

```yaml
# .github/workflows/publish.yml
name: Publish to pub.dev

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.28.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      - name: Check publish warnings
        run: dart pub publish --dry-run

      - name: Publish package
        uses: k-paxian/dart-package-publisher@v1.6
        with:
          credentialJson: ${{ secrets.CREDENTIAL_JSON }}
          flutter: true
          skipTests: true
```

### 9.3 Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "Running pre-commit checks..."

# Format check
echo "Checking formatting..."
dart format --output=none --set-exit-if-changed .
if [ $? -ne 0 ]; then
  echo "❌ Code is not formatted. Run: dart format ."
  exit 1
fi

# Analyze
echo "Running analysis..."
dart analyze --fatal-infos
if [ $? -ne 0 ]; then
  echo "❌ Analysis failed."
  exit 1
fi

# Tests
echo "Running tests..."
flutter test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed."
  exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
```

---

## 10. Pub.dev 배포

### 10.1 점수 최적화

Pub.dev 점수는 다음 항목으로 구성됩니다:

| 항목 | 점수 | 최적화 방법 |
|-----|------|-----------|
| **Documentation** | 10점 | README, API docs, Example |
| **Platforms** | 20점 | 다중 플랫폼 지원 |
| **Null safety** | 20점 | Sound null safety |
| **Pass static analysis** | 30점 | dart analyze 통과 |
| **Support up-to-date dependencies** | 10점 | 최신 의존성 |
| **Support latest SDK** | 10점 | 최신 SDK 지원 |

### 10.2 pubspec.yaml 최적화

```yaml
name: my_package
description: A comprehensive utility library for Flutter applications with string manipulation, validators, and date utilities.
version: 1.0.0
homepage: https://github.com/username/my_package
repository: https://github.com/username/my_package
issue_tracker: https://github.com/username/my_package/issues
documentation: https://pub.dev/documentation/my_package/latest/

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  meta: ^1.15.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  test: ^1.25.0
  mockito: ^5.4.4
  build_runner: ^2.4.15

topics:
  - utilities
  - validation
  - strings
  - helpers

screenshots:
  - description: 'Email validation demo'
    path: screenshots/email_validation.png
  - description: 'String utilities example'
    path: screenshots/string_utils.png

funding:
  - https://github.com/sponsors/username
```

### 10.3 배포 전 체크리스트

```bash
# 1. 버전 확인
grep "version:" pubspec.yaml

# 2. CHANGELOG 업데이트
# CHANGELOG.md에 변경사항 추가

# 3. Format & Analyze
dart format .
dart analyze --fatal-infos

# 4. Tests
flutter test

# 5. Dry-run
dart pub publish --dry-run

# 6. Pana 점수 확인
dart pub global activate pana
dart pub global run pana

# 7. 배포
dart pub publish
```

---

## 11. Semantic Versioning

### 11.1 버전 전략

| 버전 변경 | 언제 사용 | 예시 |
|----------|----------|------|
| **MAJOR (X.0.0)** | Breaking changes | API 변경, 삭제 |
| **MINOR (0.X.0)** | 새 기능 추가 (하위 호환) | 새 메서드, 클래스 |
| **PATCH (0.0.X)** | 버그 수정 | 버그 패치, 문서 수정 |

### 11.2 Breaking Change 처리

```dart
// v1.0.0
class ApiClient {
  Future<User> getUser(String id) async {
    // 구현
  }
}

// v2.0.0 - Breaking change
class ApiClient {
  // ❌ 파라미터 변경 (Breaking)
  Future<User> getUser(String id, {required String token}) async {
    // 구현
  }
}

// ✅ 올바른 접근: Deprecation 경로 제공
// v1.5.0
class ApiClient {
  @Deprecated('Use getUserWithToken instead. Will be removed in v2.0.0')
  Future<User> getUser(String id) async {
    return getUserWithToken(id, token: '');
  }

  Future<User> getUserWithToken(String id, {String token = ''}) async {
    // 새 구현
  }
}

// v2.0.0
class ApiClient {
  // 이제 안전하게 제거 가능
  Future<User> getUserWithToken(String id, {String token = ''}) async {
    // 구현
  }
}
```

### 11.3 Migration Guide

```markdown
# Migration Guide: v1.x to v2.0

## Breaking Changes

### 1. ApiClient.getUser() signature changed

**Before (v1.x):**
```dart
final user = await apiClient.getUser('user-id');
```

**After (v2.0):**
```dart
final user = await apiClient.getUser('user-id', token: 'auth-token');
```

**Migration steps:**
1. Add token parameter to all `getUser()` calls
2. Update authentication flow to pass tokens
3. Run tests to verify behavior

### 2. Validators.isValidEmail() now stricter

**Impact:** May reject previously accepted emails with incorrect TLDs

**Action required:**
- Review email validation logic
- Update test cases if needed

## New Features

### CustomButton widget
```dart
CustomButton(
  text: 'Click Me',
  onPressed: () {},
  style: CustomButtonStyle.primary,
)
```

## Deprecations

The following APIs are deprecated and will be removed in v3.0:
- `StringUtils.oldMethod()` → use `StringUtils.newMethod()`
```

---

## 12. Mono-repo 패키지

### 12.1 Melos 설정

```yaml
# melos.yaml
name: my_packages
repository: https://github.com/username/my_packages

packages:
  - packages/**

command:
  bootstrap:
    usePubspecOverrides: true

scripts:
  analyze:
    run: dart analyze --fatal-infos
    description: Run static analysis on all packages

  test:
    run: flutter test --coverage
    description: Run tests for all packages

  format:
    run: dart format .
    description: Format all Dart files

  publish:
    run: dart pub publish
    description: Publish a package to pub.dev
    select-package:
      flutter: true
      published: false
```

### 12.2 프로젝트 구조

```
my_packages/
├── melos.yaml
├── packages/
│   ├── my_core/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   ├── my_ui/
│   │   ├── lib/
│   │   ├── test/
│   │   └── pubspec.yaml
│   └── my_data/
│       ├── lib/
│       ├── test/
│       └── pubspec.yaml
└── examples/
    └── demo_app/
```

### 12.3 내부 패키지 의존성

```yaml
# packages/my_ui/pubspec.yaml
name: my_ui
version: 0.1.0

dependencies:
  flutter:
    sdk: flutter
  my_core:
    path: ../my_core

# Melos를 사용하면 자동으로 path 의존성 관리
```

### 12.4 Melos 명령어

```bash
# Melos 설치
dart pub global activate melos

# 초기화 (모든 패키지 pub get)
melos bootstrap

# 모든 패키지 분석
melos run analyze

# 모든 패키지 테스트
melos run test

# 특정 패키지만 테스트
melos run test --scope=my_core

# 버전 업데이트
melos version

# 변경된 패키지만 배포
melos publish
```

---

## 13. 유지보수

### 13.1 이슈 템플릿

```markdown
<!-- .github/ISSUE_TEMPLATE/bug_report.md -->
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Code sample**
```dart
// Paste your code here
```

**Flutter doctor output**
```
Paste output of `flutter doctor -v` here
```

**Additional context**
Add any other context about the problem here.
```

### 13.2 PR 체크리스트

```markdown
<!-- .github/pull_request_template.md -->
## Description
<!-- Describe your changes in detail -->

## Type of change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Checklist
- [ ] I have run `dart format .`
- [ ] I have run `dart analyze` with no errors
- [ ] I have added tests that prove my fix/feature works
- [ ] All new and existing tests passed
- [ ] I have updated the documentation (if applicable)
- [ ] I have updated CHANGELOG.md
```

### 13.3 Deprecation 전략

```dart
// lib/src/deprecated_apis.dart

/// 3단계 Deprecation 전략

// 1단계: 경고 추가 (v1.5.0)
@Deprecated(
  'Use newMethod() instead. '
  'This feature was deprecated after v1.5.0 and will be removed in v2.0.0.',
)
void oldMethod() {
  // 기존 구현 유지
}

// 2단계: 제거 예정 명시 (v1.9.0)
@Deprecated(
  'SCHEDULED FOR REMOVAL in v2.0.0. '
  'Use newMethod() instead. '
  'See migration guide: https://pub.dev/packages/my_package/versions/2.0.0',
)
void oldMethod() {
  // 기존 구현 유지
}

// 3단계: 제거 (v2.0.0)
// oldMethod() 완전히 삭제
```

### 13.4 보안 패치

```yaml
# .github/workflows/security.yml
name: Security Scan

on:
  schedule:
    - cron: '0 0 * * 0'  # 매주 일요일
  workflow_dispatch:

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
```

---

## 14. Best Practices

### 14.1 Do & Don't

| ✅ DO | ❌ DON'T |
|------|---------|
| 명확하고 일관된 네이밍 사용 | 약어나 모호한 이름 사용 |
| Sound null safety 적용 | `dynamic` 남발 |
| API 문서 작성 (dartdoc) | 주석 없이 배포 |
| 예제 앱 제공 | README만으로 설명 |
| Semantic versioning 준수 | 임의의 버전 변경 |
| Breaking changes에 deprecation 경로 제공 | 갑작스러운 API 변경 |
| 테스트 커버리지 80% 이상 | 테스트 없이 배포 |
| CI/CD 자동화 | 수동 배포 |
| LICENSE 명시 | 라이선스 없이 배포 |
| CHANGELOG 유지 | 변경사항 기록 안 함 |

### 14.2 API 설계 원칙

```dart
// ✅ 명확한 네이밍
class UserRepository {
  Future<User> fetchUserById(String id);
  Future<List<User>> fetchAllUsers();
  Future<void> deleteUser(String id);
}

// ❌ 모호한 네이밍
class UserRepo {
  Future<User> get(String id);  // get이 뭘 가져오는지 불명확
  Future<List<User>> all();     // all이 무엇인지 불명확
  Future<void> remove(String id);  // remove vs delete 혼용
}

// ✅ 일관된 파라미터 순서
void createUser({
  required String name,
  required String email,
  String? phoneNumber,
});

// ❌ 비일관적 파라미터
void createUser(String name, {required String email});
void updateUser({required String email}, String name);  // 순서 다름

// ✅ 명시적 예외 처리
class UserNotFoundException implements Exception {
  final String userId;
  UserNotFoundException(this.userId);

  @override
  String toString() => 'User not found: $userId';
}

// ❌ 제네릭 예외
throw Exception('Something went wrong');
```

### 14.3 성능 최적화

```dart
// ✅ const 생성자 사용
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.timeout,
  });

  final String apiUrl;
  final Duration timeout;
}

// ✅ Lazy 초기화
class ExpensiveService {
  static ExpensiveService? _instance;

  static ExpensiveService get instance {
    return _instance ??= ExpensiveService._internal();
  }

  ExpensiveService._internal();
}

// ✅ Stream 메모리 누수 방지
class DataService {
  StreamSubscription? _subscription;

  void startListening() {
    _subscription = dataStream.listen((data) {
      // 처리
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
```

### 14.4 테스트 전략

```dart
// ✅ 테스트 구조화
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      authService = AuthService(httpClient: mockHttpClient);
    });

    tearDown(() {
      // 정리
    });

    group('login', () {
      test('success case', () async {
        // Arrange
        when(mockHttpClient.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockUserResponse);

        // Act
        final user = await authService.login(email: 'test@example.com', password: 'password');

        // Assert
        expect(user.email, equals('test@example.com'));
      });

      test('failure case - invalid credentials', () {
        // ...
      });

      test('failure case - network error', () {
        // ...
      });
    });
  });
}
```

### 14.5 문서화 원칙

```dart
/// [User] 객체를 생성하고 저장소에 저장합니다.
///
/// 이 메서드는 다음 단계를 수행합니다:
/// 1. 입력 값 검증
/// 2. 비밀번호 해싱
/// 3. 데이터베이스에 저장
/// 4. 확인 이메일 전송
///
/// **예시:**
/// ```dart
/// final user = await userService.createUser(
///   name: 'John Doe',
///   email: 'john@example.com',
///   password: 'SecurePass123!',
/// );
/// print('User created with ID: ${user.id}');
/// ```
///
/// **파라미터:**
/// - [name]: 사용자 이름 (2-50자)
/// - [email]: 유효한 이메일 주소
/// - [password]: 최소 8자, 영문+숫자+특수문자 포함
///
/// **반환값:**
/// 생성된 [User] 객체 (ID 포함)
///
/// **예외:**
/// - [ValidationException]: 입력 값이 유효하지 않은 경우
/// - [DuplicateEmailException]: 이메일이 이미 존재하는 경우
/// - [DatabaseException]: 데이터베이스 저장 실패
///
/// **참고:**
/// - [updateUser] - 사용자 정보 업데이트
/// - [deleteUser] - 사용자 삭제
Future<User> createUser({
  required String name,
  required String email,
  required String password,
}) async {
  // 구현
  throw UnimplementedError();
}
```

---

## 참고 자료

- [Dart Package 개발 가이드](https://dart.dev/guides/libraries/create-packages)
- [Flutter Plugin 개발](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [Pub.dev Publishing](https://dart.dev/tools/pub/publishing)
- [Semantic Versioning](https://semver.org/)
- [Melos Documentation](https://melos.invertase.dev/)
- [Effective Dart](https://dart.dev/effective-dart)

---

## 실습 과제

### 과제 1: Dart 유틸리티 패키지 개발
자주 사용하는 유틸리티 함수(날짜 포맷, 문자열 검증 등)를 Dart 패키지로 만들고, example 프로젝트와 테스트를 작성하세요.

### 과제 2: Flutter Plugin 개발
Platform Channel을 사용하여 네이티브 배터리 정보를 가져오는 Flutter Plugin을 만들고 Pub.dev에 배포하세요.

## Self-Check

- [ ] pubspec.yaml의 필수 필드(name, version, description, homepage)를 올바르게 설정할 수 있는가?
- [ ] dart doc으로 API 문서를 생성할 수 있는가?
- [ ] Semantic Versioning 규칙(MAJOR.MINOR.PATCH)을 이해하고 적용하는가?
- [ ] pana 점수를 확인하고 Pub.dev 배포 기준을 충족할 수 있는가?
