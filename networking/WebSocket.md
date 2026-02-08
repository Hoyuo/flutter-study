# Flutter WebSocket & 실시간 통신 가이드

> **난이도**: 고급 | **카테고리**: networking | **작성 기준**: 2026년 2월
> **선행 학습**: [Networking_Dio](./Networking_Dio.md) | **예상 학습 시간**: 2h

> Flutter에서 WebSocket과 Socket.IO를 사용한 실시간 양방향 통신 구현 가이드입니다. Clean Architecture, Bloc 패턴, fpdart의 Either를 활용한 실전 예제를 포함합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - WebSocket과 Socket.IO를 사용한 실시간 양방향 통신을 구현할 수 있다
> - 연결 관리, 재접속 전략, 에러 처리를 Clean Architecture로 설계할 수 있다
> - Bloc 패턴과 fpdart를 활용한 실시간 데이터 흐름을 관리할 수 있다

## 목차
1. [개요](#1-개요)
2. [프로젝트 설정](#2-프로젝트-설정)
3. [기본 WebSocket 연결](#3-기본-websocket-연결)
4. [WebSocket 클라이언트 구현](#4-websocket-클라이언트-구현)
5. [Socket.IO 클라이언트](#5-socketio-클라이언트)
6. [메시지 프로토콜 설계](#6-메시지-프로토콜-설계)
7. [Stream 기반 데이터 처리](#7-stream-기반-데이터-처리)
8. [Bloc 연동](#8-bloc-연동)
9. [오프라인 지원](#9-오프라인-지원)
10. [채팅 앱 구현 예제](#10-채팅-앱-구현-예제)
11. [보안](#11-보안)
12. [성능 최적화](#12-성능-최적화)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

---

## 1. 개요

### 1.1 WebSocket이란?

WebSocket은 단일 TCP 연결을 통해 클라이언트와 서버 간의 **전이중(full-duplex) 양방향 통신**을 가능하게 하는 프로토콜입니다.

**주요 특징:**
- 지속적인 연결 유지 (persistent connection)
- 낮은 지연시간 (low latency)
- 양방향 실시간 데이터 전송
- HTTP 핸드셰이크 후 프로토콜 업그레이드

### 1.2 HTTP vs WebSocket 비교

| 특성 | HTTP | WebSocket |
|------|------|-----------|
| 연결 방식 | 요청/응답 (Request/Response) | 양방향 스트림 (Bidirectional Stream) |
| 연결 유지 | 단기 (요청마다 새 연결) | 장기 (지속적 연결) |
| 오버헤드 | 높음 (매 요청마다 헤더) | 낮음 (초기 핸드셰이크 후) |
| 실시간성 | 폴링 필요 | 네이티브 실시간 |
| 용도 | RESTful API, 문서 전송 | 채팅, 알림, 게임, 주식 시세 |

### 1.3 실시간 통신 옵션 비교

| 기술 | 설명 | 장점 | 단점 | 사용 사례 |
|------|------|------|------|-----------|
| **WebSocket** | 양방향 지속 연결 | 낮은 지연, 양방향 | 인프라 복잡도 | 채팅, 게임, 협업 도구 |
| **SSE** (Server-Sent Events) | 서버→클라이언트 단방향 | 간단, HTTP 기반 | 단방향만 가능 | 알림, 뉴스피드 |
| **Long Polling** | HTTP 요청 유지 | 방화벽 친화적 | 높은 서버 부하 | 레거시 시스템 |
| **Socket.IO** | WebSocket + 폴백 | 자동 재연결, 룸 | 무거움 | 복잡한 실시간 앱 |

---

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
name: chat_app
description: WebSocket 실시간 채팅 앱
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # WebSocket & 실시간 통신
  web_socket_channel: ^3.0.2      # 기본 WebSocket 클라이언트
  socket_io_client: ^3.1.4         # Socket.IO 클라이언트

  # 상태 관리 & 아키텍처
  flutter_bloc: ^9.1.1
  bloc_concurrency: ^0.3.0

  # 의존성 주입
  get_it: ^9.2.0
  injectable: ^2.7.1

  # 함수형 프로그래밍
  fpdart: ^1.2.0

  # 코드 생성
  freezed_annotation: ^3.1.0
  json_annotation: ^4.10.0

  # 유틸리티
  logger: ^2.6.2
  connectivity_plus: ^7.0.0        # 네트워크 상태 확인
  shared_preferences: ^2.5.4       # 로컬 저장소
  rxdart: ^0.28.0                  # Reactive Extensions (BehaviorSubject 등)
  battery_plus: ^6.1.0             # 배터리 상태 확인

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드 생성
  build_runner: ^2.11.0
  freezed: ^3.2.5
  json_serializable: ^6.12.0
  injectable_generator: ^2.12.0

  # 테스트
  mocktail: ^1.0.4
  bloc_test: ^10.0.0
```

### 2.2 프로젝트 구조

```
lib/
├── core/
│   └── core_network/
│       ├── websocket/
│       │   ├── websocket_client.dart          # WebSocket 클라이언트 인터페이스
│       │   ├── websocket_client_impl.dart     # 구현체
│       │   ├── websocket_config.dart          # 설정
│       │   ├── websocket_exception.dart       # 예외 처리
│       │   └── socketio/
│       │       ├── socketio_client.dart       # Socket.IO 클라이언트
│       │       └── socketio_event.dart        # 이벤트 타입
│       └── di/
│           └── network_module.dart            # 의존성 주입
├── features/
│   └── chat/
│       ├── data/
│       │   ├── models/
│       │   │   ├── message_model.dart         # Freezed 메시지 모델
│       │   │   └── chat_event_model.dart      # 채팅 이벤트 모델
│       │   ├── datasources/
│       │   │   └── chat_remote_datasource.dart
│       │   └── repositories/
│       │       └── chat_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── message.dart
│       │   ├── repositories/
│       │   │   └── chat_repository.dart
│       │   └── usecases/
│       │       ├── send_message.dart
│       │       └── subscribe_messages.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── chat_bloc.dart
│           │   ├── chat_event.dart
│           │   └── chat_state.dart
│           └── pages/
│               └── chat_page.dart
└── main.dart
```

---

## 3. 기본 WebSocket 연결

### 3.1 web_socket_channel 사용

```dart
// core/core_network/lib/src/websocket/basic_websocket_example.dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class BasicWebSocketExample {
  WebSocketChannel? _channel;

  /// WebSocket 연결
  void connect(String url) {
    try {
      // ws:// 또는 wss:// (TLS) 사용
      _channel = WebSocketChannel.connect(
        Uri.parse(url),
      );

      debugPrint('WebSocket 연결 성공: $url');

      // 메시지 수신 리스닝
      _channel!.stream.listen(
        (message) {
          debugPrint('수신: $message');
        },
        onError: (error) {
          debugPrint('에러: $error');
        },
        onDone: () {
          debugPrint('연결 종료됨');
        },
      );
    } catch (e) {
      debugPrint('연결 실패: $e');
    }
  }

  /// 메시지 전송
  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
      debugPrint('전송: $message');
    } else {
      debugPrint('연결되지 않음');
    }
  }

  /// 연결 종료
  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _channel = null;
    debugPrint('연결 종료');
  }
}

// 사용 예제
void main() {
  final ws = BasicWebSocketExample();

  // 연결
  ws.connect('wss://ws.postman-echo.com/raw'); // echo.websocket.org는 서비스 종료됨

  // 메시지 전송
  Future.delayed(Duration(seconds: 1), () {
    ws.sendMessage('Hello WebSocket!');
  });

  // 3초 후 종료
  Future.delayed(Duration(seconds: 3), () {
    ws.disconnect();
  });
}
```

### 3.2 연결 상태 모니터링

```dart
// core/core_network/lib/src/websocket/connection_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_state.freezed.dart';

@freezed
class ConnectionState with _$ConnectionState {
  const factory ConnectionState.disconnected() = _Disconnected;
  const factory ConnectionState.connecting() = _Connecting;
  const factory ConnectionState.connected() = _Connected;
  const factory ConnectionState.reconnecting({
    required int attempt,
    required int maxAttempts,
  }) = _Reconnecting;
  const factory ConnectionState.failed({
    required String reason,
  }) = _Failed;
}
```

---

## 4. WebSocket 클라이언트 구현

### 4.1 WebSocket 설정

```dart
// core/core_network/lib/src/websocket/websocket_config.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_config.freezed.dart';
part 'websocket_config.g.dart';

@freezed
class WebSocketConfig with _$WebSocketConfig {
  const factory WebSocketConfig({
    required String url,
    @Default(5000) int pingInterval,           // 핑 주기 (ms)
    @Default(10000) int connectionTimeout,     // 연결 타임아웃 (ms)
    @Default(3) int maxReconnectAttempts,      // 최대 재연결 시도
    @Default(1000) int reconnectDelay,         // 재연결 지연 (ms)
    @Default(2.0) double reconnectBackoff,     // 재연결 백오프 배수
    @Default({}) Map<String, String> headers,  // 커스텀 헤더
  }) = _WebSocketConfig;

  factory WebSocketConfig.fromJson(Map<String, dynamic> json) =>
      _$WebSocketConfigFromJson(json);
}
```

### 4.2 WebSocket 클라이언트 인터페이스

```dart
// core/core_network/lib/src/websocket/websocket_client.dart
import 'package:fpdart/fpdart.dart';
import 'websocket_exception.dart';
import 'connection_state.dart';

abstract class WebSocketClient {
  /// 연결 상태 스트림
  Stream<ConnectionState> get connectionState;

  /// 메시지 수신 스트림
  Stream<String> get messages;

  /// 현재 연결 여부
  bool get isConnected;

  /// WebSocket 연결
  Future<Either<WebSocketException, void>> connect();

  /// 메시지 전송
  Either<WebSocketException, void> send(String message);

  /// 연결 종료
  Future<void> disconnect();

  /// 재연결
  Future<Either<WebSocketException, void>> reconnect();
}
```

### 4.3 WebSocket 클라이언트 구현체

```dart
// core/core_network/lib/src/websocket/websocket_client_impl.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';
import 'websocket_client.dart';
import 'websocket_config.dart';
import 'websocket_exception.dart';
import 'connection_state.dart';

class WebSocketClientImpl implements WebSocketClient {
  final WebSocketConfig config;
  final Logger logger;

  WebSocketChannel? _channel;
  StreamController<ConnectionState>? _connectionStateController;
  StreamController<String>? _messagesController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _manualDisconnect = false;

  WebSocketClientImpl({
    required this.config,
    required this.logger,
  }) {
    _connectionStateController = StreamController<ConnectionState>.broadcast();
    _messagesController = StreamController<String>.broadcast();
  }

  @override
  Stream<ConnectionState> get connectionState =>
      _connectionStateController!.stream;

  @override
  Stream<String> get messages => _messagesController!.stream;

  @override
  bool get isConnected => _channel != null;

  @override
  Future<Either<WebSocketException, void>> connect() async {
    try {
      _manualDisconnect = false;
      _emitState(const ConnectionState.connecting());

      logger.i('WebSocket 연결 시작: ${config.url}');

      _channel = WebSocketChannel.connect(
        Uri.parse(config.url),
        // 커스텀 헤더 추가 (인증 토큰 등)
      );

      // 연결 타임아웃 처리
      await _channel!.ready.timeout(
        Duration(milliseconds: config.connectionTimeout),
        onTimeout: () {
          throw TimeoutException('연결 타임아웃');
        },
      );

      _setupListeners();
      _startPingTimer();
      _reconnectAttempts = 0;

      _emitState(const ConnectionState.connected());
      logger.i('WebSocket 연결 성공');

      return right(null);
    } catch (e) {
      logger.e('WebSocket 연결 실패: $e');
      _emitState(ConnectionState.failed(reason: e.toString()));
      return left(WebSocketException.connection(e.toString()));
    }
  }

  void _setupListeners() {
    _channel!.stream.listen(
      (message) {
        logger.d('수신: $message');
        _messagesController!.add(message.toString());
      },
      onError: (error) {
        logger.e('WebSocket 에러: $error');
        _handleError(error);
      },
      onDone: () {
        logger.w('WebSocket 연결 종료됨');
        _handleDisconnection();
      },
      cancelOnError: false,
    );
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(milliseconds: config.pingInterval),
      (_) {
        if (isConnected) {
          send('ping'); // 또는 서버 프로토콜에 맞는 핑 메시지
        }
      },
    );
  }

  void _handleError(dynamic error) {
    _emitState(ConnectionState.failed(reason: error.toString()));
    if (!_manualDisconnect) {
      _attemptReconnect();
    }
  }

  void _handleDisconnection() {
    _cleanup();
    if (!_manualDisconnect) {
      _attemptReconnect();
    } else {
      _emitState(const ConnectionState.disconnected());
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      logger.e('최대 재연결 시도 횟수 초과');
      _emitState(const ConnectionState.failed(
        reason: '최대 재연결 시도 횟수 초과',
      ));
      return;
    }

    _reconnectAttempts++;
    _emitState(ConnectionState.reconnecting(
      attempt: _reconnectAttempts,
      maxAttempts: config.maxReconnectAttempts,
    ));

    final delay = config.reconnectDelay *
        math.pow(config.reconnectBackoff, _reconnectAttempts - 1);

    logger.i('재연결 시도 $_reconnectAttempts/${config.maxReconnectAttempts} '
        '(${delay.toInt()}ms 후)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: delay.toInt()),
      () => connect(),
    );
  }

  @override
  Future<Either<WebSocketException, void>> reconnect() async {
    await disconnect();
    _reconnectAttempts = 0;
    return connect();
  }

  @override
  Either<WebSocketException, void> send(String message) {
    if (!isConnected) {
      return left(const WebSocketException.notConnected());
    }

    try {
      _channel!.sink.add(message);
      logger.d('전송: $message');
      return right(null);
    } catch (e) {
      logger.e('메시지 전송 실패: $e');
      return left(WebSocketException.send(e.toString()));
    }
  }

  @override
  Future<void> disconnect() async {
    _manualDisconnect = true;
    _cleanup();
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    _emitState(const ConnectionState.disconnected());
    logger.i('WebSocket 연결 종료');
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _emitState(ConnectionState state) {
    if (!_connectionStateController!.isClosed) {
      _connectionStateController!.add(state);
    }
  }

  void dispose() {
    disconnect();
    _connectionStateController?.close();
    _messagesController?.close();
  }
}
```

### 4.4 WebSocket 예외 처리

```dart
// core/core_network/lib/src/websocket/websocket_exception.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_exception.freezed.dart';

@freezed
class WebSocketException with _$WebSocketException implements Exception {
  const factory WebSocketException.connection(String message) = _Connection;
  const factory WebSocketException.notConnected() = _NotConnected;
  const factory WebSocketException.send(String message) = _Send;
  const factory WebSocketException.timeout() = _Timeout;
  const factory WebSocketException.unknown(String message) = _Unknown;
}
```

---

## 5. Socket.IO 클라이언트

### 5.1 Socket.IO 기본 사용

```dart
// core/core_network/lib/src/websocket/socketio/socketio_client.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';

class SocketIOClient {
  final String url;
  final Logger logger;

  IO.Socket? _socket;

  SocketIOClient({
    required this.url,
    required this.logger,
  });

  void connect({
    Map<String, dynamic>? auth,
    String? namespace,
  }) {
    final uri = namespace != null ? '$url/$namespace' : url;

    _socket = IO.io(
      uri,
      IO.OptionBuilder()
          .setTransports(['websocket'])  // WebSocket만 사용 (polling 비활성화)
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(10000)
          .setAuth(auth ?? {})           // 인증 데이터
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    // 연결 이벤트
    _socket!.onConnect((_) {
      logger.i('Socket.IO 연결됨: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      logger.w('Socket.IO 연결 종료됨');
    });

    _socket!.onConnectError((error) {
      logger.e('Socket.IO 연결 에러: $error');
    });

    _socket!.onError((error) {
      logger.e('Socket.IO 에러: $error');
    });

    // 재연결 이벤트
    _socket!.onReconnect((attempt) {
      logger.i('Socket.IO 재연결 성공 (시도: $attempt)');
    });

    _socket!.onReconnectAttempt((attempt) {
      logger.i('Socket.IO 재연결 시도 중: $attempt');
    });

    _socket!.onReconnectFailed((_) {
      logger.e('Socket.IO 재연결 실패');
    });
  }

  /// 이벤트 수신
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  /// 이벤트 전송
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// ACK와 함께 전송 (응답 콜백)
  void emitWithAck(
    String event,
    dynamic data,
    Function(dynamic) ack,
  ) {
    _socket?.emitWithAck(event, data, ack: ack);
  }

  /// 룸(Room) 참가
  void joinRoom(String roomId) {
    emit('join_room', {'roomId': roomId});
  }

  /// 룸 나가기
  void leaveRoom(String roomId) {
    emit('leave_room', {'roomId': roomId});
  }

  /// 연결 종료
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;
}
```

### 5.2 Socket.IO 채팅 클라이언트 예제

```dart
// features/chat/data/datasources/chat_socketio_datasource.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message_model.dart';

class ChatSocketIODataSource {
  final String serverUrl;
  IO.Socket? _socket;

  final StreamController<MessageModel> _messageController =
      StreamController.broadcast();
  final StreamController<bool> _typingController =
      StreamController.broadcast();

  Stream<MessageModel> get messages => _messageController.stream;
  Stream<bool> get typing => _typingController.stream;

  ChatSocketIODataSource({required this.serverUrl});

  void connect(String userId, String token) {
    _socket = IO.io(
      '$serverUrl/chat',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
            'token': token,
            'userId': userId,
          })
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('채팅 서버 연결됨');
    });

    // 메시지 수신
    _socket!.on('message', (data) {
      final message = MessageModel.fromJson(data);
      _messageController.add(message);
    });

    // 타이핑 상태 수신
    _socket!.on('user_typing', (data) {
      _typingController.add(data['isTyping'] as bool);
    });

    // 메시지 읽음 확인
    _socket!.on('message_read', (data) {
      // 메시지 읽음 상태 업데이트
    });
  }

  void joinChatRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void sendMessage(String roomId, String text) {
    _socket?.emitWithAck('send_message', {
      'roomId': roomId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    }, (response) {
      // 서버 응답 처리 (메시지 전송 확인)
      debugPrint('메시지 전송 확인: $response');
    });
  }

  void sendTypingStatus(String roomId, bool isTyping) {
    _socket?.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _messageController.close();
    _typingController.close();
  }
}
```

---

## 6. 메시지 프로토콜 설계

### 6.1 메시지 타입 정의

```dart
// features/chat/data/models/chat_event_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_event_model.freezed.dart';
part 'chat_event_model.g.dart';

enum MessageType {
  text,
  image,
  file,
  system,
}

enum EventType {
  message,
  typing,
  read,
  userJoined,
  userLeft,
  error,
}

@freezed
class ChatEventModel with _$ChatEventModel {
  const factory ChatEventModel({
    required EventType type,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
    String? userId,
  }) = _ChatEventModel;

  factory ChatEventModel.fromJson(Map<String, dynamic> json) =>
      _$ChatEventModelFromJson(json);
}
```

### 6.2 메시지 모델

```dart
// features/chat/data/models/message_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'chat_event_model.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String roomId,
    required String senderId,
    required String text,
    required MessageType type,
    required DateTime timestamp,
    @Default(false) bool isRead,
    @Default(false) bool isSent,
    String? replyToId,              // 답장 메시지 ID
    Map<String, dynamic>? metadata, // 파일 URL, 이미지 URL 등
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

@freezed
class SendMessageRequest with _$SendMessageRequest {
  const factory SendMessageRequest({
    required String roomId,
    required String text,
    required MessageType type,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) = _SendMessageRequest;

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
}
```

### 6.3 타입 안전한 메시지 파싱

```dart
// core/core_network/lib/src/websocket/message_parser.dart
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:logger/logger.dart';

class MessageParser<T> {
  final Logger logger;
  final T Function(Map<String, dynamic>) fromJson;

  MessageParser({
    required this.logger,
    required this.fromJson,
  });

  /// JSON 문자열을 타입 안전하게 파싱
  Either<Exception, T> parse(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final result = fromJson(json);
      return right(result);
    } on FormatException catch (e) {
      logger.e('JSON 파싱 실패: $e');
      return left(e);
    } on TypeError catch (e) {
      logger.e('타입 변환 실패: $e');
      return left(e);
    } catch (e) {
      logger.e('알 수 없는 파싱 에러: $e');
      return left(Exception(e.toString()));
    }
  }

  /// Stream 변환
  Stream<T> parseStream(Stream<String> input) {
    return input
        .map(parse)
        // ⚠️ 주의: getRight().toNullable()!는 강제 언래핑 안티패턴입니다.
        // 실제 프로젝트에서는 fold() 또는 match()를 사용하세요:
        // either.fold((l) => throw l, (r) => r)
        .where((either) => either.isRight())
        .map((either) => either.getRight().toNullable()!)
        .handleError((error) {
      logger.e('스트림 파싱 에러: $error');
    });
  }
}

// 사용 예제
class ChatMessageParser extends MessageParser<MessageModel> {
  ChatMessageParser(Logger logger)
      : super(
          logger: logger,
          fromJson: MessageModel.fromJson,
        );
}
```

---

## 7. Stream 기반 데이터 처리

### 7.1 StreamController 활용

```dart
// core/core_network/lib/src/websocket/websocket_stream_manager.dart
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class WebSocketStreamManager<T> {
  final StreamController<T> _inputController;
  final StreamController<T> _outputController;

  Stream<T> get output => _outputController.stream;

  WebSocketStreamManager({
    bool broadcast = true,
  })  : _inputController = StreamController<T>(),
        _outputController = broadcast
            ? StreamController<T>.broadcast()
            : StreamController<T>();

  /// 메시지 추가
  void add(T message) {
    if (!_inputController.isClosed) {
      _inputController.add(message);
    }
  }

  /// 에러 추가
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_inputController.isClosed) {
      _inputController.addError(error, stackTrace);
    }
  }

  /// Stream 변환 적용
  void pipe(Stream<T> Function(Stream<T>) transformer) {
    transformer(_inputController.stream).listen(
      (data) => _outputController.add(data),
      onError: (error, stackTrace) => _outputController.addError(error, stackTrace),
      onDone: () => _outputController.close(),
    );
  }

  void dispose() {
    _inputController.close();
    _outputController.close();
  }
}
```

### 7.2 StreamTransformer로 메시지 필터링

```dart
// features/chat/data/transformers/message_transformers.dart
import 'dart:async';
import '../models/message_model.dart';

class MessageTransformers {
  /// 특정 룸의 메시지만 필터링
  static StreamTransformer<MessageModel, MessageModel> filterByRoom(
    String roomId,
  ) {
    return StreamTransformer.fromHandlers(
      handleData: (message, sink) {
        if (message.roomId == roomId) {
          sink.add(message);
        }
      },
    );
  }

  /// 읽지 않은 메시지만 필터링
  static StreamTransformer<MessageModel, MessageModel> unreadOnly() {
    return StreamTransformer.fromHandlers(
      handleData: (message, sink) {
        if (!message.isRead) {
          sink.add(message);
        }
      },
    );
  }

  /// 중복 메시지 제거 (ID 기준)
  static StreamTransformer<MessageModel, MessageModel> distinct() {
    final seen = <String>{};
    return StreamTransformer.fromHandlers(
      handleData: (message, sink) {
        if (!seen.contains(message.id)) {
          seen.add(message.id);
          sink.add(message);
        }
      },
    );
  }

  /// 시간 윈도우로 그룹핑 (배치 처리)
  static StreamTransformer<MessageModel, List<MessageModel>> bufferTime(
    Duration duration,
  ) {
    return StreamTransformer.fromHandlers(
      handleData: (message, sink) {
        // RxDart의 bufferTime 사용 권장
      },
    );
  }
}

// 사용 예제
Stream<MessageModel> processMessages(Stream<MessageModel> input, String roomId) {
  return input
      .transform(MessageTransformers.filterByRoom(roomId))
      .transform(MessageTransformers.distinct())
      .transform(MessageTransformers.unreadOnly());
}
```

### 7.3 BroadcastStream 활용

```dart
// features/chat/data/datasources/chat_stream_datasource.dart
import 'dart:async';
import '../models/message_model.dart';
import 'package:rxdart/rxdart.dart';

class ChatStreamDataSource {
  final BehaviorSubject<List<MessageModel>> _messagesSubject;
  final PublishSubject<MessageModel> _newMessageSubject;

  Stream<List<MessageModel>> get messages => _messagesSubject.stream;
  Stream<MessageModel> get newMessages => _newMessageSubject.stream;

  List<MessageModel> get currentMessages => _messagesSubject.value;

  ChatStreamDataSource()
      : _messagesSubject = BehaviorSubject.seeded([]),
        _newMessageSubject = PublishSubject();

  void addMessage(MessageModel message) {
    final updated = [...currentMessages, message];
    _messagesSubject.add(updated);
    _newMessageSubject.add(message);
  }

  void updateMessage(String messageId, MessageModel updatedMessage) {
    final updated = currentMessages.map((msg) {
      return msg.id == messageId ? updatedMessage : msg;
    }).toList();
    _messagesSubject.add(updated);
  }

  void markAsRead(String messageId) {
    updateMessage(
      messageId,
      currentMessages
          .firstWhere((m) => m.id == messageId)
          .copyWith(isRead: true),
    );
  }

  void clear() {
    _messagesSubject.add([]);
  }

  void dispose() {
    _messagesSubject.close();
    _newMessageSubject.close();
  }
}
```

---

## 8. Bloc 연동

### 8.1 Chat Bloc 구현

```dart
// features/chat/presentation/bloc/chat_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';

part 'chat_event.freezed.dart';

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.connected() = _Connected;
  const factory ChatEvent.disconnected() = _Disconnected;
  const factory ChatEvent.messageReceived(Message message) = _MessageReceived;
  const factory ChatEvent.sendMessage(String text) = _SendMessage;
  const factory ChatEvent.joinRoom(String roomId) = _JoinRoom;
  const factory ChatEvent.leaveRoom() = _LeaveRoom;
  const factory ChatEvent.typingStarted() = _TypingStarted;
  const factory ChatEvent.typingStopped() = _TypingStopped;
}
```

```dart
// features/chat/presentation/bloc/chat_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/core_network/websocket/connection_state.dart';

part 'chat_state.freezed.dart';

@freezed
class ChatState with _$ChatState {
  const factory ChatState({
    required ConnectionState connectionState,
    required List<Message> messages,
    required String? currentRoomId,
    @Default(false) bool isTyping,
    @Default(false) bool isSending,
    String? error,
  }) = _ChatState;

  factory ChatState.initial() => const ChatState(
        connectionState: ConnectionState.disconnected(),
        messages: [],
        currentRoomId: null,
      );
}
```

```dart
// features/chat/presentation/bloc/chat_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/subscribe_messages.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage _sendMessage;
  final SubscribeMessages _subscribeMessages;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _connectionSubscription;

  ChatBloc({
    required SendMessage sendMessage,
    required SubscribeMessages subscribeMessages,
  })  : _sendMessage = sendMessage,
        _subscribeMessages = subscribeMessages,
        super(ChatState.initial()) {
    on<ChatEvent>(
      (event, emit) => event.map(
        connected: (e) => _onConnected(e, emit),
        disconnected: (e) => _onDisconnected(e, emit),
        messageReceived: (e) => _onMessageReceived(e, emit),
        sendMessage: (e) => _onSendMessage(e, emit),
        joinRoom: (e) => _onJoinRoom(e, emit),
        leaveRoom: (e) => _onLeaveRoom(e, emit),
        typingStarted: (e) => _onTypingStarted(e, emit),
        typingStopped: (e) => _onTypingStopped(e, emit),
      ),
      transformer: sequential(), // 순차 처리
    );
  }

  Future<void> _onJoinRoom(
    _JoinRoom event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(currentRoomId: event.roomId, messages: []));

    // WebSocket 메시지 구독
    final result = await _subscribeMessages(event.roomId);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.toString())),
      (stream) {
        _messagesSubscription?.cancel();
        _messagesSubscription = stream.listen(
          (message) => add(ChatEvent.messageReceived(message)),
        );
      },
    );
  }

  Future<void> _onSendMessage(
    _SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.currentRoomId == null) return;

    emit(state.copyWith(isSending: true));

    final result = await _sendMessage(SendMessageParams(
      roomId: state.currentRoomId!,
      text: event.text,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        error: failure.toString(),
      )),
      (_) => emit(state.copyWith(isSending: false)),
    );
  }

  Future<void> _onMessageReceived(
    _MessageReceived event,
    Emitter<ChatState> emit,
  ) async {
    final updatedMessages = [...state.messages, event.message];
    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onConnected(
    _Connected event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      connectionState: const ConnectionState.connected(),
    ));
  }

  Future<void> _onDisconnected(
    _Disconnected event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(
      connectionState: const ConnectionState.disconnected(),
    ));
  }

  Future<void> _onTypingStarted(
    _TypingStarted event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isTyping: true));
  }

  Future<void> _onTypingStopped(
    _TypingStopped event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isTyping: false));
  }

  Future<void> _onLeaveRoom(
    _LeaveRoom event,
    Emitter<ChatState> emit,
  ) async {
    await _messagesSubscription?.cancel();
    emit(state.copyWith(currentRoomId: null, messages: []));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
```

---

## 9. 오프라인 지원

### 9.1 메시지 큐잉

```dart
// features/chat/data/repositories/offline_message_queue.dart
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message_model.dart';

class OfflineMessageQueue {
  static const String _queueKey = 'pending_messages';
  final SharedPreferences _prefs;
  final Queue<MessageModel> _queue = Queue();

  OfflineMessageQueue(this._prefs) {
    _loadQueue();
  }

  void _loadQueue() {
    final stored = _prefs.getString(_queueKey);
    if (stored != null) {
      final list = jsonDecode(stored) as List;
      _queue.addAll(
        list.map((json) => MessageModel.fromJson(json)).toList(),
      );
    }
  }

  Future<void> _saveQueue() async {
    final json = jsonEncode(_queue.map((m) => m.toJson()).toList());
    await _prefs.setString(_queueKey, json);
  }

  /// 메시지를 큐에 추가
  Future<void> enqueue(MessageModel message) async {
    _queue.add(message.copyWith(isSent: false));
    await _saveQueue();
  }

  /// 큐에서 메시지 제거
  Future<void> dequeue(String messageId) async {
    _queue.removeWhere((m) => m.id == messageId);
    await _saveQueue();
  }

  /// 대기 중인 모든 메시지 가져오기
  List<MessageModel> getPending() => _queue.toList();

  /// 큐 비우기
  Future<void> clear() async {
    _queue.clear();
    await _prefs.remove(_queueKey);
  }

  bool get isEmpty => _queue.isEmpty;
  int get length => _queue.length;
}
```

### 9.2 자동 재전송 로직

```dart
// features/chat/data/repositories/chat_repository_impl.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../datasources/chat_remote_datasource.dart';
import 'offline_message_queue.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;
  final OfflineMessageQueue _offlineQueue;
  final Connectivity _connectivity;

  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required OfflineMessageQueue offlineQueue,
    required Connectivity connectivity,
  })  : _remoteDataSource = remoteDataSource,
        _offlineQueue = offlineQueue,
        _connectivity = connectivity {
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _processPendingMessages();
      }
    });
  }

  Future<void> _processPendingMessages() async {
    if (_offlineQueue.isEmpty) return;

    final pending = _offlineQueue.getPending();

    for (final message in pending) {
      final result = await _remoteDataSource.sendMessage(message);
      result.fold(
        (failure) {
          // 실패 시 큐에 유지
          debugPrint('재전송 실패: ${message.id}');
        },
        (_) async {
          // 성공 시 큐에서 제거
          await _offlineQueue.dequeue(message.id);
        },
      );
    }
  }

  @override
  Future<Either<Exception, void>> sendMessage(Message message) async {
    final connectivityResults = await _connectivity.checkConnectivity();

    // 오프라인 상태면 큐에 추가
    if (connectivityResults.contains(ConnectivityResult.none)) {
      await _offlineQueue.enqueue(message as MessageModel);
      return right(null);
    }

    // 온라인 상태면 즉시 전송
    final result = await _remoteDataSource.sendMessage(message);

    return result.fold(
      (failure) async {
        // 전송 실패 시 큐에 추가
        await _offlineQueue.enqueue(message as MessageModel);
        return left(failure);
      },
      (success) => right(success),
    );
  }
}
```

### 9.3 로컬 캐시

```dart
// features/chat/data/datasources/chat_local_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/message_model.dart';

class ChatLocalDataSource {
  final SharedPreferences _prefs;

  ChatLocalDataSource(this._prefs);

  /// 특정 룸의 메시지 캐시
  Future<void> cacheMessages(String roomId, List<MessageModel> messages) async {
    final key = 'messages_$roomId';
    final json = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(key, json);
  }

  /// 캐시된 메시지 가져오기
  List<MessageModel> getCachedMessages(String roomId) {
    final key = 'messages_$roomId';
    final stored = _prefs.getString(key);

    if (stored == null) return [];

    final list = jsonDecode(stored) as List;
    return list.map((json) => MessageModel.fromJson(json)).toList();
  }

  /// 특정 룸 캐시 삭제
  Future<void> clearRoomCache(String roomId) async {
    await _prefs.remove('messages_$roomId');
  }

  /// 모든 캐시 삭제
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys()
        .where((key) => key.startsWith('messages_'))
        .toList();

    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
```

---

## 10. 채팅 앱 구현 예제

### 10.1 채팅 화면 UI

```dart
// features/chat/presentation/pages/chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_list.dart';
import '../widgets/message_input.dart';
import '../widgets/connection_indicator.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatPage({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatEvent.joinRoom(widget.roomId));
    // 참고: initState()에서 context.read는 flutter_bloc에서 동작하지만,
    // didChangeDependencies()가 더 안전한 Flutter 표준 위치입니다.
  }

  @override
  void dispose() {
    // ⚠️ 주의: dispose()에서 context.read()를 직접 호출하지 않습니다.
    // initState()에서 bloc 참조를 캐시하여 사용하거나,
    // BlocProvider가 자동으로 정리하도록 합니다.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return ConnectionIndicator(
                  connectionState: state.connectionState,
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return MessageList(messages: state.messages);
              },
            ),
          ),

          // 타이핑 인디케이터
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.isTyping) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('상대방이 입력 중...'),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 메시지 입력
          MessageInput(
            onSend: (text) {
              context.read<ChatBloc>().add(ChatEvent.sendMessage(text));
            },
            onTyping: (isTyping) {
              if (isTyping) {
                context.read<ChatBloc>().add(const ChatEvent.typingStarted());
              } else {
                context.read<ChatBloc>().add(const ChatEvent.typingStopped());
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### 10.2 메시지 리스트 위젯

```dart
// features/chat/presentation/widgets/message_list.dart
import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import 'message_bubble.dart';

class MessageList extends StatefulWidget {
  final List<Message> messages;

  const MessageList({
    super.key,
    required this.messages,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 새 메시지가 추가되면 스크롤을 아래로
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text('메시지가 없습니다'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### 10.3 메시지 입력 위젯

```dart
// features/chat/presentation/widgets/message_input.dart
import 'package:flutter/material.dart';
import 'dart:async';

class MessageInput extends StatefulWidget {
  final void Function(String text) onSend;
  final void Function(bool isTyping) onTyping;

  const MessageInput({
    super.key,
    required this.onSend,
    required this.onTyping,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;

  void _handleTextChanged(String text) {
    // 타이핑 타이머 취소
    _typingTimer?.cancel();

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTyping(true);
    }

    // 1초 후 타이핑 중지
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTyping(false);
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();

    // 타이핑 상태 초기화
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      widget.onTyping(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _handleTextChanged,
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: InputBorder.none,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}
```

---

## 11. 보안

### 11.1 WSS (WebSocket Secure) 사용

```dart
// core/core_network/lib/src/websocket/secure_websocket_config.dart
class SecureWebSocketConfig {
  /// WSS URL 검증
  static bool isSecureUrl(String url) {
    return url.startsWith('wss://');
  }

  /// HTTP URL을 WSS로 변환
  static String upgradeToSecure(String url) {
    if (url.startsWith('ws://')) {
      return url.replaceFirst('ws://', 'wss://');
    }
    return url;
  }

  /// 프로덕션 환경에서 WSS 강제
  static String ensureSecure(String url, bool isProduction) {
    if (isProduction && !isSecureUrl(url)) {
      throw Exception('프로덕션에서는 WSS만 허용됩니다');
    }
    return url;
  }
}
```

### 11.2 인증 토큰

```dart
// core/core_network/lib/src/websocket/authenticated_websocket_client.dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class AuthenticatedWebSocketClient {
  final String url;
  final String token;

  AuthenticatedWebSocketClient({
    required this.url,
    required this.token,
  });

  WebSocketChannel connect() {
    // 헤더에 인증 토큰 추가
    return IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Client-Type': 'flutter',
      },
    );
  }

  /// 쿼리 파라미터로 토큰 전달 (일부 서버)
  WebSocketChannel connectWithQuery() {
    final uri = Uri.parse(url).replace(
      queryParameters: {
        'token': token,
      },
    );

    return WebSocketChannel.connect(uri);
  }
}
```

### 11.3 메시지 암호화

```dart
// core/core_network/lib/src/websocket/encrypted_message_handler.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptedMessageHandler {
  final String secretKey;

  EncryptedMessageHandler(this.secretKey);

  /// 메시지 서명 (HMAC)
  String sign(String message) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// 서명 검증
  bool verify(String message, String signature) {
    final computed = sign(message);
    return computed == signature;
  }

  /// 메시지 래핑 (서명 포함)
  Map<String, dynamic> wrapMessage(Map<String, dynamic> payload) {
    final message = jsonEncode(payload);
    final signature = sign(message);

    return {
      'payload': payload,
      'signature': signature,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// 메시지 검증 및 언래핑
  Map<String, dynamic>? unwrapMessage(Map<String, dynamic> wrapped) {
    final payload = wrapped['payload'] as Map<String, dynamic>;
    final signature = wrapped['signature'] as String;
    final message = jsonEncode(payload);

    if (!verify(message, signature)) {
      throw Exception('메시지 서명 검증 실패');
    }

    return payload;
  }
}
```

---

## 12. 성능 최적화

### 12.1 메모리 누수 방지

```dart
// features/chat/presentation/bloc/chat_bloc.dart (개선)
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  StreamSubscription? _messagesSubscription;
  Timer? _heartbeatTimer;

  @override
  Future<void> close() async {
    // 모든 리소스 정리
    await _messagesSubscription?.cancel();
    _messagesSubscription = null;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    return super.close();
  }
}

// 위젯에서 사용 시
class ChatWidget extends StatefulWidget {
  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
  }

  @override
  void dispose() {
    // Bloc 명시적으로 닫기 (필요 시)
    // _chatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: ChatContent(),
    );
  }
}
```

### 12.2 메시지 페이지네이션

```dart
// features/chat/data/datasources/paginated_chat_datasource.dart
class PaginatedChatDataSource {
  static const int pageSize = 50;

  final Map<String, List<MessageModel>> _cache = {};
  final Map<String, int> _currentPage = {};

  /// 메시지 페이지 로드
  Future<List<MessageModel>> loadMessages(
    String roomId, {
    int page = 0,
  }) async {
    // API 호출 또는 로컬 DB 조회
    final messages = await _fetchMessagesFromApi(
      roomId,
      offset: page * pageSize,
      limit: pageSize,
    );

    // 캐시 업데이트
    _cache[roomId] = [...?_cache[roomId], ...messages];
    _currentPage[roomId] = page;

    return messages;
  }

  /// 다음 페이지 로드
  Future<List<MessageModel>> loadMore(String roomId) async {
    final nextPage = (_currentPage[roomId] ?? 0) + 1;
    return loadMessages(roomId, page: nextPage);
  }

  /// 캐시된 메시지 가져오기
  List<MessageModel> getCached(String roomId) {
    return _cache[roomId] ?? [];
  }

  Future<List<MessageModel>> _fetchMessagesFromApi(
    String roomId, {
    required int offset,
    required int limit,
  }) async {
    // API 구현
    throw UnimplementedError();
  }
}
```

### 12.3 배터리 최적화

```dart
// core/core_network/lib/src/websocket/battery_aware_websocket.dart
import 'package:battery_plus/battery_plus.dart';

class BatteryAwareWebSocket {
  final Battery _battery = Battery();
  WebSocketConfig? _currentConfig;

  /// 배터리 상태에 따른 설정 조정
  Future<WebSocketConfig> getOptimizedConfig(
    WebSocketConfig baseConfig,
  ) async {
    final batteryLevel = await _battery.batteryLevel;
    final batteryState = await _battery.batteryState;

    // 배터리 부족 시 최적화
    if (batteryLevel < 20 && batteryState != BatteryState.charging) {
      return baseConfig.copyWith(
        pingInterval: 10000,              // 핑 주기 증가
        reconnectDelay: 3000,             // 재연결 지연 증가
        maxReconnectAttempts: 2,          // 재연결 시도 감소
      );
    }

    return baseConfig;
  }

  /// 백그라운드 시 연결 일시정지
  Future<void> onAppPaused() async {
    // 연결 종료 또는 최소 활동 모드
  }

  /// 포그라운드 복귀 시 재연결
  Future<void> onAppResumed() async {
    // 재연결
  }
}
```

---

## 13. 테스트

### 13.1 WebSocket Mock

```dart
// test/mocks/mock_websocket_client.dart
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import '../../lib/core/core_network/websocket/websocket_client.dart';
import '../../lib/core/core_network/websocket/connection_state.dart';

class MockWebSocketClient extends Mock implements WebSocketClient {
  final StreamController<ConnectionState> _connectionController =
      StreamController.broadcast();
  final StreamController<String> _messagesController =
      StreamController.broadcast();

  bool _isConnected = false;

  @override
  Stream<ConnectionState> get connectionState => _connectionController.stream;

  @override
  Stream<String> get messages => _messagesController.stream;

  @override
  bool get isConnected => _isConnected;

  /// 연결 시뮬레이션
  void simulateConnect() {
    _isConnected = true;
    _connectionController.add(const ConnectionState.connected());
  }

  /// 메시지 수신 시뮬레이션
  void simulateMessage(String message) {
    _messagesController.add(message);
  }

  /// 연결 해제 시뮬레이션
  void simulateDisconnect() {
    _isConnected = false;
    _connectionController.add(const ConnectionState.disconnected());
  }

  void dispose() {
    _connectionController.close();
    _messagesController.close();
  }
}
```

### 13.2 단위 테스트

```dart
// test/features/chat/presentation/bloc/chat_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ChatBloc', () {
    late ChatBloc chatBloc;
    late MockSendMessage mockSendMessage;
    late MockSubscribeMessages mockSubscribeMessages;

    setUp(() {
      mockSendMessage = MockSendMessage();
      mockSubscribeMessages = MockSubscribeMessages();

      chatBloc = ChatBloc(
        sendMessage: mockSendMessage,
        subscribeMessages: mockSubscribeMessages,
      );
    });

    tearDown(() {
      chatBloc.close();
    });

    test('초기 상태는 disconnected', () {
      expect(
        chatBloc.state.connectionState,
        const ConnectionState.disconnected(),
      );
    });

    blocTest<ChatBloc, ChatState>(
      '룸 참가 시 메시지 구독 시작',
      build: () {
        when(() => mockSubscribeMessages(any())).thenAnswer(
          (_) async => right(Stream.value(testMessage)),
        );
        return chatBloc;
      },
      act: (bloc) => bloc.add(const ChatEvent.joinRoom('room123')),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.currentRoomId,
          'currentRoomId',
          'room123',
        ),
      ],
      verify: (_) {
        verify(() => mockSubscribeMessages('room123')).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      '메시지 전송 성공',
      build: () {
        when(() => mockSendMessage(any())).thenAnswer(
          (_) async => right(null),
        );
        return chatBloc;
      },
      seed: () => ChatState.initial().copyWith(
        currentRoomId: 'room123',
      ),
      act: (bloc) => bloc.add(const ChatEvent.sendMessage('Hello')),
      expect: () => [
        isA<ChatState>().having((s) => s.isSending, 'isSending', true),
        isA<ChatState>().having((s) => s.isSending, 'isSending', false),
      ],
    );
  });
}
```

### 13.3 통합 테스트

```dart
// test/integration/websocket_integration_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSocket 통합 테스트', () {
    late WebSocketClientImpl client;

    setUp(() {
      client = WebSocketClientImpl(
        config: WebSocketConfig(
          url: 'wss://ws.postman-echo.com/raw', // echo.websocket.org는 서비스 종료됨
        ),
        logger: Logger(),
      );
    });

    tearDown(() {
      client.dispose();
    });

    test('연결 및 메시지 송수신', () async {
      // 연결
      final connectResult = await client.connect();
      expect(connectResult.isRight(), true);

      // 메시지 수신 대기
      final messagesFuture = client.messages.first;

      // 메시지 전송
      final sendResult = client.send('test message');
      expect(sendResult.isRight(), true);

      // 에코 수신 확인
      final received = await messagesFuture.timeout(
        const Duration(seconds: 5),
      );
      expect(received, 'test message');

      // 연결 종료
      await client.disconnect();
      expect(client.isConnected, false);
    });

    test('재연결 로직 검증', () async {
      await client.connect();

      final states = <ConnectionState>[];
      final subscription = client.connectionState.listen(states.add);

      // 강제 연결 해제
      await client.disconnect();

      // 재연결 시도
      await client.reconnect();

      await Future.delayed(const Duration(seconds: 2));

      expect(
        states,
        contains(const ConnectionState.reconnecting(
          attempt: 1,
          maxAttempts: 3,
        )),
      );

      await subscription.cancel();
    });
  });
}
```

---

## 14. Best Practices

### 14.1 Do's and Don'ts

| 구분 | DO ✅ | DON'T ❌ |
|------|-------|----------|
| **연결 관리** | 연결 상태를 명시적으로 모니터링 | 연결 실패를 무시하지 말 것 |
| | 자동 재연결 로직 구현 | 무한 재연결 시도 |
| | 하트비트/핑퐁으로 연결 유지 | 장시간 idle 연결 방치 |
| **메시지 처리** | Freezed로 타입 안전한 모델 사용 | dynamic 타입 남발 |
| | Either 패턴으로 에러 처리 | try-catch만으로 에러 처리 |
| | 메시지 ID로 중복 제거 | 중복 메시지 무시 |
| **Stream 관리** | BroadcastStream으로 여러 리스너 지원 | Stream 구독 후 cancel 미실행 |
| | StreamController는 반드시 close | 메모리 누수 방치 |
| | StreamTransformer로 데이터 변환 | 수동 필터링 |
| **오프라인 지원** | 메시지 큐잉 구현 | 오프라인 시 에러만 표시 |
| | 로컬 캐시 활용 | 네트워크 의존적 구현 |
| | 재전송 로직 구현 | 메시지 손실 방치 |
| **보안** | WSS (TLS) 사용 | 프로덕션에서 ws:// 사용 |
| | 인증 토큰으로 접근 제어 | 인증 없는 연결 허용 |
| | 메시지 서명/암호화 | 평문 민감 정보 전송 |
| **성능** | 메시지 페이지네이션 | 모든 메시지 한번에 로드 |
| | 배터리 상태 고려 | 무조건 짧은 핑 주기 |
| | 백그라운드 시 연결 일시정지 | 백그라운드에서 계속 연결 |
| **테스트** | Mock을 사용한 단위 테스트 | 실제 서버 의존 테스트 |
| | Bloc 테스트 작성 | 수동 테스트만 수행 |
| | 통합 테스트로 전체 플로우 검증 | 단위 테스트만 작성 |

### 14.2 체크리스트

**구현 전 확인사항:**
- [ ] WebSocket vs Socket.IO 선택 근거 명확
- [ ] 재연결 정책 정의 (최대 시도, 백오프 전략)
- [ ] 메시지 프로토콜 설계 (JSON 스키마)
- [ ] 오프라인 시나리오 고려
- [ ] 보안 요구사항 파악 (인증, 암호화)

**코드 리뷰 체크리스트:**
- [ ] StreamController는 모두 dispose에서 close 되는가?
- [ ] 연결 실패 시 적절한 에러 처리가 있는가?
- [ ] 메시지 중복 제거 로직이 있는가?
- [ ] Either 패턴으로 에러를 안전하게 처리하는가?
- [ ] 테스트 커버리지가 충분한가? (최소 70%)

**배포 전 확인사항:**
- [ ] WSS (TLS) 사용 확인
- [ ] 프로덕션 WebSocket 서버 URL 설정
- [ ] 인증 토큰 만료 처리 확인
- [ ] 배터리 최적화 적용 확인
- [ ] 통합 테스트 통과 확인

---

## 참고 자료

### 공식 문서
- [web_socket_channel](https://pub.dev/packages/web_socket_channel)
- [socket_io_client](https://pub.dev/packages/socket_io_client)
- [MDN WebSocket API](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)
- [Socket.IO Documentation](https://socket.io/docs/v4/)

### 관련 패키지
- [connectivity_plus](https://pub.dev/packages/connectivity_plus) - 네트워크 상태 확인
- [rxdart](https://pub.dev/packages/rxdart) - Reactive Extensions
- [freezed](https://pub.dev/packages/freezed) - 불변 모델
- [fpdart](https://pub.dev/packages/fpdart) - 함수형 프로그래밍

### 아키텍처 패턴
- Clean Architecture
- Bloc 패턴
- Repository 패턴
- Either 패턴 (에러 처리)

---

**작성일**: 2026년 2월 기준
**버전**: 1.0.0
**대상**: Flutter 3.32+, Dart 3.5+

---

## 실습 과제

### 과제 1: 실시간 채팅 앱 구현
WebSocket을 사용한 1:1 채팅 기능을 구현하세요. 연결 상태 표시, 메시지 전송/수신, 타이핑 인디케이터, 연결 끊김 시 자동 재접속을 포함해 주세요.

### 과제 2: Socket.IO 기반 실시간 알림
Socket.IO를 활용하여 서버에서 푸시되는 실시간 알림을 수신하고 UI에 표시하는 시스템을 구현하세요. Room 기반 구독과 네임스페이스 분리를 적용해 보세요.

## Self-Check

- [ ] WebSocket 연결 수립, 메시지 송수신, 연결 해제를 구현할 수 있다
- [ ] 재접속 전략(지수 백오프, 최대 재시도)을 설계할 수 있다
- [ ] Bloc 패턴으로 WebSocket 이벤트 스트림을 상태로 변환할 수 있다
- [ ] Socket.IO의 Room과 Namespace 개념을 활용할 수 있다
