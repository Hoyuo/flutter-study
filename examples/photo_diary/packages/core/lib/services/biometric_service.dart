// TODO: local_auth 패키지 추가 필요
// import 'package:local_auth/local_auth.dart';

/// 생체인증 유형
enum BiometricType {
  /// 지문 인식
  fingerprint,

  /// 얼굴 인식 (Face ID)
  face,

  /// 홍채 인식
  iris,

  /// 생체인증 미지원
  none,
}

/// 생체인증 서비스 인터페이스
///
/// 디바이스의 생체인증 기능(지문, Face ID 등)을 사용하여
/// 사용자 인증을 수행하는 서비스
abstract class BiometricService {
  /// 생체인증 사용 가능 여부 확인
  ///
  /// 디바이스가 생체인증을 지원하고, 등록된 생체정보가 있는지 확인
  ///
  /// Returns: 생체인증 사용 가능 시 true
  Future<bool> isAvailable();

  /// 사용 가능한 생체인증 유형 목록 조회
  ///
  /// 디바이스에서 지원하는 생체인증 유형들을 반환
  /// 예: [BiometricType.fingerprint, BiometricType.face]
  ///
  /// Returns: 사용 가능한 생체인증 유형 리스트
  Future<List<BiometricType>> getAvailableBiometrics();

  /// 생체인증 수행
  ///
  /// 시스템 생체인증 다이얼로그를 표시하고 인증을 수행
  ///
  /// Parameters:
  ///   - localizedReason: 사용자에게 표시할 인증 이유 메시지
  ///
  /// Returns: 인증 성공 시 true, 실패 또는 취소 시 false
  Future<bool> authenticate({required String localizedReason});

  /// 디바이스의 생체인증 지원 여부 확인
  ///
  /// 하드웨어적으로 생체인증을 지원하는지 확인
  /// (등록된 생체정보 유무와 무관)
  ///
  /// Returns: 생체인증 하드웨어 지원 시 true
  Future<bool> canCheckBiometrics();
}
