# Flutter 고급 보안 가이드 (시니어)

> **대상**: 10년차+ 시니어 개발자 | Flutter 3.27+ | OWASP MASVS Level 2 준수

## 개요

이 가이드는 Flutter 앱의 엔터프라이즈급 보안을 구현하기 위한 고급 기법을 다룹니다. 코드 난독화, Root/Jailbreak 감지, RASP, Certificate Pinning, Secure Enclave, 앱 위변조 감지, 네트워크 보안, OWASP MASVS 준수 등 실무에서 요구되는 보안 요구사항을 충족하는 방법을 제시합니다.

### OWASP MASVS (Mobile Application Security Verification Standard)

| 레벨 | 설명 | 적용 대상 |
|------|------|----------|
| **L1** | 기본 보안 (표준 라이브러리 사용) | 모든 앱 |
| **L2** | 심화 보안 (난독화, 루트 감지) | 금융, 헬스케어 |
| **L3** | 최고 수준 (RASP, 하드웨어 보안) | 은행, 결제 앱 |

### 보안 위협 모델링

```
┌─────────────────────────────────────────────────────────────┐
│ 위협 계층                                                     │
├─────────────────────────────────────────────────────────────┤
│ 1. 네트워크 계층                                              │
│    - MITM (중간자 공격)                                       │
│    - SSL Stripping                                           │
│    - Certificate Spoofing                                    │
│                                                              │
│ 2. 앱 계층                                                   │
│    - 코드 역공학 (Reverse Engineering)                        │
│    - 재패키징 (Repackaging)                                  │
│    - 동적 분석 (Dynamic Analysis)                            │
│                                                              │
│ 3. 데이터 계층                                               │
│    - 로컬 저장소 접근                                         │
│    - 메모리 덤프                                              │
│    - 백업 파일 노출                                           │
│                                                              │
│ 4. 플랫폼 계층                                               │
│    - Root/Jailbreak                                          │
│    - 디버거 연결                                              │
│    - 스크린샷/화면 녹화                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. 코드 난독화 (Obfuscation)

### 1.1 Dart 코드 난독화

```bash
# Release 빌드 시 자동 난독화
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols

flutter build ios --obfuscate --split-debug-info=build/ios/outputs/symbols
```

**난독화 효과:**
```dart
// 원본 코드
class UserService {
  Future<User> getUserById(String userId) async {
    final response = await api.get('/users/$userId');
    return User.fromJson(response.data);
  }
}

// 난독화 후 (디컴파일 결과)
class a {
  Future<b> c(String d) async {
    final e = await f.g('/h/$d');
    return b.i(e.j);
  }
}
```

### 1.2 ProGuard (Android)

```groovy
# android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

**ProGuard 규칙:**

```proguard
# android/app/proguard-rules.pro

# Flutter 필수 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart 네이티브 호출 보존
-keep class **.Dart* { *; }
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodChannel.MethodCallHandler *;
}

# Gson (JSON 직렬화)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 모델 클래스 보존 (필요 시)
-keep class com.myapp.models.** { *; }

# 난독화 최적화
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# 크래시 리포트를 위한 라인 번호 보존
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

### 1.3 R8 (Android Gradle Plugin 3.4.0+)

R8은 ProGuard의 개선 버전으로 자동 활성화됩니다.

```groovy
# android/gradle.properties
android.enableR8=true
android.enableR8.fullMode=true
```

### 1.4 String 암호화

민감한 문자열은 하드코딩하지 않고 암호화합니다.

```dart
// lib/core/security/string_obfuscator.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class StringObfuscator {
  // XOR 기반 간단한 난독화 (컴파일 타임)
  static String encode(String value) {
    final key = 0x5A; // 난독화 키
    final encoded = value.codeUnits.map((c) => c ^ key).toList();
    return base64Encode(encoded);
  }

  static String decode(String encoded) {
    final key = 0x5A;
    final decoded = base64Decode(encoded).map((c) => c ^ key).toList();
    return String.fromCharCodes(decoded);
  }
}

// 사용 예제
class ApiConfig {
  // ❌ 하드코딩 (위험)
  // static const apiKey = 'sk_live_1234567890abcdef';

  // ✅ 난독화
  static const _obfuscatedApiKey = 'BgcEBwQHBAc='; // encode() 결과

  static String get apiKey => StringObfuscator.decode(_obfuscatedApiKey);
}
```

---

## 2. Root/Jailbreak 감지

### 2.1 의존성 설치

```yaml
# pubspec.yaml
dependencies:
  flutter_jailbreak_detection: ^1.10.0
  safe_device: ^2.0.0  # 추가 보안 검사
```

### 2.2 기본 감지

```dart
// lib/core/security/device_security_checker.dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:safe_device/safe_device.dart';

class DeviceSecurityChecker {
  /// Root/Jailbreak 여부 확인
  static Future<DeviceSecurityStatus> check() async {
    final isJailBroken = await FlutterJailbreakDetection.jailbroken;
    final isDeveloperMode = await FlutterJailbreakDetection.developerMode;

    // safe_device로 추가 검증
    final isRealDevice = await SafeDevice.isRealDevice;
    final isSafeDevice = await SafeDevice.isSafeDevice;
    final canMockLocation = await SafeDevice.canMockLocation;

    return DeviceSecurityStatus(
      isJailBroken: isJailBroken,
      isDeveloperMode: isDeveloperMode,
      isRealDevice: isRealDevice,
      isSafeDevice: isSafeDevice,
      canMockLocation: canMockLocation,
    );
  }

  /// 보안 위험 여부
  static Future<bool> isSecure() async {
    final status = await check();
    return !status.isJailBroken &&
           !status.isDeveloperMode &&
           status.isRealDevice &&
           status.isSafeDevice &&
           !status.canMockLocation;
  }
}

class DeviceSecurityStatus {
  const DeviceSecurityStatus({
    required this.isJailBroken,
    required this.isDeveloperMode,
    required this.isRealDevice,
    required this.isSafeDevice,
    required this.canMockLocation,
  });

  final bool isJailBroken;
  final bool isDeveloperMode;
  final bool isRealDevice;
  final bool isSafeDevice;
  final bool canMockLocation;

  bool get hasSecurityRisk =>
      isJailBroken || isDeveloperMode || !isRealDevice || !isSafeDevice || canMockLocation;
}
```

### 2.3 고급 Root 감지 (Native 통합)

**Android:**

```kotlin
// android/app/src/main/kotlin/com/example/myapp/RootDetector.kt
package com.example.myapp

import android.content.Context
import java.io.File

object RootDetector {
    private val knownRootFiles = listOf(
        "/system/app/Superuser.apk",
        "/system/xbin/su",
        "/system/bin/su",
        "/sbin/su",
        "/system/su",
        "/system/bin/.ext/.su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/su",
        "/su/bin/su"
    )

    private val knownRootPackages = listOf(
        "com.noshufou.android.su",
        "com.thirdparty.superuser",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.zachspong.temprootremovejb",
        "com.ramdroid.appquarantine",
        "com.topjohnwu.magisk"
    )

    fun isRooted(context: Context): Boolean {
        return checkRootFiles() ||
               checkRootPackages(context) ||
               checkSuCommand() ||
               checkRWPaths()
    }

    private fun checkRootFiles(): Boolean {
        return knownRootFiles.any { File(it).exists() }
    }

    private fun checkRootPackages(context: Context): Boolean {
        val pm = context.packageManager
        return knownRootPackages.any { packageName ->
            try {
                pm.getPackageInfo(packageName, 0)
                true
            } catch (e: Exception) {
                false
            }
        }
    }

    private fun checkSuCommand(): Boolean {
        return try {
            Runtime.getRuntime().exec("which su")
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun checkRWPaths(): Boolean {
        val paths = arrayOf("/system", "/system/bin", "/system/sbin", "/system/xbin", "/vendor/bin", "/sbin", "/etc")
        return paths.any { path ->
            val file = File(path)
            file.exists() && file.canWrite()
        }
    }
}
```

**iOS:**

```swift
// ios/Runner/JailbreakDetector.swift
import Foundation
import UIKit

class JailbreakDetector {
    static func isJailbroken() -> Bool {
        return checkSuspiciousFiles() ||
               checkSuspiciousApps() ||
               checkWriteAccess() ||
               checkCydiaURL() ||
               checkFork()
    }

    private static func checkSuspiciousFiles() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/tmp/cydia.log",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"
        ]

        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private static func checkSuspiciousApps() -> Bool {
        let schemes = ["cydia://", "sileo://", "zbra://", "filza://"]
        return schemes.contains { UIApplication.shared.canOpenURL(URL(string: $0)!) }
    }

    private static func checkWriteAccess() -> Bool {
        let testPath = "/private/jailbreak.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private static func checkCydiaURL() -> Bool {
        return UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!)
    }

    private static func checkFork() -> Bool {
        let result = fork()
        if result >= 0 {
            if result > 0 {
                kill(result, SIGKILL)
            }
            return true
        }
        return false
    }
}
```

### 2.4 보안 위반 시 대응

```dart
// lib/core/security/security_policy.dart
enum SecurityAction {
  allow,          // 허용 (경고만)
  restrictFeatures, // 민감한 기능 제한
  block,          // 앱 차단
  reportAndBlock, // 서버 리포트 후 차단
}

class SecurityPolicy {
  static SecurityAction getAction(DeviceSecurityStatus status) {
    if (status.isJailBroken) {
      return SecurityAction.block; // 루팅/탈옥 시 무조건 차단
    }

    if (status.isDeveloperMode) {
      return SecurityAction.restrictFeatures; // 개발자 모드 시 기능 제한
    }

    if (!status.isRealDevice) {
      return SecurityAction.allow; // 에뮬레이터는 개발용으로 허용
    }

    if (status.canMockLocation) {
      return SecurityAction.restrictFeatures; // 위치 위조 가능 시 위치 기반 기능 제한
    }

    return SecurityAction.allow;
  }

  static Future<void> enforce(DeviceSecurityStatus status) async {
    final action = getAction(status);

    switch (action) {
      case SecurityAction.allow:
        // 정상 진행
        break;

      case SecurityAction.restrictFeatures:
        // 민감한 기능 비활성화
        FeatureFlags.disablePayment = true;
        FeatureFlags.disableLocationServices = true;
        _showWarningDialog('일부 기능이 제한됩니다.');
        break;

      case SecurityAction.block:
        _showBlockDialog('보안상의 이유로 이 기기에서는 앱을 사용할 수 없습니다.');
        exit(0);

      case SecurityAction.reportAndBlock:
        await _reportToServer(status);
        _showBlockDialog('보안 위반이 감지되었습니다.');
        exit(0);
    }
  }

  static Future<void> _reportToServer(DeviceSecurityStatus status) async {
    // 서버에 보안 위반 리포트
    await api.post('/security/report', {
      'deviceInfo': await DeviceInfo.collect(),
      'securityStatus': status.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

---

## 3. RASP (Runtime Application Self-Protection)

RASP는 런타임에 앱을 보호하는 기술입니다.

### 3.1 디버거 감지

```dart
// lib/core/security/debugger_detector.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class DebuggerDetector {
  static bool isDebuggerAttached() {
    // Flutter Debug 모드 확인
    if (kDebugMode) {
      return true;
    }

    // Android: TracerPid 확인
    if (Platform.isAndroid) {
      return _checkAndroidDebugger();
    }

    // iOS: sysctl 확인
    if (Platform.isIOS) {
      return _checkIOSDebugger();
    }

    return false;
  }

  static bool _checkAndroidDebugger() {
    try {
      final status = File('/proc/self/status').readAsStringSync();
      final tracerPid = RegExp(r'TracerPid:\s+(\d+)').firstMatch(status);
      if (tracerPid != null) {
        final pid = int.parse(tracerPid.group(1)!);
        return pid != 0; // TracerPid가 0이 아니면 디버거 연결
      }
    } catch (e) {
      // 파일 읽기 실패 시 의심
      return true;
    }
    return false;
  }

  static bool _checkIOSDebugger() {
    // Native 코드 필요 (Method Channel)
    return false;
  }

  /// 주기적 디버거 감지
  static void startMonitoring({
    Duration interval = const Duration(seconds: 5),
    VoidCallback? onDebuggerDetected,
  }) {
    Timer.periodic(interval, (timer) {
      if (isDebuggerAttached()) {
        timer.cancel();
        onDebuggerDetected?.call();
      }
    });
  }
}
```

### 3.2 코드 무결성 검증

```dart
// lib/core/security/integrity_checker.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

class IntegrityChecker {
  // 빌드 타임에 계산된 해시 (난독화된 형태로 저장)
  static const _expectedHash = 'abc123...'; // 실제로는 긴 해시

  /// APK/IPA 서명 확인
  static Future<bool> verifySignature() async {
    if (Platform.isAndroid) {
      return _verifyAndroidSignature();
    } else if (Platform.isIOS) {
      return _verifyIOSSignature();
    }
    return false;
  }

  static Future<bool> _verifyAndroidSignature() async {
    // Method Channel로 Native 코드 호출
    try {
      final result = await platform.invokeMethod('verifySignature');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _verifyIOSSignature() async {
    // iOS 서명 확인 (Native)
    try {
      final result = await platform.invokeMethod('verifyCodeSignature');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 중요 파일 체크섬 검증
  static Future<bool> verifyFileIntegrity(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();

      // 예상 해시와 비교
      return hash == _getExpectedHash(filePath);
    } catch (e) {
      return false;
    }
  }

  static String _getExpectedHash(String filePath) {
    // 파일별 예상 해시 (빌드 타임에 생성)
    final hashes = {
      'lib/core/api/api_client.dart': 'hash1...',
      'lib/core/security/crypto_service.dart': 'hash2...',
    };
    return hashes[filePath] ?? '';
  }
}
```

**Android Native (Kotlin):**

```kotlin
// android/app/src/main/kotlin/com/example/myapp/IntegrityChecker.kt
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import java.security.MessageDigest

object IntegrityChecker {
    // 빌드 타임에 계산된 예상 서명 해시
    private const val EXPECTED_SIGNATURE = "ABC123..." // 실제 서명 해시

    fun verifySignature(context: Context): Boolean {
        try {
            val packageInfo = context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_SIGNATURES
            )

            val signatures: Array<Signature> = packageInfo.signatures
            val signature = signatures[0]

            val md = MessageDigest.getInstance("SHA-256")
            md.update(signature.toByteArray())
            val currentSignature = md.digest().joinToString("") { "%02x".format(it) }

            return currentSignature == EXPECTED_SIGNATURE
        } catch (e: Exception) {
            return false
        }
    }
}
```

### 3.3 메모리 덤프 방지

```dart
// lib/core/security/anti_tampering.dart
import 'package:flutter/services.dart';

class AntiTampering {
  static const platform = MethodChannel('com.example.app/security');

  /// 스크린샷 방지
  static Future<void> preventScreenshot() async {
    if (Platform.isAndroid) {
      await platform.invokeMethod('setSecureFlag');
    }
    // iOS는 별도 처리 필요 (화면 캡처 감지)
  }

  /// 화면 녹화 감지 (iOS)
  static Future<bool> isScreenRecording() async {
    if (Platform.isIOS) {
      return await platform.invokeMethod('isScreenBeingCaptured') ?? false;
    }
    return false;
  }
}
```

**Android:**

```kotlin
// android/app/src/main/kotlin/com/example/myapp/MainActivity.kt
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureFlag" -> {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

---

## 4. Certificate Pinning 심화

### 4.1 동적 핀 업데이트

```dart
// lib/core/security/certificate_pinning_manager.dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';

class CertificatePinningManager {
  static final Map<String, List<String>> _pinnedCertificates = {};
  static DateTime? _lastUpdate;

  /// 서버에서 최신 인증서 핀 가져오기
  static Future<void> updatePins() async {
    try {
      // 안전한 채널로 핀 목록 가져오기 (자체 서명된 요청)
      final response = await _secureClient.get('/api/security/pins');

      final pins = Map<String, List<String>>.from(response.data['pins']);
      _pinnedCertificates.addAll(pins);
      _lastUpdate = DateTime.now();

      // 로컬에 캐시
      await _savePinsToLocal(pins);
    } catch (e) {
      // 실패 시 로컬 캐시 사용
      await _loadPinsFromLocal();
    }
  }

  /// Certificate Pinning이 적용된 Dio 클라이언트 생성
  static Dio createSecureClient(String baseUrl) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();

      client.badCertificateCallback = (cert, host, port) {
        // 핀 검증
        final pins = _pinnedCertificates[host] ?? [];
        if (pins.isEmpty) {
          return false; // 핀이 없으면 거부
        }

        // SHA-256 해시 계산
        final certHash = sha256.convert(cert.der).toString();
        return pins.contains(certHash);
      };

      return client;
    };

    return dio;
  }

  /// 핀 만료 확인
  static bool isPinsExpired() {
    if (_lastUpdate == null) return true;

    final daysSinceUpdate = DateTime.now().difference(_lastUpdate!).inDays;
    return daysSinceUpdate > 7; // 7일마다 갱신
  }

  static Future<void> _savePinsToLocal(Map<String, List<String>> pins) async {
    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(
      key: 'certificate_pins',
      value: jsonEncode(pins),
    );
  }

  static Future<void> _loadPinsFromLocal() async {
    final secureStorage = FlutterSecureStorage();
    final stored = await secureStorage.read(key: 'certificate_pins');
    if (stored != null) {
      _pinnedCertificates.addAll(
        Map<String, List<String>>.from(jsonDecode(stored)),
      );
    }
  }
}
```

### 4.2 다중 핀 전략 (Backup Pins)

```dart
// lib/core/security/multi_pin_strategy.dart
class MultiPinStrategy {
  // 현재 인증서 핀
  static const primaryPins = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  // 백업 인증서 핀 (인증서 갱신 대비)
  static const backupPins = [
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  /// 핀 검증 (primary 또는 backup)
  static bool verify(String certHash) {
    return primaryPins.contains(certHash) || backupPins.contains(certHash);
  }

  /// 핀 회전 (rotation)
  static Future<void> rotatePins() async {
    // 새 인증서로 전환
    // 1. 서버에서 새 핀 가져오기
    // 2. backupPins를 primaryPins로 승격
    // 3. 새 백업 핀 설정
  }
}
```

---

## 5. Secure Enclave / Android Keystore 활용

### 5.1 하드웨어 지원 암호화

```dart
// lib/core/security/hardware_security.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HardwareSecurityManager {
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Android Keystore 사용 (하드웨어 지원)
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // Secure Enclave 사용 (가능한 경우)
    ),
  );

  /// 민감한 데이터 저장 (하드웨어 암호화)
  static Future<void> storeSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// 민감한 데이터 읽기
  static Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }

  /// Biometric 인증과 함께 사용
  static Future<void> storeWithBiometric(String key, String value) async {
    // iOS: Secure Enclave + Face ID/Touch ID
    // Android: Keystore + Fingerprint/Face Unlock
    await _storage.write(
      key: key,
      value: value,
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.when_passcode_set_this_device_only,
      ),
    );
  }
}
```

### 5.2 Android Keystore 직접 사용

```kotlin
// android/app/src/main/kotlin/com/example/myapp/KeystoreManager.kt
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

object KeystoreManager {
    private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
    private const val KEY_ALIAS = "MyAppSecureKey"

    fun generateKey() {
        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            KEYSTORE_PROVIDER
        )

        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true) // Biometric 필요
            .setUserAuthenticationValidityDurationSeconds(30)
            .build()

        keyGenerator.init(spec)
        keyGenerator.generateKey()
    }

    fun encrypt(plaintext: ByteArray): Pair<ByteArray, ByteArray> {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        val secretKey = keyStore.getKey(KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)

        val iv = cipher.iv
        val ciphertext = cipher.doFinal(plaintext)

        return Pair(ciphertext, iv)
    }

    fun decrypt(ciphertext: ByteArray, iv: ByteArray): ByteArray {
        val keyStore = KeyStore.getInstance(KEYSTORE_PROVIDER).apply { load(null) }
        val secretKey = keyStore.getKey(KEY_ALIAS, null) as SecretKey

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(128, iv))

        return cipher.doFinal(ciphertext)
    }
}
```

---

## 6. 앱 위변조 감지

### 6.1 패키지 무결성 확인

```dart
// lib/core/security/package_integrity.dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PackageIntegrityChecker {
  // 빌드 타임에 설정된 예상 값
  static const _expectedPackageName = 'com.example.myapp';
  static const _expectedVersionCode = 123;
  static const _expectedSignature = 'ABC123...';

  /// 패키지 정보 검증
  static Future<bool> verify() async {
    final packageInfo = await PackageInfo.fromPlatform();

    // 패키지명 확인
    if (packageInfo.packageName != _expectedPackageName) {
      await _reportTampering('Package name mismatch');
      return false;
    }

    // 버전 코드 확인
    final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;
    if (versionCode < _expectedVersionCode) {
      await _reportTampering('Version downgrade detected');
      return false;
    }

    // 서명 확인 (Native)
    final isSignatureValid = await IntegrityChecker.verifySignature();
    if (!isSignatureValid) {
      await _reportTampering('Invalid signature');
      return false;
    }

    return true;
  }

  /// 설치 경로 확인 (Android)
  static Future<bool> verifyInstallSource() async {
    if (!Platform.isAndroid) return true;

    try {
      final result = await platform.invokeMethod('getInstallerPackageName');
      final installer = result as String?;

      // Google Play에서만 설치 허용
      final allowedInstallers = [
        'com.android.vending', // Google Play
        'com.google.android.feedback', // Google Play (debug)
      ];

      return installer != null && allowedInstallers.contains(installer);
    } catch (e) {
      return false;
    }
  }

  static Future<void> _reportTampering(String reason) async {
    await api.post('/security/tampering', {
      'reason': reason,
      'deviceInfo': await DeviceInfo.collect(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
```

### 6.2 런타임 코드 체크섬

```dart
// lib/core/security/runtime_integrity.dart
class RuntimeIntegrityChecker {
  /// 중요 함수의 체크섬 검증
  static bool verifyFunctionIntegrity() {
    // 중요 함수의 바이트코드 해시 검증
    final functions = [
      _hashFunction(_criticalFunction1),
      _hashFunction(_criticalFunction2),
    ];

    final expectedHashes = [
      'hash1...',
      'hash2...',
    ];

    for (int i = 0; i < functions.length; i++) {
      if (functions[i] != expectedHashes[i]) {
        return false;
      }
    }

    return true;
  }

  static String _hashFunction(Function fn) {
    // 함수 바이트코드 해시 계산 (Native 지원 필요)
    // 실제 구현은 플랫폼별로 다름
    return '';
  }

  static void _criticalFunction1() {
    // 결제 로직 등 중요한 함수
  }

  static void _criticalFunction2() {
    // 인증 로직 등 중요한 함수
  }
}
```

---

## 7. 네트워크 보안

### 7.1 mTLS (Mutual TLS)

```dart
// lib/core/network/mtls_client.dart
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class MTLSClient {
  static Future<Dio> create(String baseUrl) async {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    // 클라이언트 인증서 로드
    final certBytes = await rootBundle.load('assets/certs/client-cert.pem');
    final keyBytes = await rootBundle.load('assets/certs/client-key.pem');

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient(
        context: SecurityContext()
          ..useCertificateChainBytes(certBytes.buffer.asUint8List())
          ..usePrivateKeyBytes(keyBytes.buffer.asUint8List()),
      );

      return client;
    };

    return dio;
  }
}
```

### 7.2 API Key Rotation

```dart
// lib/core/security/api_key_manager.dart
class ApiKeyManager {
  static String? _currentApiKey;
  static DateTime? _keyExpiry;

  /// API 키 가져오기 (자동 회전)
  static Future<String> getApiKey() async {
    if (_currentApiKey == null || _isKeyExpired()) {
      await _rotateKey();
    }
    return _currentApiKey!;
  }

  static bool _isKeyExpired() {
    if (_keyExpiry == null) return true;
    return DateTime.now().isAfter(_keyExpiry!);
  }

  static Future<void> _rotateKey() async {
    // 서버에서 새 API 키 요청
    final response = await _authClient.post('/api/keys/rotate', {
      'deviceId': await DeviceInfo.getDeviceId(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    _currentApiKey = response.data['apiKey'];
    _keyExpiry = DateTime.parse(response.data['expiresAt']);

    // 로컬에 암호화 저장
    await HardwareSecurityManager.storeSecure('api_key', _currentApiKey!);
    await HardwareSecurityManager.storeSecure('key_expiry', _keyExpiry!.toIso8601String());
  }

  /// 앱 시작 시 키 복원
  static Future<void> restore() async {
    _currentApiKey = await HardwareSecurityManager.readSecure('api_key');
    final expiryStr = await HardwareSecurityManager.readSecure('key_expiry');
    if (expiryStr != null) {
      _keyExpiry = DateTime.parse(expiryStr);
    }
  }
}
```

### 7.3 Request Signing

```dart
// lib/core/network/request_signer.dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RequestSigner {
  static const _secret = 'YOUR_SECRET_KEY'; // 난독화 필요

  /// HMAC-SHA256 서명 생성
  static String sign(String method, String path, Map<String, dynamic>? body) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final bodyStr = body != null ? jsonEncode(body) : '';

    final message = '$method|$path|$timestamp|$bodyStr';
    final hmac = Hmac(sha256, utf8.encode(_secret));
    final digest = hmac.convert(utf8.encode(message));

    return '$digest|$timestamp';
  }

  /// Dio Interceptor로 자동 서명
  static InterceptorsWrapper createInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final signature = sign(
          options.method,
          options.path,
          options.data,
        );

        options.headers['X-Signature'] = signature;
        handler.next(options);
      },
    );
  }
}
```

---

## 8. Biometric 인증 심화

### 8.1 서버 검증과 결합

```dart
// lib/core/auth/biometric_auth_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Biometric 인증 + 서버 검증
  static Future<AuthResult> authenticate() async {
    // 1단계: 로컬 Biometric 인증
    final localAuth = await _authenticateLocally();
    if (!localAuth.success) {
      return AuthResult.failure('Local authentication failed');
    }

    // 2단계: 서버에 챌린지 요청
    final challenge = await _requestChallenge();

    // 3단계: 챌린지에 서명
    final signature = await _signChallenge(challenge);

    // 4단계: 서버 검증
    final serverAuth = await _verifyWithServer(challenge, signature);

    return serverAuth;
  }

  static Future<LocalAuthResult> _authenticateLocally() async {
    try {
      final canAuthenticate = await _auth.canCheckBiometrics &&
                              await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return LocalAuthResult.failure('Biometric not available');
      }

      final authenticated = await _auth.authenticate(
        localizedReason: '본인 확인이 필요합니다',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric 인증',
            cancelButton: '취소',
          ),
          IOSAuthMessages(
            cancelButton: '취소',
          ),
        ],
      );

      return authenticated
          ? LocalAuthResult.success()
          : LocalAuthResult.failure('Authentication failed');
    } catch (e) {
      return LocalAuthResult.failure(e.toString());
    }
  }

  static Future<String> _requestChallenge() async {
    final response = await api.post('/auth/biometric/challenge', {
      'deviceId': await DeviceInfo.getDeviceId(),
    });
    return response.data['challenge'];
  }

  static Future<String> _signChallenge(String challenge) async {
    // 하드웨어 키로 챌린지 서명
    final signature = await HardwareSecurityManager.sign(challenge);
    return signature;
  }

  static Future<AuthResult> _verifyWithServer(String challenge, String signature) async {
    final response = await api.post('/auth/biometric/verify', {
      'challenge': challenge,
      'signature': signature,
      'deviceId': await DeviceInfo.getDeviceId(),
    });

    if (response.data['verified'] == true) {
      return AuthResult.success(response.data['token']);
    } else {
      return AuthResult.failure('Server verification failed');
    }
  }
}

class LocalAuthResult {
  final bool success;
  final String? error;

  LocalAuthResult.success() : success = true, error = null;
  LocalAuthResult.failure(this.error) : success = false;
}

class AuthResult {
  final bool success;
  final String? token;
  final String? error;

  AuthResult.success(this.token) : success = true, error = null;
  AuthResult.failure(this.error) : success = false, token = null;
}
```

---

## 9. 데이터 암호화 전략

### 9.1 AES-256 암호화

```dart
// lib/core/security/encryption_service.dart
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  static final _key = encrypt.Key.fromSecureRandom(32); // 256-bit
  static final _iv = encrypt.IV.fromSecureRandom(16);   // 128-bit

  /// AES-256-GCM 암호화
  static String encryptAES(String plaintext) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: _iv);
    return encrypted.base64;
  }

  /// AES-256-GCM 복호화
  static String decryptAES(String ciphertext) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.gcm),
    );

    final decrypted = encrypter.decrypt64(ciphertext, iv: _iv);
    return decrypted;
  }

  /// 키 생성 (PBKDF2)
  static encrypt.Key deriveKey(String password, String salt) {
    final codec = Utf8Codec();
    final key = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 10000,
      bits: 256,
    ).deriveKey(
      secretKey: SecretKey(codec.encode(password)),
      nonce: codec.encode(salt),
    );

    return encrypt.Key(key.extractBytes());
  }
}
```

### 9.2 RSA 암호화 (하이브리드)

```dart
// lib/core/security/rsa_encryption.dart
import 'package:pointycastle/export.dart';
import 'dart:typed_data';
import 'dart:math';

class RSAEncryption {
  late AsymmetricKeyPair<PublicKey, PrivateKey> _keyPair;

  /// RSA 키 생성
  void generateKeyPair() {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
          SecureRandom('Fortuna')..seed(
              KeyParameter(
                Uint8List.fromList(
                  List.generate(32, (_) => Random.secure().nextInt(256)),
                ),
              ),
            ),
        ),
      );

    _keyPair = keyGen.generateKeyPair();
  }

  /// RSA 암호화 (공개키)
  Uint8List encrypt(Uint8List plaintext, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    return encryptor.process(plaintext);
  }

  /// RSA 복호화 (개인키)
  Uint8List decrypt(Uint8List ciphertext, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    return decryptor.process(ciphertext);
  }

  /// 하이브리드 암호화 (RSA + AES)
  /// 대용량 데이터를 AES로 암호화하고, AES 키를 RSA로 암호화
  Map<String, String> hybridEncrypt(String plaintext, RSAPublicKey publicKey) {
    // AES 키 생성
    final aesKey = encrypt.Key.fromSecureRandom(32);
    final aesIV = encrypt.IV.fromSecureRandom(16);

    // AES로 데이터 암호화
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encryptedData = encrypter.encrypt(plaintext, iv: aesIV);

    // RSA로 AES 키 암호화
    final encryptedKey = encrypt(aesKey.bytes, publicKey);
    final encryptedIV = encrypt(aesIV.bytes, publicKey);

    return {
      'data': encryptedData.base64,
      'key': base64Encode(encryptedKey),
      'iv': base64Encode(encryptedIV),
    };
  }
}
```

---

## 10. 보안 체크리스트

### 프로덕션 릴리스 전 필수 확인

#### 코드 보안
- [ ] 모든 민감한 정보는 난독화/암호화
- [ ] API Key는 환경 변수 또는 서버에서 동적 로드
- [ ] Dart 코드 난독화 활성화 (`--obfuscate`)
- [ ] ProGuard/R8 설정 (Android)
- [ ] 디버그 로그 제거 (`kDebugMode` 체크)

#### 네트워크 보안
- [ ] HTTPS 강제 (cleartext traffic 차단)
- [ ] Certificate Pinning 적용
- [ ] Request Signing 구현
- [ ] API Key Rotation 전략
- [ ] Timeout 설정 (DoS 방지)

#### 데이터 보안
- [ ] 민감한 데이터는 flutter_secure_storage 사용
- [ ] 하드웨어 지원 암호화 (Keystore/Keychain)
- [ ] 데이터베이스 암호화 (SQLCipher)
- [ ] 백업 파일 암호화/제외
- [ ] 메모리에 평문 저장 최소화

#### 플랫폼 보안
- [ ] Root/Jailbreak 감지
- [ ] 디버거 연결 감지
- [ ] 스크린샷 방지 (민감 화면)
- [ ] 앱 서명 검증
- [ ] 설치 경로 검증

#### 인증/인가
- [ ] Biometric 인증 + 서버 검증
- [ ] 토큰 만료 처리
- [ ] 리프레시 토큰 전략
- [ ] 세션 타임아웃
- [ ] 다중 기기 로그인 제한

---

## 결론

엔터프라이즈급 모바일 앱 보안은 **다층 방어 전략**이 필수입니다.

**보안 성숙도 로드맵:**

```
Level 1 (기본): HTTPS + 데이터 암호화
Level 2 (표준): + 코드 난독화 + Root 감지
Level 3 (고급): + Certificate Pinning + RASP
Level 4 (엔터프라이즈): + mTLS + 하드웨어 보안 + 위변조 감지
```

**OWASP MASVS Level 2 달성 체크리스트:**
- ✅ 데이터 저장 보안 (V2)
- ✅ 암호화 (V3)
- ✅ 인증 및 세션 관리 (V4)
- ✅ 네트워크 통신 (V5)
- ✅ 플랫폼 상호작용 (V6)
- ✅ 코드 품질 및 빌드 설정 (V7)
- ✅ 복원력 (V8)

금융/헬스케어 앱은 **Level 3 (OWASP MASVS L2+RASP)** 이상을 목표로 하세요.
정기적인 보안 감사와 침투 테스트로 취약점을 사전에 발견하고 대응하는 것이 중요합니다.
