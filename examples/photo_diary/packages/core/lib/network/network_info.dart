import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 연결 정보 클래스
///
/// connectivity_plus 패키지를 사용하여
/// 네트워크 연결 상태를 확인하는 메서드를 제공합니다.
class NetworkInfo {
  NetworkInfo({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// 기기가 인터넷에 연결되어 있는지 확인
  ///
  /// WiFi, 모바일 데이터, 이더넷을 통해 연결된 경우 true를 반환합니다.
  /// 연결이 없거나 연결 타입이 none인 경우 false를 반환합니다.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// 현재 연결 결과 가져오기
  ///
  /// 활성 연결 타입의 리스트를 반환합니다.
  /// 일부 기기에서는 여러 타입이 동시에 활성화될 수 있습니다 (예: WiFi + 모바일).
  Future<List<ConnectivityResult>> get connectivityResults async {
    return _connectivity.checkConnectivity();
  }

  /// WiFi로 연결되어 있는지 확인
  Future<bool> get isConnectedViaWiFi async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// 모바일 데이터로 연결되어 있는지 확인
  Future<bool> get isConnectedViaMobile async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  /// 이더넷으로 연결되어 있는지 확인
  Future<bool> get isConnectedViaEthernet async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.ethernet);
  }

  /// 연결 상태 변경 스트림
  ///
  /// 이 스트림을 구독하면 연결 상태가 변경될 때마다 알림을 받을 수 있습니다.
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  /// 연결/연결 해제 상태를 bool로 전달하는 스트림
  ///
  /// 연결되면 true, 연결 해제되면 false를 방출합니다.
  Stream<bool> get onConnectionChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      ),
    );
  }
}
