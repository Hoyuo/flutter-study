import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart' as local_auth;

import 'biometric_service.dart';

/// BiometricService의 구현체
///
/// local_auth 패키지를 사용하여 생체인증 기능을 제공
@LazySingleton(as: BiometricService)
class BiometricServiceImpl implements BiometricService {
  final local_auth.LocalAuthentication _localAuth;

  /// 기본 생성자
  ///
  /// LocalAuthentication 인스턴스를 생성하여 초기화
  BiometricServiceImpl() : _localAuth = local_auth.LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      // 생체인증 하드웨어 지원 확인
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;

      // 디바이스 지원 확인 (PIN, 패턴 등 포함)
      final canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      // 사용 가능한 생체인증이 있는지 확인
      if (canAuthenticateWithBiometrics) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }

      return canAuthenticate;
    } catch (e) {
      // 에러 발생 시 사용 불가로 처리
      return false;
    }
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.map((biometric) {
        switch (biometric) {
          case local_auth.BiometricType.face:
            return BiometricType.face;
          case local_auth.BiometricType.fingerprint:
            return BiometricType.fingerprint;
          case local_auth.BiometricType.iris:
            return BiometricType.iris;
          case local_auth.BiometricType.strong:
          case local_auth.BiometricType.weak:
            return BiometricType.fingerprint;
        }
      }).toList();
    } catch (e) {
      // 에러 발생 시 빈 리스트 반환
      return [];
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      // 생체인증 사용 가능 여부 확인
      final isAvailableResult = await isAvailable();
      if (!isAvailableResult) {
        return false;
      }

      // 생체인증 수행
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        // 생체인증만 사용 (PIN/패턴 제외)
        biometricOnly: false,
        // 인증 상태 유지 (백그라운드에서 돌아와도 재인증 불필요)
        persistAcrossBackgrounding: true,
      );

      return authenticated;
    } on local_auth.LocalAuthException catch (_) {
      // 모든 local_auth 예외는 인증 실패로 처리
      return false;
    } catch (e) {
      // 예상치 못한 에러
      return false;
    }
  }

  @override
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
}
