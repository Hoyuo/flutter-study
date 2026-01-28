import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_user.freezed.dart';
part 'current_user.g.dart';

/// Current authenticated user information
@freezed
class CurrentUser with _$CurrentUser {
  const factory CurrentUser({
    required String id,
    required String email,
    @Default(null) String? displayName,
    @Default(null) String? photoUrl,
  }) = _CurrentUser;

  factory CurrentUser.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserFromJson(json);
}
