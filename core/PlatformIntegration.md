# Flutter 플랫폼 통합 가이드 (시니어)

> 네이티브 플랫폼과의 심층 통합을 위한 고급 패턴 및 최적화 전략

## 목차

1. [플랫폼 통합 개요](#1-플랫폼-통합-개요)
2. [Platform Channel 심화](#2-platform-channel-심화)
3. [Dart FFI](#3-dart-ffi)
4. [Pigeon을 사용한 타입 안전 Channel](#4-pigeon을-사용한-타입-안전-channel)
5. [네이티브 뷰 임베딩](#5-네이티브-뷰-임베딩)
6. [Platform-specific 코드 최적화](#6-platform-specific-코드-최적화)
7. [백그라운드 Isolate와 네이티브 통신](#7-백그라운드-isolate와-네이티브-통신)
8. [네이티브 SDK 통합 패턴](#8-네이티브-sdk-통합-패턴)
9. [Kotlin Multiplatform과 Flutter](#9-kotlin-multiplatform과-flutter)
10. [직렬화 성능 최적화](#10-직렬화-성능-최적화)

---

## 1. 플랫폼 통합 개요

### 플랫폼 통합이 필요한 경우

```dart
// ✅ Platform Channel이 필요한 경우:
// 1. 네이티브 API 접근 (Bluetooth, NFC, Biometrics)
// 2. 네이티브 라이브러리 사용 (ML Kit, ARCore, ARKit)
// 3. 플랫폼별 최적화가 필요한 기능
// 4. 기존 네이티브 코드 재사용

// ❌ Platform Channel이 불필요한 경우:
// 1. 이미 pub.dev에 패키지 존재
// 2. 순수 Dart로 구현 가능
// 3. 웹 API로 충분한 경우
```

### 통신 방식 비교

| 방식 | 방향 | 용도 | 성능 |
|------|------|------|------|
| **MethodChannel** | 양방향 (Request-Response) | 일회성 호출 | 중간 |
| **EventChannel** | 단방향 (Native → Flutter) | 스트림 데이터 | 높음 |
| **BasicMessageChannel** | 양방향 (비구조적) | 커스텀 프로토콜 | 낮음 |
| **Dart FFI** | 직접 호출 | C/C++ 라이브러리 | 매우 높음 |
| **Pigeon** | 양방향 (타입 안전) | 복잡한 API | 중간 |

### 아키텍처 패턴

```dart
// ============= 권장 아키텍처 =============

// Flutter Layer
// ├── Presentation (UI)
// ├── Domain (Business Logic)
// └── Data
//     ├── Repository (Interface)
//     └── DataSource
//         ├── RemoteDataSource (API)
//         └── LocalDataSource
//             ├── Database (SQLite, Hive)
//             └── PlatformDataSource (Platform Channel)

// Platform Layer (Android/iOS)
// ├── Plugin Interface
// ├── Platform Implementation
// └── Native SDK Integration

// 예제: Biometric 인증
abstract class BiometricRepository {
  Future<Either<BiometricFailure, bool>> authenticate();
  Future<bool> isAvailable();
}

@LazySingleton(as: BiometricRepository)
class BiometricRepositoryImpl implements BiometricRepository {
  final BiometricPlatformChannel _platformChannel;

  BiometricRepositoryImpl(this._platformChannel);

  @override
  Future<Either<BiometricFailure, bool>> authenticate() async {
    try {
      final result = await _platformChannel.authenticate(
        reason: 'Please authenticate to continue',
      );
      return Right(result);
    } on PlatformException catch (e) {
      return Left(BiometricFailure.fromPlatformException(e));
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _platformChannel.isAvailable();
    } catch (e) {
      return false;
    }
  }
}
```

---

## 2. Platform Channel 심화

### 2.1 MethodChannel

```dart
// ============= Flutter Side =============
class BiometricPlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.example.app/biometric');

  Future<bool> authenticate({required String reason}) async {
    try {
      final bool result = await _channel.invokeMethod(
        'authenticate',
        {'reason': reason},
      );
      return result;
    } on PlatformException catch (e) {
      print('Biometric authentication failed: ${e.message}');
      rethrow;
    }
  }

  Future<bool> isAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isAvailable');
      return result;
    } on PlatformException catch (e) {
      print('Failed to check biometric availability: ${e.message}');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<dynamic> types = await _channel.invokeMethod('getAvailableBiometrics');
      return types.map((type) => BiometricType.fromString(type as String)).toList();
    } catch (e) {
      return [];
    }
  }
}

enum BiometricType {
  face,
  fingerprint,
  iris;

  static BiometricType fromString(String value) {
    return BiometricType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => BiometricType.fingerprint,
    );
  }
}

// ============= Android Side (Kotlin) =============
// android/app/src/main/kotlin/com/example/app/BiometricPlugin.kt
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BiometricPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var activity: FragmentActivity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.app/biometric")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authenticate" -> {
                val reason = call.argument<String>("reason") ?: "Authenticate"
                authenticate(reason, result)
            }
            "isAvailable" -> {
                val isAvailable = checkBiometricAvailability()
                result.success(isAvailable)
            }
            "getAvailableBiometrics" -> {
                val types = getAvailableBiometricTypes()
                result.success(types)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun authenticate(reason: String, result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(activity)
        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult
                ) {
                    result.success(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    result.error("AUTH_ERROR", errString.toString(), errorCode)
                }

                override fun onAuthenticationFailed() {
                    result.error("AUTH_FAILED", "Authentication failed", null)
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle(reason)
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    private fun checkBiometricAvailability(): Boolean {
        val biometricManager = BiometricManager.from(activity)
        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    private fun getAvailableBiometricTypes(): List<String> {
        val types = mutableListOf<String>()
        val biometricManager = BiometricManager.from(activity)

        if (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            == BiometricManager.BIOMETRIC_SUCCESS) {
            // Android doesn't provide detailed biometric type info
            types.add("fingerprint")
        }

        return types
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

// ============= iOS Side (Swift) =============
// ios/Runner/BiometricPlugin.swift
import Flutter
import LocalAuthentication

class BiometricPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.app/biometric",
            binaryMessenger: registrar.messenger()
        )
        let instance = BiometricPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "authenticate":
            guard let args = call.arguments as? [String: Any],
                  let reason = args["reason"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Reason required", details: nil))
                return
            }
            authenticate(reason: reason, result: result)

        case "isAvailable":
            let isAvailable = checkBiometricAvailability()
            result(isAvailable)

        case "getAvailableBiometrics":
            let types = getAvailableBiometricTypes()
            result(types)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func authenticate(reason: String, result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            result(FlutterError(
                code: "NOT_AVAILABLE",
                message: error?.localizedDescription ?? "Biometric not available",
                details: nil
            ))
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    result(true)
                } else {
                    result(FlutterError(
                        code: "AUTH_FAILED",
                        message: error?.localizedDescription ?? "Authentication failed",
                        details: nil
                    ))
                }
            }
        }
    }

    private func checkBiometricAvailability() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private func getAvailableBiometricTypes() -> [String] {
        let context = LAContext()
        var types: [String] = []

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .faceID:
                    types.append("face")
                case .touchID:
                    types.append("fingerprint")
                case .none:
                    break
                @unknown default:
                    break
                }
            }
        }

        return types
    }
}
```

### 2.2 EventChannel

```dart
// ============= Flutter Side =============
class LocationStreamChannel {
  static const EventChannel _channel = EventChannel('com.example.app/location_stream');

  Stream<LocationData> get locationStream {
    return _channel.receiveBroadcastStream().map((dynamic event) {
      return LocationData.fromMap(event as Map);
    });
  }

  Stream<LocationData> startLocationUpdates({
    required double distanceFilter,
    required int interval,
  }) {
    return _channel
        .receiveBroadcastStream({
          'distanceFilter': distanceFilter,
          'interval': interval,
        })
        .map((dynamic event) => LocationData.fromMap(event as Map));
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  factory LocationData.fromMap(Map map) {
    return LocationData(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      accuracy: map['accuracy'] as double,
      altitude: map['altitude'] as double? ?? 0.0,
      speed: map['speed'] as double? ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

// 사용 예
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationStreamChannel _locationChannel;
  StreamSubscription<LocationData>? _locationSubscription;

  LocationBloc(this._locationChannel) : super(const LocationState.initial()) {
    on<LocationEvent>(_onEvent);
  }

  Future<void> _onStartTracking(Emitter<LocationState> emit) async {
    emit(const LocationState.loading());

    _locationSubscription = _locationChannel
        .startLocationUpdates(
          distanceFilter: 10.0, // meters
          interval: 5000, // milliseconds
        )
        .listen(
          (location) {
            add(LocationEvent.locationUpdated(location));
          },
          onError: (error) {
            add(LocationEvent.locationError(error.toString()));
          },
        );
  }

  Future<void> _onStopTracking(Emitter<LocationState> emit) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    emit(const LocationState.initial());
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}

// ============= Android Side (Kotlin) =============
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import io.flutter.plugin.common.EventChannel

class LocationStreamHandler(
    private val locationManager: LocationManager
) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val locationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            val locationMap = mapOf(
                "latitude" to location.latitude,
                "longitude" to location.longitude,
                "accuracy" to location.accuracy.toDouble(),
                "altitude" to location.altitude,
                "speed" to location.speed.toDouble(),
                "timestamp" to location.time
            )
            eventSink?.success(locationMap)
        }

        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        override fun onProviderEnabled(provider: String) {}
        override fun onProviderDisabled(provider: String) {
            eventSink?.error("PROVIDER_DISABLED", "Location provider disabled", null)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        val args = arguments as? Map<*, *>
        val distanceFilter = (args?.get("distanceFilter") as? Number)?.toFloat() ?: 0f
        val interval = (args?.get("interval") as? Number)?.toLong() ?: 5000L

        try {
            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                interval,
                distanceFilter,
                locationListener
            )
        } catch (e: SecurityException) {
            eventSink?.error("PERMISSION_DENIED", "Location permission denied", null)
        }
    }

    override fun onCancel(arguments: Any?) {
        locationManager.removeUpdates(locationListener)
        eventSink = null
    }
}

// ============= iOS Side (Swift) =============
import CoreLocation

class LocationStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
    private var eventSink: FlutterEventSink?
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events

        if let args = arguments as? [String: Any] {
            let distanceFilter = args["distanceFilter"] as? Double ?? 0.0
            locationManager.distanceFilter = distanceFilter
        }

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationManager.stopUpdatingLocation()
        eventSink = nil
        return nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "altitude": location.altitude,
            "speed": location.speed,
            "timestamp": Int(location.timestamp.timeIntervalSince1970 * 1000)
        ]

        eventSink?(locationData)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        eventSink?(FlutterError(
            code: "LOCATION_ERROR",
            message: error.localizedDescription,
            details: nil
        ))
    }
}
```

### 2.3 BasicMessageChannel

```dart
// 커스텀 바이너리 프로토콜 (이미지 전송)
class ImageTransferChannel {
  static const BasicMessageChannel<ByteData> _channel = BasicMessageChannel(
    'com.example.app/image_transfer',
    StandardMessageCodec(),
  );

  Future<void> sendImage(Uint8List imageBytes) async {
    final byteData = ByteData.sublistView(imageBytes);
    await _channel.send(byteData);
  }

  void setMessageHandler(Future<ByteData?> Function(ByteData? message) handler) {
    _channel.setMessageHandler(handler);
  }
}

// 고성능 데이터 전송
class BinaryDataChannel {
  static const BasicMessageChannel<ByteData> _channel = BasicMessageChannel(
    'com.example.app/binary_data',
    BinaryCodec(),
  );

  Future<Uint8List?> processLargeData(Uint8List data) async {
    final byteData = ByteData.sublistView(data);
    final result = await _channel.send(byteData);
    return result != null ? result.buffer.asUint8List() : null;
  }
}
```

---

## 3. Dart FFI

Dart FFI (Foreign Function Interface)는 네이티브 C/C++ 코드를 직접 호출합니다.

### 3.1 기본 FFI 사용

```dart
// ============= C 라이브러리 =============
// native/calculator.c
#include <stdint.h>

__attribute__((visibility("default"))) __attribute__((used))
int32_t add(int32_t a, int32_t b) {
    return a + b;
}

__attribute__((visibility("default"))) __attribute__((used))
double multiply(double a, double b) {
    return a * b;
}

__attribute__((visibility("default"))) __attribute__((used))
void process_array(int32_t* arr, int32_t length) {
    for (int32_t i = 0; i < length; i++) {
        arr[i] = arr[i] * 2;
    }
}

// ============= Dart FFI 바인딩 =============
// lib/src/native_calculator.dart
import 'dart:ffi' as ffi;
import 'dart:io';

// C 함수 시그니처 정의
typedef AddFunc = ffi.Int32 Function(ffi.Int32 a, ffi.Int32 b);
typedef AddDart = int Function(int a, int b);

typedef MultiplyFunc = ffi.Double Function(ffi.Double a, ffi.Double b);
typedef MultiplyDart = double Function(double a, double b);

typedef ProcessArrayFunc = ffi.Void Function(ffi.Pointer<ffi.Int32> arr, ffi.Int32 length);
typedef ProcessArrayDart = void Function(ffi.Pointer<ffi.Int32> arr, int length);

class NativeCalculator {
  late final ffi.DynamicLibrary _lib;
  late final AddDart _add;
  late final MultiplyDart _multiply;
  late final ProcessArrayDart _processArray;

  NativeCalculator() {
    // 플랫폼별 라이브러리 로드
    if (Platform.isAndroid) {
      _lib = ffi.DynamicLibrary.open('libnative_calculator.so');
    } else if (Platform.isIOS) {
      _lib = ffi.DynamicLibrary.process();
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    // 함수 바인딩
    _add = _lib.lookupFunction<AddFunc, AddDart>('add');
    _multiply = _lib.lookupFunction<MultiplyFunc, MultiplyDart>('multiply');
    _processArray = _lib.lookupFunction<ProcessArrayFunc, ProcessArrayDart>('process_array');
  }

  int add(int a, int b) => _add(a, b);

  double multiply(double a, double b) => _multiply(a, b);

  List<int> processArray(List<int> input) {
    // Dart List를 C 배열로 변환
    final pointer = ffi.calloc<ffi.Int32>(input.length);

    try {
      // 데이터 복사
      for (int i = 0; i < input.length; i++) {
        pointer[i] = input[i];
      }

      // C 함수 호출
      _processArray(pointer, input.length);

      // 결과를 Dart List로 변환
      final result = <int>[];
      for (int i = 0; i < input.length; i++) {
        result.add(pointer[i]);
      }

      return result;
    } finally {
      // 메모리 해제
      ffi.calloc.free(pointer);
    }
  }
}
```

### 3.2 복잡한 구조체 전달

```dart
// ============= C 구조체 =============
// native/image_processor.h
typedef struct {
    uint8_t* data;
    int32_t width;
    int32_t height;
    int32_t channels;
} Image;

typedef struct {
    double r;
    double g;
    double b;
    double a;
} Color;

__attribute__((visibility("default"))) __attribute__((used))
void apply_filter(Image* image, Color* tint);

// ============= Dart FFI 구조체 =============
import 'dart:ffi' as ffi;
import 'dart:typed_data';

// Dart에서 C 구조체 정의
class ImageStruct extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> data;

  @ffi.Int32()
  external int width;

  @ffi.Int32()
  external int height;

  @ffi.Int32()
  external int channels;
}

class ColorStruct extends ffi.Struct {
  @ffi.Double()
  external double r;

  @ffi.Double()
  external double g;

  @ffi.Double()
  external double b;

  @ffi.Double()
  external double a;
}

typedef ApplyFilterFunc = ffi.Void Function(
  ffi.Pointer<ImageStruct> image,
  ffi.Pointer<ColorStruct> tint,
);
typedef ApplyFilterDart = void Function(
  ffi.Pointer<ImageStruct> image,
  ffi.Pointer<ColorStruct> tint,
);

class NativeImageProcessor {
  late final ffi.DynamicLibrary _lib;
  late final ApplyFilterDart _applyFilter;

  NativeImageProcessor() {
    _lib = Platform.isAndroid
        ? ffi.DynamicLibrary.open('libimage_processor.so')
        : ffi.DynamicLibrary.process();

    _applyFilter = _lib.lookupFunction<ApplyFilterFunc, ApplyFilterDart>('apply_filter');
  }

  Uint8List applyFilter(
    Uint8List imageData,
    int width,
    int height,
    int channels,
    Color tintColor,
  ) {
    // 이미지 데이터를 C 메모리에 할당
    final dataSize = width * height * channels;
    final dataPointer = ffi.calloc<ffi.Uint8>(dataSize);

    // 이미지 구조체 할당
    final imagePointer = ffi.calloc<ImageStruct>();

    // 색상 구조체 할당
    final colorPointer = ffi.calloc<ColorStruct>();

    try {
      // 데이터 복사
      for (int i = 0; i < dataSize; i++) {
        dataPointer[i] = imageData[i];
      }

      // 이미지 구조체 설정
      imagePointer.ref.data = dataPointer;
      imagePointer.ref.width = width;
      imagePointer.ref.height = height;
      imagePointer.ref.channels = channels;

      // 색상 구조체 설정
      colorPointer.ref.r = tintColor.red / 255.0;
      colorPointer.ref.g = tintColor.green / 255.0;
      colorPointer.ref.b = tintColor.blue / 255.0;
      colorPointer.ref.a = tintColor.alpha / 255.0;

      // C 함수 호출
      _applyFilter(imagePointer, colorPointer);

      // 결과를 Dart로 변환
      final result = Uint8List(dataSize);
      for (int i = 0; i < dataSize; i++) {
        result[i] = dataPointer[i];
      }

      return result;
    } finally {
      // 메모리 해제
      ffi.calloc.free(dataPointer);
      ffi.calloc.free(imagePointer);
      ffi.calloc.free(colorPointer);
    }
  }
}
```

### 3.3 비동기 FFI 호출

```dart
// ============= C 라이브러리 (긴 작업) =============
// native/heavy_computation.c
#include <stdint.h>
#include <unistd.h>

__attribute__((visibility("default"))) __attribute__((used))
int64_t heavy_computation(int32_t input) {
    // 무거운 계산 시뮬레이션
    sleep(2);
    int64_t result = 0;
    for (int64_t i = 0; i < input * 1000000; i++) {
        result += i;
    }
    return result;
}

// ============= Dart FFI (비동기) =============
import 'dart:ffi' as ffi;
import 'dart:isolate';

typedef HeavyComputationFunc = ffi.Int64 Function(ffi.Int32 input);
typedef HeavyComputationDart = int Function(int input);

class NativeHeavyComputation {
  late final ffi.DynamicLibrary _lib;
  late final HeavyComputationDart _heavyComputation;

  NativeHeavyComputation() {
    _lib = Platform.isAndroid
        ? ffi.DynamicLibrary.open('libheavy_computation.so')
        : ffi.DynamicLibrary.process();

    _heavyComputation = _lib.lookupFunction<HeavyComputationFunc, HeavyComputationDart>(
      'heavy_computation',
    );
  }

  // 동기 호출 (UI 블로킹)
  int computeSync(int input) {
    return _heavyComputation(input);
  }

  // 비동기 호출 (Isolate 사용)
  Future<int> computeAsync(int input) async {
    return Isolate.run(() => _heavyComputation(input));
  }

  // 스트림으로 여러 작업 처리
  Stream<int> computeStream(List<int> inputs) async* {
    for (final input in inputs) {
      yield await computeAsync(input);
    }
  }
}

// 사용 예
class ComputationBloc extends Bloc<ComputationEvent, ComputationState> {
  final NativeHeavyComputation _computation;

  ComputationBloc(this._computation) : super(const ComputationState.initial()) {
    on<ComputationEvent>(_onEvent);
  }

  Future<void> _onCompute(int input, Emitter<ComputationState> emit) async {
    emit(const ComputationState.loading());

    try {
      // 비동기 호출 (UI 블로킹 없음)
      final result = await _computation.computeAsync(input);
      emit(ComputationState.completed(result));
    } catch (e) {
      emit(ComputationState.error(e.toString()));
    }
  }
}
```

### 3.4 ffigen을 사용한 자동 바인딩 생성

```yaml
# pubspec.yaml
dev_dependencies:
  ffigen: ^13.0.0

# ffigen.yaml
name: NativeLibrary
description: Auto-generated bindings for native library
output: 'lib/src/generated/native_bindings.dart'
headers:
  entry-points:
    - 'native/calculator.h'
    - 'native/image_processor.h'
  include-directives:
    - 'native/**'
compiler-opts:
  - '-I/usr/include'
```

```dart
// 자동 생성된 바인딩 사용
import 'generated/native_bindings.dart';

class NativeWrapper {
  late final NativeLibrary _bindings;

  NativeWrapper() {
    final lib = Platform.isAndroid
        ? ffi.DynamicLibrary.open('libnative.so')
        : ffi.DynamicLibrary.process();

    _bindings = NativeLibrary(lib);
  }

  // 타입 안전한 호출
  int add(int a, int b) => _bindings.add(a, b);

  double multiply(double a, double b) => _bindings.multiply(a, b);
}
```

---

## 4. Pigeon을 사용한 타입 안전 Channel

Pigeon은 타입 안전한 Platform Channel 코드를 자동 생성합니다.

### 4.1 Pigeon 설정

```yaml
# pubspec.yaml
dev_dependencies:
  pigeon: ^22.0.0

# pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/pigeon_messages.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/app/src/main/kotlin/dev/flutter/pigeon/Messages.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.example.app',
  ),
  swiftOut: 'ios/Runner/Messages.swift',
  swiftOptions: SwiftOptions(),
))

// ============= 데이터 클래스 정의 =============
class User {
  String? id;
  String? name;
  String? email;
  int? age;
}

class LoginRequest {
  String? email;
  String? password;
}

class LoginResponse {
  User? user;
  String? token;
  String? refreshToken;
}

// ============= API 인터페이스 정의 =============
@HostApi()
abstract class AuthApi {
  @async
  LoginResponse login(LoginRequest request);

  @async
  void logout();

  @async
  User getCurrentUser();

  @async
  bool isAuthenticated();
}

// Flutter → Native 통신
@FlutterApi()
abstract class AuthCallbackApi {
  void onAuthStateChanged(User? user);
  void onTokenRefreshed(String token);
}
```

### 4.2 생성된 코드 사용

```dart
// ============= Flutter 구현 =============
import 'generated/pigeon_messages.dart';

// Native 구현 호출
class AuthRepository {
  final AuthApi _authApi = AuthApi();

  Future<LoginResponse> login(String email, String password) async {
    final request = LoginRequest(
      email: email,
      password: password,
    );

    return await _authApi.login(request);
  }

  Future<void> logout() async {
    await _authApi.logout();
  }

  Future<User> getCurrentUser() async {
    return await _authApi.getCurrentUser();
  }

  Future<bool> isAuthenticated() async {
    return await _authApi.isAuthenticated();
  }
}

// Native → Flutter 콜백 수신
class AuthCallbackHandler extends AuthCallbackApi {
  final StreamController<User?> _authStateController = StreamController.broadcast();
  final StreamController<String> _tokenController = StreamController.broadcast();

  Stream<User?> get authStateStream => _authStateController.stream;
  Stream<String> get tokenStream => _tokenController.stream;

  @override
  void onAuthStateChanged(User? user) {
    _authStateController.add(user);
  }

  @override
  void onTokenRefreshed(String token) {
    _tokenController.add(token);
  }

  void dispose() {
    _authStateController.close();
    _tokenController.close();
  }
}

// ============= Android 구현 (Kotlin) =============
class AuthApiImpl : AuthApi {
    override fun login(request: LoginRequest, callback: (Result<LoginResponse>) -> Unit) {
        // 비동기 작업
        GlobalScope.launch {
            try {
                val user = authenticateUser(request.email!!, request.password!!)
                val token = generateToken(user)
                val refreshToken = generateRefreshToken(user)

                val response = LoginResponse().apply {
                    this.user = user
                    this.token = token
                    this.refreshToken = refreshToken
                }

                callback(Result.success(response))
            } catch (e: Exception) {
                callback(Result.failure(e))
            }
        }
    }

    override fun logout(callback: (Result<Unit>) -> Unit) {
        clearSession()
        callback(Result.success(Unit))
    }

    override fun getCurrentUser(callback: (Result<User>) -> Unit) {
        val user = sessionManager.getCurrentUser()
        if (user != null) {
            callback(Result.success(user))
        } else {
            callback(Result.failure(Exception("No user logged in")))
        }
    }

    override fun isAuthenticated(callback: (Result<Boolean>) -> Unit) {
        val isAuth = sessionManager.isAuthenticated()
        callback(Result.success(isAuth))
    }

    // Native → Flutter 콜백
    private fun notifyAuthStateChanged(user: User?) {
        authCallbackApi.onAuthStateChanged(user) {}
    }
}

// ============= iOS 구현 (Swift) =============
class AuthApiImpl: AuthApi {
    func login(request: LoginRequest, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        // 비동기 작업
        DispatchQueue.global().async {
            do {
                let user = try self.authenticateUser(
                    email: request.email!,
                    password: request.password!
                )
                let token = self.generateToken(user: user)
                let refreshToken = self.generateRefreshToken(user: user)

                let response = LoginResponse(
                    user: user,
                    token: token,
                    refreshToken: refreshToken
                )

                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        clearSession()
        completion(.success(()))
    }

    func getCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        if let user = sessionManager.getCurrentUser() {
            completion(.success(user))
        } else {
            completion(.failure(NSError(domain: "AuthError", code: 401)))
        }
    }

    func isAuthenticated(completion: @escaping (Result<Bool, Error>) -> Void) {
        let isAuth = sessionManager.isAuthenticated()
        completion(.success(isAuth))
    }

    // Native → Flutter 콜백
    private func notifyAuthStateChanged(user: User?) {
        authCallbackApi.onAuthStateChanged(user: user) { }
    }
}
```

### 4.3 복잡한 데이터 타입

```dart
// pigeons/complex_types.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/complex_types.dart',
  kotlinOut: 'android/app/src/main/kotlin/dev/flutter/pigeon/ComplexTypes.kt',
  swiftOut: 'ios/Runner/ComplexTypes.swift',
))

// Enum
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  applePay,
  googlePay,
}

// Nested objects
class Address {
  String? street;
  String? city;
  String? state;
  String? zipCode;
  String? country;
}

class PaymentInfo {
  PaymentMethod? method;
  String? cardNumber;
  String? expiryDate;
  String? cvv;
  Address? billingAddress;
}

class Order {
  String? id;
  List<OrderItem?>? items;
  PaymentInfo? paymentInfo;
  Address? shippingAddress;
  double? total;
  DateTime? createdAt;
}

class OrderItem {
  String? productId;
  String? name;
  int? quantity;
  double? price;
}

// Complex API
@HostApi()
abstract class OrderApi {
  @async
  Order createOrder(Order order);

  @async
  List<Order> getOrders(int page, int pageSize);

  @async
  Order getOrderById(String orderId);

  @async
  void cancelOrder(String orderId);

  @async
  Map<String, Object> getOrderStatistics();
}
```

---

## 5. 네이티브 뷰 임베딩

Flutter 위젯 트리에 네이티브 뷰를 임베딩합니다.

### 5.1 AndroidView

```dart
// ============= Flutter Side =============
class NativeMapView extends StatelessWidget {
  final LatLng initialPosition;
  final double zoom;
  final ValueChanged<LatLng>? onCameraMove;

  const NativeMapView({
    super.key,
    required this.initialPosition,
    this.zoom = 15.0,
    this.onCameraMove,
  });

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'com.example.app/mapview',
      creationParams: {
        'latitude': initialPosition.latitude,
        'longitude': initialPosition.longitude,
        'zoom': zoom,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (int id) {
        _onPlatformViewCreated(id);
      },
    );
  }

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('com.example.app/mapview_$id');

    channel.setMethodCallHandler((call) async {
      if (call.method == 'onCameraMove') {
        final lat = call.arguments['latitude'] as double;
        final lng = call.arguments['longitude'] as double;
        onCameraMove?.call(LatLng(lat, lng));
      }
    });
  }
}

// ============= Android Side (Kotlin) =============
// MapViewFactory.kt
import android.content.Context
import android.view.View
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.model.LatLng
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MapViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>
        return NativeMapView(context, messenger, id, params)
    }
}

class NativeMapView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    params: Map<String, Any>?
) : PlatformView {
    private val mapView = MapView(context)
    private val channel = MethodChannel(messenger, "com.example.app/mapview_$id")
    private var googleMap: GoogleMap? = null

    init {
        mapView.onCreate(null)
        mapView.getMapAsync { map ->
            googleMap = map

            // 초기 위치 설정
            params?.let {
                val lat = it["latitude"] as? Double ?: 0.0
                val lng = it["longitude"] as? Double ?: 0.0
                val zoom = it["zoom"] as? Double ?: 15.0

                val position = LatLng(lat, lng)
                map.moveCamera(CameraUpdateFactory.newLatLngZoom(position, zoom.toFloat()))
            }

            // 카메라 이동 리스너
            map.setOnCameraMoveListener {
                val position = map.cameraPosition.target
                channel.invokeMethod("onCameraMove", mapOf(
                    "latitude" to position.latitude,
                    "longitude" to position.longitude
                ))
            }
        }

        // Method channel handler
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "animateCamera" -> {
                    val lat = call.argument<Double>("latitude")!!
                    val lng = call.argument<Double>("longitude")!!
                    val zoom = call.argument<Double>("zoom")!!

                    googleMap?.animateCamera(
                        CameraUpdateFactory.newLatLngZoom(
                            LatLng(lat, lng),
                            zoom.toFloat()
                        )
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun getView(): View = mapView

    override fun dispose() {
        mapView.onDestroy()
    }
}

// MainActivity.kt에서 등록
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "com.example.app/mapview",
                MapViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}
```

### 5.2 UiKitView (iOS)

```dart
// ============= Flutter Side =============
class NativeMapView extends StatelessWidget {
  final LatLng initialPosition;
  final double zoom;

  const NativeMapView({
    super.key,
    required this.initialPosition,
    this.zoom = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'com.example.app/mapview',
        creationParams: {
          'latitude': initialPosition.latitude,
          'longitude': initialPosition.longitude,
          'zoom': zoom,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return AndroidView(/* ... */);
  }

  void _onPlatformViewCreated(int id) {
    // iOS specific setup
  }
}

// ============= iOS Side (Swift) =============
// MapViewFactory.swift
import Flutter
import MapKit

class MapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NativeMapView(
            frame: frame,
            viewId: viewId,
            args: args,
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeMapView: NSObject, FlutterPlatformView, MKMapViewDelegate {
    private var mapView: MKMapView
    private var channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewId: Int64,
        args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        mapView = MKMapView(frame: frame)
        channel = FlutterMethodChannel(
            name: "com.example.app/mapview_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        mapView.delegate = self

        // 초기 위치 설정
        if let params = args as? [String: Any] {
            let latitude = params["latitude"] as? Double ?? 0.0
            let longitude = params["longitude"] as? Double ?? 0.0
            let zoom = params["zoom"] as? Double ?? 15.0

            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: zoom * 1000,
                longitudinalMeters: zoom * 1000
            )
            mapView.setRegion(region, animated: false)
        }

        // Method channel handler
        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "animateCamera":
                if let args = call.arguments as? [String: Any],
                   let lat = args["latitude"] as? Double,
                   let lng = args["longitude"] as? Double {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    let region = MKCoordinateRegion(
                        center: coordinate,
                        latitudinalMeters: 1000,
                        longitudinalMeters: 1000
                    )
                    self?.mapView.setRegion(region, animated: true)
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView {
        return mapView
    }

    // MKMapViewDelegate
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        channel.invokeMethod("onCameraMove", arguments: [
            "latitude": center.latitude,
            "longitude": center.longitude
        ])
    }
}

// AppDelegate.swift에서 등록
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let registrar = controller.registrar(forPlugin: "MapView")!

        let factory = MapViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.example.app/mapview")

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 5.3 Hybrid Composition vs Virtual Display

```dart
// ============= Hybrid Composition (권장) =============
// - 더 나은 성능
// - 네이티브 터치 이벤트 지원
// - 플랫폼별 제스처 동작

AndroidView(
  viewType: 'com.example.app/webview',
  // Hybrid Composition 사용 (기본값)
)

// ============= Virtual Display (레거시) =============
// - 호환성이 더 좋음
// - 약간 느린 성능
// - 일부 터치 이벤트 이슈

PlatformViewLink(
  viewType: 'com.example.app/webview',
  surfaceFactory: (context, controller) {
    return AndroidViewSurface(
      controller: controller as AndroidViewController,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
  },
  onCreatePlatformView: (params) {
    return PlatformViewsService.initAndroidView(
      id: params.id,
      viewType: 'com.example.app/webview',
      layoutDirection: TextDirection.ltr,
      creationParams: {},
      creationParamsCodec: const StandardMessageCodec(),
      onFocus: () {
        params.onFocusChanged(true);
      },
    )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated);
  },
)
```

### 5.4 네이티브 뷰 성능 최적화

```dart
// ============= 지연 로딩 =============
class LazyNativeView extends StatefulWidget {
  @override
  State<LazyNativeView> createState() => _LazyNativeViewState();
}

class _LazyNativeViewState extends State<LazyNativeView> {
  bool _shouldRender = false;

  @override
  void initState() {
    super.initState();
    // 뷰가 실제로 필요할 때까지 대기
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _shouldRender = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender) {
      return const Placeholder(); // 또는 로딩 인디케이터
    }

    return const NativeMapView(
      initialPosition: LatLng(37.7749, -122.4194),
    );
  }
}

// ============= 조건부 렌더링 =============
class ConditionalNativeView extends StatelessWidget {
  final bool useNativeView;

  const ConditionalNativeView({super.key, required this.useNativeView});

  @override
  Widget build(BuildContext context) {
    if (useNativeView) {
      return const NativeMapView(
        initialPosition: LatLng(37.7749, -122.4194),
      );
    }

    // Flutter 위젯으로 대체 (성능 향상)
    return FlutterMap(
      initialPosition: const LatLng(37.7749, -122.4194),
    );
  }
}

// ============= 메모리 관리 =============
class ManagedNativeView extends StatefulWidget {
  @override
  State<ManagedNativeView> createState() => _ManagedNativeViewState();
}

class _ManagedNativeViewState extends State<ManagedNativeView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 화면 전환 시 유지

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    return const NativeMapView(
      initialPosition: LatLng(37.7749, -122.4194),
    );
  }

  @override
  void dispose() {
    // 명시적으로 리소스 정리
    super.dispose();
  }
}
```

---

## 6. Platform-specific 코드 최적화

### 6.1 플랫폼별 구현 분기

```dart
// ============= 플랫폼 감지 =============
import 'dart:io' show Platform;

class PlatformService {
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => kIsWeb;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

// ============= 플랫폼별 구현 =============
abstract class CameraService {
  Future<XFile?> takePicture();
  Future<List<XFile>> pickMultipleImages();
}

class CameraServiceImpl implements CameraService {
  final CameraService _delegate;

  factory CameraServiceImpl() {
    if (Platform.isAndroid) {
      return CameraServiceImpl._(AndroidCameraService());
    } else if (Platform.isIOS) {
      return CameraServiceImpl._(IOSCameraService());
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  CameraServiceImpl._(this._delegate);

  @override
  Future<XFile?> takePicture() => _delegate.takePicture();

  @override
  Future<List<XFile>> pickMultipleImages() => _delegate.pickMultipleImages();
}

// Android 구현
class AndroidCameraService implements CameraService {
  @override
  Future<XFile?> takePicture() async {
    // Android specific implementation
    // CameraX API 사용
  }

  @override
  Future<List<XFile>> pickMultipleImages() async {
    // Android Photo Picker API (Android 13+)
  }
}

// iOS 구현
class IOSCameraService implements CameraService {
  @override
  Future<XFile?> takePicture() async {
    // iOS specific implementation
    // AVFoundation 사용
  }

  @override
  Future<List<XFile>> pickMultipleImages() async {
    // PHPickerViewController 사용
  }
}
```

### 6.2 조건부 import

```dart
// ============= 플랫폼별 파일 분리 =============
// lib/src/services/storage_service.dart
export 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_mobile.dart'
    if (dart.library.html) 'storage_service_web.dart';

// lib/src/services/storage_service_stub.dart
abstract class StorageService {
  Future<void> save(String key, String value);
  Future<String?> read(String key);
}

class StorageServiceImpl implements StorageService {
  StorageServiceImpl() {
    throw UnsupportedError('Platform not supported');
  }

  @override
  Future<void> save(String key, String value) => throw UnimplementedError();

  @override
  Future<String?> read(String key) => throw UnimplementedError();
}

// lib/src/services/storage_service_mobile.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageServiceImpl implements StorageService {
  late final SharedPreferences _prefs;

  StorageServiceImpl() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<void> save(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }
}

// lib/src/services/storage_service_web.dart
import 'dart:html' as html;

class StorageServiceImpl implements StorageService {
  @override
  Future<void> save(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }
}

// 사용
import 'services/storage_service.dart';

final storage = StorageServiceImpl(); // 자동으로 플랫폼별 구현 선택
```

### 6.3 플랫폼별 UI 최적화

```dart
// ============= Material vs Cupertino =============
class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
  }
}

// ============= 플랫폼별 스크롤 동작 =============
class AdaptiveScrollView extends StatelessWidget {
  final List<Widget> children;

  const AdaptiveScrollView({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: Platform.isIOS
          ? const CupertinoScrollBehavior()
          : const MaterialScrollBehavior(),
      child: ListView(children: children),
    );
  }
}

// ============= 플랫폼별 애니메이션 =============
class AdaptivePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  AdaptivePageRoute({required this.builder});

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => '';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Platform.isIOS) {
      // iOS style slide transition
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        child: child,
        linearTransition: false,
      );
    }

    // Android style fade + slide transition
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}
```

---

## 7. 백그라운드 Isolate와 네이티브 통신

### 7.1 백그라운드 Isolate 설정

```dart
// ============= 백그라운드 작업 =============
class BackgroundService {
  static const MethodChannel _channel = MethodChannel('com.example.app/background');

  // 백그라운드 Isolate 진입점
  @pragma('vm:entry-point')
  static Future<void> backgroundEntryPoint() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 백그라운드 Method Channel 설정
    const backgroundChannel = MethodChannel('com.example.app/background');

    backgroundChannel.setMethodCallHandler((call) async {
      if (call.method == 'process') {
        final data = call.arguments as Map<String, dynamic>;
        final result = await _processData(data);
        return result;
      }
    });
  }

  static Future<Map<String, dynamic>> _processData(Map<String, dynamic> data) async {
    // 무거운 작업 처리
    await Future.delayed(const Duration(seconds: 2));
    return {'result': 'processed'};
  }

  // 백그라운드 작업 시작
  static Future<void> startBackgroundTask() async {
    await _channel.invokeMethod('startBackground');
  }

  static Future<void> stopBackgroundTask() async {
    await _channel.invokeMethod('stopBackground');
  }
}

// ============= Android Side (Kotlin) =============
import android.content.Context
import android.content.Intent
import androidx.work.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain

class BackgroundWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    override fun doWork(): Result {
        // Flutter Engine 초기화
        FlutterMain.startInitialization(applicationContext)
        FlutterMain.ensureInitializationComplete(applicationContext, null)

        val flutterEngine = FlutterEngine(applicationContext)

        // Dart 콜백 실행
        val callbackHandle = inputData.getLong("callback_handle", 0)
        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)

        flutterEngine.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(
                applicationContext.assets,
                FlutterMain.findAppBundlePath()!!,
                callbackInfo
            )
        )

        // 작업 완료 대기
        Thread.sleep(5000)

        flutterEngine.destroy()

        return Result.success()
    }
}

class BackgroundPlugin : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startBackground" -> {
                val workRequest = OneTimeWorkRequestBuilder<BackgroundWorker>()
                    .setInputData(
                        Data.Builder()
                            .putLong("callback_handle", call.argument<Long>("callback_handle")!!)
                            .build()
                    )
                    .build()

                WorkManager.getInstance(context)
                    .enqueue(workRequest)

                result.success(null)
            }
            "stopBackground" -> {
                WorkManager.getInstance(context).cancelAllWork()
                result.success(null)
            }
        }
    }
}

// ============= iOS Side (Swift) =============
import Flutter
import UIKit

class BackgroundPlugin: NSObject, FlutterPlugin {
    private var flutterEngine: FlutterEngine?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.app/background",
            binaryMessenger: registrar.messenger()
        )
        let instance = BackgroundPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startBackground":
            guard let args = call.arguments as? [String: Any],
                  let callbackHandle = args["callback_handle"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }

            startBackgroundTask(callbackHandle: callbackHandle)
            result(nil)

        case "stopBackground":
            stopBackgroundTask()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startBackgroundTask(callbackHandle: Int64) {
        flutterEngine = FlutterEngine(name: "background")
        flutterEngine?.run(withEntrypoint: nil, libraryURI: nil)

        let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)

        flutterEngine?.dartExecutor.execute(
            withEntrypoint: callbackInfo?.callbackName,
            libraryURI: callbackInfo?.callbackLibraryPath
        )
    }

    private func stopBackgroundTask() {
        flutterEngine?.destroyContext()
        flutterEngine = nil
    }
}
```

### 7.2 Isolate 간 통신

```dart
// ============= Root Isolate ↔ Background Isolate =============
class IsolateCommunication {
  static SendPort? _backgroundSendPort;
  static ReceivePort? _receivePort;

  static Future<void> initialize() async {
    _receivePort = ReceivePort();

    // Background Isolate 시작
    await Isolate.spawn(
      _backgroundIsolate,
      _receivePort!.sendPort,
    );

    // Background Isolate의 SendPort 받기
    _backgroundSendPort = await _receivePort!.first as SendPort;
  }

  static void sendToBackground(Map<String, dynamic> data) {
    _backgroundSendPort?.send(data);
  }

  static Stream<dynamic> get messagesFromBackground {
    return _receivePort!.asBroadcastStream().skip(1); // 첫 번째 SendPort 스킵
  }

  @pragma('vm:entry-point')
  static void _backgroundIsolate(SendPort mainSendPort) async {
    final backgroundReceivePort = ReceivePort();

    // Main Isolate에 SendPort 전송
    mainSendPort.send(backgroundReceivePort.sendPort);

    // Main Isolate로부터 메시지 수신
    await for (final message in backgroundReceivePort) {
      if (message is Map<String, dynamic>) {
        // 작업 처리
        final result = await _processInBackground(message);

        // 결과 전송
        mainSendPort.send(result);
      }
    }
  }

  static Future<Map<String, dynamic>> _processInBackground(
    Map<String, dynamic> data,
  ) async {
    // 무거운 작업
    await Future.delayed(const Duration(seconds: 1));
    return {'status': 'completed', 'data': data};
  }
}

// 사용 예
class DataProcessingBloc extends Bloc<DataEvent, DataState> {
  DataProcessingBloc() : super(const DataState.initial()) {
    on<DataEvent>(_onEvent);

    // Isolate 초기화
    IsolateCommunication.initialize();

    // Background Isolate로부터 메시지 수신
    IsolateCommunication.messagesFromBackground.listen((message) {
      add(DataEvent.backgroundResultReceived(message));
    });
  }

  Future<void> _onProcess(Emitter<DataState> emit) async {
    emit(const DataState.processing());

    // Background Isolate로 작업 전송
    IsolateCommunication.sendToBackground({
      'type': 'heavy_computation',
      'input': state.data,
    });
  }

  Future<void> _onBackgroundResultReceived(
    Map<String, dynamic> result,
    Emitter<DataState> emit,
  ) async {
    emit(DataState.completed(result));
  }
}
```

---

## 8. 네이티브 SDK 통합 패턴

### 8.1 카메라 통합 (CameraX / AVFoundation)

```dart
// ============= Flutter Wrapper =============
class NativeCameraService {
  static const MethodChannel _channel = MethodChannel('com.example.app/camera');

  Future<void> startCamera() async {
    await _channel.invokeMethod('startCamera');
  }

  Future<void> stopCamera() async {
    await _channel.invokeMethod('stopCamera');
  }

  Future<String> capturePhoto() async {
    final String path = await _channel.invokeMethod('capturePhoto');
    return path;
  }

  Future<void> startVideoRecording() async {
    await _channel.invokeMethod('startVideoRecording');
  }

  Future<String> stopVideoRecording() async {
    final String path = await _channel.invokeMethod('stopVideoRecording');
    return path;
  }

  Stream<Uint8List> get previewStream {
    const eventChannel = EventChannel('com.example.app/camera_preview');
    return eventChannel.receiveBroadcastStream().cast<Uint8List>();
  }
}

// ============= Android (CameraX) =============
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraPlugin(
    private val activity: FragmentActivity
) : MethodCallHandler {
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture? = null
    private lateinit var cameraExecutor: ExecutorService

    init {
        cameraExecutor = Executors.newSingleThreadExecutor()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startCamera" -> {
                startCamera(result)
            }
            "stopCamera" -> {
                stopCamera(result)
            }
            "capturePhoto" -> {
                capturePhoto(result)
            }
            "startVideoRecording" -> {
                startVideoRecording(result)
            }
            "stopVideoRecording" -> {
                stopVideoRecording(result)
            }
        }
    }

    private fun startCamera(result: Result) {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            val preview = Preview.Builder().build()

            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build()

            val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

            try {
                cameraProvider?.unbindAll()
                cameraProvider?.bindToLifecycle(
                    activity,
                    cameraSelector,
                    preview,
                    imageCapture
                )

                result.success(null)
            } catch (e: Exception) {
                result.error("CAMERA_ERROR", e.message, null)
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    private fun capturePhoto(result: Result) {
        val imageCapture = imageCapture ?: run {
            result.error("NO_CAMERA", "Camera not started", null)
            return
        }

        val photoFile = File(
            activity.externalMediaDirs.firstOrNull(),
            "${System.currentTimeMillis()}.jpg"
        )

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()

        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(activity),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    result.success(photoFile.absolutePath)
                }

                override fun onError(exception: ImageCaptureException) {
                    result.error("CAPTURE_ERROR", exception.message, null)
                }
            }
        )
    }
}

// ============= iOS (AVFoundation) =============
import AVFoundation
import UIKit

class CameraPlugin: NSObject, FlutterPlugin, AVCapturePhotoCaptureDelegate {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var photoResult: FlutterResult?

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startCamera":
            startCamera(result: result)
        case "stopCamera":
            stopCamera(result: result)
        case "capturePhoto":
            capturePhoto(result: result)
        case "startVideoRecording":
            startVideoRecording(result: result)
        case "stopVideoRecording":
            stopVideoRecording(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startCamera(result: @escaping FlutterResult) {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              let session = captureSession else {
            result(FlutterError(code: "CAMERA_ERROR", message: "Failed to start camera", details: nil))
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput!) {
            session.addOutput(photoOutput!)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }

    private func capturePhoto(result: @escaping FlutterResult) {
        guard let photoOutput = photoOutput else {
            result(FlutterError(code: "NO_CAMERA", message: "Camera not started", details: nil))
            return
        }

        self.photoResult = result

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoResult?(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoResult?(FlutterError(code: "CAPTURE_ERROR", message: "Failed to process photo", details: nil))
            return
        }

        // 파일로 저장
        let filename = "\(Date().timeIntervalSince1970).jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL)
            photoResult?(fileURL.path)
        }
    }
}
```

### 8.2 생체 인증 통합

```dart
// ============= Flutter Wrapper =============
class BiometricAuthService {
  static const MethodChannel _channel = MethodChannel('com.example.app/biometric');

  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('authenticate', {
        'reason': reason,
        'useErrorDialogs': useErrorDialogs,
        'stickyAuth': stickyAuth,
      });
      return result;
    } on PlatformException catch (e) {
      print('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final bool result = await _channel.invokeMethod('canCheckBiometrics');
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<dynamic> types = await _channel.invokeMethod('getAvailableBiometrics');
      return types.map((type) => BiometricType.fromString(type as String)).toList();
    } catch (e) {
      return [];
    }
  }
}

enum BiometricType {
  face,
  fingerprint,
  iris,
  weak,
  strong;

  static BiometricType fromString(String value) {
    return BiometricType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => BiometricType.weak,
    );
  }
}

// ============= Android (BiometricPrompt) =============
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat

class BiometricPlugin(
    private val activity: FragmentActivity
) : MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "authenticate" -> {
                val reason = call.argument<String>("reason")!!
                val useErrorDialogs = call.argument<Boolean>("useErrorDialogs") ?: true
                authenticate(reason, useErrorDialogs, result)
            }
            "canCheckBiometrics" -> {
                result.success(canCheckBiometrics())
            }
            "getAvailableBiometrics" -> {
                result.success(getAvailableBiometrics())
            }
        }
    }

    private fun authenticate(reason: String, useErrorDialogs: Boolean, result: Result) {
        val executor = ContextCompat.getMainExecutor(activity)

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    result.error("AUTH_ERROR", errString.toString(), errorCode)
                }

                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    result.success(true)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    result.success(false)
                }
            }
        )

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle(reason)
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(
                BiometricManager.Authenticators.BIOMETRIC_STRONG or
                BiometricManager.Authenticators.DEVICE_CREDENTIAL
            )
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    private fun canCheckBiometrics(): Boolean {
        val biometricManager = BiometricManager.from(activity)
        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }

    private fun getAvailableBiometrics(): List<String> {
        val types = mutableListOf<String>()
        val biometricManager = BiometricManager.from(activity)

        when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> types.add("strong")
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {}
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {}
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {}
        }

        return types
    }
}
```

---

## 9. Kotlin Multiplatform과 Flutter

### 9.1 KMP 공유 코드

```kotlin
// ============= Kotlin Multiplatform 공유 코드 =============
// shared/src/commonMain/kotlin/com/example/app/DataProcessor.kt
expect class Platform() {
    val name: String
}

class DataProcessor {
    fun process(input: String): String {
        return "Processed on ${Platform().name}: $input"
    }

    fun calculateHash(data: ByteArray): String {
        // 공통 로직
        return data.contentHashCode().toString()
    }
}

// Android 구현
// shared/src/androidMain/kotlin/com/example/app/Platform.kt
actual class Platform actual constructor() {
    actual val name: String = "Android ${android.os.Build.VERSION.SDK_INT}"
}

// iOS 구현
// shared/src/iosMain/kotlin/com/example/app/Platform.kt
import platform.UIKit.UIDevice

actual class Platform actual constructor() {
    actual val name: String = UIDevice.currentDevice.systemName() + " " + UIDevice.currentDevice.systemVersion
}
```

### 9.2 Flutter에서 KMP 사용

```dart
// ============= Flutter Bridge =============
class KMPDataProcessor {
  static const MethodChannel _channel = MethodChannel('com.example.app/kmp');

  Future<String> process(String input) async {
    final String result = await _channel.invokeMethod('process', {'input': input});
    return result;
  }

  Future<String> calculateHash(Uint8List data) async {
    final String result = await _channel.invokeMethod('calculateHash', {'data': data});
    return result;
  }
}

// ============= Android Bridge =============
class KMPPlugin : MethodCallHandler {
    private val dataProcessor = DataProcessor()

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "process" -> {
                val input = call.argument<String>("input")!!
                val output = dataProcessor.process(input)
                result.success(output)
            }
            "calculateHash" -> {
                val data = call.argument<ByteArray>("data")!!
                val hash = dataProcessor.calculateHash(data)
                result.success(hash)
            }
        }
    }
}

// ============= iOS Bridge =============
class KMPPlugin: NSObject, FlutterPlugin {
    private let dataProcessor = DataProcessor()

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "process":
            if let args = call.arguments as? [String: Any],
               let input = args["input"] as? String {
                let output = dataProcessor.process(input: input)
                result(output)
            }
        case "calculateHash":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? FlutterStandardTypedData {
                let hash = dataProcessor.calculateHash(data: data.data)
                result(hash)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

---

## 10. 직렬화 성능 최적화

### 10.1 직렬화 방식 비교

```dart
// ============= JSON vs MessagePack vs Protobuf =============

// 1. JSON (표준 방식)
class JsonSerializer {
  static Map<String, dynamic> encode(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'age': user.age,
    };
  }

  static User decode(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      age: json['age'] as int,
    );
  }
}

// 2. MessagePack (더 작은 크기, 더 빠름)
import 'package:msgpack_dart/msgpack_dart.dart';

class MessagePackSerializer {
  static Uint8List encode(User user) {
    final data = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'age': user.age,
    };
    return serialize(data);
  }

  static User decode(Uint8List bytes) {
    final data = deserialize(bytes) as Map;
    return User(
      id: data['id'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      age: data['age'] as int,
    );
  }
}

// 3. Protocol Buffers (타입 안전, 스키마)
// user.proto
// syntax = "proto3";
// message User {
//   string id = 1;
//   string name = 2;
//   string email = 3;
//   int32 age = 4;
// }

import 'generated/user.pb.dart';

class ProtobufSerializer {
  static Uint8List encode(User user) {
    final proto = UserProto()
      ..id = user.id
      ..name = user.name
      ..email = user.email
      ..age = user.age;

    return proto.writeToBuffer();
  }

  static User decode(Uint8List bytes) {
    final proto = UserProto.fromBuffer(bytes);
    return User(
      id: proto.id,
      name: proto.name,
      email: proto.email,
      age: proto.age,
    );
  }
}

// 성능 벤치마크
class SerializationBenchmark {
  static Future<void> run() async {
    final user = User(
      id: '123',
      name: 'John Doe',
      email: 'john@example.com',
      age: 30,
    );

    // JSON
    final jsonStart = DateTime.now();
    for (int i = 0; i < 10000; i++) {
      final encoded = jsonEncode(JsonSerializer.encode(user));
      JsonSerializer.decode(jsonDecode(encoded));
    }
    final jsonDuration = DateTime.now().difference(jsonStart);
    print('JSON: ${jsonDuration.inMilliseconds}ms');

    // MessagePack
    final msgpackStart = DateTime.now();
    for (int i = 0; i < 10000; i++) {
      final encoded = MessagePackSerializer.encode(user);
      MessagePackSerializer.decode(encoded);
    }
    final msgpackDuration = DateTime.now().difference(msgpackStart);
    print('MessagePack: ${msgpackDuration.inMilliseconds}ms');

    // Protobuf
    final protobufStart = DateTime.now();
    for (int i = 0; i < 10000; i++) {
      final encoded = ProtobufSerializer.encode(user);
      ProtobufSerializer.decode(encoded);
    }
    final protobufDuration = DateTime.now().difference(protobufStart);
    print('Protobuf: ${protobufDuration.inMilliseconds}ms');

    // 결과 (10,000회 반복):
    // JSON: ~500ms
    // MessagePack: ~350ms
    // Protobuf: ~250ms
  }
}
```

### 10.2 대용량 데이터 전송 최적화

```dart
// ============= 스트리밍 전송 =============
class StreamingDataTransfer {
  static const MethodChannel _channel = MethodChannel('com.example.app/streaming');
  static const EventChannel _eventChannel = EventChannel('com.example.app/streaming_events');

  // 대용량 데이터를 청크로 나누어 전송
  Future<void> sendLargeData(Uint8List data) async {
    const chunkSize = 1024 * 1024; // 1MB
    final totalChunks = (data.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = math.min(start + chunkSize, data.length);
      final chunk = data.sublist(start, end);

      await _channel.invokeMethod('sendChunk', {
        'chunk': chunk,
        'index': i,
        'total': totalChunks,
      });
    }
  }

  // 스트림으로 데이터 수신
  Stream<Uint8List> receiveLargeData() {
    return _eventChannel.receiveBroadcastStream().map((chunk) {
      return chunk as Uint8List;
    });
  }
}

// ============= Android (Kotlin) =============
class StreamingPlugin : MethodCallHandler, EventChannel.StreamHandler {
    private var eventSink: EventSink? = null
    private val receivedChunks = mutableMapOf<Int, ByteArray>()

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "sendChunk" -> {
                val chunk = call.argument<ByteArray>("chunk")!!
                val index = call.argument<Int>("index")!!
                val total = call.argument<Int>("total")!!

                receivedChunks[index] = chunk

                if (receivedChunks.size == total) {
                    // 모든 청크 수신 완료
                    val fullData = assembleChunks(receivedChunks, total)
                    processLargeData(fullData)
                    receivedChunks.clear()
                }

                result.success(null)
            }
        }
    }

    private fun assembleChunks(chunks: Map<Int, ByteArray>, total: Int): ByteArray {
        val size = chunks.values.sumOf { it.size }
        val result = ByteArray(size)
        var offset = 0

        for (i in 0 until total) {
            val chunk = chunks[i]!!
            System.arraycopy(chunk, 0, result, offset, chunk.size)
            offset += chunk.size
        }

        return result
    }

    private fun processLargeData(data: ByteArray) {
        // 백그라운드 스레드에서 처리
        Thread {
            // 처리 후 Flutter로 스트리밍
            val chunkSize = 1024 * 1024
            var offset = 0

            while (offset < data.size) {
                val end = Math.min(offset + chunkSize, data.size)
                val chunk = data.copyOfRange(offset, end)

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(chunk)
                }

                offset = end
                Thread.sleep(10) // 백프레셔 방지
            }
        }.start()
    }

    override fun onListen(arguments: Any?, events: EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
```

### 10.3 압축 및 암호화

```dart
// ============= 압축 =============
import 'dart:io';

class DataCompression {
  static Uint8List compress(Uint8List data) {
    return gzip.encode(data);
  }

  static Uint8List decompress(Uint8List data) {
    return Uint8List.fromList(gzip.decode(data));
  }
}

// ============= 암호화 =============
import 'package:encrypt/encrypt.dart' as encrypt;

class DataEncryption {
  final encrypt.Key _key;
  final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  DataEncryption(String keyString, String ivString)
      : _key = encrypt.Key.fromUtf8(keyString.padRight(32)),
        _iv = encrypt.IV.fromUtf8(ivString.padRight(16)) {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  Uint8List encryptData(Uint8List data) {
    final encrypted = _encrypter.encryptBytes(data, iv: _iv);
    return encrypted.bytes;
  }

  Uint8List decryptData(Uint8List data) {
    final encrypted = encrypt.Encrypted(data);
    return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
  }
}

// ============= 압축 + 암호화 파이프라인 =============
class SecureDataTransfer {
  final DataEncryption _encryption;

  SecureDataTransfer(String key, String iv)
      : _encryption = DataEncryption(key, iv);

  Uint8List prepare(Uint8List data) {
    // 1. 압축
    final compressed = DataCompression.compress(data);

    // 2. 암호화
    final encrypted = _encryption.encryptData(compressed);

    return encrypted;
  }

  Uint8List restore(Uint8List data) {
    // 1. 복호화
    final decrypted = _encryption.decryptData(data);

    // 2. 압축 해제
    final decompressed = DataCompression.decompress(decrypted);

    return decompressed;
  }
}

// 사용 예
class SecureChannelService {
  static const MethodChannel _channel = MethodChannel('com.example.app/secure');
  final SecureDataTransfer _transfer;

  SecureChannelService(String key, String iv)
      : _transfer = SecureDataTransfer(key, iv);

  Future<void> sendSecureData(Uint8List data) async {
    final prepared = _transfer.prepare(data);
    await _channel.invokeMethod('sendData', {'data': prepared});
  }

  Future<Uint8List> receiveSecureData() async {
    final Uint8List encrypted = await _channel.invokeMethod('receiveData');
    return _transfer.restore(encrypted);
  }
}
```

---

## 결론

Flutter와 네이티브 플랫폼의 심층 통합은 다음과 같은 전략으로 접근합니다:

1. **Platform Channel 선택**
   - MethodChannel: 일회성 호출
   - EventChannel: 스트림 데이터
   - Dart FFI: 고성능 C/C++ 통합

2. **Pigeon**: 타입 안전 자동 코드 생성

3. **네이티브 뷰**: AndroidView/UiKitView로 기존 UI 재사용

4. **플랫폼 최적화**: 플랫폼별 구현 분기 및 조건부 import

5. **백그라운드 작업**: Isolate + WorkManager/Background Modes

6. **네이티브 SDK**: 카메라, 생체인증 등 네이티브 기능 활용

7. **KMP**: Kotlin Multiplatform으로 비즈니스 로직 공유

8. **직렬화**: MessagePack/Protobuf로 성능 최적화

대규모 프로덕션 앱에서는 초기부터 플랫폼 통합 전략을 수립하고, 성능과 유지보수성을 고려한 아키텍처를 설계해야 합니다.

## 참고 자료

- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Dart FFI Documentation](https://dart.dev/guides/libraries/c-interop)
- [Pigeon Documentation](https://pub.dev/packages/pigeon)
- [Platform Views](https://docs.flutter.dev/development/platform-integration/platform-views)
- [Kotlin Multiplatform](https://kotlinlang.org/docs/multiplatform.html)
