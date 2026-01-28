import 'package:auth/domain/entities/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data model for User entity
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    required DateTime createdAt,
    String? displayName,
    String? photoUrl,
  }) = _UserModel;

  /// Create UserModel from FirebaseUser
  factory UserModel.fromFirebaseUser(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Create UserModel from domain User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      createdAt: user.createdAt,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
    );
  }

  /// Convert UserModel to domain User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      createdAt: createdAt,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
