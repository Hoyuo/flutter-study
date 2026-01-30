# Flutter 푸시 알림 가이드 (FCM + Local Notification)

## 개요

Firebase Cloud Messaging(FCM)과 flutter_local_notifications를 조합하여 푸시 알림을 구현합니다. FCM은 서버에서 클라이언트로 메시지를 전송하고, flutter_local_notifications는 로컬에서 알림을 표시하고 커스터마이징합니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^4.4.0
  firebase_messaging: ^16.0.4
  flutter_local_notifications: ^19.5.0
```

### Migration Notes (firebase_messaging v15 → v16)

**firebase_messaging v16.0.4 (Latest Stable):**
- Deprecated functions 제거
- iOS SDK 12.0.0으로 업그레이드 (breaking)
- Android SDK 34.0.0으로 업그레이드 (breaking)
- iOS 18 알림 처리 및 scene delegate 지원 개선

**flutter_local_notifications v19.5.0 (Stable Recommended):**
- 안정적인 프로덕션 사용 권장
- Android 14 완전 지원
- iOS 17 호환성 보장

> **참고**: flutter_local_notifications v20.0.0은 아직 개발 버전(dev)입니다. 프로덕션 환경에서는 v19.5.0 사용을 권장합니다.

### Firebase 프로젝트 설정

1. Firebase Console에서 프로젝트 생성
2. iOS/Android 앱 추가
3. `google-services.json` (Android), `GoogleService-Info.plist` (iOS) 다운로드

### Android 설정

```kotlin
// android/build.gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

```kotlin
// android/app/build.gradle
plugins {
    id 'com.google.gms.google-services'
}

android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- FCM 권한 -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application>
        <!-- FCM 기본 채널 -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />

        <!-- FCM 아이콘 (선택) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />

        <!-- FCM 색상 (선택) -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

### iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

Xcode에서:
1. Target > Signing & Capabilities
2. "+ Capability" 클릭
3. "Push Notifications" 추가
4. "Background Modes" 추가 → "Remote notifications" 체크

### APNs 인증 키 설정 (iOS)

1. Apple Developer > Certificates, Identifiers & Profiles
2. Keys > Create a Key > Enable "Apple Push Notifications service (APNs)"
3. 키 다운로드 (.p8 파일)
4. Firebase Console > Project Settings > Cloud Messaging > iOS app configuration
5. APNs Authentication Key 업로드

## 초기화

### Firebase 및 알림 초기화

```dart
// lib/core/notification/notification_service.dart
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';  // for debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // print 대신 적절한 로깅
  debugPrint('[FCM] Background message: ${message.messageId}');
  // 또는 Crashlytics 로깅
  // FirebaseCrashlytics.instance.log('Background message: ${message.messageId}');
  // 백그라운드에서 알림 표시가 필요하면 여기서 처리
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 알림 채널 (Android)
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  /// 초기화
  Future<void> initialize() async {
    // 백그라운드 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 권한 요청 (iOS, Android 13+)
    await _requestPermission();

    // Local Notifications 초기화
    await _initializeLocalNotifications();

    // Android 알림 채널 생성
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_highImportanceChannel);
    }

    // Foreground 메시지 리스너
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 알림 클릭으로 앱 열렸을 때 (terminated → opened)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 알림 클릭으로 앱 열렸을 때 (background → opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// 권한 요청
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
  }

  /// Local Notifications 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Foreground 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    // Android 특정 알림 속성 (향후 사용 예정)
    // final android = message.notification?.android;

    // Notification 메시지 처리
    if (notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
      return;
    }

    // Data-only 메시지 처리 (추가!)
    // 서버에서 notification 없이 data만 보내는 경우
    if (message.data.isNotEmpty) {
      final title = message.data['title'] as String?;
      final body = message.data['body'] as String?;

      if (title != null || body != null) {
        await _showLocalNotification(
          id: message.hashCode,
          title: title ?? '',
          body: body ?? '',
          payload: message.data.toString(),
        );
      }
    }
  }

  /// Local Notification 표시
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  /// 알림 클릭 처리
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // 딥링크 처리 등
    final data = message.data;
    if (data.containsKey('route')) {
      // Navigator 또는 GoRouter로 이동
      // context.go(data['route']);
    }
  }

  /// Local Notification 응답 처리
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    // payload 파싱하여 화면 이동 등 처리
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// 토큰 갱신 리스너
  void onTokenRefresh(void Function(String token) callback) {
    _messaging.onTokenRefresh.listen(callback);
  }

  /// 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// 테스트용: private 메서드 접근
  @visibleForTesting
  Future<void> showLocalNotificationForTest({
    required String title,
    required String body,
  }) => _showLocalNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
  );
}
```

### main.dart에서 초기화

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/notification/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // iOS foreground 알림 표시 설정 (추가 필수!)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,  // 알림 배너 표시
    badge: true,  // 앱 아이콘 배지
    sound: true,  // 알림음
  );

  // 알림 초기화
  await NotificationService().initialize();

  runApp(const MyApp());
}
```

## FCM 토큰 관리

### 토큰 저장 및 서버 전송

```dart
// lib/features/notification/data/repositories/notification_repository_impl.dart
import 'package:injectable/injectable.dart';

import '../../../../core/notification/notification_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/notification_repository.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationService _notificationService;
  final SecureStorage _secureStorage;
  final NotificationApi _api;

  NotificationRepositoryImpl(
    this._notificationService,
    this._secureStorage,
    this._api,
  );

  static const _fcmTokenKey = 'fcm_token';

  @override
  Future<void> registerToken() async {
    final token = await _notificationService.getToken();
    if (token == null) return;

    // 저장된 토큰과 비교
    final savedToken = await _secureStorage.read(_fcmTokenKey);
    if (savedToken == token) return;

    // 서버에 토큰 등록
    await _api.registerToken(token);

    // 로컬에 토큰 저장
    await _secureStorage.write(_fcmTokenKey, token);
  }

  @override
  void setupTokenRefreshListener() {
    _notificationService.onTokenRefresh((newToken) async {
      // 서버에 새 토큰 등록
      await _api.registerToken(newToken);
      await _secureStorage.write(_fcmTokenKey, newToken);
    });
  }

  @override
  Future<void> deleteToken() async {
    await _secureStorage.delete(_fcmTokenKey);
    // 서버에서 토큰 삭제 요청
    await _api.deleteToken();
  }
}
```

## 알림 유형별 처리

### 알림 데이터 모델

```dart
// lib/features/notification/domain/entities/push_notification.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_notification.freezed.dart';
part 'push_notification.g.dart';

@freezed
class PushNotification with _$PushNotification {
  const factory PushNotification({
    required String id,
    required String title,
    required String body,
    required NotificationType type,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? receivedAt,
    @Default(false) bool isRead,
  }) = _PushNotification;

  factory PushNotification.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationFromJson(json);

  factory PushNotification.fromRemoteMessage(RemoteMessage message) {
    return PushNotification(
      id: message.messageId ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: NotificationType.fromString(message.data['type']),
      imageUrl: message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      data: message.data,
      receivedAt: message.sentTime,
    );
  }
}

enum NotificationType {
  order,      // 주문 관련
  promotion,  // 프로모션
  notice,     // 공지사항
  chat,       // 채팅
  general;    // 일반

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.general,
    );
  }
}
```

### 딥링크 처리

```dart
// lib/core/notification/notification_handler.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

class NotificationHandler {
  final GoRouter _router;

  NotificationHandler(this._router);

  void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final targetId = data['target_id'];

    switch (type) {
      case 'order':
        _router.push('/orders/$targetId');
        break;
      case 'promotion':
        _router.push('/promotions/$targetId');
        break;
      case 'chat':
        _router.push('/chat/$targetId');
        break;
      case 'notice':
        _router.push('/notices/$targetId');
        break;
      default:
        _router.push('/notifications');
    }
  }
}
```

## 고급 기능

### 이미지 포함 알림

```dart
// 필요한 패키지: pubspec.yaml에 추가
// dependencies:
//   http: ^1.1.0
//   path_provider: ^2.1.0  // iOS 이미지 로컬 저장용
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<void> _showImageNotification(RemoteMessage message) async {
  final notification = message.notification;
  final imageUrl = message.data['image_url'] as String? ??
      notification?.android?.imageUrl ??
      notification?.apple?.imageUrl;

  if (imageUrl == null) {
    await _showLocalNotification(
      id: message.hashCode,
      title: notification?.title ?? '',
      body: notification?.body ?? '',
    );
    return;
  }

  try {
    // 이미지 다운로드
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      // 이미지 로드 실패 시 일반 알림으로 fallback
      await _showBasicNotification(message);
      return;
    }

    // Android: base64 문자열로 변환 (필수!)
    final base64Image = base64Encode(response.bodyBytes);
    final bigPicture = ByteArrayAndroidBitmap.fromBase64String(base64Image);

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigPictureStyleInformation(
        bigPicture,
        contentTitle: notification?.title,
        summaryText: notification?.body,
        hideExpandedLargeIcon: true,
      ),
    );

    // iOS: 로컬 파일로 저장 후 첨부 (URL 직접 전달 불가!)
    final localImagePath = await _downloadAndSaveImage(imageUrl, response.bodyBytes);

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: localImagePath != null
          ? [
              DarwinNotificationAttachment(
                localImagePath,  // 로컬 파일 경로 사용
                identifier: 'image',
              ),
            ]
          : null,
    );

    await _localNotifications.show(
      message.hashCode,
      notification?.title ?? '',
      notification?.body ?? '',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  } catch (e) {
    // 이미지 로드 실패 시 일반 알림으로 fallback
    await _showBasicNotification(message);
  }
}

/// iOS용: 이미지를 로컬 파일로 저장
Future<String?> _downloadAndSaveImage(String imageUrl, List<int> imageBytes) async {
  if (!Platform.isIOS) return null;

  try {
    // 임시 디렉토리에 저장
    final tempDir = await getTemporaryDirectory();
    final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    return file.path;
  } catch (e) {
    debugPrint('[FCM] Failed to save image: $e');
    return null;
  }
}

/// 기본 알림 표시 (이미지 없음)
Future<void> _showBasicNotification(RemoteMessage message) async {
  final notification = message.notification;
  await _showLocalNotification(
    id: message.hashCode,
    title: notification?.title ?? '',
    body: notification?.body ?? '',
    payload: jsonEncode(message.data),
  );
}
```

### 알림 그룹화 (Android)

```dart
Future<void> _showGroupedNotification({
  required int id,
  required String title,
  required String body,
  required String groupKey,
}) async {
  // 개별 알림
  final androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
    groupKey: groupKey,
  );

  await _localNotifications.show(
    id,
    title,
    body,
    NotificationDetails(android: androidDetails),
  );

  // 그룹 요약 알림
  final summaryDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
    groupKey: groupKey,
    setAsGroupSummary: true,
    groupAlertBehavior: GroupAlertBehavior.children,
  );

  await _localNotifications.show(
    0, // 그룹 요약은 고정 ID
    '새로운 알림',
    '',
    NotificationDetails(android: summaryDetails),
  );
}
```

### 예약 알림 (Local)

```dart
// timezone 패키지 필요: pubspec.yaml에 추가
// dependencies:
//   timezone: ^0.9.0
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// main()에서 초기화 필요:
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   tz.initializeTimeZones();
//   runApp(const MyApp());
// }

Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  await _localNotifications.zonedSchedule(
    id,
    title,
    body,
    tz.TZDateTime.from(scheduledDate, tz.local),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

// 예약 알림 취소
Future<void> cancelScheduledNotification(int id) async {
  await _localNotifications.cancel(id);
}

// 모든 예약 알림 취소
Future<void> cancelAllScheduledNotifications() async {
  await _localNotifications.cancelAll();
}
```

### 배지 카운트 관리

```dart
// iOS 배지 카운트 설정
Future<void> updateBadgeCount(int count) async {
  if (Platform.isIOS) {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(badge: true);

    // 직접 배지 설정은 flutter_app_badger 패키지 사용 권장
  }
}

// 배지 초기화
Future<void> clearBadge() async {
  await _localNotifications.cancelAll();
  // flutter_app_badger로 배지 카운트 0으로 설정
}
```

## Bloc 통합

### Notification Bloc

```dart
// lib/features/notification/presentation/bloc/notification_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/push_notification.dart';

part 'notification_event.freezed.dart';

@freezed
class NotificationEvent with _$NotificationEvent {
  const factory NotificationEvent.initialized() = _Initialized;
  const factory NotificationEvent.received(PushNotification notification) = _Received;
  const factory NotificationEvent.tapped(PushNotification notification) = _Tapped;
  const factory NotificationEvent.cleared() = _Cleared;
  const factory NotificationEvent.settingsChanged({
    required bool enabled,
  }) = _SettingsChanged;
}
```

```dart
// lib/features/notification/presentation/bloc/notification_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/push_notification.dart';

part 'notification_state.freezed.dart';

@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    required List<PushNotification> notifications,
    required bool isEnabled,
    required int unreadCount,
    required bool isLoading,
  }) = _NotificationState;

  factory NotificationState.initial() => const NotificationState(
        notifications: [],
        isEnabled: true,
        unreadCount: 0,
        isLoading: false,
      );
}
```

```dart
// lib/features/notification/presentation/bloc/notification_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final NotificationService _notificationService;

  NotificationBloc({
    required GetNotificationsUseCase getNotificationsUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required NotificationService notificationService,
  })  : _getNotificationsUseCase = getNotificationsUseCase,
        _markAsReadUseCase = markAsReadUseCase,
        _notificationService = notificationService,
        super(NotificationState.initial()) {
    on<NotificationEvent>((event, emit) async {
      await event.when(
        initialized: () => _onInitialized(emit),
        received: (notification) => _onReceived(notification, emit),
        tapped: (notification) => _onTapped(notification, emit),
        cleared: () => _onCleared(emit),
        settingsChanged: (enabled) => _onSettingsChanged(enabled, emit),
      );
    });
  }

  Future<void> _onInitialized(Emitter<NotificationState> emit) async {
    emit(state.copyWith(isLoading: true));

    final result = await _getNotificationsUseCase();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false)),
      (notifications) => emit(state.copyWith(
        isLoading: false,
        notifications: notifications,
        unreadCount: notifications.where((n) => !n.isRead).length,
      )),
    );
  }

  Future<void> _onReceived(
    PushNotification notification,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(
      notifications: [notification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    ));
  }

  Future<void> _onTapped(
    PushNotification notification,
    Emitter<NotificationState> emit,
  ) async {
    await _markAsReadUseCase(notification.id);

    final updated = state.notifications.map((n) {
      if (n.id == notification.id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    emit(state.copyWith(
      notifications: updated,
      unreadCount: state.unreadCount - 1,
    ));
  }

  Future<void> _onCleared(Emitter<NotificationState> emit) async {
    emit(state.copyWith(
      notifications: [],
      unreadCount: 0,
    ));
  }

  Future<void> _onSettingsChanged(
    bool enabled,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isEnabled: enabled));

    if (enabled) {
      await _notificationService.subscribeToTopic('all');
    } else {
      await _notificationService.unsubscribeFromTopic('all');
    }
  }
}
```

## 토픽 기반 알림

### 토픽 관리

```dart
// lib/features/notification/domain/usecases/manage_topics_usecase.dart
import 'package:injectable/injectable.dart';

import '../../../../core/notification/notification_service.dart';

@injectable
class ManageTopicsUseCase {
  final NotificationService _notificationService;

  ManageTopicsUseCase(this._notificationService);

  /// 국가별 토픽 구독
  Future<void> subscribeCountryTopic(String countryCode) async {
    await _notificationService.subscribeToTopic('country_$countryCode');
  }

  /// 카테고리별 토픽 구독
  Future<void> subscribeCategoryTopic(String category) async {
    await _notificationService.subscribeToTopic('category_$category');
  }

  /// 전체 알림 구독
  Future<void> subscribeAll() async {
    await _notificationService.subscribeToTopic('all');
  }

  /// 마케팅 알림 구독
  Future<void> subscribeMarketing() async {
    await _notificationService.subscribeToTopic('marketing');
  }

  /// 마케팅 알림 구독 해제
  Future<void> unsubscribeMarketing() async {
    await _notificationService.unsubscribeFromTopic('marketing');
  }
}
```

### 알림 설정 화면

```dart
// lib/features/notification/presentation/pages/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('푸시 알림'),
                subtitle: const Text('모든 푸시 알림을 받습니다'),
                value: state.isEnabled,
                onChanged: (value) {
                  context.read<NotificationBloc>().add(
                        NotificationEvent.settingsChanged(enabled: value),
                      );
                },
              ),
              const Divider(),
              const ListTile(
                title: Text(
                  '알림 종류',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _NotificationTypeTile(
                title: '주문 알림',
                subtitle: '주문 상태 변경 알림',
                topic: 'orders',
              ),
              _NotificationTypeTile(
                title: '프로모션',
                subtitle: '할인 및 이벤트 알림',
                topic: 'marketing',
              ),
              _NotificationTypeTile(
                title: '공지사항',
                subtitle: '서비스 공지사항 알림',
                topic: 'notices',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTypeTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String topic;

  const _NotificationTypeTile({
    required this.title,
    required this.subtitle,
    required this.topic,
  });

  @override
  State<_NotificationTypeTile> createState() => _NotificationTypeTileState();
}

class _NotificationTypeTileState extends State<_NotificationTypeTile> {
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      subtitle: Text(widget.subtitle),
      value: _isEnabled,
      onChanged: (value) async {
        setState(() => _isEnabled = value);

        final service = NotificationService();
        if (value) {
          await service.subscribeToTopic(widget.topic);
        } else {
          await service.unsubscribeFromTopic(widget.topic);
        }
      },
    );
  }
}
```

## 11. FCM 메시지 유형 이해 (중요!)

### 11.1 메시지 유형 비교

| 항목 | Notification Message | Data Message |
|-----|---------------------|--------------|
| 페이로드 | `notification: {...}` | `data: {...}` |
| Foreground | `onMessage` 호출 | `onMessage` 호출 |
| Background | **시스템이 자동 표시** | `onBackgroundMessage` 호출 |
| Terminated | **시스템이 자동 표시** | `onBackgroundMessage` 호출 |
| 커스터마이징 | 제한적 | 완전한 제어 |
| 권장 용도 | 단순 알림 | 복잡한 로직 필요 시 |

### 11.2 서버 페이로드 예시

```json
// Notification Message (시스템이 처리)
{
  "message": {
    "token": "device_token",
    "notification": {
      "title": "새 메시지",
      "body": "John님이 메시지를 보냈습니다"
    }
  }
}

// Data Message (앱이 처리)
{
  "message": {
    "token": "device_token",
    "data": {
      "type": "new_message",
      "sender_id": "123",
      "sender_name": "John",
      "message_preview": "안녕하세요..."
    }
  }
}

// 혼합 메시지 (주의 필요!)
{
  "message": {
    "token": "device_token",
    "notification": {
      "title": "새 메시지",
      "body": "John님이 메시지를 보냈습니다"
    },
    "data": {
      "chat_id": "456",
      "sender_id": "123"
    }
  }
}
```

### 11.3 앱 상태별 동작

```
┌─────────────────────────────────────────────────────────────────┐
│                    FCM 메시지 수신 흐름                          │
├─────────────────┬───────────────────┬───────────────────────────┤
│ 앱 상태          │ Notification Msg  │ Data Message              │
├─────────────────┼───────────────────┼───────────────────────────┤
│ Foreground      │ onMessage ✓       │ onMessage ✓               │
│                 │ 알림 표시 안됨     │ 알림 표시 안됨             │
├─────────────────┼───────────────────┼───────────────────────────┤
│ Background      │ 시스템 알림 표시   │ onBackgroundMessage ✓     │
│                 │ onMessage 안됨 ❌  │ 직접 알림 표시 필요        │
├─────────────────┼───────────────────┼───────────────────────────┤
│ Terminated      │ 시스템 알림 표시   │ onBackgroundMessage ✓     │
│                 │ 탭 시 initial msg │ 직접 알림 표시 필요        │
└─────────────────┴───────────────────┴───────────────────────────┘
```

### 11.4 Data Message 처리 (권장 패턴)

```dart
// 백그라운드 핸들러 (top-level 함수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // Data Message인 경우 직접 알림 표시
  if (message.notification == null && message.data.isNotEmpty) {
    await _showLocalNotification(message);
  }
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final data = message.data;

  final notification = NotificationDetails(
    android: AndroidNotificationDetails(
      'data_channel',
      'Data Notifications',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    data['title'] ?? '알림',
    data['body'] ?? '',
    notification,
    payload: jsonEncode(data),
  );
}
```

### 11.5 권장사항

| 상황 | 권장 메시지 유형 |
|-----|----------------|
| 단순 알림 (프로모션, 공지) | Notification Message |
| 채팅 앱 | Data Message (읽음 상태, 뱃지 업데이트) |
| Silent Push (데이터 동기화) | Data Message (content_available: true) |
| 커스텀 알림 UI | Data Message |
| 알림 그룹핑 | Data Message |

### 11.6 흔한 실수

```dart
// ❌ 잘못된 예: Notification Message를 Background에서 처리하려 함
void setupFCM() {
  FirebaseMessaging.onBackgroundMessage(_handler);
}

Future<void> _handler(RemoteMessage message) async {
  // Notification Message는 여기서 호출되지 않음!
  print(message.notification?.title); // null일 수 있음
}

// ✅ 올바른 예: Data Message 사용
Future<void> _handler(RemoteMessage message) async {
  final data = message.data;
  print(data['title']); // 항상 접근 가능
  await _showLocalNotification(message);
}
```

## 테스트

### 알림 테스트 (Firebase Console)

1. Firebase Console > Cloud Messaging
2. "Send your first message" 클릭
3. 제목, 본문 입력
4. Target: 앱 선택 또는 토픽 지정
5. "Review" → "Publish"

### 로컬 테스트

```dart
// 테스트용 알림 발송
Future<void> testLocalNotification() async {
  final service = NotificationService();
  await service._showLocalNotification(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: '테스트 알림',
    body: '이것은 테스트 알림입니다.',
    payload: '{"type": "test", "target_id": "123"}',
  );
}
```

### Mock NotificationService

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService mockService;
  late NotificationBloc bloc;

  setUp(() {
    mockService = MockNotificationService();
    bloc = NotificationBloc(
      getNotificationsUseCase: MockGetNotificationsUseCase(),
      markAsReadUseCase: MockMarkAsReadUseCase(),
      notificationService: mockService,
    );
  });

  blocTest<NotificationBloc, NotificationState>(
    'should subscribe to topic when settings enabled',
    build: () {
      when(() => mockService.subscribeToTopic('all'))
          .thenAnswer((_) async {});
      return bloc;
    },
    act: (bloc) => bloc.add(const NotificationEvent.settingsChanged(enabled: true)),
    verify: (_) {
      verify(() => mockService.subscribeToTopic('all')).called(1);
    },
  );
}
```

## 체크리스트

- [ ] Firebase 프로젝트 설정 및 SDK 추가
- [ ] firebase_messaging, flutter_local_notifications 설치
- [ ] Android: google-services.json 추가, AndroidManifest 권한 설정
- [ ] iOS: GoogleService-Info.plist 추가, APNs 설정, Capabilities 추가
- [ ] NotificationService 구현 (초기화, 권한, 메시지 핸들러)
- [ ] FCM 토큰 관리 (저장, 서버 전송, 갱신)
- [ ] Foreground 알림 표시 (flutter_local_notifications)
- [ ] 알림 클릭 딥링크 처리
- [ ] 토픽 기반 알림 구독/해제
- [ ] 알림 설정 UI 구현
- [ ] 백그라운드 메시지 핸들러 구현
- [ ] 이미지 알림 지원 (필요시)
- [ ] 예약 알림 지원 (필요시)
