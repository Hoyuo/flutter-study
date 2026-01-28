import 'package:injectable/injectable.dart';
import 'current_user_service.dart';

/// CurrentUserService의 구현체
///
/// 앱 전역에서 현재 로그인한 사용자 정보를 관리합니다.
/// AuthBloc에서 로그인/로그아웃 시 setCurrentUserId를 호출하여 상태를 업데이트합니다.
@LazySingleton(as: CurrentUserService)
class CurrentUserServiceImpl implements CurrentUserService {
  String? _currentUserId;

  @override
  String? get currentUserId => _currentUserId;

  @override
  String get requireCurrentUserId {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError(
        'User is not logged in. Call setCurrentUserId after successful login.',
      );
    }
    return userId;
  }

  @override
  bool get isLoggedIn => _currentUserId != null;

  @override
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }
}
