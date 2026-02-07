# Flutter Firebase 통합 가이드

> **난이도**: 중급 | **카테고리**: infrastructure
> **선행 학습**: [DI](./DI.md)
> **예상 학습 시간**: 2h

> Flutter 애플리케이션에서 Firebase의 주요 서비스(Authentication, Firestore, Storage, FCM, Crashlytics, Analytics)를 Clean Architecture와 Bloc 패턴으로 통합하는 종합 가이드입니다. 실무에서 바로 적용 가능한 코드 예제와 Best Practices를 제공합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Firebase Auth로 이메일/소셜 로그인을 구현할 수 있다
> - Firestore로 실시간 데이터 동기화를 구현할 수 있다
> - Cloud Storage, FCM, Crashlytics, Analytics를 통합할 수 있다

## 목차
1. [개요](#1-개요)
2. [프로젝트 설정](#2-프로젝트-설정)
3. [Firebase Authentication](#3-firebase-authentication)
4. [Cloud Firestore](#4-cloud-firestore)
5. [Firebase Storage](#5-firebase-storage)
6. [Cloud Functions](#6-cloud-functions)
7. [Firebase Cloud Messaging](#7-firebase-cloud-messaging-fcm)
8. [Firebase Crashlytics](#8-firebase-crashlytics)
9. [Firebase Analytics](#9-firebase-analytics)
10. [Security Rules](#10-security-rules)
11. [Clean Architecture 연동](#11-clean-architecture-연동)
12. [오프라인 지원](#12-오프라인-지원)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

---

## 1. 개요

### 1.1 Firebase란?

Firebase는 Google이 제공하는 모바일 및 웹 애플리케이션 개발 플랫폼입니다. Backend 인프라를 직접 구축하지 않고도 인증, 데이터베이스, 스토리지, 푸시 알림 등의 기능을 빠르게 구현할 수 있습니다.

### 1.2 Firebase 서비스 전체 맵

| 서비스 | 용도 | 주요 기능 |
|--------|------|-----------|
| **Authentication** | 사용자 인증 | 이메일/패스워드, Google, Apple, 소셜 로그인 |
| **Cloud Firestore** | NoSQL 데이터베이스 | 실시간 동기화, 오프라인 지원, 복합 쿼리 |
| **Realtime Database** | 실시간 데이터베이스 | JSON 트리 구조, 낮은 레이턴시 |
| **Storage** | 파일 저장소 | 이미지/비디오 업로드, CDN 제공 |
| **Cloud Functions** | 서버리스 함수 | HTTP API, 트리거 함수, 백그라운드 작업 |
| **Cloud Messaging (FCM)** | 푸시 알림 | 토픽 구독, 타겟팅, 데이터 메시지 |
| **Crashlytics** | 에러 리포팅 | 실시간 크래시 추적, 사용자 영향 분석 |
| **Analytics** | 사용자 분석 | 이벤트 추적, 전환율, 사용자 여정 |
| **Remote Config** | 동적 설정 | A/B 테스트, 피처 플래그 |
| **Performance Monitoring** | 성능 모니터링 | 앱 시작 시간, 네트워크 요청 분석 |

### 1.3 사용 시나리오

**소셜 미디어 앱**
- Authentication: 사용자 로그인/회원가입
- Firestore: 게시글, 댓글, 좋아요 데이터
- Storage: 프로필 이미지, 게시글 미디어
- FCM: 새 댓글/좋아요 알림
- Analytics: 사용자 행동 분석

**채팅 앱**
- Authentication: 사용자 인증
- Firestore: 실시간 메시지 동기화
- Storage: 첨부 파일, 이미지
- FCM: 메시지 푸시 알림
- Crashlytics: 앱 안정성 모니터링

**전자상거래 앱**
- Authentication: 사용자 계정 관리
- Firestore: 제품 카탈로그, 주문 내역
- Cloud Functions: 결제 처리, 주문 확인 이메일
- Remote Config: 프로모션 배너, 할인율
- Analytics: 구매 전환율, 장바구니 이탈률

---

## 2. 프로젝트 설정

### 2.1 FlutterFire CLI 설정

```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트 초기화
flutterfire configure

# 특정 플랫폼만 설정
flutterfire configure --platforms=ios,android
```

### 2.2 pubspec.yaml 의존성 (2026년 기준)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase Core
  firebase_core: ^3.1.0

  # Firebase Services
  firebase_auth: ^5.1.0
  cloud_firestore: ^5.0.1
  firebase_storage: ^12.0.1
  cloud_functions: ^5.0.1
  firebase_messaging: ^15.0.1
  firebase_crashlytics: ^4.0.1
  firebase_analytics: ^11.0.1
  firebase_remote_config: ^5.0.1

  # State Management & DI
  flutter_bloc: ^9.1.1
  injectable: ^2.5.0
  get_it: ^9.2.0

  # Functional Programming
  fpdart: ^1.2.0
  freezed_annotation: ^3.1.0

  # Code Generation
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.15
  freezed: ^3.2.4
  json_serializable: ^6.9.5
  injectable_generator: ^2.7.0
```

### 2.3 firebase_options.dart 생성

`flutterfire configure` 실행 시 자동 생성됩니다:

```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:web:...',
    messagingSenderId: '123456789',
    projectId: 'my-project',
    authDomain: 'my-project.firebaseapp.com',
    storageBucket: 'my-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:android:...',
    messagingSenderId: '123456789',
    projectId: 'my-project',
    storageBucket: 'my-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:ios:...',
    messagingSenderId: '123456789',
    projectId: 'my-project',
    storageBucket: 'my-project.appspot.com',
    iosBundleId: 'com.example.app',
  );
}
```

### 2.4 멀티 환경 설정 (dev/staging/prod)

```dart
// lib/firebase_options_dev.dart
class DevFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:android:...',
    messagingSenderId: '123456789',
    projectId: 'my-project-dev',
    storageBucket: 'my-project-dev.appspot.com',
  );
}

// lib/firebase_options_prod.dart
class ProdFirebaseOptions {
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...',
    appId: '1:123456789:android:...',
    messagingSenderId: '123456789',
    projectId: 'my-project-prod',
    storageBucket: 'my-project-prod.appspot.com',
  );
}

// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  final firebaseOptions = env == 'prod'
      ? prod.ProdFirebaseOptions.android
      : dev.DevFirebaseOptions.android;

  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const MyApp());
}
```

**빌드 명령어:**
```bash
# Development
flutter run --dart-define=ENV=dev

# Production
flutter run --dart-define=ENV=prod
flutter build apk --dart-define=ENV=prod
```

---

## 3. Firebase Authentication

### 3.1 이메일/패스워드 인증

#### 3.1.1 Domain Layer

```dart
// core/core_firebase/lib/src/domain/entities/user_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    required bool emailVerified,
  }) = _UserEntity;
}
```

```dart
// core/core_firebase/lib/src/domain/repositories/auth_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/user_entity.dart';
import '../failures/auth_failure.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Either<AuthFailure, void>> signOut();

  Future<Either<AuthFailure, void>> sendPasswordResetEmail(String email);

  Future<Either<AuthFailure, void>> sendEmailVerification();

  Stream<Option<UserEntity>> get authStateChanges;

  Option<UserEntity> get currentUser;
}
```

```dart
// core/core_firebase/lib/src/domain/failures/auth_failure.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_failure.freezed.dart';

@freezed
class AuthFailure with _$AuthFailure {
  const factory AuthFailure.invalidEmail() = _InvalidEmail;
  const factory AuthFailure.weakPassword() = _WeakPassword;
  const factory AuthFailure.userNotFound() = _UserNotFound;
  const factory AuthFailure.wrongPassword() = _WrongPassword;
  const factory AuthFailure.emailAlreadyInUse() = _EmailAlreadyInUse;
  const factory AuthFailure.networkError() = _NetworkError;
  const factory AuthFailure.unknown(String message) = _Unknown;
}
```

#### 3.1.2 Data Layer

```dart
// core/core_firebase/lib/src/data/repositories/firebase_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository(this._firebaseAuth);

  @override
  Future<Either<AuthFailure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return left(const AuthFailure.unknown('User is null'));
      }

      return right(_mapFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return left(const AuthFailure.unknown('User is null'));
      }

      // Update display name if provided
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return right(_mapFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return right(null);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return right(null);
    } on FirebaseAuthException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return left(const AuthFailure.unknown('No user signed in'));
      }
      await user.sendEmailVerification();
      return right(null);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Stream<Option<UserEntity>> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      return user != null ? some(_mapFirebaseUser(user)) : none();
    });
  }

  @override
  Option<UserEntity> get currentUser {
    final user = _firebaseAuth.currentUser;
    return user != null ? some(_mapFirebaseUser(user)) : none();
  }

  UserEntity _mapFirebaseUser(User user) {
    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  AuthFailure _mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure.invalidEmail();
      case 'weak-password':
        return const AuthFailure.weakPassword();
      case 'user-not-found':
        return const AuthFailure.userNotFound();
      case 'wrong-password':
        return const AuthFailure.wrongPassword();
      case 'email-already-in-use':
        return const AuthFailure.emailAlreadyInUse();
      case 'network-request-failed':
        return const AuthFailure.networkError();
      default:
        return AuthFailure.unknown(e.message ?? e.code);
    }
  }
}
```

### 3.2 Google 로그인

```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.1.5
```

```dart
// core/core_firebase/lib/src/data/repositories/firebase_auth_repository.dart
import 'package:google_sign_in/google_sign_in.dart';

@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository(
    this._firebaseAuth,
    this._googleSignIn,
  );

  Future<Either<AuthFailure, UserEntity>> signInWithGoogle() async {
    try {
      // Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return left(const AuthFailure.unknown('Google sign in cancelled'));
      }

      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        return left(const AuthFailure.unknown('User is null'));
      }

      return right(_mapFirebaseUser(user));
    } on FirebaseAuthException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }
}
```

### 3.3 Apple 로그인

```yaml
# pubspec.yaml
dependencies:
  sign_in_with_apple: ^5.0.0
```

```dart
// core/core_firebase/lib/src/data/repositories/firebase_auth_repository.dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

Future<Either<AuthFailure, UserEntity>> signInWithApple() async {
  try {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = userCredential.user;

    if (user == null) {
      return left(const AuthFailure.unknown('User is null'));
    }

    // Update display name from Apple if available
    if (appleCredential.givenName != null || appleCredential.familyName != null) {
      final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      await user.updateDisplayName(displayName);
      await user.reload();
    }

    return right(_mapFirebaseUser(user));
  } on FirebaseAuthException catch (e) {
    return left(_mapFirebaseException(e));
  } catch (e) {
    return left(AuthFailure.unknown(e.toString()));
  }
}
```

### 3.4 토큰 관리

```dart
// core/core_firebase/lib/src/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  // ... 기존 메서드들

  Future<Either<AuthFailure, String>> getIdToken({bool forceRefresh = false});
}

// core/core_firebase/lib/src/data/repositories/firebase_auth_repository.dart
@override
Future<Either<AuthFailure, String>> getIdToken({bool forceRefresh = false}) async {
  try {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return left(const AuthFailure.unknown('No user signed in'));
    }

    final token = await user.getIdToken(forceRefresh);
    if (token == null) {
      return left(const AuthFailure.unknown('Token is null'));
    }

    return right(token);
  } catch (e) {
    return left(AuthFailure.unknown(e.toString()));
  }
}
```

---

## 4. Cloud Firestore

### 4.1 컬렉션/문서 구조

```
users (collection)
  └─ {userId} (document)
      ├─ email: String
      ├─ displayName: String
      ├─ photoUrl: String
      ├─ createdAt: Timestamp
      └─ posts (subcollection)
          └─ {postId} (document)
              ├─ title: String
              ├─ content: String
              ├─ createdAt: Timestamp
              └─ likes: Number
```

### 4.2 CRUD 작업

#### 4.2.1 Domain Layer

```dart
// core/core_firebase/lib/src/domain/entities/post_entity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_entity.freezed.dart';

@freezed
class PostEntity with _$PostEntity {
  const factory PostEntity({
    required String id,
    required String userId,
    required String title,
    required String content,
    required DateTime createdAt,
    required int likes,
    String? imageUrl,
  }) = _PostEntity;
}
```

```dart
// core/core_firebase/lib/src/domain/repositories/post_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/post_entity.dart';
import '../failures/firestore_failure.dart';

abstract class PostRepository {
  Future<Either<FirestoreFailure, void>> createPost(PostEntity post);
  Future<Either<FirestoreFailure, PostEntity>> getPost(String postId);
  Future<Either<FirestoreFailure, List<PostEntity>>> getUserPosts(String userId);
  Future<Either<FirestoreFailure, void>> updatePost(PostEntity post);
  Future<Either<FirestoreFailure, void>> deletePost(String postId);
  Stream<Either<FirestoreFailure, List<PostEntity>>> watchUserPosts(String userId);
}
```

#### 4.2.2 Data Layer

```dart
// core/core_firebase/lib/src/data/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/post_entity.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

@freezed
class PostModel with _$PostModel {
  const PostModel._();

  const factory PostModel({
    required String id,
    required String userId,
    required String title,
    required String content,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required DateTime createdAt,
    required int likes,
    String? imageUrl,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel.fromJson({...data, 'id': doc.id});
  }

  PostEntity toEntity() {
    return PostEntity(
      id: id,
      userId: userId,
      title: title,
      content: content,
      createdAt: createdAt,
      likes: likes,
      imageUrl: imageUrl,
    );
  }

  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      createdAt: entity.createdAt,
      likes: entity.likes,
      imageUrl: entity.imageUrl,
    );
  }

  static DateTime _timestampFromJson(Timestamp timestamp) =>
      timestamp.toDate();

  static Timestamp _timestampToJson(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);
}
```

```dart
// core/core_firebase/lib/src/data/repositories/firestore_post_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/failures/firestore_failure.dart';
import '../../domain/repositories/post_repository.dart';
import '../models/post_model.dart';

@LazySingleton(as: PostRepository)
class FirestorePostRepository implements PostRepository {
  final FirebaseFirestore _firestore;

  FirestorePostRepository(this._firestore);

  CollectionReference get _postsCollection => _firestore.collection('posts');

  @override
  Future<Either<FirestoreFailure, void>> createPost(PostEntity post) async {
    try {
      final model = PostModel.fromEntity(post);
      await _postsCollection.doc(post.id).set(model.toJson());
      return right(null);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FirestoreFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<FirestoreFailure, PostEntity>> getPost(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();

      if (!doc.exists) {
        return left(const FirestoreFailure.notFound());
      }

      final model = PostModel.fromFirestore(doc);
      return right(model.toEntity());
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FirestoreFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<FirestoreFailure, List<PostEntity>>> getUserPosts(
    String userId,
  ) async {
    try {
      final querySnapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final posts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc).toEntity())
          .toList();

      return right(posts);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FirestoreFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<FirestoreFailure, void>> updatePost(PostEntity post) async {
    try {
      final model = PostModel.fromEntity(post);
      await _postsCollection.doc(post.id).update(model.toJson());
      return right(null);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FirestoreFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<FirestoreFailure, void>> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FirestoreFailure.unknown(e.toString()));
    }
  }

  @override
  Stream<Either<FirestoreFailure, List<PostEntity>>> watchUserPosts(
    String userId,
  ) {
    return _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      try {
        final posts = snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc).toEntity())
            .toList();
        return right<FirestoreFailure, List<PostEntity>>(posts);
      } catch (e) {
        return left<FirestoreFailure, List<PostEntity>>(
          FirestoreFailure.unknown(e.toString()),
        );
      }
    })
    // ⚠️ 주의: handleError의 콜백은 void를 반환하므로 아래 return left(...) 값은
    // 실제로 스트림에 전달되지 않습니다. 실제 프로젝트에서는 StreamTransformer를
    // 사용하거나 .map() 내부에서 try-catch로 에러를 Either.left로 변환해야 합니다.
    .handleError((error) {
      if (error is FirebaseException) {
        return left<FirestoreFailure, List<PostEntity>>(
          _mapFirebaseException(error),
        );
      }
      return left<FirestoreFailure, List<PostEntity>>(
        FirestoreFailure.unknown(error.toString()),
      );
    });
  }

  FirestoreFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const FirestoreFailure.permissionDenied();
      case 'not-found':
        return const FirestoreFailure.notFound();
      case 'unavailable':
        return const FirestoreFailure.unavailable();
      default:
        return FirestoreFailure.unknown(e.message ?? e.code);
    }
  }
}
```

### 4.3 복합 쿼리

```dart
// core/core_firebase/lib/src/domain/repositories/post_repository.dart
abstract class PostRepository {
  // ... 기존 메서드들

  Future<Either<FirestoreFailure, List<PostEntity>>> getPopularPosts({
    required int minLikes,
    required int limit,
  });

  Future<Either<FirestoreFailure, List<PostEntity>>> searchPostsByTitle(
    String query,
  );
}

// core/core_firebase/lib/src/data/repositories/firestore_post_repository.dart
@override
Future<Either<FirestoreFailure, List<PostEntity>>> getPopularPosts({
  required int minLikes,
  required int limit,
}) async {
  try {
    final querySnapshot = await _postsCollection
        .where('likes', isGreaterThanOrEqualTo: minLikes)
        .orderBy('likes', descending: true)
        .limit(limit)
        .get();

    final posts = querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc).toEntity())
        .toList();

    return right(posts);
  } on FirebaseException catch (e) {
    return left(_mapFirebaseException(e));
  } catch (e) {
    return left(FirestoreFailure.unknown(e.toString()));
  }
}

@override
Future<Either<FirestoreFailure, List<PostEntity>>> searchPostsByTitle(
  String query,
) async {
  try {
    // Firestore는 full-text search를 지원하지 않으므로
    // title이 query로 시작하는 문서만 검색 가능
    final querySnapshot = await _postsCollection
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: '$query\uf8ff')
        .orderBy('title')
        .get();

    final posts = querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc).toEntity())
        .toList();

    return right(posts);
  } on FirebaseException catch (e) {
    return left(_mapFirebaseException(e));
  } catch (e) {
    return left(FirestoreFailure.unknown(e.toString()));
  }
}
```

### 4.4 실시간 스냅샷 with Bloc

```dart
// features/posts/presentation/bloc/posts_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/core_firebase/lib/core_firebase.dart';

part 'posts_event.dart';
part 'posts_state.dart';
part 'posts_bloc.freezed.dart';

// ⚠️ 주의: DI.md 가이드에서는 Bloc을 GetIt에 등록하지 않을 것을 권장합니다.
// 실제 프로젝트에서는 BlocProvider를 통해 Bloc을 제공하세요.
// 이 예제는 Firebase 연동 패턴 학습용으로만 참고하세요.
@injectable
class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostRepository _postRepository;
  StreamSubscription? _postsSubscription;

  PostsBloc(this._postRepository) : super(const PostsState.initial()) {
    on<PostsEvent>((event, emit) async {
      await event.map(
        watchUserPosts: (e) => _onWatchUserPosts(e, emit),
        postsReceived: (e) => _onPostsReceived(e, emit),
      );
    });
  }

  Future<void> _onWatchUserPosts(
    _WatchUserPosts event,
    Emitter<PostsState> emit,
  ) async {
    emit(const PostsState.loading());

    await _postsSubscription?.cancel();

    _postsSubscription = _postRepository
        .watchUserPosts(event.userId)
        .listen((either) {
      add(PostsEvent.postsReceived(either));
    });
  }

  Future<void> _onPostsReceived(
    _PostsReceived event,
    Emitter<PostsState> emit,
  ) async {
    event.either.fold(
      (failure) => emit(PostsState.error(failure)),
      (posts) => emit(PostsState.loaded(posts)),
    );
  }

  @override
  Future<void> close() {
    _postsSubscription?.cancel();
    return super.close();
  }
}
```

---

## 5. Firebase Storage

### 5.1 파일 업로드/다운로드

```dart
// core/core_firebase/lib/src/domain/repositories/storage_repository.dart
import 'dart:io';
import 'package:fpdart/fpdart.dart';
import '../failures/storage_failure.dart';

abstract class StorageRepository {
  Future<Either<StorageFailure, String>> uploadFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  });

  Future<Either<StorageFailure, String>> getDownloadUrl(String path);

  Future<Either<StorageFailure, void>> deleteFile(String path);
}
```

```dart
// core/core_firebase/lib/src/data/repositories/firebase_storage_repository.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../domain/failures/storage_failure.dart';
import '../../domain/repositories/storage_repository.dart';

@LazySingleton(as: StorageRepository)
class FirebaseStorageRepository implements StorageRepository {
  final FirebaseStorage _storage;

  FirebaseStorageRepository(this._storage);

  @override
  Future<Either<StorageFailure, String>> uploadFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      // Monitor upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return right(downloadUrl);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(StorageFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, String>> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();
      return right(url);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(StorageFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, void>> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(StorageFailure.unknown(e.toString()));
    }
  }

  StorageFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        return const StorageFailure.notFound();
      case 'unauthorized':
        return const StorageFailure.unauthorized();
      case 'quota-exceeded':
        return const StorageFailure.quotaExceeded();
      default:
        return StorageFailure.unknown(e.message ?? e.code);
    }
  }
}
```

### 5.2 진행률 모니터링 with Bloc

```dart
// features/upload/presentation/bloc/upload_bloc.dart
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/core_firebase/lib/core_firebase.dart';

part 'upload_event.dart';
part 'upload_state.dart';
part 'upload_bloc.freezed.dart';

// ⚠️ 주의: DI.md 가이드에서는 Bloc을 GetIt에 등록하지 않을 것을 권장합니다.
// 실제 프로젝트에서는 BlocProvider를 통해 Bloc을 제공하세요.
// 이 예제는 Firebase 연동 패턴 학습용으로만 참고하세요.
@injectable
class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final StorageRepository _storageRepository;

  UploadBloc(this._storageRepository) : super(const UploadState.initial()) {
    on<UploadEvent>((event, emit) async {
      await event.map(
        uploadFile: (e) => _onUploadFile(e, emit),
      );
    });
  }

  Future<void> _onUploadFile(
    _UploadFile event,
    Emitter<UploadState> emit,
  ) async {
    emit(const UploadState.uploading(0.0));

    final result = await _storageRepository.uploadFile(
      file: event.file,
      path: event.path,
      onProgress: (progress) {
        emit(UploadState.uploading(progress));
      },
    );

    result.fold(
      (failure) => emit(UploadState.error(failure)),
      (url) => emit(UploadState.success(url)),
    );
  }
}

// Widget에서 사용
BlocBuilder<UploadBloc, UploadState>(
  builder: (context, state) {
    return state.maybeMap(
      uploading: (state) => LinearProgressIndicator(
        value: state.progress,
      ),
      success: (state) => Text('Uploaded: ${state.url}'),
      error: (state) => Text('Error: ${state.failure}'),
      orElse: () => ElevatedButton(
        onPressed: () {
          context.read<UploadBloc>().add(
            UploadEvent.uploadFile(
              file: selectedFile,
              path: 'uploads/${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          );
        },
        child: const Text('Upload'),
      ),
    );
  },
)
```

### 5.3 이미지 리사이징 (Cloud Functions 연동)

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const sharp = require('sharp');
const path = require('path');
const os = require('os');
const fs = require('fs-extra');

admin.initializeApp();

exports.generateThumbnail = functions.storage.object().onFinalize(async (object) => {
  const filePath = object.name;
  const contentType = object.contentType;
  const bucket = admin.storage().bucket(object.bucket);

  if (!contentType.startsWith('image/')) {
    return null;
  }

  if (filePath.includes('_thumb')) {
    return null;
  }

  const fileName = path.basename(filePath);
  const tempFilePath = path.join(os.tmpdir(), fileName);
  const thumbFileName = `${path.parse(fileName).name}_thumb${path.parse(fileName).ext}`;
  const thumbFilePath = path.join(path.dirname(filePath), thumbFileName);
  const tempThumbPath = path.join(os.tmpdir(), thumbFileName);

  await bucket.file(filePath).download({ destination: tempFilePath });

  await sharp(tempFilePath)
    .resize(200, 200, { fit: 'cover' })
    .toFile(tempThumbPath);

  await bucket.upload(tempThumbPath, {
    destination: thumbFilePath,
    metadata: { contentType: contentType },
  });

  await fs.remove(tempFilePath);
  await fs.remove(tempThumbPath);

  return null;
});
```

---

## 6. Cloud Functions

### 6.1 HTTP Functions

```dart
// core/core_firebase/lib/src/domain/repositories/functions_repository.dart
import 'package:fpdart/fpdart.dart';
import '../failures/functions_failure.dart';

abstract class FunctionsRepository {
  Future<Either<FunctionsFailure, Map<String, dynamic>>> callFunction({
    required String name,
    Map<String, dynamic>? parameters,
  });
}
```

```dart
// core/core_firebase/lib/src/data/repositories/firebase_functions_repository.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../domain/failures/functions_failure.dart';
import '../../domain/repositories/functions_repository.dart';

@LazySingleton(as: FunctionsRepository)
class FirebaseFunctionsRepository implements FunctionsRepository {
  final FirebaseFunctions _functions;

  FirebaseFunctionsRepository(this._functions);

  @override
  Future<Either<FunctionsFailure, Map<String, dynamic>>> callFunction({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final callable = _functions.httpsCallable(name);
      final result = await callable.call(parameters);

      return right(result.data as Map<String, dynamic>);
    } on FirebaseFunctionsException catch (e) {
      return left(_mapFirebaseException(e));
    } catch (e) {
      return left(FunctionsFailure.unknown(e.toString()));
    }
  }

  FunctionsFailure _mapFirebaseException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return const FunctionsFailure.notFound();
      case 'unauthenticated':
        return const FunctionsFailure.unauthenticated();
      case 'permission-denied':
        return const FunctionsFailure.permissionDenied();
      case 'deadline-exceeded':
        return const FunctionsFailure.timeout();
      default:
        return FunctionsFailure.unknown(e.message ?? e.code);
    }
  }
}
```

### 6.2 Callable Functions 예제

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendWelcomeEmail = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { email, displayName } = data;

  // Validate input
  if (!email || !displayName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email and displayName are required'
    );
  }

  try {
    // Send email logic here
    console.log(`Sending welcome email to ${email}`);

    return {
      success: true,
      message: `Welcome email sent to ${displayName}`,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

```dart
// Flutter에서 호출
final result = await functionsRepository.callFunction(
  name: 'sendWelcomeEmail',
  parameters: {
    'email': 'user@example.com',
    'displayName': 'John Doe',
  },
);

result.fold(
  (failure) => print('Error: $failure'),
  (data) => print('Success: ${data['message']}'),
);
```

---

## 7. Firebase Cloud Messaging (FCM)

### 7.1 푸시 알림 설정

#### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

#### Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application>
    <!-- ... -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="high_importance_channel" />
  </application>
</manifest>
```

### 7.2 FCM 초기화 및 토큰 관리

```dart
// core/core_firebase/lib/src/data/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

@lazySingleton
class FCMService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  FCMService(
    this._messaging,
    this._localNotifications,
  );

  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel (Android)
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    // Navigate to specific screen based on message data
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap
  }
}
```

### 7.3 서버에서 FCM 전송

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.sendNotificationOnNewPost = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snapshot, context) => {
    const post = snapshot.data();
    const postId = context.params.postId;

    const message = {
      notification: {
        title: 'New Post',
        body: post.title,
      },
      data: {
        postId: postId,
        type: 'new_post',
      },
      topic: 'all_users',
    };

    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
```

---

## 8. Firebase Crashlytics

### 8.1 에러 리포팅

```dart
// lib/main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics 초기화
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}
```

### 8.2 커스텀 키 및 비치명적 에러

```dart
// core/core_firebase/lib/src/data/services/crashlytics_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService(this._crashlytics);

  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(exception, stack, fatal: fatal);
  }
}

// 사용 예제
class SomeRepository {
  final CrashlyticsService _crashlytics;

  Future<void> someMethod() async {
    try {
      await _crashlytics.log('Starting someMethod');
      await _crashlytics.setCustomKey('method_name', 'someMethod');

      // Risky operation
      await riskyOperation();

    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, fatal: false);
      rethrow;
    }
  }
}
```

---

## 9. Firebase Analytics

### 9.1 이벤트 로깅

```dart
// core/core_firebase/lib/src/data/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setCurrentScreen({
    required String screenName,
    String? screenClassOverride,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClassOverride,
    );
  }

  // Predefined events
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logPurchase({
    required String currency,
    required double value,
    String? transactionId,
    List<AnalyticsEventItem>? items,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: value,
      transactionId: transactionId,
      items: items,
    );
  }

  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method,
    );
  }
}
```

### 9.2 사용자 속성 및 스크린 추적

```dart
// features/auth/presentation/bloc/auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AnalyticsService _analytics;

  Future<void> _onSignIn(
    _SignIn event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.signInWithEmailPassword(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthState.error(failure)),
      (user) async {
        await _analytics.setUserId(user.uid);
        await _analytics.setUserProperty(name: 'email', value: user.email);
        await _analytics.logLogin('email');
        emit(AuthState.authenticated(user));
      },
    );
  }
}

// lib/app.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final analyticsService = getIt<AnalyticsService>();

    return MaterialApp(
      navigatorObservers: [
        analyticsService.observer, // Auto screen tracking
      ],
      // ...
    );
  }
}
```

---

## 10. Security Rules

### 10.1 Firestore Security Rules

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    function hasValidData() {
      return request.resource.data.keys().hasAll(['title', 'content', 'createdAt']);
    }

    // Users collection
    match /users/{userId} {
      allow read: if isSignedIn();
      allow create: if isOwner(userId) && hasValidData();
      allow update, delete: if isOwner(userId);
    }

    // Posts collection
    match /posts/{postId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn()
        && hasValidData()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.title.size() <= 100
        && request.resource.data.content.size() <= 10000;

      allow update: if isOwner(resource.data.userId)
        && hasValidData()
        && request.resource.data.userId == resource.data.userId; // Cannot change owner

      allow delete: if isOwner(resource.data.userId);
    }

    // Comments subcollection
    match /posts/{postId}/comments/{commentId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn()
        && request.resource.data.userId == request.auth.uid;
      allow update, delete: if isOwner(resource.data.userId);
    }
  }
}
```

### 10.2 Storage Security Rules

```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isImageFile() {
      return request.resource.contentType.matches('image/.*');
    }

    function isUnder10MB() {
      return request.resource.size < 10 * 1024 * 1024;
    }

    // User profile images
    match /users/{userId}/profile.jpg {
      allow read: if true; // Public read
      allow write: if isSignedIn()
        && request.auth.uid == userId
        && isImageFile()
        && isUnder10MB();
    }

    // Post images
    match /posts/{postId}/{imageId} {
      allow read: if true;
      allow write: if isSignedIn()
        && isImageFile()
        && isUnder10MB();
      allow delete: if isSignedIn();
    }

    // Private user files
    match /users/{userId}/private/{allPaths=**} {
      allow read, write: if isSignedIn() && request.auth.uid == userId;
    }
  }
}
```

---

## 11. Clean Architecture 연동

### 11.1 프로젝트 구조

```
lib/
├── core/
│   └── core_firebase/
│       ├── lib/
│       │   ├── src/
│       │   │   ├── domain/
│       │   │   │   ├── entities/
│       │   │   │   │   ├── user_entity.dart
│       │   │   │   │   └── post_entity.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   ├── auth_repository.dart
│       │   │   │   │   ├── post_repository.dart
│       │   │   │   │   └── storage_repository.dart
│       │   │   │   └── failures/
│       │   │   │       ├── auth_failure.dart
│       │   │   │       ├── firestore_failure.dart
│       │   │   │       └── storage_failure.dart
│       │   │   ├── data/
│       │   │   │   ├── models/
│       │   │   │   │   ├── post_model.dart
│       │   │   │   │   └── user_model.dart
│       │   │   │   ├── repositories/
│       │   │   │   │   ├── firebase_auth_repository.dart
│       │   │   │   │   ├── firestore_post_repository.dart
│       │   │   │   │   └── firebase_storage_repository.dart
│       │   │   │   └── services/
│       │   │   │       ├── fcm_service.dart
│       │   │   │       ├── analytics_service.dart
│       │   │   │       └── crashlytics_service.dart
│       │   │   └── di/
│       │   │       └── firebase_module.dart
│       │   └── core_firebase.dart
│       └── pubspec.yaml
└── features/
    ├── auth/
    │   └── presentation/
    │       └── bloc/
    │           └── auth_bloc.dart
    └── posts/
        └── presentation/
            └── bloc/
                └── posts_bloc.dart
```

### 11.2 Dependency Injection 설정

```dart
// core/core_firebase/lib/src/di/firebase_module.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseModule {
  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  FirebaseFirestore get firebaseFirestore => FirebaseFirestore.instance;

  @lazySingleton
  FirebaseStorage get firebaseStorage => FirebaseStorage.instance;

  @lazySingleton
  FirebaseFunctions get firebaseFunctions => FirebaseFunctions.instance;

  @lazySingleton
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;

  @lazySingleton
  FirebaseCrashlytics get firebaseCrashlytics => FirebaseCrashlytics.instance;

  @lazySingleton
  FirebaseAnalytics get firebaseAnalytics => FirebaseAnalytics.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn();

  @lazySingleton
  FlutterLocalNotificationsPlugin get localNotifications =>
      FlutterLocalNotificationsPlugin();
}
```

```dart
// lib/di/injection.config.dart (auto-generated)
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  configureDependencies();

  // Initialize services
  await getIt<FCMService>().initialize();

  runApp(const MyApp());
}
```

---

## 12. 오프라인 지원

### 12.1 Firestore 영속성 활성화

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}
```

### 12.2 네트워크 상태 처리

```dart
// core/core_firebase/lib/src/data/repositories/firestore_post_repository.dart
@override
Future<Either<FirestoreFailure, List<PostEntity>>> getUserPosts(
  String userId,
) async {
  try {
    final querySnapshot = await _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.cache)) // Try cache first
        .catchError((error) {
      // Fallback to server if cache fails
      return _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
    });

    final posts = querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc).toEntity())
        .toList();

    return right(posts);
  } on FirebaseException catch (e) {
    if (e.code == 'unavailable') {
      // Return cached data if network is unavailable
      return _getCachedPosts(userId);
    }
    return left(_mapFirebaseException(e));
  } catch (e) {
    return left(FirestoreFailure.unknown(e.toString()));
  }
}

Future<Either<FirestoreFailure, List<PostEntity>>> _getCachedPosts(
  String userId,
) async {
  try {
    final querySnapshot = await _postsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get(const GetOptions(source: Source.cache));

    final posts = querySnapshot.docs
        .map((doc) => PostModel.fromFirestore(doc).toEntity())
        .toList();

    return right(posts);
  } catch (e) {
    return left(const FirestoreFailure.unavailable());
  }
}
```

---

## 13. 테스트

### 13.1 Firebase Emulator Suite 설정

```bash
# Emulator 설치
firebase init emulators

# Emulator 시작
firebase emulators:start
```

```json
// firebase.json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "functions": {
      "port": 5001
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### 13.2 테스트 환경 설정

```dart
// test/helpers/test_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> setupFirebaseEmulators() async {
  await Firebase.initializeApp();

  // Connect to emulators
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}

Future<void> clearFirestoreData() async {
  final firestore = FirebaseFirestore.instance;
  final collections = await firestore.listCollections();

  for (final collection in collections) {
    final docs = await collection.get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }
}
```

### 13.3 Repository 단위 테스트

```dart
// test/core/data/repositories/firebase_auth_repository_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../../../helpers/test_firebase.dart';

void main() {
  late FirebaseAuthRepository repository;
  late FirebaseAuth mockAuth;

  setUpAll(() async {
    await setupFirebaseEmulators();
  });

  setUp(() {
    mockAuth = FirebaseAuth.instance;
    repository = FirebaseAuthRepository(mockAuth);
  });

  tearDown(() async {
    await mockAuth.signOut();
  });

  group('signUpWithEmailPassword', () {
    test('should create new user successfully', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const displayName = 'Test User';

      // Act
      final result = await repository.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (user) {
          expect(user.email, email);
          expect(user.displayName, displayName);
        },
      );
    });

    test('should return emailAlreadyInUse failure when email exists', () async {
      // Arrange
      const email = 'existing@example.com';
      const password = 'password123';

      // Create user first
      await repository.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      // Act - Try to create again
      final result = await repository.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, const AuthFailure.emailAlreadyInUse());
        },
        (user) => fail('Should fail'),
      );
    });
  });
}
```

---

## 14. Best Practices

### 14.1 Do/Don't 테이블

| 구분 | Do | Don't |
|------|-----|-------|
| **인증** | 이메일 인증 강제 | 인증 없이 민감한 데이터 접근 |
| **Firestore** | Batch write 사용 (다중 작업) | 개별 write 반복 실행 |
| **쿼리** | 복합 인덱스 생성 | 인덱스 없이 복합 쿼리 |
| **Storage** | 진행률 콜백 제공 | 대용량 파일 업로드 시 UI 피드백 없음 |
| **Security Rules** | 최소 권한 원칙 | 모든 데이터 public 설정 |
| **오프라인** | 영속성 활성화 | 네트워크 에러 무시 |
| **에러 처리** | Either/Result 패턴 사용 | try-catch만 사용 |
| **테스트** | Emulator 사용 | Production 데이터로 테스트 |

### 14.2 비용 최적화

#### Firestore 읽기 최적화

```dart
// ❌ Bad: 모든 문서를 읽고 클라이언트에서 필터링
final allPosts = await _postsCollection.get();
final filteredPosts = allPosts.docs
    .where((doc) => doc.data()['likes'] > 100)
    .toList();

// ✅ Good: 서버 사이드 쿼리로 필터링
final popularPosts = await _postsCollection
    .where('likes', isGreaterThan: 100)
    .get();
```

#### Batch 작업 사용

```dart
// ❌ Bad: 개별 작업 반복
for (final post in posts) {
  await _postsCollection.doc(post.id).set(post.toJson());
}

// ✅ Good: Batch write
final batch = _firestore.batch();
for (final post in posts) {
  final ref = _postsCollection.doc(post.id);
  batch.set(ref, post.toJson());
}
await batch.commit();
```

#### 실시간 리스너 제한

```dart
// ❌ Bad: 불필요한 리스너 유지
class PostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: postsRepository.watchAllPosts(), // 모든 포스트 구독
      // ...
    );
  }
}

// ✅ Good: 필요한 데이터만 구독
class PostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: postsRepository.watchUserPosts(currentUserId), // 현재 유저만
      // ...
    );
  }
}
```

### 14.3 보안 체크리스트

- [ ] 모든 Firestore 컬렉션에 Security Rules 적용
- [ ] Storage에 파일 크기/타입 제한 설정
- [ ] 민감한 API 키는 환경변수로 관리
- [ ] 클라이언트에서 직접 관리자 권한 작업 금지
- [ ] Cloud Functions에서 인증 확인 필수
- [ ] HTTPS만 허용 (HTTP 비활성화)
- [ ] Rate limiting 설정 (Functions)
- [ ] 사용자 입력 데이터 검증

### 14.4 성능 체크리스트

- [ ] Firestore 복합 쿼리에 인덱스 생성
- [ ] 이미지 업로드 전 리사이징
- [ ] 무한 스크롤에 pagination 적용
- [ ] 오프라인 영속성 활성화
- [ ] 불필요한 실시간 리스너 제거
- [ ] Batch write 사용 (대량 작업)
- [ ] 캐시 우선 전략 적용
- [ ] 네트워크 상태 감지 및 처리

---

## 참고 자료

| 리소스 | URL |
|--------|-----|
| **FlutterFire 공식 문서** | https://firebase.flutter.dev/ |
| **Firebase Console** | https://console.firebase.google.com/ |
| **Firestore Security Rules** | https://firebase.google.com/docs/firestore/security/get-started |
| **Firebase Emulator Suite** | https://firebase.google.com/docs/emulator-suite |
| **Clean Architecture** | https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html |
| **fpdart** | https://pub.dev/packages/fpdart |
| **freezed** | https://pub.dev/packages/freezed |
| **injectable** | https://pub.dev/packages/injectable |

---

**마지막 업데이트:** 2026-02-06

---

## 실습 과제

### 과제 1: Firebase Auth 로그인 구현
이메일/비밀번호와 Google 소셜 로그인을 Firebase Auth로 구현하고, 인증 상태에 따라 화면을 전환하세요.

### 과제 2: Firestore 실시간 CRUD
Firestore 컬렉션에 게시글을 CRUD하고, snapshots()으로 실시간 데이터 동기화를 구현하세요.

### 과제 3: Cloud Storage 이미지 업로드
사용자 프로필 이미지를 Firebase Cloud Storage에 업로드하고, 다운로드 URL을 Firestore에 저장하세요.

## Self-Check

- [ ] Firebase 프로젝트 초기화와 플랫폼별 설정(google-services.json, GoogleService-Info.plist)을 완료할 수 있는가?
- [ ] Firebase Auth의 인증 상태 스트림을 Bloc과 연동할 수 있는가?
- [ ] Firestore Security Rules를 작성하여 데이터 접근을 제어할 수 있는가?
- [ ] FCM으로 포그라운드/백그라운드 푸시 알림을 처리할 수 있는가?
- [ ] Crashlytics로 비정상 종료를 모니터링하고 분석할 수 있는가?
