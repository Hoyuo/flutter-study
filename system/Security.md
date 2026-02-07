# Flutter 보안 가이드

> **최신 업데이트**: Flutter 3.27 및 flutter_secure_storage 10.0.0 기준으로 작성되었습니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - 민감한 데이터를 SecureStorage로 안전하게 저장할 수 있다
> - Certificate Pinning으로 네트워크 통신을 보호할 수 있다
> - OWASP Mobile Top 10 취약점을 이해하고 대응할 수 있다

## 개요

모바일 앱의 보안은 사용자 데이터 보호와 앱의 무결성 유지에 필수적입니다. 이 가이드는 Flutter 앱에서 적용할 수 있는 실무 기반의 보안 전략을 다룹니다.

### 주요 변경사항 (2026년 기준)

**Flutter 3.27 요구사항**
- Java 17 필수 (기존 Java 11)
- Android NDK r28 권장
- 향상된 보안 기능 및 성능 개선

**flutter_secure_storage 10.0.0 Breaking Changes**
- Android 최소 SDK: 19 → 23 (Android 6.0+)
- 기본 암호화: RSA OAEP with SHA-256 (더 강력한 보안)
- 자동 마이그레이션: `migrateOnAlgorithmChange` 옵션 지원
- 표준 API: `FlutterSecureStorage.standard()` 팩토리 생성자 추가

### 모바일 앱 보안 위협

| 위협 | 설명 | 영향 |
|------|------|------|
| 데이터 유출 | 로컬 저장소, 네트워크 전송 중 민감 데이터 노출 | 사용자 정보 탈취 |
| 인증 우회 | 부정한 인증 시도, 토큰 탈취 | 계정 접근 권한 획득 |
| 네트워크 도청 | MITM 공격, 평문 전송 | 통신 내용 감청 |
| 코드 리버싱 | 디컴파일, 분석을 통한 로직 이해 | 취약점 발견, 위조 앱 제작 |
| 악성 코드 삽입 | 앱 재패키징, 라이브러리 조작 | 악성 기능 추가 |
| 로컬 저장소 접근 | 단말기 루팅/탈옥 상태에서 접근 | 저장된 민감 데이터 노출 |

### OWASP Mobile Top 10

Flutter 앱 개발 시 주의해야 할 보안 취약점:

| 순위 | 취약점 | 예방 방법 |
|------|--------|----------|
| M1 | 부적절한 인증 및 인가 | 강력한 토큰 관리, 세션 검증 |
| M2 | 부적절한 암호화 | AES-256 암호화, TLS 1.3 |
| M3 | 불충분한 로깅 및 모니터링 | Crashlytics, 감사 로그 |
| M4 | 불충분한 코드 품질 | 정적 분석, 보안 테스트 |
| M5 | 부적절한 암호 기반 키 도출 | PBKDF2, Argon2 사용 |
| M6 | 부적절한 권한 검증 | 최소 권한 원칙 |
| M7 | 클라이언트 측 주입 | 입력 검증, SQL 인젝션 방지 |
| M8 | 부적절한 API 구현 | API 보안, 레이트 제한 |
| M9 | 부적절한 암호 저장 | 단방향 해싱, salt 사용 |
| M10 | 역공학 | 코드 난독화, 타이밍 공격 방지 |

---

## 데이터 보안

### flutter_secure_storage를 이용한 안전한 저장

flutter_secure_storage는 플랫폼별 보안 저장소(iOS Keychain, Android Keystore)를 래핑합니다.

#### 설정

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^10.0.0
  crypto: ^3.0.0
  pointycastle: ^3.7.0
```

**Flutter 3.27 요구사항**

| 항목 | 요구사항 | 비고 |
|------|---------|------|
| Flutter | 3.27.0+ | 최신 안정 버전 |
| Java | 17+ | Flutter 3.27부터 필수 |
| Android SDK | 23+ (Android 6.0) | flutter_secure_storage 10.0.0 최소 요구사항 |
| NDK | r28 | 네이티브 코드 컴파일 |
| iOS | 13.0+ | Keychain 보안 기능 |

**flutter_secure_storage 10.0.0 Breaking Changes**

- **Android SDK 최소 버전**: 19 → 23 (Android 6.0 Marshmallow 이상)
- **기본 암호화 알고리즘**: `RSA_ECB_OAEPwithSHA_256andMGF1Padding` (기존 RSA/ECB/PKCS1Padding)
- **새로운 API**: `FlutterSecureStorage.standard()` 팩토리 생성자
- **마이그레이션 옵션**: 기존 암호화 알고리즘에서 자동 마이그레이션 지원

#### 기본 저장소 구현

```dart
// lib/core/security/secure_storage_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // flutter_secure_storage 10.0.0+ 표준 설정
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Android 6.0+ (API 23) 기본 암호화 알고리즘
      // RSA_ECB_OAEPwithSHA_256andMGF1Padding (더 안전한 OAEP 패딩)
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,

      // 오류 발생 시 저장소 초기화 (예: 암호화 키 손상)
      resetOnError: true,

      // 기존 암호화 알고리즘에서 자동 마이그레이션
      // 이전 버전(RSA/ECB/PKCS1Padding)에서 업그레이드 시 true 설정
      migrateOnAlgorithmChange: true,
    ),
    iOptions: IOSOptions(
      // iOS Keychain 접근성: 첫 잠금 해제 후 + 기기에서만 접근
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 문자열 저장
  Future<void> save(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException('Failed to save: $key - $e');
    }
  }

  /// 문자열 읽기
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException('Failed to read: $key - $e');
    }
  }

  /// 삭제
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException('Failed to delete: $key - $e');
    }
  }

  /// 전체 삭제 (로그아웃 시)
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to delete all - $e');
    }
  }

  /// 특정 패턴의 모든 키 삭제
  Future<void> deleteByPrefix(String prefix) async {
    try {
      final keys = await _storage.readAll();
      for (final key in keys.keys) {
        if (key.startsWith(prefix)) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      throw StorageException('Failed to delete by prefix - $e');
    }
  }
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
```

#### flutter_secure_storage 옵션 설명

**AndroidOptions**

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `keyCipherAlgorithm` | `RSA_ECB_OAEPwithSHA_256andMGF1Padding` | RSA 키 암호화 알고리즘 (10.0.0+에서 OAEP 패딩으로 변경) |
| `storageCipherAlgorithm` | `AES_GCM_NoPadding` | 데이터 암호화 알고리즘 (AES-GCM 인증 암호화) |
| `resetOnError` | `false` | 암호화 오류 발생 시 저장소 초기화 여부 |
| `migrateOnAlgorithmChange` | `false` | 암호화 알고리즘 변경 시 자동 마이그레이션 활성화 |
| `encryptedSharedPreferences` | `false` | EncryptedSharedPreferences 사용 (Android 6.0+) |

**IOSOptions**

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `accessibility` | `unlocked_this_device` | Keychain 접근 조건 |
| `accountName` | `null` | Keychain 계정 이름 |
| `synchronizable` | `false` | iCloud Keychain 동기화 |
| `groupId` | `null` | 앱 그룹 간 Keychain 공유 |

**Keychain Accessibility 옵션 (iOS)**

```dart
enum KeychainAccessibility {
  // 기기 잠금 해제 상태에서만 접근 (가장 안전)
  when_unlocked,

  // 기기가 잠긴 후에도 접근 가능
  after_first_unlock,

  // 항상 접근 가능 (권장하지 않음)
  always,

  // 잠금 해제 상태 + 이 기기에서만 (백업 제외)
  when_unlocked_this_device_only,

  // 첫 잠금 해제 후 + 이 기기에서만 (권장)
  first_unlock_this_device,

  // 항상 + 이 기기에서만
  always_this_device_only,

  // 패스코드 설정 시에만 접근 (가장 안전)
  when_passcode_set_this_device_only,
}
```

**간단한 사용 예시 (standard API)**

```dart
// 기본 설정으로 빠르게 시작
final storage = FlutterSecureStorage.standard();

// 값 저장
await storage.write(key: 'token', value: 'my-secret-token');

// 값 읽기
final token = await storage.read(key: 'token');

// 값 삭제
await storage.delete(key: 'token');
```

#### 민감한 데이터 저장 패턴

```dart
// lib/core/security/sensitive_data_storage.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SensitiveDataStorage {
  // flutter_secure_storage 10.0.0+ 권장 설정
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
      migrateOnAlgorithmChange: true,  // 기존 데이터 자동 마이그레이션
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _tokenKey = 'app_auth_token';
  static const _refreshTokenKey = 'app_refresh_token';
  static const _userIdKey = 'app_user_id';
  static const _biometricKey = 'app_biometric_enabled';

  /// 인증 토큰 저장
  /// ⚠️ 중요: 토큰은 해싱하지 않고 그대로 저장합니다.
  /// SecureStorage가 자동으로 암호화하므로 원본 토큰을 API 호출에 사용할 수 있습니다.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// 토큰 조회
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Refresh 토큰 저장
  static Future<void> saveRefreshToken(String token) async {
    // Refresh 토큰은 더 긴 만료 시간으로 저장
    final expiryTime = DateTime.now().add(const Duration(days: 30));
    final data = '$token|${expiryTime.toIso8601String()}';
    await _storage.write(key: _refreshTokenKey, value: data);
  }

  /// 사용자 ID 저장
  static Future<void> saveUserId(String userId) async {
    // 사용자 ID는 암호화되지 않아도 되지만 보안 저장소 사용
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// 저장된 사용자 ID 조회
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// 로그아웃 - 모든 인증 정보 삭제
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Biometric 인증 활성화 상태 저장
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricKey, value: enabled.toString());
  }

  /// Biometric 인증 활성화 상태 조회
  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }
}
```

### 고급 암호화 전략

#### AES-256 암호화 구현

```dart
// lib/core/security/aes_encryption.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/pointycastle.dart';

// pubspec.yaml에 pointycastle 의존성 추가 필요:
// dependencies:
//   pointycastle: ^3.7.0
//   encrypt: ^5.0.0

class PBKDF2 {
  static Uint8List derive({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final params = Pbkdf2Parameters(salt, iterations, keyLength);
    final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
      ..init(params);
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }
}

class AESEncryption {
  static const _keyLength = 32;  // AES-256
  static const _ivLength = 16;   // 128-bit IV

  /// 마스터 키에서 암호화 키 생성 (PBKDF2)
  static Uint8List deriveKey(
    String password, {
    int iterations = 600000,  // OWASP 2024 권장
  }) {
    // ⚠️ 프로덕션에서는 랜덤 salt를 생성하고 해시와 함께 저장하세요
    // final salt = generateRandomSalt(); // 권장
    final salt = utf8.encode('flutter_app_salt');  // 예시용 - 프로덕션 사용 금지!
    final key = PBKDF2.derive(
      password: password,
      salt: Uint8List.fromList(salt),
      iterations: iterations,
      keyLength: _keyLength,
    );
    return key;
  }

  /// 데이터 암호화
  static String encrypt(String plaintext, String password) {
    try {
      final key = encrypt.Key.fromBase64(
        base64Encode(deriveKey(password)),
      );

      // 무작위 IV 생성
      final iv = encrypt.IV.fromSecureRandom(_ivLength);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // IV + 암호화 데이터 결합
      final combined = '${iv.base64}:${encrypted.base64}';
      return base64Encode(utf8.encode(combined));
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// 데이터 복호화
  static String decrypt(String encryptedData, String password) {
    try {
      final key = encrypt.Key.fromBase64(
        base64Encode(deriveKey(password)),
      );

      // IV와 암호화 데이터 분리
      final combined = utf8.decode(base64Decode(encryptedData));
      final parts = combined.split(':');

      if (parts.length != 2) {
        throw EncryptionException('Invalid encrypted data format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// 암호 해싱 (PBKDF2)
  static String hashPassword(String password) {
    const iterations = 600000;  // OWASP 2024 권장
    const saltLength = 32;

    // 무작위 salt 생성
    final random = Random.secure();
    final values = List<int>.generate(saltLength, (i) => random.nextInt(256));
    final salt = Uint8List.fromList(values);

    // PBKDF2로 해싱
    final digest = PBKDF2.derive(
      password: password,
      salt: salt,
      iterations: iterations,
      keyLength: 32,
    );

    // salt + 해시 함께 저장
    return '$iterations:${base64Encode(salt)}:${base64Encode(digest)}';
  }

  /// 암호 검증
  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 3) return false;

      final iterations = int.parse(parts[0]);
      final salt = base64Decode(parts[1]);
      final storedHash = parts[2];

      final digest = PBKDF2.derive(
        password: password,
        salt: Uint8List.fromList(salt),
        iterations: iterations,
        keyLength: 32,
      );
      return base64Encode(digest) == storedHash;
    } catch (_) {
      return false;
    }
  }
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
```

#### RSA 암호화 (비대칭)

```dart
// lib/core/security/rsa_encryption.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class RSAEncryption {
  /// RSA 키 쌍 생성
  static Future<RSAKeyPair> generateKeyPair({int keySize = 2048}) async {
    final random = SecureRandom('AES/CTR/AUTO-SEED-PRNG')
      ..seed(KeyParameter(Uint8List.fromList(
        List.generate(32, (_) => Random.secure().nextInt(256))
      )));
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.from(65537),  // 공개 지수
            keySize,
            64,
          ),
          random,
        ),
      );

    final pair = keyGen.generateKeyPair();
    return RSAKeyPair(
      publicKey: pair.publicKey as RSAPublicKey,
      privateKey: pair.privateKey as RSAPrivateKey,
    );
  }

  /// 공개 키로 암호화
  static String encryptWithPublicKey(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final input = utf8.encode(plaintext);
    final output = cipher.process(input);

    return base64Encode(output);
  }

  /// 개인 키로 복호화
  static String decryptWithPrivateKey(
    String encryptedData,
    RSAPrivateKey privateKey,
  ) {
    final cipher = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final input = base64Decode(encryptedData);
    final output = cipher.process(input);

    return utf8.decode(output);
  }
}

class RSAKeyPair {
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;

  RSAKeyPair({
    required this.publicKey,
    required this.privateKey,
  });
}
```

---

## 네트워크 보안

### Certificate Pinning (SSL Pinning)

네트워크 통신 중 중간자(MITM) 공격으로부터 보호합니다.

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.9.0
  dio_http2_adapter: ^2.0.0
```

#### Certificate Pinning 구현

```dart
// lib/core/network/certificate_pinning.dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class CertificatePinningInterceptor extends Interceptor {
  final List<String> certificatePins;  // SHA-256 해시 리스트
  final List<String> domainPins;       // 도메인 리스트

  CertificatePinningInterceptor({
    required this.certificatePins,
    required this.domainPins,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // HTTPS 요청만 검증
    if (options.uri.scheme == 'https') {
      final domain = options.uri.host;

      // 핀에 포함된 도메인인지 확인
      if (domainPins.contains(domain)) {
        // 서버 인증서 검증은 HttpClient에서 수행됨
        // (아래 setupHttpClient 참고)
      }
    }

    return handler.next(options);
  }

  /// HttpClient 설정 (Certificate Pinning)
  static HttpClient setupHttpClient(
    List<String> certificateShas,
  ) {
    final client = HttpClient();

    client.badCertificateCallback = (cert, host, port) {
      // 인증서의 SHA-256 해시 계산
      final certHash = _calculateCertificateHash(cert);

      // 허용된 해시 목록에 포함되는지 확인
      if (certificateShas.contains(certHash)) {
        return true;  // 인증서 수락
      }

      return false;  // 인증서 거부
    };

    return client;
  }

  static String _calculateCertificateHash(X509Certificate cert) {
    // 인증서의 SHA-256 해시 계산
    final bytes = cert.der;
    final hash = sha256.convert(bytes).toString();
    return hash;
  }
}
```

#### Dio에서 Certificate Pinning 적용

```dart
// lib/core/network/dio_client.dart
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

class DioClient {
  static Dio createDioWithPinning({
    required String baseUrl,
    required List<String> certificatePins,
    required List<String> domainPins,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // HTTP/2 어댑터 사용
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        onClientCreate: (_, config) {
          config.onBadCertificate = (cert, host, port) {
            // Certificate Pinning 로직
            return _verifyCertificate(cert, certificatePins);
          };
        },
      ),
    );

    // 인터셉터 추가
    dio.interceptors.add(
      CertificatePinningInterceptor(
        certificatePins: certificatePins,
        domainPins: domainPins,
      ),
    );

    return dio;
  }

  static bool _verifyCertificate(
    X509Certificate cert,
    List<String> allowedHashes,
  ) {
    final hash = _getCertificateHash(cert);
    return allowedHashes.contains(hash);
  }

  static String _getCertificateHash(X509Certificate cert) {
    final bytes = cert.der;
    return sha256.convert(bytes).toString();
  }
}
```

### API 키 보호

API 키는 환경 변수나 보안 저장소에 저장해야 합니다.

```dart
// lib/core/config/app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get apiKey => dotenv.env['API_KEY'] ?? '';

  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';

  /// API 키를 런타임에 로드 (동적 로딩)
  static Future<void> loadConfig() async {
    await dotenv.load(fileName: '.env');
  }

  /// 빌드 시간에 API 키 주입 (CI/CD 파이프라인)
  static void injectSecrets({
    required String apiBaseUrl,
    required String apiKey,
  }) {
    // Android: BuildConfig에서 읽기
    // iOS: Info.plist에서 읽기
  }
}
```

#### .env 파일 (git ignore)

```
API_BASE_URL=https://api.example.com
API_KEY=your-api-key-here
JWT_SECRET=your-jwt-secret-here
```

#### 빌드 시간 환경 변수

```bash
# Android - build.gradle
android {
  buildTypes {
    release {
      buildConfigField "String", "API_KEY", "\"${System.getenv('API_KEY')}\""
    }
  }
}

# iOS - xcconfig
// Configuration.xcconfig
API_KEY = $(API_KEY)
```

### HTTPS 강제 및 보안 헤더

```dart
// lib/core/network/security_headers_interceptor.dart
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

class SecurityHeadersInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 보안 헤더 추가
    options.headers.addAll({
      // HTTPS 강제 (HSTS)
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',

      // XSS 방지
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',

      // CSRF 보호
      'X-CSRF-Token': _generateCsrfToken(),

      // 컨텐츠 보안 정책
      'Content-Security-Policy': 'default-src \'self\'',

      // 캐시 제어
      'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0',

      // 타사 참조 금지 (Referrer Policy)
      'Referrer-Policy': 'strict-origin-when-cross-origin',
    });

    return handler.next(options);
  }

  static String _generateCsrfToken() {
    // 무작위 CSRF 토큰 생성
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(values);
  }
}
```

---

## 코드 보안

### 코드 난독화 설정

#### Android (R8/ProGuard)

```gradle
// android/app/build.gradle
android {
  buildTypes {
    release {
      signingConfig signingConfigs.release

      // R8 활성화 (Android Gradle Plugin 3.4.0+에서 기본)
      minifyEnabled true

      // ProGuard 규칙 파일
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                    'proguard-rules.pro'

      // 자산 및 리소스 축소
      shrinkResources true
    }
  }
}
```

```properties
# android/app/proguard-rules.pro
# Flutter 클래스 보호
-keep class io.flutter.** { *; }
-keep class com.google.android.material.** { *; }

# 앱 특정 클래스 보호
-keep class com.example.myapp.** { *; }

# 보안 관련 라이브러리
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# Gson, Retrofit 등 직렬화 라이브러리
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# 중요 메서드 보호
-keepclasseswithmembernames class * {
  native <methods>;
}

# 로깅 제거 (난독화 추가)
-assumenosideeffects class android.util.Log {
  public static *** d(...);
  public static *** v(...);
  public static *** i(...);
}

# 스택 트레이스 난독화
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable
```

#### iOS (Swift Obfuscation)

```swift
// ios/Runner/Runner.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 앱 그룹화 방지 -->
  <key>com.apple.security.application-groups</key>
  <false/>

  <!-- 앱 샌드박스 활성화 -->
  <key>com.apple.security.app-sandbox</key>
  <true/>

  <!-- 네트워크 접근 제한 -->
  <key>com.apple.security.network.client</key>
  <true/>
</dict>
</plist>
```

### 리버스 엔지니어링 방지

```dart
// lib/core/security/reverse_engineering_check.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReverseEngineeringCheck {
  /// 루팅/탈옥 감지
  static Future<bool> isDeviceCompromised() async {
    if (Platform.isAndroid) {
      return await _checkAndroidRoot();
    } else if (Platform.isIOS) {
      return await _checkIOSJailbreak();
    }
    return false;
  }

  /// Android 루팅 감지
  static Future<bool> _checkAndroidRoot() async {
    try {
      // 루팅 흔적 확인
      final rootIndicators = [
        '/system/app/Superuser.apk',
        '/system/xbin/su',
        '/system/bin/su',
        '/data/local/xbin/su',
        '/data/local/tmp/su',
        '/system/sd/xbin/su',
      ];

      for (final indicator in rootIndicators) {
        final file = File(indicator);
        if (await file.exists()) {
          return true;
        }
      }

      // 루팅 앱 감지
      const platform = MethodChannel('com.example.app/security');
      try {
        final isRooted = await platform.invokeMethod<bool>('isRooted');
        return isRooted ?? false;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// iOS 탈옥 감지
  static Future<bool> _checkIOSJailbreak() async {
    try {
      final jailbreakIndicators = [
        '/Applications/Cydia.app',
        '/var/lib/cydia',
        '/etc/apt',
        '/private/var/lib/apt',
      ];

      for (final indicator in jailbreakIndicators) {
        final file = File(indicator);
        if (await file.exists()) {
          return true;
        }
      }

      // Jailbreak 감지 (네이티브)
      const platform = MethodChannel('com.example.app/security');
      try {
        final isJailbroken = await platform.invokeMethod<bool>('isJailbroken');
        return isJailbroken ?? false;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  /// 디버그 모드 감지
  static Future<bool> isDebugMode() async {
    if (Platform.isAndroid) {
      const platform = MethodChannel('com.example.app/security');
      try {
        final isDebug = await platform.invokeMethod<bool>('isDebugMode');
        return isDebug ?? false;
      } catch (_) {
        return false;
      }
    }

    // iOS에서는 빌드 타입으로 감지
    return !kReleaseMode;
  }

  /// USB 디버깅 활성화 감지 (Android)
  static Future<bool> isUSBDebuggingEnabled() async {
    if (!Platform.isAndroid) return false;

    const platform = MethodChannel('com.example.app/security');
    try {
      final enabled = await platform.invokeMethod<bool>('isUSBDebuggingEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Frida 감지 (동적 분석 도구)
  static Future<bool> isFridaPresent() async {
    try {
      // Frida 포트 스캔
      for (int port = 27042; port <= 27045; port++) {
        try {
          final socket = await Socket.connect(
            'localhost',
            port,
            timeout: const Duration(milliseconds: 100),
          );
          socket.destroy();
          return true;
        } catch (_) {}
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 보안 검사 실행
  static Future<SecurityCheckResult> performSecurityCheck() async {
    final results = {
      'isCompromised': await isDeviceCompromised(),
      'isDebugMode': await isDebugMode(),
      'isUSBDebuggingEnabled': await isUSBDebuggingEnabled(),
      'isFridaPresent': await isFridaPresent(),
    };

    return SecurityCheckResult(results);
  }
}

class SecurityCheckResult {
  final Map<String, bool> results;

  SecurityCheckResult(this.results);

  bool get isSecure => results.values.every((v) => !v);

  String get summary {
    final issues = results.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (issues.isEmpty) return '보안 검사 통과';
    return '보안 위협: ${issues.join(', ')}';
  }
}
```

### 타이밍 공격 방지

```dart
// lib/core/security/timing_safe_comparison.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';

class TimingSafeComparison {
  /// 일정한 시간에 비교 (타이밍 공격 방지)
  static bool constantTimeEqual(String a, String b) {
    // 길이가 다르면 먼저 해시
    final hashA = _hash(a);
    final hashB = _hash(b);

    if (hashA.length != hashB.length) return false;

    int result = 0;
    for (int i = 0; i < hashA.length; i++) {
      result |= hashA.codeUnitAt(i) ^ hashB.codeUnitAt(i);
    }

    return result == 0;
  }

  static String _hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  /// 토큰 비교 (일정한 시간)
  static bool verifyToken(String providedToken, String expectedToken) {
    return constantTimeEqual(providedToken, expectedToken);
  }

  /// HMAC 검증
  static bool verifyHmac(
    String message,
    String signature,
    String secret,
  ) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final bytes = utf8.encode(message);
    final computed = hmac.convert(bytes).toString();

    return constantTimeEqual(signature, computed);
  }
}
```

---

## 인증/인가 보안

### 토큰 저장 및 관리

```dart
// lib/core/security/token_manager.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenManager {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';

  final SecureStorageService _storage;

  TokenManager(this._storage);

  /// 토큰 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      // Access 토큰 검증
      if (!_isValidToken(accessToken)) {
        throw TokenException('Invalid access token');
      }

      // Refresh 토큰 검증
      if (!_isValidToken(refreshToken)) {
        throw TokenException('Invalid refresh token');
      }

      // 토큰 저장
      await _storage.save(_accessTokenKey, accessToken);
      await _storage.save(_refreshTokenKey, refreshToken);

      // 만료 시간 저장
      final expiryTime = JwtDecoder.getExpirationDate(accessToken);
      await _storage.save(_tokenExpiryKey, expiryTime.toIso8601String());
    } catch (e) {
      throw TokenException('Failed to save tokens: $e');
    }
  }

  /// 액세스 토큰 조회
  Future<String?> getAccessToken() async {
    try {
      final token = await _storage.read(_accessTokenKey);

      if (token == null) return null;

      // 만료 확인
      if (JwtDecoder.isExpired(token)) {
        await clearTokens();
        return null;
      }

      return token;
    } catch (_) {
      return null;
    }
  }

  /// Refresh 토큰 조회
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(_refreshTokenKey);
    } catch (_) {
      return null;
    }
  }

  /// 토큰 새로고침
  Future<bool> refreshToken(
    Future<String> Function(String) apiCall,
  ) async {
    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        return false;
      }

      // API 호출로 새 토큰 획득
      final newAccessToken = await apiCall(refreshToken);

      // 새 토큰 저장
      await _storage.save(_accessTokenKey, newAccessToken);

      final expiryTime = JwtDecoder.getExpirationDate(newAccessToken);
      await _storage.save(_tokenExpiryKey, expiryTime.toIso8601String());

      return true;
    } catch (_) {
      return false;
    }
  }

  /// 토큰 정보 조회
  Future<Map<String, dynamic>?> getTokenInfo() async {
    try {
      final token = await getAccessToken();

      if (token == null) return null;

      return JwtDecoder.decode(token);
    } catch (_) {
      return null;
    }
  }

  /// 토큰 유효성 확인
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    return token != null && _isValidToken(token);
  }

  /// 토큰 삭제
  Future<void> clearTokens() async {
    await _storage.delete(_accessTokenKey);
    await _storage.delete(_refreshTokenKey);
    await _storage.delete(_tokenExpiryKey);
  }

  bool _isValidToken(String token) {
    try {
      // ⚠️ 주의: 클라이언트에서 JWT 디코딩 시 서명 검증 불가
      // 실제 검증은 서버에서 수행해야 함
      // 클라이언트에서는 만료 시간(exp) 확인 용도로만 사용

      // JWT 형식 검증
      if (!token.contains('.') || token.split('.').length != 3) {
        return false;
      }

      // 만료 확인
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

class TokenException implements Exception {
  final String message;
  const TokenException(this.message);

  @override
  String toString() => 'TokenException: $message';
}
```

### Biometric 인증

```yaml
# pubspec.yaml
dependencies:
  local_auth: ^2.1.0
  local_auth_ios: ^1.0.0
  local_auth_android: ^1.0.0
```

```dart
// lib/core/security/biometric_auth.dart
import 'package:local_auth/local_auth.dart';

class BiometricAuth {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 생체 인증 사용 가능 여부
  Future<bool> canUseBiometrics() async {
    try {
      final isDeviceSupported =
          await _localAuth.canCheckBiometrics;
      final availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      return isDeviceSupported && availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 사용 가능한 생체 인증 종류
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// 생체 인증 실행
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: '앱 접근을 위해 인증해주세요',
        options: const AuthenticationOptions(
          stickyAuth: true,           // 화면 전환 시에도 유지
          biometricOnly: true,        // 생체 인증만 사용
          sensitiveTransaction: true, // 보안 트랜잭션
        ),
      );
    } on Exception catch (_) {
      return false;
    }
  }

  /// 민감한 작업 전 인증
  Future<bool> authenticateForSensitiveOperation({
    String reason = '민감한 작업을 위해 인증해주세요',
  }) async {
    try {
      final canUse = await canUseBiometrics();

      if (!canUse) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
```

#### Biometric 인증 UI

```dart
// lib/features/auth/presentation/pages/biometric_auth_page.dart
import 'package:flutter/material.dart';

class BiometricAuthPage extends StatefulWidget {
  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  late BiometricAuth _biometricAuth;
  bool _isAuthenticating = false;
  String _status = '인증 대기 중';

  @override
  void initState() {
    super.initState();
    _biometricAuth = BiometricAuth();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final canUse = await _biometricAuth.canUseBiometrics();

    if (canUse) {
      setState(() => _status = '생체 인증 사용 가능');
      // 자동 인증 시도
      _authenticate();
    } else {
      setState(() => _status = '생체 인증을 사용할 수 없습니다');
    }
  }

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);

    final result = await _biometricAuth.authenticate();

    if (result) {
      // 인증 성공
      if (mounted) {
        setState(() => _status = '인증 성공');
        // 다음 화면으로 이동
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      // 인증 실패
      if (mounted) {
        setState(() => _status = '인증 실패');
      }
    }

    setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생체 인증')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(_status),
            const SizedBox(height: 24),
            if (!_isAuthenticating)
              ElevatedButton(
                onPressed: _authenticate,
                child: const Text('인증'),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

### Session 관리

```dart
// lib/core/security/session_manager.dart
class SessionManager {
  static const _sessionTimeoutKey = 'session_timeout';
  static const _lastActivityKey = 'last_activity';
  static const _defaultSessionTimeout = Duration(minutes: 15);

  final SecureStorageService _storage;

  SessionManager(this._storage);

  /// Session 시작
  Future<void> startSession({
    Duration timeout = _defaultSessionTimeout,
  }) async {
    await _storage.save(
      _sessionTimeoutKey,
      timeout.inSeconds.toString(),
    );
    await _updateLastActivity();
  }

  /// 마지막 활동 시간 업데이트
  Future<void> _updateLastActivity() async {
    await _storage.save(
      _lastActivityKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Session 유효성 확인
  Future<bool> isSessionValid() async {
    try {
      final lastActivity = await _storage.read(_lastActivityKey);
      final timeoutSeconds = await _storage.read(_sessionTimeoutKey);

      if (lastActivity == null || timeoutSeconds == null) {
        return false;
      }

      final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastActivity),
      );
      final timeout = Duration(seconds: int.parse(timeoutSeconds));

      final elapsed = DateTime.now().difference(lastActivityTime);
      return elapsed < timeout;
    } catch (_) {
      return false;
    }
  }

  /// Session 갱신
  Future<void> refreshSession() async {
    final isValid = await isSessionValid();

    if (isValid) {
      await _updateLastActivity();
    } else {
      await endSession();
    }
  }

  /// Session 종료
  Future<void> endSession() async {
    await _storage.delete(_sessionTimeoutKey);
    await _storage.delete(_lastActivityKey);
  }

  /// 비활성 시간 계산
  Future<Duration?> getInactiveTime() async {
    final lastActivity = await _storage.read(_lastActivityKey);

    if (lastActivity == null) return null;

    final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(
      int.parse(lastActivity),
    );

    return DateTime.now().difference(lastActivityTime);
  }
}
```

---

## 보안 테스트

### 정적 분석 도구

#### Dart 분석기 설정

```yaml
# analysis_options.yaml
analyzer:
  # Records와 Patterns는 Dart 3.0+에서 기본 활성화
  # enable-experiment:  # 더 이상 필요 없음

  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore

  exclude:
    - 'lib/generated/**'

linter:
  rules:
    # 보안 관련 규칙
    - secure_pubspec_urls
    - only_throw_errors
    - avoid_empty_else
    - avoid_function_literals_in_foreach_calls
    - avoid_private_typedef_functions
    - await_only_futures
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - control_flow_in_finally
    - empty_statements
    - hash_and_equals
    # invariant_booleans - Dart 2.x에서 deprecated, 제거
    # leading_newlines_in_multiline_strings - deprecated, 제거
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - prefer_void_to_null
    - throw_in_finally
    - unnecessary_await_in_return
    - unnecessary_statements
    - unrelated_type_equality_checks
```

#### 정적 분석 실행

```bash
# Dart 분석
flutter analyze

# 추가 보안 검사
dart pub get
dart run custom_lint

# Dartfmt (코드 스타일)
dart format lib/
```

### 동적 분석

#### Frida를 이용한 런타임 분석

```bash
# Frida 설치
pip install frida-tools

# Frida 서버 실행 (Android 기기)
adb push frida-server-android /data/local/tmp/
adb shell chmod +x /data/local/tmp/frida-server-android
adb shell /data/local/tmp/frida-server-android

# 앱 훅
frida -l hook.js -f com.example.app --no-pause

# iOS (macOS)
sudo pip install frida-tools
frida -U -f com.example.app
```

#### Dart 코드 보안 감사

```dart
// lib/core/security/security_audit.dart
class SecurityAudit {
  /// 로깅 확인
  static Future<void> checkLoggingPractices() async {
    // 프로덕션에서 debugPrint 사용 금지
    debugPrint('This should not appear in production');
  }

  /// 민감 데이터 로깅 확인
  static Future<void> checkSensitiveDataLogging() async {
    // 금지된 항목들
    final sensitivePatterns = [
      RegExp(r'password'),
      RegExp(r'token'),
      RegExp(r'ssn'),
      RegExp(r'credit'),
      RegExp(r'api.?key', caseSensitive: false),
    ];

    // 코드에서 민감 데이터 패턴 검사
  }

  /// 네트워크 보안 확인
  static Future<void> checkNetworkSecurity() async {
    // HTTP 요청 금지 (HTTPS만)
    // Certificate Pinning 확인
    // 보안 헤더 확인
  }

  /// 인증 보안 확인
  static Future<void> checkAuthenticationSecurity() async {
    // 토큰 저장 방식 확인
    // 세션 관리 확인
  }
}
```

### 침투 테스트 체크리스트

```dart
// lib/core/security/penetration_test_checklist.dart
class PenetrationTestChecklist {
  static const Map<String, String> checklist = {
    // 인증 및 인가
    'auth_001': '기본 인증정보 (약한 암호) 시도',
    'auth_002': '토큰 탈취 시나리오',
    'auth_003': '세션 토큰 복제 시도',
    'auth_004': '권한 에스컬레이션 시도',

    // 데이터 보안
    'data_001': '로컬 저장소 평문 데이터 확인',
    'data_002': '중요 데이터 암호화 확인',
    'data_003': '메모리 레지던스 확인',
    'data_004': '임시 파일 정리 확인',

    // 네트워크 보안
    'net_001': 'HTTPS 강제 확인',
    'net_002': 'Certificate Pinning 검증',
    'net_003': 'MITM 공격 시뮬레이션',
    'net_004': 'API 응답 검증',

    // 클라이언트 보안
    'client_001': '클라이언트 사이드 검증만으로 우회',
    'client_002': '입력 검증 우회 시도',
    'client_003': '메모리 덤프 분석',
    'client_004': '코드 역공학 시도',

    // 감시 및 로깅
    'logging_001': '보안 이벤트 로깅 확인',
    'logging_002': '감사 추적 확인',
    'logging_003': '에러 로깅 민감정보 노출 확인',

    // 플랫폼 특정
    'android_001': '루팅 탐지 우회 시도',
    'android_002': 'AndroidManifest 권한 검증',
    'ios_001': '탈옥 탐지 우회 시도',
    'ios_002': 'Info.plist 설정 검증',
  };

  /// 체크리스트 출력
  static void printChecklist() {
    print('=== 침투 테스트 체크리스트 ===');
    checklist.forEach((key, value) {
      print('[$key] $value');
    });
  }

  /// 테스트 결과 기록
  static Future<void> recordTestResult({
    required String testId,
    required bool passed,
    required String notes,
  }) async {
    // 테스트 결과 저장
    print('Test [$testId]: ${passed ? 'PASS' : 'FAIL'} - $notes');
  }
}
```

---

## 플랫폼별 보안 설정

### Android 보안 설정

#### AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.app">

  <!-- Android 6.0 (API 23) 이상 요구 (flutter_secure_storage 10.0.0) -->
  <uses-sdk
      android:minSdkVersion="23"
      android:targetSdkVersion="34" />

  <!-- 필요한 권한만 요청 (최소 권한 원칙) -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

  <!-- 위험한 권한 요청 제거 -->
  <!-- <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" /> -->

  <application
      android:icon="@mipmap/ic_launcher"
      android:label="@string/app_name"
      android:theme="@style/AppTheme"
      android:usesCleartextTraffic="false"
      android:allowBackup="false"
      android:debuggable="false">

    <!-- 스크린캐시 비활성화 -->
    <activity
        android:name=".MainActivity"
        android:windowSecure="true">
    </activity>

    <!-- Content Provider 암호화 -->
    <provider
        android:name=".data.ContentProvider"
        android:authorities="com.example.app.provider"
        android:exported="false"
        android:permission="com.example.app.permission.DATA_ACCESS">
    </provider>

    <!-- 브로드캐스트 리시버 보호 -->
    <receiver
        android:name=".receivers.SecurityBroadcastReceiver"
        android:exported="false">
      <intent-filter>
        <action android:name="android.intent.action.PACKAGE_REPLACED" />
      </intent-filter>
    </receiver>
  </application>
</manifest>
```

#### build.gradle 보안 설정

```gradle
android {
  compileSdk 34

  // Java 17 필수 (Flutter 3.27+)
  compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
  }

  // NDK 버전 (r28 권장)
  ndkVersion "28.0.12433566"

  defaultConfig {
    // flutter_secure_storage 10.0.0 최소 요구사항
    minSdk 23  // Android 6.0 Marshmallow 이상
    targetSdk 34

    // 버전 관리
    versionCode 1
    versionName "1.0.0"

    // 네트워크 보안
    manifestPlaceholders = [
      usesCleartextTraffic: false
    ]
  }

  signingConfigs {
    release {
      storeFile file(System.getenv('KEYSTORE_PATH') ?: 'release.keystore')
      storePassword System.getenv('KEYSTORE_PASSWORD')
      keyAlias System.getenv('KEY_ALIAS')
      keyPassword System.getenv('KEY_PASSWORD')
    }
  }

  buildTypes {
    debug {
      debuggable false  // 본 환경에서도 비활성화
      minifyEnabled false
    }

    release {
      debuggable false
      minifyEnabled true
      proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                    'proguard-rules.pro'
      signingConfig signingConfigs.release
      shrinkResources true
    }
  }

  // 보안 라이브러리 의존성
  dependencies {
    // 정기적으로 업데이트
    implementation 'androidx.security:security-crypto:1.1.0-alpha06'
  }
}
```

### iOS 보안 설정

#### Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 앱 이름 -->
  <key>CFBundleDisplayName</key>
  <string>My App</string>

  <!-- 앱 버전 -->
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>

  <!-- HTTPS 강제 -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsArbitraryLoadsInMedia</key>
    <false/>
    <key>NSAllowsLocalNetworking</key>
    <false/>

    <!-- 특정 도메인 예외 (필요시만) -->
    <key>NSExceptionDomains</key>
    <dict>
      <key>api.example.com</key>
      <dict>
        <key>NSIncludesSubdomains</key>
        <true/>
        <key>NSExceptionMinimumTLSVersion</key>
        <string>TLSv1.2</string>
      </dict>
    </dict>
  </dict>

  <!-- 캐시 관련 -->
  <key>NSBrowsingContextControlPolicy</key>
  <string>kWKBrowsingContextControlPolicyRestricted</string>

  <!-- Siri 보안 -->
  <key>NSUserActivityTypes</key>
  <array>
    <string>com.example.app.secure-activity</string>
  </array>

  <!-- 로컬 저장 정책 -->
  <key>NSLocalNetworkUsageDescription</key>
  <string>로컬 네트워크 접근이 필요합니다</string>

  <!-- 카메라, 마이크 등 권한 -->
  <key>NSCameraUsageDescription</key>
  <string>카메라 접근이 필요합니다</string>

  <key>NSMicrophoneUsageDescription</key>
  <string>마이크 접근이 필요합니다</string>

  <key>NSLocationWhenInUseUsageDescription</key>
  <string>위치 정보가 필요합니다</string>
</dict>
</plist>
```

#### Entitlements 파일

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 앱 샌드박스 활성화 -->
  <key>com.apple.security.app-sandbox</key>
  <true/>

  <!-- 권한 최소화 -->
  <key>com.apple.security.files.user-selected.read-only</key>
  <true/>

  <!-- 네트워크 제한 -->
  <key>com.apple.security.network.client</key>
  <true/>
  <key>com.apple.security.network.server</key>
  <false/>

  <!-- 프로세스 제한 -->
  <key>com.apple.security.cs.disable-library-validation</key>
  <false/>

  <!-- 디버깅 비활성화 -->
  <key>com.apple.security.debugging</key>
  <false/>
</dict>
</plist>
```

---

## 14. App Attestation (앱 무결성 검증)

### 14.1 Android - Play Integrity API

```dart
// pubspec.yaml
dependencies:
  play_integrity: ^1.0.0

// lib/services/integrity_service.dart
// ⚠️ 주의: play_integrity 패키지는 pub.dev에 존재하지 않는 fabricated API입니다.
// Play Integrity API는 네이티브 Android API로, MethodChannel을 통한 플랫폼 채널 구현이 필요합니다.
// 이 코드는 개념적 의사코드(pseudo-code)로만 참고하세요.
import 'package:play_integrity/play_integrity.dart';

class IntegrityService {
  final PlayIntegrity _playIntegrity = PlayIntegrity();

  /// 앱 무결성 토큰 요청
  Future<String?> requestIntegrityToken(String nonce) async {
    try {
      final token = await _playIntegrity.requestIntegrityToken(
        IntegrityTokenRequest(nonce: nonce),
      );
      return token?.token;
    } catch (e) {
      // 에뮬레이터 또는 루팅된 기기에서 실패할 수 있음
      return null;
    }
  }

  /// 서버에서 토큰 검증 (백엔드 필요)
  Future<IntegrityVerdict> verifyOnServer(String token) async {
    final response = await dio.post('/api/verify-integrity', data: {
      'token': token,
    });
    return IntegrityVerdict.fromJson(response.data);
  }
}

class IntegrityVerdict {
  final bool deviceRecognized;
  final bool basicIntegrity;
  final bool strongIntegrity;
  final bool appRecognized;

  bool get isSecure =>
    deviceRecognized && basicIntegrity && appRecognized;
}
```

### 14.2 iOS - DeviceCheck / App Attest

```dart
// pubspec.yaml
dependencies:
  device_check: ^1.0.0

// lib/services/device_check_service.dart
// ⚠️ 주의: device_check 패키지는 pub.dev에 존재하지 않는 fabricated API입니다.
// iOS DeviceCheck/App Attest는 네이티브 Swift/ObjC 코드가 필요하며 MethodChannel로 접근해야 합니다.
// 이 코드는 개념적 의사코드(pseudo-code)로만 참고하세요.
import 'package:device_check/device_check.dart';

class DeviceCheckService {
  final DeviceCheck _deviceCheck = DeviceCheck();

  /// DeviceCheck 지원 여부 확인
  Future<bool> isSupported() async {
    return await _deviceCheck.isSupported();
  }

  /// 디바이스 토큰 생성 (서버 검증용)
  Future<String?> generateToken() async {
    if (!await isSupported()) return null;

    try {
      return await _deviceCheck.generateToken();
    } catch (e) {
      return null;
    }
  }

  /// App Attest 키 생성 (iOS 14+)
  Future<String?> generateAppAttestKey() async {
    try {
      return await _deviceCheck.generateKey();
    } catch (e) {
      return null;
    }
  }

  /// App Attest assertion 생성
  Future<String?> generateAssertion(String keyId, String challenge) async {
    try {
      return await _deviceCheck.generateAssertion(
        keyId: keyId,
        clientDataHash: challenge,
      );
    } catch (e) {
      return null;
    }
  }
}
```

### 14.3 통합 사용 예시

```dart
class SecureApiClient {
  final IntegrityService _integrityService;
  final DeviceCheckService _deviceCheckService;

  Future<void> secureRequest() async {
    String? attestationToken;

    if (Platform.isAndroid) {
      attestationToken = await _integrityService.requestIntegrityToken(
        _generateNonce(),
      );
    } else if (Platform.isIOS) {
      attestationToken = await _deviceCheckService.generateToken();
    }

    if (attestationToken == null) {
      throw SecurityException('기기 무결성을 확인할 수 없습니다');
    }

    // 서버 요청에 attestation 토큰 포함
    await dio.post('/api/secure-endpoint',
      options: Options(headers: {
        'X-Attestation-Token': attestationToken,
      }),
    );
  }
}
```

### 14.4 주의사항

| 항목 | 설명 |
|-----|------|
| 에뮬레이터 | Play Integrity는 에뮬레이터에서 실패함 |
| 개발 중 | 개발 환경에서는 attestation 건너뛰기 필요 |
| 비용 | Play Integrity API는 일정 호출 이후 과금 |
| 서버 검증 | 토큰은 반드시 서버에서 검증해야 함 |

---

## 15. 보안 인시던트 대응

### 15.1 보안 사고 분류

| 등급 | 예시 | 대응 시간 |
|-----|------|---------|
| Critical | 사용자 데이터 유출, API 키 노출 | 즉시 (15분 내) |
| High | 인증 우회, 권한 상승 취약점 | 2시간 내 |
| Medium | XSS, CSRF 취약점 | 24시간 내 |
| Low | 정보 노출 (버전 정보 등) | 1주일 내 |

### 15.2 대응 절차

```dart
class SecurityIncidentResponse {
  /// 1. 격리 (Contain)
  static Future<void> contain() async {
    // 손상된 토큰/키 즉시 폐기
    await revokeCompromisedTokens();
    // 의심 계정 잠금
    await lockSuspiciousAccounts();
    // 영향 받는 API 엔드포인트 차단
    await blockAffectedEndpoints();
  }

  /// 2. 조사 (Investigate)
  static Future<void> investigate() async {
    // 로그 분석
    await analyzeSecurityLogs();
    // 영향 범위 파악
    await determineScope();
    // 침입 경로 추적
    await traceEntryPoint();
  }

  /// 3. 통보 (Notify)
  static Future<void> notify() async {
    // GDPR: 72시간 내 감독기관 통보
    // 영향 받는 사용자에게 알림
    await notifyAffectedUsers();
  }

  /// 4. 복구 (Remediate)
  static Future<void> remediate() async {
    // 취약점 패치
    await applySecurityPatch();
    // 키/인증서 교체
    await rotateCredentials();
    // 모니터링 강화
    await enhanceMonitoring();
  }
}
```

### 15.3 API 키 유출 시 대응

```bash
# 1. 즉시 키 폐기
firebase console → Project Settings → Service accounts → Revoke

# 2. 새 키 생성 및 배포
firebase apps:sdkconfig

# 3. CI/CD 시크릿 업데이트
gh secret set FIREBASE_API_KEY --body "new-key"

# 4. 긴급 앱 업데이트 배포
flutter build apk --release
fastlane android production
```

### 15.4 사용자 통보 템플릿

```dart
const breachNotificationTemplate = '''
[중요] 보안 알림

귀하의 계정과 관련된 보안 사고가 발생했습니다.

영향 범위: {scope}
발생 일시: {date}
조치 사항: {actions}

권장 조치:
1. 비밀번호 즉시 변경
2. 다른 서비스 동일 비밀번호 사용 시 변경
3. 의심스러운 활동 발견 시 연락

문의: security@example.com
''';
```

---

## 보안 체크리스트

### 개발 단계

**환경 설정**
- [ ] Flutter 3.27.0 이상 사용
- [ ] Java 17 설치 및 설정
- [ ] Android NDK r28 설치
- [ ] Android minSdk 23 이상 설정 (flutter_secure_storage 10.0.0 요구사항)

**데이터 보안**
- [ ] 모든 민감 데이터는 flutter_secure_storage 10.0.0+ 사용
- [ ] AndroidOptions에서 migrateOnAlgorithmChange: true 설정 (기존 앱 업그레이드 시)
- [ ] resetOnError: true 설정으로 암호화 오류 대응
- [ ] iOS Keychain accessibility 적절히 설정 (first_unlock_this_device 권장)

**네트워크 보안**
- [ ] 네트워크 통신은 HTTPS 강제
- [ ] Certificate Pinning 구현
- [ ] API 키는 환경 변수나 보안 저장소 사용

**코드 보안**
- [ ] 입력 데이터 검증 (SQL 인젝션, XSS 방지)
- [ ] 에러 메시지에 민감 정보 노출 금지
- [ ] 로깅에서 민감 정보 제거
- [ ] 강력한 암호 요구사항 구현
- [ ] 비밀번호 해싱 (PBKDF2, Argon2)
- [ ] 토큰 기반 인증 구현

### 빌드 및 배포 단계

- [ ] ProGuard/R8로 코드 난독화
- [ ] Debuggable 플래그 비활성화
- [ ] 백업 비활성화 (Android)
- [ ] HTTPS 강제 (cleartext 금지)
- [ ] 앱 서명 인증서 안전하게 관리
- [ ] 민감 정보를 빌드 아티팩트에 포함 금지
- [ ] 의존성 라이브러리 정기적 업데이트

### 배포 후 모니터링

- [ ] Crashlytics로 에러 모니터링
- [ ] 보안 이벤트 로깅
- [ ] 비정상 패턴 감지
- [ ] 정기적인 보안 감사
- [ ] 사용자 보고 피드백 검토
- [ ] 취약점 발견 시 긴급 패치

### 보안 테스트

- [ ] 정적 분석 도구 실행 (Dart Analyzer)
- [ ] 동적 분석 (Frida, Burp Suite)
- [ ] 침투 테스트 수행
- [ ] OWASP Mobile Top 10 검증
- [ ] 권한 에스컬레이션 테스트
- [ ] 데이터 유출 테스트
- [ ] 루팅/탈옥 탐지 테스트

### 기타

- [ ] 개인정보 처리방침 작성
- [ ] 보안 정책 문서화
- [ ] 개발팀 보안 교육
- [ ] 써드파티 라이브러리 보안 검토
- [ ] 정기적인 보안 업데이트 계획
- [ ] 응급 대응 계획 수립

---

## 실습 과제

### 과제 1: SecureStorage 토큰 관리
JWT 토큰과 리프레시 토큰을 SecureStorage에 저장하고, 토큰 만료 시 자동 갱신하는 AuthRepository를 구현하세요.

### 과제 2: Certificate Pinning 적용
Dio Interceptor에 Certificate Pinning을 적용하여 MITM 공격을 방지하세요.

## Self-Check

- [ ] SecureStorage에 민감 데이터를 저장하고 있는가?
- [ ] API 통신에 Certificate Pinning이 적용되어 있는가?
- [ ] 로그에 민감 정보(토큰, 비밀번호)가 노출되지 않는가?
- [ ] ProGuard/R8으로 코드 난독화를 적용했는가?
