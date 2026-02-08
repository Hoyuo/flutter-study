# Flutter Isolate & 동시성 가이드

> **마지막 업데이트**: 2026-02-08 | **Flutter 3.38** | **Dart 3.10**
> **난이도**: 고급 | **카테고리**: system
> **선행 학습**: [DartAdvanced](../fundamentals/DartAdvanced.md) | **예상 학습 시간**: 2h

> **Flutter 3.27+ / Dart 3.6+** | flutter_bloc ^9.1.1 | workmanager ^0.5.2 | flutter_background_service ^5.0.10

> Flutter의 Isolate를 활용한 동시성 프로그래밍 완벽 가이드. Event Loop 이해부터 백그라운드 작업, Worker Isolate, WorkManager, 그리고 실전 패턴까지 Clean Architecture와 Bloc을 활용한 실무 예제로 학습합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Flutter의 Event Loop와 Isolate 동작 원리를 이해할 수 있다
> - compute()와 Worker Isolate를 사용한 백그라운드 작업을 구현할 수 있다
> - 실전 프로젝트에서 Isolate가 필요한 시나리오를 판단하고 적용할 수 있다

## 목차

1. [개요](#1-개요)
2. [프로젝트 설정](#2-프로젝트-설정)
3. [compute() 함수](#3-compute-함수)
4. [Isolate.spawn](#4-isolatespawn)
5. [Isolate 간 데이터 전달](#5-isolate-간-데이터-전달)
6. [장기 실행 Isolate (Worker Isolate)](#6-장기-실행-isolate-worker-isolate)
7. [Isolate Pool](#7-isolate-pool)
8. [WorkManager](#8-workmanager)
9. [백그라운드 서비스](#9-백그라운드-서비스)
10. [Bloc 연동](#10-bloc-연동)
11. [실전 패턴](#11-실전-패턴)
12. [플랫폼별 차이](#12-플랫폼별-차이)
13. [테스트](#13-테스트)
14. [Best Practices](#14-best-practices)

## 1. 개요

### 1.1 Dart 동시성 모델

Dart는 **단일 스레드 이벤트 루프** 모델을 기반으로 하며, **Isolate**를 통해 진정한 병렬 처리를 구현합니다.

| 개념 | 설명 | 특징 |
|------|------|------|
| Event Loop | 단일 스레드에서 이벤트 큐 처리 | 비동기 작업(`async`/`await`) |
| Microtask Queue | 우선순위 높은 작업 큐 | `scheduleMicrotask()` |
| Event Queue | 일반 이벤트 큐 | I/O, 타이머, UI 이벤트 |
| Isolate | 독립된 메모리 공간의 실행 단위 | 진정한 병렬 처리, 메모리 공유 없음 |

### 1.2 Event Loop 동작 원리

```dart
// lib/core/concurrency/event_loop_example.dart

void main() {
  print('1: Synchronous');

  // Event Queue에 추가
  Future(() => print('2: Future in Event Queue'));

  // Microtask Queue에 추가 (우선순위 높음)
  scheduleMicrotask(() => print('3: Microtask'));

  Future(() => print('4: Another Future'));

  print('5: Synchronous End');
}

// 출력 순서:
// 1: Synchronous
// 5: Synchronous End
// 3: Microtask
// 2: Future in Event Queue
// 4: Another Future
```

**실행 순서:**
1. Synchronous 코드 실행
2. Microtask Queue 비울 때까지 처리
3. Event Queue에서 하나의 이벤트 처리
4. 2-3 반복

### 1.3 Isolate가 필요한 경우

| 작업 유형 | Event Loop | Isolate | 이유 |
|----------|-----------|---------|------|
| API 호출 | ✅ | ❌ | I/O 작업은 비동기로 충분 |
| 간단한 JSON 파싱 | ✅ | ❌ | 작은 데이터는 차단 시간 짧음 |
| 대용량 JSON 파싱 (10MB+) | ❌ | ✅ | UI 차단 방지 |
| 이미지 처리 | ❌ | ✅ | CPU 집약적 작업 |
| 암호화/복호화 | ❌ | ✅ | 연산 집약적 |
| 대량 데이터 정렬 | ❌ | ✅ | CPU 사용 시간 길음 |

## 2. 프로젝트 설정

### 2.1 pubspec.yaml

```yaml
name: isolate_concurrency_example
description: Flutter Isolate & Concurrency Guide
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.10.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  flutter_bloc: ^9.1.1

  # 의존성 주입
  injectable: ^2.7.1
  get_it: ^9.2.0

  # 함수형 프로그래밍
  fpdart: ^1.2.0

  # 코드 생성
  freezed_annotation: ^3.1.0
  json_annotation: ^4.10.0

  # 백그라운드 작업
  workmanager: ^0.9.0+3
  flutter_background_service: ^5.1.0

  # 유틸리티
  logger: ^2.6.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  # 코드 생성 도구
  build_runner: ^2.11.0
  freezed: ^3.2.5
  json_serializable: ^6.12.0
  injectable_generator: ^2.12.0

  # 린트
  lints: ^6.1.0

  # 테스트
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
```

### 2.2 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart
│   │   └── injection.config.dart
│   ├── error/
│   │   └── failures.dart
│   ├── isolates/
│   │   ├── compute_helper.dart
│   │   ├── isolate_manager.dart
│   │   ├── isolate_pool.dart
│   │   └── worker_isolate.dart
│   └── utils/
│       └── logger.dart
├── features/
│   ├── image_processing/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── image_processor_datasource.dart
│   │   │   └── repositories/
│   │   │       └── image_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── processed_image.dart
│   │   │   ├── repositories/
│   │   │   │   └── image_repository.dart
│   │   │   └── usecases/
│   │   │       ├── compress_image.dart
│   │   │       └── apply_filter.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── image_bloc.dart
│   │       │   ├── image_event.dart
│   │       │   └── image_state.dart
│   │       └── pages/
│   │           └── image_processing_page.dart
│   └── data_processing/
│       └── ... (유사한 구조)
└── main.dart
```

## 3. compute() 함수

### 3.1 기본 사용법

`compute()`는 Flutter에서 제공하는 가장 간단한 Isolate 실행 방법입니다.

```dart
// lib/core/isolates/compute_helper.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ComputeHelper {
  /// JSON 파싱을 Isolate에서 실행
  static Future<List<Map<String, dynamic>>> parseJsonInIsolate(
    String jsonString,
  ) async {
    return await compute(_parseJson, jsonString);
  }

  /// 이미지 압축을 Isolate에서 실행
  static Future<Uint8List> compressImageInIsolate(
    Uint8List imageBytes,
  ) async {
    return await compute(_compressImage, imageBytes);
  }

  /// 대량 데이터 정렬
  static Future<List<int>> sortLargeListInIsolate(
    List<int> numbers,
  ) async {
    return await compute(_sortList, numbers);
  }
}

// Top-level 함수 또는 static 함수여야 함
List<Map<String, dynamic>> _parseJson(String jsonString) {
  final decoded = json.decode(jsonString) as List;
  return decoded.cast<Map<String, dynamic>>();
}

Uint8List _compressImage(Uint8List imageBytes) {
  // 실제 압축 로직 (예: image 패키지 사용)
  // 여기서는 간단한 예제
  return imageBytes; // 실제로는 압축된 데이터 반환
}

List<int> _sortList(List<int> numbers) {
  final copy = List<int>.from(numbers);
  copy.sort();
  return copy;
}
```

### 3.2 실전 예제: 대용량 JSON 파싱

```dart
// lib/features/data_processing/domain/usecases/parse_large_json.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/isolates/compute_helper.dart';

@injectable
class ParseLargeJson {
  Future<Either<Failure, List<Map<String, dynamic>>>> call(
    String jsonString,
  ) async {
    try {
      final result = await ComputeHelper.parseJsonInIsolate(jsonString);
      return right(result);
    } catch (e) {
      return left(Failure.unexpected(message: e.toString()));
    }
  }
}
```

### 3.3 compute() 제약사항

| 제약 | 설명 | 해결 방법 |
|------|------|----------|
| 단일 파라미터 | 하나의 인자만 전달 가능 | 클래스로 감싸서 전달 |
| Top-level 함수 | static 또는 최상위 함수만 가능 | 별도 함수 정의 |
| 직렬화 가능 타입 | Primitive, List, Map 등만 가능 | JSON 직렬화 |
| 일회성 작업 | 매번 새 Isolate 생성 | 장기 실행은 `Isolate.spawn` 사용 |

```dart
// 여러 파라미터 전달 패턴
class CompressionParams {
  final Uint8List imageBytes;
  final int quality;
  final int targetWidth;

  CompressionParams({
    required this.imageBytes,
    required this.quality,
    required this.targetWidth,
  });
}

Future<Uint8List> compressWithParams(CompressionParams params) async {
  return await compute(_compressWithQuality, params);
}

Uint8List _compressWithQuality(CompressionParams params) {
  // params.quality, params.targetWidth 사용
  return params.imageBytes; // 실제 압축 로직
}
```

> **Dart 2.19+**: `Isolate.run()`은 `compute()`의 순수 Dart 대안입니다. Flutter 의존성 없이 사용할 수 있습니다:
> ```dart
> final result = await Isolate.run(() => _parseJson(jsonString));
> ```

## 4. Isolate.spawn

### 4.1 직접 Isolate 생성

`Isolate.spawn`은 `compute()`보다 세밀한 제어가 가능합니다.

```dart
// lib/core/isolates/isolate_manager.dart

import 'dart:async';
import 'dart:isolate';
import 'package:injectable/injectable.dart';

@singleton
class IsolateManager {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _responseController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get responses => _responseController.stream;

  /// Isolate 시작
  Future<void> start() async {
    final receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      receivePort.sendPort,
    );

    // 핸드셰이크: Isolate로부터 SendPort 받기
    final completer = Completer<SendPort>();

    receivePort.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else {
        _responseController.add(message);
      }
    });

    _sendPort = await completer.future;
  }

  /// 작업 전송
  void sendTask(dynamic task) {
    if (_sendPort == null) {
      throw StateError('Isolate not started');
    }
    _sendPort!.send(task);
  }

  /// Isolate 종료
  Future<void> stop() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    await _responseController.close();
  }
}

// Isolate 엔트리 포인트 (Top-level 함수)
void _isolateEntryPoint(SendPort callerSendPort) {
  final receivePort = ReceivePort();

  // SendPort를 메인으로 전송 (핸드셰이크)
  callerSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is Map) {
      // 작업 처리
      final result = _processTask(message);
      callerSendPort.send(result);
    }
  });
}

dynamic _processTask(Map<String, dynamic> task) {
  final type = task['type'] as String;

  switch (type) {
    case 'sort':
      final numbers = task['data'] as List<int>;
      numbers.sort();
      return {'type': 'sort_result', 'data': numbers};

    case 'hash':
      final data = task['data'] as String;
      // 해시 계산 로직
      return {'type': 'hash_result', 'data': data.hashCode};

    default:
      return {'type': 'error', 'message': 'Unknown task type'};
  }
}
```

### 4.2 SendPort/ReceivePort 통신 패턴

```dart
// lib/core/isolates/bidirectional_isolate.dart
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

class BidirectionalIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;

  Future<void> initialize() async {
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      _receivePort!.sendPort,
    );

    // 핸드셰이크: Worker의 SendPort 받기
    final completer = Completer<SendPort>();

    _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else {
        _handleResponse(message);
      }
    });

    _sendPort = await completer.future;
  }

  void _handleResponse(dynamic message) {
    debugPrint('Received from worker: $message');
  }

  Future<void> sendRequest(String data) async {
    if (_sendPort == null) {
      throw StateError('Isolate not initialized');
    }
    _sendPort!.send(data);
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }
}

void _workerEntryPoint(SendPort callerSendPort) {
  final workerReceivePort = ReceivePort();

  // SendPort 전송 (핸드셰이크)
  callerSendPort.send(workerReceivePort.sendPort);

  workerReceivePort.listen((message) {
    // 작업 처리
    final result = message.toString().toUpperCase();
    callerSendPort.send(result);
  });
}
```

## 5. Isolate 간 데이터 전달

### 5.1 직렬화 가능한 타입

Isolate 간에는 메모리를 공유하지 않으므로 데이터를 복사하거나 전송해야 합니다.

| 타입 | 전달 가능 | 비고 |
|------|----------|------|
| `int`, `double`, `bool`, `String` | ✅ | Primitive 타입 |
| `List`, `Map`, `Set` | ✅ | 재귀적으로 직렬화 가능한 요소 |
| `Uint8List`, `Int32List` 등 | ✅ | TypedData |
| `TransferableTypedData` | ✅ | 복사 없이 소유권 이전 (Zero-copy) |
| Custom 클래스 | ❌ | JSON 변환 필요 |
| `Function` | ❌ | 전달 불가 |

### 5.2 TransferableTypedData (Zero-Copy)

대용량 바이너리 데이터를 복사 없이 전송합니다.

```dart
// lib/core/isolates/transferable_data_example.dart

import 'dart:isolate';
import 'dart:typed_data';

class TransferableDataExample {
  /// 대용량 이미지 데이터를 복사 없이 Isolate로 전송
  static Future<Uint8List> processLargeImage(Uint8List imageBytes) async {
    final receivePort = ReceivePort();

    // TransferableTypedData로 변환 (Zero-copy 전송)
    final transferable = TransferableTypedData.fromList([imageBytes]);

    await Isolate.spawn(
      _processImageIsolate,
      [receivePort.sendPort, transferable],
    );

    final result = await receivePort.first as TransferableTypedData;
    return result.materialize().asUint8List();
  }
}

void _processImageIsolate(List<dynamic> args) {
  final sendPort = args[0] as SendPort;
  final transferable = args[1] as TransferableTypedData;

  // Materialize: TransferableTypedData -> Uint8List
  final imageBytes = transferable.materialize().asUint8List();

  // 이미지 처리 (예: 필터 적용)
  final processed = _applyFilter(imageBytes);

  // 다시 TransferableTypedData로 전송
  final result = TransferableTypedData.fromList([processed]);
  sendPort.send(result);
}

Uint8List _applyFilter(Uint8List bytes) {
  // 필터 로직
  return bytes; // 실제로는 처리된 데이터 반환
}
```

### 5.3 Custom 클래스 직렬화

```dart
// lib/features/data_processing/domain/entities/task_data.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_data.freezed.dart';
part 'task_data.g.dart';

@freezed
class TaskData with _$TaskData {
  const factory TaskData({
    required String id,
    required String type,
    required Map<String, dynamic> payload,
    @Default(0) int priority,
  }) = _TaskData;

  factory TaskData.fromJson(Map<String, dynamic> json) =>
      _$TaskDataFromJson(json);
}

// Isolate로 전송
Future<void> sendTaskToIsolate(TaskData task) async {
  final json = task.toJson();
  sendPort.send(json); // Map은 전송 가능
}

// Isolate에서 수신
void _isolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();

  receivePort.listen((message) {
    if (message is Map<String, dynamic>) {
      final task = TaskData.fromJson(message);
      // task 처리
    }
  });
}
```

## 6. 장기 실행 Isolate (Worker Isolate)

### 6.1 Worker Isolate 패턴

매번 Isolate를 생성하지 않고 장기 실행 Worker를 유지합니다.

```dart
// lib/core/isolates/worker_isolate.dart

import 'dart:async';
import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

@singleton
class WorkerIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  bool get isInitialized => _sendPort != null;

  Future<void> initialize() async {
    if (isInitialized) return;

    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _workerMain,
      _receivePort!.sendPort,
    );

    final completer = Completer<SendPort>();

    StreamSubscription? subscription;
    subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
        subscription?.cancel();
      }
    });

    _sendPort = await completer.future;

    // 응답 리스너 설정
    _receivePort!.listen(_handleResponse);
  }

  void _handleResponse(dynamic message) {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as String;
      final completer = _pendingRequests.remove(requestId);

      if (message.containsKey('error')) {
        completer?.completeError(message['error']);
      } else {
        completer?.complete(message['result']);
      }
    }
  }

  Future<T> execute<T>(String taskType, dynamic data) async {
    if (!isInitialized) {
      throw StateError('Worker not initialized');
    }

    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    _sendPort!.send({
      'requestId': requestId,
      'taskType': taskType,
      'data': data,
    });

    return completer.future;
  }

  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _sendPort = null;
    _pendingRequests.clear();
  }
}

void _workerMain(SendPort callerSendPort) {
  final receivePort = ReceivePort();
  callerSendPort.send(receivePort.sendPort);

  receivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as String;
      final taskType = message['taskType'] as String;
      final data = message['data'];

      try {
        final result = await _processTask(taskType, data);
        callerSendPort.send({
          'requestId': requestId,
          'result': result,
        });
      } catch (e) {
        callerSendPort.send({
          'requestId': requestId,
          'error': e.toString(),
        });
      }
    }
  });
}

Future<dynamic> _processTask(String taskType, dynamic data) async {
  switch (taskType) {
    case 'hash':
      return data.toString().hashCode;

    case 'encrypt':
      // 암호화 로직
      return 'encrypted_$data';

    case 'compress':
      // 압축 로직
      await Future.delayed(const Duration(seconds: 1)); // 시뮬레이션
      return 'compressed_$data';

    default:
      throw UnsupportedError('Unknown task type: $taskType');
  }
}
```

### 6.2 UseCase에서 Worker Isolate 사용

```dart
// lib/features/crypto/domain/usecases/encrypt_data.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/isolates/worker_isolate.dart';

@injectable
class EncryptData {
  final WorkerIsolate _workerIsolate;

  EncryptData(this._workerIsolate);

  Future<Either<Failure, String>> call(String plainText) async {
    try {
      if (!_workerIsolate.isInitialized) {
        await _workerIsolate.initialize();
      }

      final result = await _workerIsolate.execute<String>(
        'encrypt',
        plainText,
      );

      return right(result);
    } catch (e) {
      return left(Failure.unexpected(message: e.toString()));
    }
  }
}
```

## 7. Isolate Pool

### 7.1 다중 Isolate 관리

여러 Isolate를 풀로 관리하여 병렬 작업 처리량을 극대화합니다.

```dart
// lib/core/isolates/isolate_pool.dart

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:collection/collection.dart';
import 'package:injectable/injectable.dart';

@singleton
class IsolatePool {
  final int _poolSize;
  final List<_IsolateWorker> _workers = [];
  final Queue<_Task> _taskQueue = Queue();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  IsolatePool({int poolSize = 4}) : _poolSize = poolSize;

  Future<void> initialize() async {
    if (_isInitialized) return;

    for (int i = 0; i < _poolSize; i++) {
      final worker = _IsolateWorker(id: i);
      await worker.initialize();
      _workers.add(worker);
    }

    _isInitialized = true;
  }

  Future<T> execute<T>(
    String taskType,
    dynamic data, {
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      throw StateError('Pool not initialized');
    }

    final task = _Task<T>(
      taskType: taskType,
      data: data,
      timeout: timeout,
    );

    _taskQueue.add(task);
    _processQueue();

    return task.completer.future;
  }

  void _processQueue() {
    if (_taskQueue.isEmpty) return;

    // 사용 가능한 Worker 찾기
    final availableWorker = _workers.firstWhereOrNull((w) => !w.isBusy);

    if (availableWorker != null && _taskQueue.isNotEmpty) {
      final task = _taskQueue.removeFirst();
      _executeTask(availableWorker, task);

      // 재귀적으로 다음 작업 처리
      _processQueue();
    }
  }

  Future<void> _executeTask(_IsolateWorker worker, _Task task) async {
    worker.isBusy = true;

    try {
      final result = await worker.execute(
        task.taskType,
        task.data,
      ).timeout(
        task.timeout ?? const Duration(seconds: 30),
      );

      task.completer.complete(result);
    } catch (e) {
      task.completer.completeError(e);
    } finally {
      worker.isBusy = false;
      _processQueue(); // 대기 중인 작업 처리
    }
  }

  Future<void> dispose() async {
    for (final worker in _workers) {
      await worker.dispose();
    }
    _workers.clear();
    _taskQueue.clear();
    _isInitialized = false;
  }
}

class _IsolateWorker {
  final int id;
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  bool isBusy = false;
  final Map<String, Completer<dynamic>> _pendingRequests = {};

  _IsolateWorker({required this.id});

  Future<void> initialize() async {
    _receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _workerEntryPoint,
      _receivePort!.sendPort,
    );

    final completer = Completer<SendPort>();

    StreamSubscription? subscription;
    subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
        subscription?.cancel();
      }
    });

    _sendPort = await completer.future;
    _receivePort!.listen(_handleResponse);
  }

  void _handleResponse(dynamic message) {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as String;
      final completer = _pendingRequests.remove(requestId);

      if (message.containsKey('error')) {
        completer?.completeError(message['error']);
      } else {
        completer?.complete(message['result']);
      }
    }
  }

  Future<T> execute<T>(String taskType, dynamic data) async {
    final requestId = '${id}_${DateTime.now().microsecondsSinceEpoch}';
    final completer = Completer<T>();
    _pendingRequests[requestId] = completer;

    _sendPort!.send({
      'requestId': requestId,
      'taskType': taskType,
      'data': data,
    });

    return completer.future;
  }

  Future<void> dispose() async {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
  }
}

void _workerEntryPoint(SendPort callerSendPort) {
  final receivePort = ReceivePort();
  callerSendPort.send(receivePort.sendPort);

  receivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final requestId = message['requestId'] as String;
      final taskType = message['taskType'] as String;
      final data = message['data'];

      try {
        final result = await _heavyComputation(taskType, data);
        callerSendPort.send({
          'requestId': requestId,
          'result': result,
        });
      } catch (e) {
        callerSendPort.send({
          'requestId': requestId,
          'error': e.toString(),
        });
      }
    }
  });
}

Future<dynamic> _heavyComputation(String taskType, dynamic data) async {
  // 실제 무거운 연산 처리
  await Future.delayed(const Duration(milliseconds: 100));
  return 'Result for $taskType: $data';
}

class _Task<T> {
  final String taskType;
  final dynamic data;
  final Duration? timeout;
  final Completer<T> completer = Completer<T>();

  _Task({
    required this.taskType,
    required this.data,
    this.timeout,
  });
}

// dart:collection의 Queue 사용 (O(1) removeFirst)
// import 'dart:collection';

// collection 패키지의 firstWhereOrNull 사용
// import 'package:collection/collection.dart';
```

### 7.2 IsolatePool 사용 예제

```dart
// lib/features/batch_processing/domain/usecases/process_batch.dart

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/isolates/isolate_pool.dart';

@injectable
class ProcessBatch {
  final IsolatePool _isolatePool;

  ProcessBatch(this._isolatePool);

  Future<Either<Failure, List<String>>> call(List<String> items) async {
    try {
      if (!_isolatePool.isInitialized) {
        await _isolatePool.initialize();
      }

      // 모든 아이템을 병렬로 처리
      final futures = items.map((item) {
        return _isolatePool.execute<String>('process', item);
      }).toList();

      final results = await Future.wait(futures);
      return right(results);
    } catch (e) {
      return left(Failure.unexpected(message: e.toString()));
    }
  }
}
```

## 8. WorkManager

### 8.1 WorkManager 설정

백그라운드에서 지연 실행 또는 주기적 작업을 스케줄링합니다.

**Android 설정:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application>
    <provider
      android:name="androidx.startup.InitializationProvider"
      android:authorities="${applicationId}.androidx-startup"
      android:exported="false"
      tools:node="merge">
      <meta-data
        android:name="androidx.work.WorkManagerInitializer"
        android:value="androidx.startup"
        tools:node="remove" />
    </provider>
  </application>
</manifest>
```

**iOS 설정:**
```xml
<!-- ios/Runner/Info.plist -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.yourcompany.app.refresh</string>
</array>
```

### 8.2 WorkManager 기본 사용

```dart
// lib/core/background/work_manager_service.dart

import 'package:injectable/injectable.dart';
import 'package:workmanager/workmanager.dart';

const String syncTaskName = 'com.example.sync';
const String cleanupTaskName = 'com.example.cleanup';

@singleton
class WorkManagerService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// 일회성 작업 등록
  Future<void> registerOneTimeTask(
    String uniqueName,
    String taskName, {
    Duration delay = Duration.zero,
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      initialDelay: delay,
      inputData: inputData,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// 주기적 작업 등록 (최소 15분)
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration frequency = const Duration(hours: 1),
    Map<String, dynamic>? inputData,
  }) async {
    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
      inputData: inputData,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  /// 작업 취소
  Future<void> cancelTask(String uniqueName) async {
    await Workmanager().cancelByUniqueName(uniqueName);
  }

  /// 모든 작업 취소
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}

// Top-level 콜백 함수
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case syncTaskName:
          await _performSync(inputData);
          break;

        case cleanupTaskName:
          await _performCleanup(inputData);
          break;

        default:
          // 주의: WorkManager 콜백은 별도 Isolate에서 실행되므로
          // Flutter 엔진이 없는 환경에서는 debugPrint가 동작하지 않을 수 있습니다.
          print('Unknown task: $taskName');
      }
      return true; // 성공
    } catch (e) {
      print('Task failed: $e');
      return false; // 실패 (재시도됨)
    }
  });
}

Future<void> _performSync(Map<String, dynamic>? inputData) async {
  print('Performing sync task');
  // 실제 동기화 로직
  await Future.delayed(Duration(seconds: 2));
}

Future<void> _performCleanup(Map<String, dynamic>? inputData) async {
  print('Performing cleanup task');
  // 실제 정리 로직
  await Future.delayed(Duration(seconds: 1));
}
```

### 8.3 제약 조건 설정

```dart
// lib/core/background/constrained_task.dart

import 'package:workmanager/workmanager.dart';

class ConstrainedTask {
  static Future<void> registerWithConstraints() async {
    await Workmanager().registerOneOffTask(
      'battery-intensive-task',
      'heavyProcessing',
      constraints: Constraints(
        networkType: NetworkType.connected, // Wi-Fi 또는 모바일 데이터 필요
        requiresBatteryNotLow: true, // 배터리 충분해야 함
        requiresCharging: true, // 충전 중이어야 함
        requiresDeviceIdle: false, // 기기가 유휴 상태일 필요 없음
        requiresStorageNotLow: true, // 저장 공간 충분해야 함
      ),
      backoffPolicy: BackoffPolicy.exponential, // 실패 시 재시도 정책
      backoffPolicyDelay: Duration(minutes: 1), // 재시도 지연
    );
  }
}
```

## 9. 백그라운드 서비스

### 9.1 flutter_background_service 설정

장기 실행 백그라운드 서비스를 구현합니다.

```dart
// lib/core/background/background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:injectable/injectable.dart';

@singleton
class BackgroundService {
  final service = FlutterBackgroundService();

  Future<void> initialize() async {
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: false,
      ),
    );
  }

  Future<void> startService() async {
    await service.startService();
  }

  Future<void> stopService() async {
    service.invoke('stop');
  }

  void sendData(String key, dynamic value) {
    service.invoke('update', {key: value});
  }

  Stream<Map<String, dynamic>?> get onDataReceived {
    return service.on('update');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stop').listen((event) {
    service.stopSelf();
  });

  // 주기적 작업
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // 포그라운드 서비스 알림 업데이트
        service.setForegroundNotificationInfo(
          title: 'Background Service',
          content: 'Updated at ${DateTime.now()}',
        );
      }
    }

    // 데이터 전송
    service.invoke('update', {
      'timestamp': DateTime.now().toIso8601String(),
      'count': timer.tick,
    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
```

### 9.2 포그라운드 서비스 (Android)

```dart
// lib/features/tracking/presentation/bloc/tracking_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/background/background_service.dart';

part 'tracking_bloc.freezed.dart';
part 'tracking_event.dart';
part 'tracking_state.dart';

@injectable
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final BackgroundService _backgroundService;
  late final StreamSubscription<Map<String, dynamic>?> _dataSubscription;

  TrackingBloc(this._backgroundService) : super(const TrackingState.initial()) {
    on<TrackingEvent>((event, emit) async {
      await event.when(
        started: () => _onStarted(emit),
        stopped: () => _onStopped(emit),
        dataReceived: (data) => _onDataReceived(data, emit),
      );
    });

    // 서비스로부터 데이터 수신
    _dataSubscription = _backgroundService.onDataReceived.listen((data) {
      if (data != null) {
        add(TrackingEvent.dataReceived(data));
      }
    });
  }

  @override
  Future<void> close() async {
    await _dataSubscription.cancel();
    return super.close();
  }

  Future<void> _onStarted(Emitter<TrackingState> emit) async {
    emit(const TrackingState.loading());

    try {
      await _backgroundService.initialize();
      await _backgroundService.startService();
      emit(const TrackingState.running());
    } catch (e) {
      emit(TrackingState.error(e.toString()));
    }
  }

  Future<void> _onStopped(Emitter<TrackingState> emit) async {
    await _backgroundService.stopService();
    emit(const TrackingState.stopped());
  }

  Future<void> _onDataReceived(
    Map<String, dynamic> data,
    Emitter<TrackingState> emit,
  ) async {
    state.maybeWhen(
      running: () => emit(TrackingState.dataUpdated(data)),
      orElse: () {},
    );
  }
}
```

## 10. Bloc 연동

### 10.1 Isolate와 Bloc 통합

```dart
// lib/features/image_processing/presentation/bloc/image_bloc.dart

import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/compress_image.dart';
import '../../domain/usecases/apply_filter.dart';

part 'image_bloc.freezed.dart';
part 'image_event.dart';
part 'image_state.dart';

@injectable
class ImageBloc extends Bloc<ImageEvent, ImageState> {
  final CompressImage _compressImage;
  final ApplyFilter _applyFilter;

  ImageBloc(
    this._compressImage,
    this._applyFilter,
  ) : super(const ImageState.initial()) {
    on<ImageEvent>((event, emit) async {
      await event.when(
        compress: (bytes, quality) => _onCompress(bytes, quality, emit),
        applyFilter: (bytes, filterType) => _onApplyFilter(bytes, filterType, emit),
      );
    });
  }

  Future<void> _onCompress(
    Uint8List bytes,
    int quality,
    Emitter<ImageState> emit,
  ) async {
    emit(const ImageState.loading());

    final result = await _compressImage(bytes, quality);

    result.fold(
      // 📝 참고: Failure에 message getter가 정의되어 있어야 합니다
      (failure) => emit(ImageState.error(failure.message)),
      (compressed) => emit(ImageState.compressed(compressed)),
    );
  }

  Future<void> _onApplyFilter(
    Uint8List bytes,
    String filterType,
    Emitter<ImageState> emit,
  ) async {
    emit(const ImageState.loading());

    final result = await _applyFilter(bytes, filterType);

    result.fold(
      // 📝 참고: Failure에 message getter가 정의되어 있어야 합니다
      (failure) => emit(ImageState.error(failure.message)),
      (filtered) => emit(ImageState.filtered(filtered)),
    );
  }
}
```

### 10.2 UseCase에서 Isolate 실행

```dart
// lib/features/image_processing/domain/usecases/compress_image.dart

import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/isolates/isolate_pool.dart';

@injectable
class CompressImage {
  final IsolatePool _isolatePool;

  CompressImage(this._isolatePool);

  Future<Either<Failure, Uint8List>> call(
    Uint8List imageBytes,
    int quality,
  ) async {
    try {
      if (!_isolatePool.isInitialized) {
        await _isolatePool.initialize();
      }

      final result = await _isolatePool.execute<Uint8List>(
        'compress_image',
        {'bytes': imageBytes, 'quality': quality},
        timeout: const Duration(seconds: 30),
      );

      return right(result);
    } catch (e) {
      return left(Failure.unexpected(message: e.toString()));
    }
  }
}
```

## 11. 실전 패턴

### 11.1 이미지 처리

```dart
// lib/features/image_processing/data/datasources/image_processor_datasource.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class ImageProcessorDatasource {
  Future<Uint8List> compressImage(Uint8List bytes, int quality) async {
    return await compute(_compressImageIsolate, {
      'bytes': bytes,
      'quality': quality,
    });
  }

  Future<Uint8List> applyGrayscaleFilter(Uint8List bytes) async {
    return await compute(_grayscaleFilterIsolate, bytes);
  }

  Future<Uint8List> resizeImage(
    Uint8List bytes,
    int targetWidth,
    int targetHeight,
  ) async {
    return await compute(_resizeImageIsolate, {
      'bytes': bytes,
      'width': targetWidth,
      'height': targetHeight,
    });
  }
}

// Isolate 함수들
Uint8List _compressImageIsolate(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final quality = params['quality'] as int;

  // 실제 압축 로직 (image 패키지 사용)
  // 여기서는 간단한 예제
  return bytes;
}

Uint8List _grayscaleFilterIsolate(Uint8List bytes) {
  // 그레이스케일 변환 로직
  final pixels = bytes.buffer.asUint32List();

  for (int i = 0; i < pixels.length; i++) {
    final pixel = pixels[i];
    final r = (pixel >> 16) & 0xFF;
    final g = (pixel >> 8) & 0xFF;
    final b = pixel & 0xFF;
    final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();

    pixels[i] = (0xFF << 24) | (gray << 16) | (gray << 8) | gray;
  }

  return bytes;
}

Uint8List _resizeImageIsolate(Map<String, dynamic> params) {
  // 리사이즈 로직
  return params['bytes'] as Uint8List;
}
```

### 11.2 대용량 JSON 파싱

```dart
// lib/features/data_processing/data/datasources/json_parser_datasource.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class JsonParserDatasource {
  Future<List<Map<String, dynamic>>> parseHugeJson(String jsonString) async {
    return await compute(_parseJsonIsolate, jsonString);
  }

  Future<String> serializeToJson(List<Map<String, dynamic>> data) async {
    return await compute(_serializeJsonIsolate, data);
  }
}

List<Map<String, dynamic>> _parseJsonIsolate(String jsonString) {
  final decoded = json.decode(jsonString) as List;
  return decoded.cast<Map<String, dynamic>>();
}

String _serializeJsonIsolate(List<Map<String, dynamic>> data) {
  return json.encode(data);
}
```

### 11.3 데이터 암호화

```dart
// lib/features/crypto/data/datasources/crypto_datasource.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class CryptoDatasource {
  Future<String> encryptData(String plainText, String key) async {
    return await compute(_encryptIsolate, {
      'plainText': plainText,
      'key': key,
    });
  }

  Future<String> decryptData(String encrypted, String key) async {
    return await compute(_decryptIsolate, {
      'encrypted': encrypted,
      'key': key,
    });
  }

  Future<String> hashPassword(String password) async {
    return await compute(_hashIsolate, password);
  }
}

String _encryptIsolate(Map<String, dynamic> params) {
  final plainText = params['plainText'] as String;
  final key = params['key'] as String;

  // 실제 암호화 로직 (encrypt 패키지 사용)
  // 여기서는 간단한 Base64 인코딩 예제
  final bytes = utf8.encode(plainText);
  return base64.encode(bytes);
}

String _decryptIsolate(Map<String, dynamic> params) {
  final encrypted = params['encrypted'] as String;

  final bytes = base64.decode(encrypted);
  return utf8.decode(bytes);
}

String _hashIsolate(String password) {
  // 실제 해싱 로직 (crypto 패키지 사용)
  return password.hashCode.toString();
}
```

### 11.4 파일 I/O

```dart
// lib/features/file_processing/data/datasources/file_processor_datasource.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@injectable
class FileProcessorDatasource {
  Future<List<String>> readLargeFile(String filePath) async {
    return await compute(_readFileIsolate, filePath);
  }

  Future<void> writeLargeFile(String filePath, List<String> lines) async {
    await compute(_writeFileIsolate, {
      'path': filePath,
      'lines': lines,
    });
  }

  Future<Map<String, int>> analyzeTextFile(String filePath) async {
    return await compute(_analyzeFileIsolate, filePath);
  }
}

List<String> _readFileIsolate(String filePath) {
  final file = File(filePath);
  return file.readAsLinesSync();
}

void _writeFileIsolate(Map<String, dynamic> params) {
  final filePath = params['path'] as String;
  final lines = params['lines'] as List<String>;

  final file = File(filePath);
  file.writeAsStringSync(lines.join('\n'));
}

Map<String, int> _analyzeFileIsolate(String filePath) {
  final file = File(filePath);
  final content = file.readAsStringSync();

  final words = content.split(RegExp(r'\s+'));
  final wordCount = <String, int>{};

  for (final word in words) {
    if (word.isNotEmpty) {
      wordCount[word.toLowerCase()] = (wordCount[word.toLowerCase()] ?? 0) + 1;
    }
  }

  return wordCount;
}
```

## 12. 플랫폼별 차이

### 12.1 Android vs iOS 제약사항

| 기능 | Android | iOS | 비고 |
|------|---------|-----|------|
| Isolate 실행 | 제약 없음 | 백그라운드 제한 | iOS는 앱이 백그라운드일 때 제한적 |
| 백그라운드 작업 시간 | 무제한 (포그라운드 서비스) | 30초 (최대 3분) | iOS는 `beginBackgroundTask` 사용 |
| 주기적 작업 | WorkManager | BGTaskScheduler | iOS는 최소 15분 간격 |
| 위치 추적 | 포그라운드 서비스 | Background Modes | iOS는 권한 설정 엄격 |
| 알림 | 자유롭게 표시 | 제한적 | iOS는 사용자 승인 필요 |

### 12.2 iOS 백그라운드 제약 대응

```dart
// lib/core/background/platform_aware_service.dart

import 'dart:io';
import 'package:injectable/injectable.dart';

@singleton
class PlatformAwareService {
  Future<void> performBackgroundTask() async {
    if (Platform.isIOS) {
      // iOS: 30초 제한 고려
      await _performQuickTask();
    } else {
      // Android: 장기 실행 가능
      await _performLongTask();
    }
  }

  Future<void> _performQuickTask() async {
    // iOS용 최적화된 짧은 작업
    await Future.delayed(Duration(seconds: 20));
  }

  Future<void> _performLongTask() async {
    // Android용 장기 실행 작업
    await Future.delayed(Duration(minutes: 5));
  }

  bool get canRunLongBackgroundTask {
    return Platform.isAndroid;
  }
}
```

### 12.3 Android 포그라운드 서비스 권한

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />

  <application>
    <service
      android:name="id.flutter.flutter_background_service.BackgroundService"
      android:foregroundServiceType="dataSync"
      android:exported="false" />
  </application>
</manifest>
```

## 13. 테스트

### 13.1 Isolate 테스트

```dart
// test/core/isolates/isolate_manager_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_concurrency_example/core/isolates/worker_isolate.dart';

void main() {
  late WorkerIsolate workerIsolate;

  setUp(() {
    workerIsolate = WorkerIsolate();
  });

  tearDown(() async {
    await workerIsolate.dispose();
  });

  group('WorkerIsolate', () {
    test('should initialize successfully', () async {
      await workerIsolate.initialize();
      expect(workerIsolate.isInitialized, true);
    });

    test('should execute hash task', () async {
      await workerIsolate.initialize();

      final result = await workerIsolate.execute<int>('hash', 'test_data');

      expect(result, isA<int>());
      expect(result, 'test_data'.hashCode);
    });

    test('should handle multiple concurrent tasks', () async {
      await workerIsolate.initialize();

      final futures = List.generate(10, (i) {
        return workerIsolate.execute<String>('encrypt', 'data_$i');
      });

      final results = await Future.wait(futures);

      expect(results.length, 10);
      for (int i = 0; i < 10; i++) {
        expect(results[i], 'encrypted_data_$i');
      }
    });

    test('should handle errors gracefully', () async {
      await workerIsolate.initialize();

      expect(
        () => workerIsolate.execute('unknown_task', 'data'),
        throwsA(isA<String>()),
      );
    });

    test('should timeout long-running tasks', () async {
      await workerIsolate.initialize();

      // 타임아웃 테스트는 실제 구현에 따라 다름
      // 여기서는 예제
    });
  });

  group('IsolatePool', () {
    // IsolatePool 테스트는 유사하게 작성
  });
}
```

### 13.2 Mock Isolate

```dart
// test/mocks/mock_worker_isolate.dart

import 'package:mocktail/mocktail.dart';
import 'package:isolate_concurrency_example/core/isolates/worker_isolate.dart';

class MockWorkerIsolate extends Mock implements WorkerIsolate {}
```

### 13.3 타이밍 테스트

```dart
// test/features/image_processing/domain/usecases/compress_image_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:isolate_concurrency_example/features/image_processing/domain/usecases/compress_image.dart';

class MockIsolatePool extends Mock implements IsolatePool {}

void main() {
  late CompressImage usecase;
  late MockIsolatePool mockPool;

  setUp(() {
    mockPool = MockIsolatePool();
    usecase = CompressImage(mockPool);
  });

  group('CompressImage', () {
    test('should complete within timeout', () async {
      final testBytes = Uint8List.fromList([1, 2, 3]);

      when(() => mockPool.isInitialized).thenReturn(true);
      when(() => mockPool.execute<Uint8List>(
        any(),
        any(),
        timeout: any(named: 'timeout'),
      )).thenAnswer((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return testBytes;
      });

      final stopwatch = Stopwatch()..start();
      final result = await usecase(testBytes, 80);
      stopwatch.stop();

      expect(result.isRight(), true);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
```

## 14. Best Practices

### 14.1 Do / Don't

| Do ✅ | Don't ❌ |
|-------|----------|
| CPU 집약적 작업에 Isolate 사용 | 간단한 계산에 Isolate 오버헤드 |
| `compute()` 먼저 시도, 필요시 `Isolate.spawn` | 모든 비동기 작업에 Isolate 사용 |
| TransferableTypedData로 대용량 데이터 전송 | 큰 객체를 직렬화해서 복사 |
| Isolate Pool로 다중 작업 병렬화 | 매번 새 Isolate 생성 |
| 플랫폼별 제약 고려 (특히 iOS) | 플랫폼 차이 무시 |
| 타임아웃 설정으로 무한 대기 방지 | 타임아웃 없이 대기 |
| 에러 처리와 재시도 로직 구현 | Isolate 실패를 무시 |
| 백그라운드 작업은 WorkManager 사용 | 앱 종료 시 작업 손실 |
| Bloc/Cubit으로 상태 관리 통합 | UI와 Isolate 직접 연결 |
| 테스트 작성 (특히 타이밍, 동시성) | 테스트 없이 배포 |

### 14.2 성능 최적화

```dart
// lib/core/isolates/optimization_tips.dart

class IsolateOptimizationTips {
  /// 1. 작업 크기 확인
  static bool shouldUseIsolate(int dataSize, int processingTimeMs) {
    // 데이터가 크거나 처리 시간이 길면 Isolate 사용
    return dataSize > 1024 * 1024 || processingTimeMs > 100; // 1MB 또는 100ms
  }

  /// 2. Batch 처리
  static Future<List<Result>> processBatch(List<Data> items) async {
    const batchSize = 100;
    final batches = <List<Data>>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }

    final futures = batches.map((batch) {
      return compute(_processBatch, batch);
    });

    final results = await Future.wait(futures);
    return results.expand((r) => r).toList();
  }

  /// 3. 캐싱
  static final Map<String, dynamic> _cache = {};

  static Future<dynamic> executeWithCache(String key, Future<dynamic> Function() computation) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final result = await computation();
    _cache[key] = result;
    return result;
  }
}

List<Result> _processBatch(List<Data> batch) {
  // 배치 처리 로직
  return [];
}

class Data {}
class Result {}
```

### 14.3 메모리 관리

```dart
// lib/core/isolates/memory_management.dart

class IsolateMemoryManagement {
  /// Isolate 수명 관리
  static Future<void> withIsolate<T>(
    Future<T> Function(WorkerIsolate) operation,
  ) async {
    final isolate = WorkerIsolate();

    try {
      await isolate.initialize();
      await operation(isolate);
    } finally {
      await isolate.dispose(); // 반드시 정리
    }
  }

  /// Stream 대신 Future 사용 (메모리 효율)
  static Future<List<String>> processInChunks(List<String> data) async {
    final results = <String>[];

    for (final item in data) {
      final result = await compute(_processItem, item);
      results.add(result);

      // 메모리 압박 시 중간 정리
      if (results.length % 1000 == 0) {
        await Future.delayed(Duration.zero); // Event Loop에 제어권 양보
      }
    }

    return results;
  }
}

String _processItem(String item) {
  return item.toUpperCase();
}
```

### 14.4 에러 처리 전략

```dart
// lib/core/isolates/error_handling.dart

class IsolateErrorHandling {
  /// 재시도 로직
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow;
        }

        await Future.delayed(delay * attempt); // Exponential backoff
      }
    }
  }

  /// Fallback 패턴
  static Future<T> executeWithFallback<T>(
    Future<T> Function() primary,
    Future<T> Function() fallback,
  ) async {
    try {
      return await primary();
    } catch (e) {
      return await fallback();
    }
  }
}
```

### 14.5 종합 체크리스트

**Isolate 사용 전 확인:**
- [ ] 작업이 CPU 집약적인가? (100ms 이상 소요)
- [ ] 데이터 크기가 충분히 큰가? (1MB 이상)
- [ ] `compute()`로 충분한가? 아니면 장기 실행 Worker가 필요한가?
- [ ] 직렬화 가능한 데이터 타입인가?
- [ ] 타임아웃 설정이 적절한가?

**백그라운드 작업 전 확인:**
- [ ] WorkManager로 충분한가? 아니면 포그라운드 서비스가 필요한가?
- [ ] iOS 백그라운드 제약 (30초) 고려했는가?
- [ ] 배터리, 네트워크 제약 조건 설정했는가?
- [ ] 작업 실패 시 재시도 로직이 있는가?

**배포 전 확인:**
- [ ] 메모리 누수 테스트 완료
- [ ] 동시성 테스트 (Race condition 확인)
- [ ] 플랫폼별 테스트 (Android & iOS)
- [ ] 에러 처리 및 로깅 구현
- [ ] 성능 프로파일링 완료

---

## 마치며

Flutter의 Isolate를 활용하면 CPU 집약적 작업도 UI 차단 없이 부드럽게 처리할 수 있습니다. Clean Architecture와 Bloc 패턴을 함께 사용하면 테스트 가능하고 유지보수하기 쉬운 동시성 코드를 작성할 수 있습니다.

**핵심 요약:**
1. **간단한 작업**: `compute()` 사용
2. **장기 실행**: `WorkerIsolate` 또는 `IsolatePool`
3. **백그라운드 스케줄링**: `WorkManager`
4. **포그라운드 서비스**: `flutter_background_service`
5. **플랫폼별 차이 고려**: 특히 iOS 제약사항

실전에서는 항상 성능 프로파일링을 통해 실제로 Isolate가 필요한지 확인하고, 과도한 최적화를 피하세요.

---

## 실습 과제

### 과제 1: compute()를 활용한 JSON 파싱
대용량 JSON 데이터(1MB 이상)를 compute() 함수로 백그라운드에서 파싱하는 Repository를 구현하세요. UI 스레드 블로킹 없이 데이터를 처리하고 Bloc을 통해 결과를 표시하세요.

### 과제 2: Worker Isolate 패턴 구현
장시간 실행되는 이미지 처리 작업을 위한 Worker Isolate를 구현하세요. SendPort/ReceivePort를 통한 양방향 통신, 진행률 보고, 취소 처리를 포함해 주세요.

## Self-Check

- [ ] Event Loop와 Isolate의 동작 원리를 설명할 수 있다
- [ ] compute()와 Isolate.spawn()의 차이점과 사용 시나리오를 구분할 수 있다
- [ ] SendPort/ReceivePort를 통한 Isolate 간 통신을 구현할 수 있다
- [ ] Isolate 사용이 필요한 시나리오와 불필요한 시나리오를 판단할 수 있다

---
**다음 문서:** [DI](../infrastructure/DI.md) - 의존성 주입 설정
