import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// User entity representing an authenticated user
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    required DateTime createdAt,
  }) = _User;
}
