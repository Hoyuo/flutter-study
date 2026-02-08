# Flutter 지도 & 위치 서비스 가이드

> Flutter에서 Google Maps, Geolocator, Geocoding을 활용한 위치 기반 서비스 구현 가이드. Clean Architecture, Bloc 패턴, injectable DI, fpdart Either를 적용한 실전 예제로 마커 관리, 경로 탐색, Geofencing, 클러스터링까지 다룹니다.

> **난이도**: 중급 | **카테고리**: features
> **선행 학습**: [Permission](./Permission.md) | **예상 학습 시간**: 2h

## 학습 목표

이 문서를 학습하면 다음을 할 수 있습니다:

1. Google Maps Flutter 플러그인을 설정하고, 카메라 제어/맵 타입 변경 등 기본 지도 기능을 구현할 수 있다
2. 마커, 폴리라인, 폴리곤, 서클 등 오버레이를 Bloc 패턴으로 관리할 수 있다
3. Geolocator를 활용한 실시간 위치 추적과 Geocoding(주소 <-> 좌표 변환)을 구현할 수 있다
4. Directions API와 Polyline을 사용한 경로 탐색 기능을 구현할 수 있다
5. Geofencing(영역 진입/이탈 감지)과 마커 클러스터링을 적용할 수 있다

## 1. 개요

### 1.1 지도 서비스 옵션

Flutter에서 사용 가능한 주요 지도 서비스:

| 서비스 | 패키지 | 장점 | 단점 |
|--------|---------|------|------|
| **Google Maps** | google_maps_flutter | 풍부한 기능, 글로벌 커버리지, 많은 레퍼런스 | 비용 발생 (무료 한도 초과 시) |
| **Mapbox** | flutter_mapbox_gl | 커스터마이징 우수, 스타일링 자유도 높음 | 한국 지도 데이터 부족 |
| **Naver Maps** | flutter_naver_map | 한국 지도 정확도 최고, 한국어 지원 | 한국 외 지역 제한적 |
| **OpenStreetMap** | flutter_map | 무료, 오픈소스 | 성능 최적화 필요 |

### 1.2 위치 서비스 라이브러리

| 라이브러리 | 용도 | 핵심 기능 |
|-----------|------|----------|
| **geolocator** | 위치 추적 | GPS 좌표, 권한 관리, 실시간 스트림 |
| **geocoding** | 주소 변환 | 주소 ↔ 좌표 변환 |
| **google_maps_flutter** | 지도 렌더링 | GoogleMap 위젯, 마커, 폴리라인 |
| **flutter_polyline_points** | 경로 표시 | Directions API 결과 디코딩 |

---

## 2. 프로젝트 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
name: maps_geolocation_example
description: Flutter Maps & Geolocation comprehensive guide
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.1.1

  # Functional Programming
  fpdart: ^1.2.0

  # Dependency Injection
  injectable: ^2.5.0
  get_it: ^9.2.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

  # Maps & Location
  google_maps_flutter: ^2.12.1
  google_maps_flutter_web: ^0.5.10
  google_maps_flutter_android: ^2.14.6
  google_maps_flutter_ios: ^2.11.0
  geolocator: ^13.0.2
  geocoding: ^3.0.0
  flutter_polyline_points: ^2.1.0

  # Utilities
  permission_handler: ^11.3.1
  uuid: ^4.5.1
  http: ^1.2.2
  cached_network_image: ^3.4.1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.15
  freezed: ^3.2.4
  json_serializable: ^6.9.5
  injectable_generator: ^2.7.0

  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4

  # Linting
  flutter_lints: ^4.0.0
```

### 2.2 Android 설정

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 권한 선언 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

    <application
        android:label="maps_geolocation_example"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Google Maps API Key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_API_KEY_HERE"/>

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

```gradle
// android/app/build.gradle
android {
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34
    }
}
```

### 2.3 iOS 설정

```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Google Maps API Key -->
    <key>GMSApiKey</key>
    <string>YOUR_IOS_API_KEY_HERE</string>

    <!-- 위치 권한 설명 -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>앱 사용 중 위치 정보를 사용하여 지도에 현재 위치를 표시합니다.</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>백그라운드에서 위치 정보를 사용하여 Geofencing 알림을 제공합니다.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>항상 위치 정보를 사용하여 더 나은 서비스를 제공합니다.</string>
</dict>
</plist>
```

```ruby
# ios/Podfile
platform :ios, '14.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Google Maps
  pod 'GoogleMaps', '8.4.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
```

### 2.4 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   ├── injection.dart
│   │   └── injection.config.dart
│   ├── error/
│   │   └── failures.dart
│   └── utils/
│       └── map_helpers.dart
├── features/
│   └── maps/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── location_local_data_source.dart
│       │   │   └── location_remote_data_source.dart
│       │   ├── models/
│       │   │   ├── location_model.dart
│       │   │   ├── place_model.dart
│       │   │   └── route_model.dart
│       │   └── repositories/
│       │       └── location_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── location.dart
│       │   │   ├── place.dart
│       │   │   └── route.dart
│       │   ├── repositories/
│       │   │   └── location_repository.dart
│       │   └── usecases/
│       │       ├── get_current_location.dart
│       │       ├── get_address_from_coordinates.dart
│       │       ├── get_route.dart
│       │       └── track_location.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── map_bloc.dart
│           │   ├── map_event.dart
│           │   ├── map_state.dart
│           │   ├── location_bloc.dart
│           │   └── marker_bloc.dart
│           ├── pages/
│           │   ├── map_page.dart
│           │   └── location_search_page.dart
│           └── widgets/
│               ├── custom_marker.dart
│               ├── location_permission_dialog.dart
│               └── map_controls.dart
└── main.dart
```

---

## 3. Google Maps 기본

### 3.1 도메인 레이어 - Location Entity

```dart
// lib/features/maps/domain/entities/location.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:math';

part 'location.freezed.dart';

@freezed
class Location with _$Location {
  const factory Location({
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
  }) = _Location;

  const Location._();

  /// 두 지점 간 거리 계산 (미터)
  double distanceTo(Location other) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) * cos(_toRadians(other.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
```

### 3.2 GoogleMap 위젯 기본 사용

```dart
// lib/features/maps/presentation/pages/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;

  // 서울 시청 기본 위치
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 14.0,
    tilt: 0.0,
    bearing: 0.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps 기본'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapTypeDialog,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        onCameraMove: (CameraPosition position) {
          debugPrint('Camera moved to: ${position.target}');
        },
        onCameraIdle: () {
          debugPrint('Camera movement ended');
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            child: const Icon(Icons.add),
            onPressed: () => _zoomCamera(1.0),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            child: const Icon(Icons.remove),
            onPressed: () => _zoomCamera(-1.0),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'my_location',
            child: const Icon(Icons.my_location),
            onPressed: _goToMyLocation,
          ),
        ],
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('지도 타입 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapTypeOption('일반', MapType.normal),
            _buildMapTypeOption('위성', MapType.satellite),
            _buildMapTypeOption('하이브리드', MapType.hybrid),
            _buildMapTypeOption('지형', MapType.terrain),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String label, MapType type) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          // MapType 변경은 GoogleMap 위젯 재구성 필요
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _zoomCamera(double delta) async {
    final controller = _mapController;
    if (controller == null) return;

    final currentZoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.zoomTo(currentZoom + delta),
    );
  }

  Future<void> _goToMyLocation() async {
    final controller = _mapController;
    if (controller == null) return;

    // LocationBloc에서 현재 위치 가져오기
    // 여기서는 예시로 서울 시청으로 이동
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(37.5665, 126.9780),
          zoom: 16.0,
          tilt: 45.0,
          bearing: 90.0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

### 3.3 카메라 제어 유틸리티

```dart
// lib/core/utils/map_helpers.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MapHelpers {
  /// 두 지점을 모두 포함하는 카메라 위치 계산
  static CameraPosition getBoundsForLocations(
    List<LatLng> locations, {
    double padding = 50.0,
  }) {
    if (locations.isEmpty) {
      return const CameraPosition(
        target: LatLng(37.5665, 126.9780),
        zoom: 10,
      );
    }

    if (locations.length == 1) {
      return CameraPosition(
        target: locations.first,
        zoom: 14,
      );
    }

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    return CameraPosition(
      target: LatLng(centerLat, centerLng),
      zoom: _calculateZoomLevel(minLat, maxLat, minLng, maxLng),
    );
  }

  static double _calculateZoomLevel(
    double minLat,
    double maxLat,
    double minLng,
    double maxLng,
  ) {
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.01) return 15;
    if (maxDiff < 0.05) return 13;
    if (maxDiff < 0.1) return 11;
    if (maxDiff < 0.5) return 9;
    return 7;
  }

  /// 부드러운 카메라 애니메이션
  static Future<void> animateCameraToPosition(
    GoogleMapController controller,
    LatLng target, {
    double zoom = 14.0,
    double tilt = 0.0,
    double bearing = 0.0,
    Duration duration = const Duration(milliseconds: 1000),
  }) async {
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
          tilt: tilt,
          bearing: bearing,
        ),
      ),
    );
  }

  /// BitmapDescriptor 생성 헬퍼
  static Future<BitmapDescriptor> createCustomMarker({
    required Color color,
    required String text,
    double size = 100,
  }) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    // 원형 배경
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
```

---

## 4. 마커 & 오버레이

### 4.1 도메인 엔티티 - Place

```dart
// lib/features/maps/domain/entities/place.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'place.freezed.dart';

@freezed
class Place with _$Place {
  const factory Place({
    required String id,
    required String name,
    required LatLng location,
    required PlaceCategory category,
    String? description,
    String? imageUrl,
    double? rating,
  }) = _Place;
}

enum PlaceCategory {
  restaurant,
  cafe,
  park,
  museum,
  hotel,
  other;

  String get displayName {
    switch (this) {
      case PlaceCategory.restaurant:
        return '음식점';
      case PlaceCategory.cafe:
        return '카페';
      case PlaceCategory.park:
        return '공원';
      case PlaceCategory.museum:
        return '박물관';
      case PlaceCategory.hotel:
        return '호텔';
      case PlaceCategory.other:
        return '기타';
    }
  }
}
```

### 4.2 Marker Bloc

```dart
// lib/features/maps/presentation/bloc/marker_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/place.dart';

part 'marker_event.dart';
part 'marker_state.dart';
part 'marker_bloc.freezed.dart';

@injectable
class MarkerBloc extends Bloc<MarkerEvent, MarkerState> {
  MarkerBloc() : super(const MarkerState.initial()) {
    on<_AddMarker>(_onAddMarker);
    on<_RemoveMarker>(_onRemoveMarker);
    on<_UpdateMarker>(_onUpdateMarker);
    on<_SelectMarker>(_onSelectMarker);
    on<_ClearMarkers>(_onClearMarkers);
  }

  void _onAddMarker(_AddMarker event, Emitter<MarkerState> emit) {
    state.maybeWhen(
      loaded: (markers, polylines, polygons, circles, selectedMarkerId) {
        final marker = Marker(
          markerId: MarkerId(event.place.id),
          position: event.place.location,
          infoWindow: InfoWindow(
            title: event.place.name,
            snippet: event.place.description,
          ),
          icon: _getMarkerIcon(event.place.category),
          onTap: () => add(MarkerEvent.selectMarker(event.place.id)),
        );

        emit(MarkerState.loaded(
          markers: {...markers, marker},
          polylines: polylines,
          polygons: polygons,
          circles: circles,
          selectedMarkerId: selectedMarkerId,
        ));
      },
      orElse: () {
        // Initial 상태에서 첫 마커 추가
        final marker = Marker(
          markerId: MarkerId(event.place.id),
          position: event.place.location,
          infoWindow: InfoWindow(
            title: event.place.name,
            snippet: event.place.description,
          ),
          icon: _getMarkerIcon(event.place.category),
        );

        emit(MarkerState.loaded(
          markers: {marker},
          polylines: const {},
          polygons: const {},
          circles: const {},
          selectedMarkerId: null,
        ));
      },
    );
  }

  void _onRemoveMarker(_RemoveMarker event, Emitter<MarkerState> emit) {
    state.maybeWhen(
      loaded: (markers, polylines, polygons, circles, selectedMarkerId) {
        final updatedMarkers = markers
            .where((m) => m.markerId.value != event.markerId)
            .toSet();

        emit(MarkerState.loaded(
          markers: updatedMarkers,
          polylines: polylines,
          polygons: polygons,
          circles: circles,
          selectedMarkerId: selectedMarkerId == event.markerId
              ? null
              : selectedMarkerId,
        ));
      },
      orElse: () {},
    );
  }

  void _onUpdateMarker(_UpdateMarker event, Emitter<MarkerState> emit) {
    state.maybeWhen(
      loaded: (markers, polylines, polygons, circles, selectedMarkerId) {
        final updatedMarkers = markers.map((marker) {
          if (marker.markerId.value == event.markerId) {
            return Marker(
              markerId: marker.markerId,
              position: event.newPosition,
              draggable: true,
              onDragEnd: (newPos) {
                add(MapEvent.markerDragged(
                  markerId: marker.markerId.value,
                  newPosition: newPos,
                ));
              },
            );
          }
          return marker;
        }).toSet();

        emit(MarkerState.loaded(
          markers: updatedMarkers,
          polylines: polylines,
          polygons: polygons,
          circles: circles,
          selectedMarkerId: selectedMarkerId,
        ));
      },
      orElse: () {},
    );
  }

  void _onSelectMarker(_SelectMarker event, Emitter<MarkerState> emit) {
    state.maybeWhen(
      loaded: (markers, polylines, polygons, circles, selectedMarkerId) {
        emit(MarkerState.loaded(
          markers: markers,
          polylines: polylines,
          polygons: polygons,
          circles: circles,
          selectedMarkerId: event.markerId,
        ));
      },
      orElse: () {},
    );
  }

  void _onClearMarkers(_ClearMarkers event, Emitter<MarkerState> emit) {
    emit(const MarkerState.loaded(
      markers: {},
      polylines: {},
      polygons: {},
      circles: {},
      selectedMarkerId: null,
    ));
  }

  BitmapDescriptor _getMarkerIcon(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case PlaceCategory.cafe:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case PlaceCategory.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case PlaceCategory.museum:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case PlaceCategory.hotel:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      case PlaceCategory.other:
        return BitmapDescriptor.defaultMarker;
    }
  }
}
```

```dart
// lib/features/maps/presentation/bloc/marker_event.dart
part of 'marker_bloc.dart';

@freezed
class MarkerEvent with _$MarkerEvent {
  const factory MarkerEvent.addMarker(Place place) = _AddMarker;
  const factory MarkerEvent.removeMarker(String markerId) = _RemoveMarker;
  const factory MarkerEvent.updateMarker(String markerId, LatLng newPosition) = _UpdateMarker;
  const factory MarkerEvent.selectMarker(String markerId) = _SelectMarker;
  const factory MarkerEvent.clearMarkers() = _ClearMarkers;
}
```

```dart
// lib/features/maps/presentation/bloc/marker_state.dart
part of 'marker_bloc.dart';

@freezed
class MarkerState with _$MarkerState {
  const factory MarkerState.initial() = _Initial;
  const factory MarkerState.loaded({
    required Set<Marker> markers,
    required Set<Polyline> polylines,
    required Set<Polygon> polygons,
    required Set<Circle> circles,
    String? selectedMarkerId,
  }) = _Loaded;
}
```

### 4.3 Polyline & Polygon 추가

```dart
// lib/features/maps/presentation/widgets/map_overlay_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../bloc/marker_bloc.dart';

class MapOverlayControls extends StatelessWidget {
  const MapOverlayControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_location),
          label: const Text('경로 추가'),
          onPressed: () => _addPolyline(context),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.polygon),
          label: const Text('구역 추가'),
          onPressed: () => _addPolygon(context),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.circle_outlined),
          label: const Text('범위 추가'),
          onPressed: () => _addCircle(context),
        ),
      ],
    );
  }

  void _addPolyline(BuildContext context) {
    final bloc = context.read<MarkerBloc>();

    final polyline = Polyline(
      polylineId: const PolylineId('route_1'),
      points: const [
        LatLng(37.5665, 126.9780), // 서울 시청
        LatLng(37.5796, 126.9770), // 경복궁
        LatLng(37.5794, 126.9769), // 광화문
      ],
      color: Colors.blue,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    // Polyline 추가 로직 (MarkerBloc 확장 필요)
  }

  void _addPolygon(BuildContext context) {
    final polygon = Polygon(
      polygonId: const PolygonId('area_1'),
      points: const [
        LatLng(37.5665, 126.9780),
        LatLng(37.5700, 126.9780),
        LatLng(37.5700, 126.9850),
        LatLng(37.5665, 126.9850),
      ],
      strokeColor: Colors.red,
      strokeWidth: 2,
      fillColor: Colors.red.withValues(alpha: 0.3),
    );

    // Polygon 추가 로직
  }

  void _addCircle(BuildContext context) {
    final circle = Circle(
      circleId: const CircleId('range_1'),
      center: const LatLng(37.5665, 126.9780),
      radius: 500, // 500 meters
      strokeColor: Colors.green,
      strokeWidth: 2,
      fillColor: Colors.green.withValues(alpha: 0.2),
    );

    // Circle 추가 로직
  }
}
```

---

## 5. 사용자 위치 추적

### 5.1 Location Repository 인터페이스

```dart
// lib/features/maps/domain/repositories/location_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/location.dart';

abstract class LocationRepository {
  /// 현재 위치 가져오기
  Future<Either<Failure, Location>> getCurrentLocation();

  /// 위치 권한 확인
  Future<Either<Failure, bool>> checkLocationPermission();

  /// 위치 권한 요청
  Future<Either<Failure, bool>> requestLocationPermission();

  /// 실시간 위치 스트림
  Stream<Either<Failure, Location>> watchLocation();

  /// 위치 서비스 활성화 여부
  Future<Either<Failure, bool>> isLocationServiceEnabled();
}
```

### 5.2 Location Repository 구현

```dart
// lib/features/maps/data/repositories/location_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';

@LazySingleton(as: LocationRepository)
class LocationRepositoryImpl implements LocationRepository {
  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return left(const Failure.locationServiceDisabled());
      }

      // 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return left(const Failure.permissionDenied());
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return left(const Failure.permissionDeniedForever());
      }

      // 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      return right(_positionToLocation(position));
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return right(
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse,
      );
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      return right(
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse,
      );
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Location>> watchLocation() async* {
    try {
      // 위치 서비스 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        yield left(const Failure.locationServiceDisabled());
        return;
      }

      // 권한 확인
      final permissionResult = await checkLocationPermission();
      final hasPermission = permissionResult.getOrElse(() => false);

      if (!hasPermission) {
        yield left(const Failure.permissionDenied());
        return;
      }

      // 위치 스트림
      final positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10m 이동 시 업데이트
        ),
      ).timeout(const Duration(seconds: 30));

      await for (final position in positionStream) {
        yield right(_positionToLocation(position));
      }
    } catch (e) {
      yield left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      return right(enabled);
    } catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  Location _positionToLocation(Position position) {
    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
    );
  }
}
```

### 5.3 Location Bloc

```dart
// lib/features/maps/presentation/bloc/location_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';

part 'location_event.dart';
part 'location_state.dart';
part 'location_bloc.freezed.dart';

@injectable
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationRepository _repository;
  StreamSubscription<Either<Failure, Location>>? _locationSubscription;

  LocationBloc(this._repository) : super(const LocationState.initial()) {
    on<_GetCurrentLocation>(_onGetCurrentLocation);
    on<_StartTracking>(_onStartTracking);
    on<_StopTracking>(_onStopTracking);
    on<_LocationUpdated>(_onLocationUpdated);
    on<_CheckPermission>(_onCheckPermission);
    on<_RequestPermission>(_onRequestPermission);
  }

  Future<void> _onGetCurrentLocation(
    _GetCurrentLocation event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationState.loading());

    final result = await _repository.getCurrentLocation();

    result.fold(
      (failure) => emit(LocationState.error(failure.message)),
      (location) => emit(LocationState.loaded(location, isTracking: false)),
    );
  }

  Future<void> _onStartTracking(
    _StartTracking event,
    Emitter<LocationState> emit,
  ) async {
    // 기존 구독 취소
    await _locationSubscription?.cancel();

    emit(const LocationState.loading());

    // 실시간 위치 스트림 구독
    _locationSubscription = _repository.watchLocation().listen(
      (result) {
        result.fold(
          (failure) => add(LocationEvent.locationUpdated(failure: failure)),
          (location) => add(LocationEvent.locationUpdated(location: location)),
        );
      },
    );
  }

  Future<void> _onStopTracking(
    _StopTracking event,
    Emitter<LocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    state.maybeWhen(
      loaded: (location, _) => emit(
        LocationState.loaded(location, isTracking: false),
      ),
      orElse: () => emit(const LocationState.initial()),
    );
  }

  void _onLocationUpdated(
    _LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    if (event.failure != null) {
      emit(LocationState.error(event.failure!.message));
    } else if (event.location != null) {
      emit(LocationState.loaded(event.location!, isTracking: true));
    }
  }

  Future<void> _onCheckPermission(
    _CheckPermission event,
    Emitter<LocationState> emit,
  ) async {
    final result = await _repository.checkLocationPermission();

    result.fold(
      (failure) => emit(LocationState.error(failure.message)),
      (hasPermission) {
        if (!hasPermission) {
          emit(const LocationState.permissionDenied());
        }
      },
    );
  }

  Future<void> _onRequestPermission(
    _RequestPermission event,
    Emitter<LocationState> emit,
  ) async {
    final result = await _repository.requestLocationPermission();

    result.fold(
      (failure) => emit(LocationState.error(failure.message)),
      (granted) {
        if (granted) {
          add(const LocationEvent.getCurrentLocation());
        } else {
          emit(const LocationState.permissionDenied());
        }
      },
    );
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
```

---

## 6. Geocoding

### 6.1 Geocoding Use Cases

```dart
// lib/features/maps/domain/usecases/get_address_from_coordinates.dart
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/location_repository.dart';

@injectable
class GetAddressFromCoordinates {
  final LocationRepository _repository;

  GetAddressFromCoordinates(this._repository);

  Future<Either<Failure, String>> call({
    required double latitude,
    required double longitude,
  }) async {
    return _repository.getAddressFromCoordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
```

```dart
// lib/features/maps/domain/usecases/get_coordinates_from_address.dart
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/location_repository.dart';

@injectable
class GetCoordinatesFromAddress {
  final LocationRepository _repository;

  GetCoordinatesFromAddress(this._repository);

  Future<Either<Failure, LatLng>> call(String address) async {
    return _repository.getCoordinatesFromAddress(address);
  }
}
```

### 6.2 Repository 확장

```dart
// lib/features/maps/data/repositories/location_repository_impl.dart 확장
import 'package:geocoding/geocoding.dart';

// LocationRepositoryImpl 클래스에 추가

@override
Future<Either<Failure, String>> getAddressFromCoordinates({
  required double latitude,
  required double longitude,
}) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);

    if (placemarks.isEmpty) {
      return left(const Failure.notFound('주소를 찾을 수 없습니다'));
    }

    final placemark = placemarks.first;
    final address = _formatAddress(placemark);

    return right(address);
  } catch (e) {
    return left(Failure.unexpected(e.toString()));
  }
}

@override
Future<Either<Failure, LatLng>> getCoordinatesFromAddress(
  String address,
) async {
  try {
    final locations = await locationFromAddress(address);

    if (locations.isEmpty) {
      return left(const Failure.notFound('좌표를 찾을 수 없습니다'));
    }

    final location = locations.first;

    return right(LatLng(location.latitude, location.longitude));
  } catch (e) {
    return left(Failure.unexpected(e.toString()));
  }
}

String _formatAddress(Placemark placemark) {
  final parts = <String>[];

  if (placemark.country != null) parts.add(placemark.country!);
  if (placemark.administrativeArea != null) {
    parts.add(placemark.administrativeArea!);
  }
  if (placemark.locality != null) parts.add(placemark.locality!);
  if (placemark.thoroughfare != null) parts.add(placemark.thoroughfare!);
  if (placemark.subThoroughfare != null) {
    parts.add(placemark.subThoroughfare!);
  }

  return parts.join(' ');
}
```

### 6.3 주소 검색 UI

```dart
// lib/features/maps/presentation/pages/location_search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _searchController = TextEditingController();
  String? _currentAddress;
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '주소를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentAddress = null;
                      _selectedLocation = null;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchAddress,
            ),
          ),
          if (_selectedLocation != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_currentAddress ?? '주소 정보 없음'),
                  subtitle: Text(
                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () {
                      Navigator.pop(context, _selectedLocation);
                    },
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;

    // GetCoordinatesFromAddress UseCase 호출
    // 여기서는 간단히 예시로 처리
    setState(() {
      _currentAddress = query;
      _selectedLocation = const LatLng(37.5665, 126.9780);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

---

## 7. 경로 탐색

### 7.1 Route Entity

```dart
// lib/features/maps/domain/entities/route.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'route.freezed.dart';

@freezed
class RouteInfo with _$RouteInfo {
  const factory RouteInfo({
    required List<LatLng> polylinePoints,
    required double distanceInMeters,
    required Duration duration,
    String? summary,
    List<RouteStep>? steps,
  }) = _RouteInfo;

  const RouteInfo._();

  String get distanceText {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)}m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
  }

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${minutes}분';
  }
}

@freezed
class RouteStep with _$RouteStep {
  const factory RouteStep({
    required String instruction,
    required double distanceInMeters,
    required Duration duration,
    required LatLng startLocation,
    required LatLng endLocation,
  }) = _RouteStep;
}
```

### 7.2 Directions API Service

```dart
// lib/features/maps/data/datasources/location_remote_data_source.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/route_model.dart';

abstract class LocationRemoteDataSource {
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  });
}

@LazySingleton(as: LocationRemoteDataSource)
class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final http.Client _client;
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  LocationRemoteDataSourceImpl(this._client);

  @override
  Future<RouteModel> getRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr = '${destination.latitude},${destination.longitude}';

    String waypointsStr = '';
    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsStr = '&waypoints=${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}';
    }

    final url = Uri.parse(
      '$_baseUrl/directions/json?'
      'origin=$originStr'
      '&destination=$destStr'
      '$waypointsStr'
      '&mode=driving'
      '&language=ko'
      '&key=$_apiKey',
    );

    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to get route: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['status'] != 'OK') {
      throw Exception('Directions API error: ${json['status']}');
    }

    return RouteModel.fromJson(json);
  }
}
```

### 7.3 Route Model

```dart
// lib/features/maps/data/models/route_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../domain/entities/route.dart';

part 'route_model.freezed.dart';
part 'route_model.g.dart';

@freezed
class RouteModel with _$RouteModel {
  const factory RouteModel({
    required List<LatLng> polylinePoints,
    required double distanceInMeters,
    required int durationInSeconds,
    String? summary,
  }) = _RouteModel;

  const RouteModel._();

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List;
    if (routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes.first as Map<String, dynamic>;
    final legs = route['legs'] as List;
    final leg = legs.first as Map<String, dynamic>;

    // Polyline 디코딩
    final overviewPolyline = route['overview_polyline'] as Map<String, dynamic>;
    final encodedPolyline = overviewPolyline['points'] as String;

    final polylinePoints = PolylinePoints()
        .decodePolyline(encodedPolyline)
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    // 거리와 시간
    final distance = (leg['distance'] as Map<String, dynamic>)['value'] as int;
    final duration = (leg['duration'] as Map<String, dynamic>)['value'] as int;
    final summary = route['summary'] as String?;

    return RouteModel(
      polylinePoints: polylinePoints,
      distanceInMeters: distance.toDouble(),
      durationInSeconds: duration,
      summary: summary,
    );
  }

  RouteInfo toEntity() {
    return RouteInfo(
      polylinePoints: polylinePoints,
      distanceInMeters: distanceInMeters,
      duration: Duration(seconds: durationInSeconds),
      summary: summary,
    );
  }
}
```

### 7.4 Route Use Case

```dart
// lib/features/maps/domain/usecases/get_route.dart
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/location_repository.dart';

@injectable
class GetRoute {
  final LocationRepository _repository;

  GetRoute(this._repository);

  Future<Either<Failure, RouteInfo>> call({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    return _repository.getRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
    );
  }
}
```

---

## 8. Geofencing

### 8.1 Geofence Entity

```dart
// lib/features/maps/domain/entities/geofence.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'geofence.freezed.dart';

@freezed
class Geofence with _$Geofence {
  const factory Geofence({
    required String id,
    required String name,
    required LatLng center,
    required double radiusInMeters,
    required GeofenceAction onEnter,
    required GeofenceAction onExit,
    @Default(true) bool isActive,
  }) = _Geofence;

  const Geofence._();

  bool containsLocation(LatLng location) {
    final distance = _calculateDistance(center, location);
    return distance <= radiusInMeters;
  }

  double _calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) * cos(_toRadians(to.latitude)) *
        sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;
}

enum GeofenceAction {
  notification,
  log,
  callback,
  none;
}

@freezed
class GeofenceEvent with _$GeofenceEvent {
  const factory GeofenceEvent.entered({
    required Geofence geofence,
    required LatLng location,
    required DateTime timestamp,
  }) = GeofenceEntered;

  const factory GeofenceEvent.exited({
    required Geofence geofence,
    required LatLng location,
    required DateTime timestamp,
  }) = GeofenceExited;
}
```

### 8.2 Geofence Manager

```dart
// lib/features/maps/data/services/geofence_manager.dart
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/geofence.dart';
import '../../domain/entities/location.dart';

@singleton
class GeofenceManager {
  final Map<String, Geofence> _geofences = {};
  final Map<String, bool> _currentStates = {}; // true = inside

  final _eventController = StreamController<GeofenceEvent>.broadcast();
  Stream<GeofenceEvent> get events => _eventController.stream;

  void addGeofence(Geofence geofence) {
    _geofences[geofence.id] = geofence;
    _currentStates[geofence.id] = false;
  }

  void removeGeofence(String id) {
    _geofences.remove(id);
    _currentStates.remove(id);
  }

  void updateLocation(Location location) {
    final latLng = LatLng(location.latitude, location.longitude);

    for (final geofence in _geofences.values) {
      if (!geofence.isActive) continue;

      final isInside = geofence.containsLocation(latLng);
      final wasInside = _currentStates[geofence.id] ?? false;

      // 진입 감지
      if (isInside && !wasInside) {
        _currentStates[geofence.id] = true;
        _eventController.add(
          GeofenceEvent.entered(
            geofence: geofence,
            location: latLng,
            timestamp: location.timestamp,
          ),
        );
        _handleAction(geofence.onEnter, geofence, true);
      }

      // 이탈 감지
      else if (!isInside && wasInside) {
        _currentStates[geofence.id] = false;
        _eventController.add(
          GeofenceEvent.exited(
            geofence: geofence,
            location: latLng,
            timestamp: location.timestamp,
          ),
        );
        _handleAction(geofence.onExit, geofence, false);
      }
    }
  }

  void _handleAction(GeofenceAction action, Geofence geofence, bool isEnter) {
    switch (action) {
      case GeofenceAction.notification:
        // 알림 표시 로직
        debugPrint('🔔 ${isEnter ? "진입" : "이탈"}: ${geofence.name}');
        break;
      case GeofenceAction.log:
        debugPrint('📍 ${isEnter ? "Entered" : "Exited"} ${geofence.name}');
        break;
      case GeofenceAction.callback:
        // 콜백 실행
        break;
      case GeofenceAction.none:
        break;
    }
  }

  bool isInsideGeofence(String geofenceId) {
    return _currentStates[geofenceId] ?? false;
  }

  List<Geofence> getActiveGeofences() {
    return _geofences.values.where((g) => g.isActive).toList();
  }

  void dispose() {
    _eventController.close();
  }
}
```

### 8.3 Geofence UI Example

```dart
// lib/features/maps/presentation/widgets/geofence_overlay.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/geofence.dart';

class GeofenceOverlay {
  static Set<Circle> buildCircles(List<Geofence> geofences) {
    return geofences.map((geofence) {
      return Circle(
        circleId: CircleId(geofence.id),
        center: geofence.center,
        radius: geofence.radiusInMeters,
        strokeColor: geofence.isActive ? Colors.blue : Colors.grey,
        strokeWidth: 2,
        fillColor: (geofence.isActive ? Colors.blue : Colors.grey)
            .withValues(alpha: 0.2),
      );
    }).toSet();
  }

  static Set<Marker> buildMarkers(List<Geofence> geofences) {
    return geofences.map((geofence) {
      return Marker(
        markerId: MarkerId('${geofence.id}_marker'),
        position: geofence.center,
        infoWindow: InfoWindow(
          title: geofence.name,
          snippet: '${geofence.radiusInMeters}m',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          geofence.isActive
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }
}
```

---

## 9. 클러스터링

### 9.1 Marker Clustering 패키지

```yaml
# pubspec.yaml에 추가
dependencies:
  google_maps_cluster_manager: ^3.0.0+1
  dart_geohash: ^2.0.1  # Geohash 계산을 위해 추가
```

### 9.2 Cluster Item Model

```dart
// lib/features/maps/data/models/cluster_place.dart
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dart_geohash/dart_geohash.dart';
import '../../domain/entities/place.dart';

class ClusterPlace with ClusterItem {
  final Place place;

  ClusterPlace(this.place);

  @override
  LatLng get location => place.location;

  @override
  String get geohash {
    // dart_geohash 패키지를 사용한 geohash 계산
    final geoHasher = GeoHasher();
    return geoHasher.encode(location.longitude, location.latitude);
  }
}
```

### 9.3 Clustering Manager

```dart
// lib/features/maps/presentation/widgets/clustered_map.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import '../../domain/entities/place.dart';
import '../../data/models/cluster_place.dart';

class ClusteredMapPage extends StatefulWidget {
  final List<Place> places;

  const ClusteredMapPage({
    super.key,
    required this.places,
  });

  @override
  State<ClusteredMapPage> createState() => _ClusteredMapPageState();
}

class _ClusteredMapPageState extends State<ClusteredMapPage> {
  late ClusterManager<ClusterPlace> _clusterManager;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    _clusterManager = ClusterManager<ClusterPlace>(
      widget.places.map((p) => ClusterPlace(p)).toList(),
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
      extraPercent: 0.2,
      stopClusteringZoom: 17.0,
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마커 클러스터링'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.5665, 126.9780),
          zoom: 10,
        ),
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
          _clusterManager.setMapId(controller.mapId);
        },
        onCameraMove: (position) {
          _clusterManager.onCameraMove(position);
        },
        onCameraIdle: () {
          _clusterManager.updateMap();
        },
      ),
    );
  }

  Future<Marker> _markerBuilder(Cluster<ClusterPlace> cluster) async {
    final isMultipleItems = cluster.isMultiple;

    if (isMultipleItems) {
      // 클러스터 마커
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterMarker(
          cluster.count,
          _getClusterColor(cluster.count),
        ),
        onTap: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.location, 15),
          );
        },
      );
    } else {
      // 단일 마커
      final place = cluster.items.first.place;
      return Marker(
        markerId: MarkerId(place.id),
        position: place.location,
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.description,
        ),
        icon: _getPlaceMarker(place.category),
      );
    }
  }

  Future<BitmapDescriptor> _getClusterMarker(
    int clusterSize,
    Color color,
  ) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 120.0;

    // 외곽 원
    final paint = Paint()..color = color;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // 내부 원
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      innerPaint,
    );

    // 숫자 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: clusterSize.toString(),
        style: TextStyle(
          color: color,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  Color _getClusterColor(int clusterSize) {
    if (clusterSize < 10) return Colors.green;
    if (clusterSize < 50) return Colors.orange;
    if (clusterSize < 100) return Colors.red;
    return Colors.purple;
  }

  BitmapDescriptor _getPlaceMarker(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.restaurant:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case PlaceCategory.cafe:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case PlaceCategory.park:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case PlaceCategory.museum:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case PlaceCategory.hotel:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
```

---

## 10. Bloc 연동

### 10.1 Map Bloc 통합

```dart
// lib/features/maps/presentation/bloc/map_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/place.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_route.dart';

part 'map_event.dart';
part 'map_state.dart';
part 'map_bloc.freezed.dart';

@injectable
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCurrentLocation _getCurrentLocation;
  final GetRoute _getRoute;

  MapBloc(
    this._getCurrentLocation,
    this._getRoute,
  ) : super(const MapState.initial()) {
    on<_Initialize>(_onInitialize);
    on<_MoveCamera>(_onMoveCamera);
    on<_AddPlace>(_onAddPlace);
    on<_ShowRoute>(_onShowRoute);
    on<_ClearRoute>(_onClearRoute);
  }

  Future<void> _onInitialize(
    _Initialize event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapState.loading());

    final result = await _getCurrentLocation();

    result.fold(
      (failure) => emit(MapState.error(failure.message)),
      (location) {
        emit(MapState.ready(
          currentLocation: location,
          cameraPosition: CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 14,
          ),
          places: const [],
          markers: const {},
          polylines: const {},
          selectedPlaceId: null,
        ));
      },
    );
  }

  void _onMoveCamera(
    _MoveCamera event,
    Emitter<MapState> emit,
  ) {
    state.maybeWhen(
      ready: (currentLocation, _, places, markers, polylines, selectedPlaceId) {
        emit(MapState.ready(
          currentLocation: currentLocation,
          cameraPosition: event.position,
          places: places,
          markers: markers,
          polylines: polylines,
          selectedPlaceId: selectedPlaceId,
        ));
      },
      orElse: () {},
    );
  }

  void _onAddPlace(
    _AddPlace event,
    Emitter<MapState> emit,
  ) {
    state.maybeWhen(
      ready: (currentLocation, cameraPosition, places, markers, polylines, selectedPlaceId) {
        final updatedPlaces = [...places, event.place];

        final marker = Marker(
          markerId: MarkerId(event.place.id),
          position: event.place.location,
          infoWindow: InfoWindow(
            title: event.place.name,
            snippet: event.place.description,
          ),
        );

        emit(MapState.ready(
          currentLocation: currentLocation,
          cameraPosition: cameraPosition,
          places: updatedPlaces,
          markers: {...markers, marker},
          polylines: polylines,
          selectedPlaceId: selectedPlaceId,
        ));
      },
      orElse: () {},
    );
  }

  Future<void> _onShowRoute(
    _ShowRoute event,
    Emitter<MapState> emit,
  ) async {
    await state.maybeWhen(
      ready: (currentLocation, cameraPosition, places, markers, polylines, selectedPlaceId) async {
        emit(const MapState.loading());

        final result = await _getRoute(
          origin: event.origin,
          destination: event.destination,
        );

        result.fold(
          (failure) => emit(MapState.error(failure.message)),
          (route) {
            final polyline = Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints,
              color: Colors.blue,
              width: 5,
            );

            emit(MapState.ready(
              currentLocation: currentLocation,
              cameraPosition: cameraPosition,
              places: places,
              markers: markers,
              polylines: {polyline},
              selectedPlaceId: selectedPlaceId,
            ));
          },
        );
      },
      orElse: () async {},
    );
  }

  void _onClearRoute(
    _ClearRoute event,
    Emitter<MapState> emit,
  ) {
    state.maybeWhen(
      ready: (currentLocation, cameraPosition, places, markers, polylines, selectedPlaceId) {
        emit(MapState.ready(
          currentLocation: currentLocation,
          cameraPosition: cameraPosition,
          places: places,
          markers: markers,
          polylines: const {},
          selectedPlaceId: selectedPlaceId,
        ));
      },
      orElse: () {},
    );
  }
}
```

---

## 11. Clean Architecture 연동

### 11.1 Dependency Injection 설정

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() => getIt.init();

@module
abstract class RegisterModule {
  @lazySingleton
  http.Client get httpClient => http.Client();
}
```

### 11.2 Main 파일

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/maps/presentation/bloc/map_bloc.dart';
import 'features/maps/presentation/bloc/location_bloc.dart';
import 'features/maps/presentation/bloc/marker_bloc.dart';
import 'features/maps/presentation/pages/map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps & Geolocation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => getIt<MapBloc>()..add(const MapEvent.initialize())),
          BlocProvider(create: (_) => getIt<LocationBloc>()),
          BlocProvider(create: (_) => getIt<MarkerBloc>()),
        ],
        child: const MapPage(),
      ),
    );
  }
}
```

---

## 12. 오프라인 지도

### 12.1 타일 캐싱 전략

```dart
// lib/features/maps/data/services/map_tile_cache.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@singleton
class MapTileCache {
  final http.Client _client;
  Directory? _cacheDir;

  MapTileCache(this._client);

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/map_tiles');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }

  Future<Uint8List?> getTile({
    required int x,
    required int y,
    required int zoom,
  }) async {
    if (_cacheDir == null) await initialize();

    final fileName = '${zoom}_${x}_$y.png';
    final file = File('${_cacheDir!.path}/$fileName');

    // 캐시 확인
    if (await file.exists()) {
      return await file.readAsBytes();
    }

    // 네트워크에서 다운로드
    try {
      final url = 'https://mt1.google.com/vt/lyrs=m&x=$x&y=$y&z=$zoom';
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        await file.writeAsBytes(bytes);
        return bytes;
      }
    } catch (e) {
      debugPrint('Tile download failed: $e');
    }

    return null;
  }

  Future<void> clearCache() async {
    if (_cacheDir == null) await initialize();

    if (await _cacheDir!.exists()) {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create();
    }
  }

  Future<int> getCacheSize() async {
    if (_cacheDir == null) await initialize();

    int totalSize = 0;

    await for (final entity in _cacheDir!.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }
}
```

---

## 13. 테스트

### 13.1 Mock Location Repository

```dart
// test/features/maps/data/repositories/mock_location_repository.dart
import 'package:fpdart/fpdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maps_geolocation_example/core/error/failures.dart';
import 'package:maps_geolocation_example/features/maps/domain/entities/location.dart';
import 'package:maps_geolocation_example/features/maps/domain/repositories/location_repository.dart';

class MockLocationRepository extends Mock implements LocationRepository {
  @override
  Future<Either<Failure, Location>> getCurrentLocation() async {
    return right(Location(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
      accuracy: 10.0,
    ));
  }

  @override
  Stream<Either<Failure, Location>> watchLocation() async* {
    yield right(Location(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
    ));
  }
}
```

### 13.2 Location Bloc Test

```dart
// test/features/maps/presentation/bloc/location_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:maps_geolocation_example/features/maps/domain/entities/location.dart';
import 'package:maps_geolocation_example/features/maps/domain/repositories/location_repository.dart';
import 'package:maps_geolocation_example/features/maps/presentation/bloc/location_bloc.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

void main() {
  late MockLocationRepository mockRepository;
  late LocationBloc bloc;

  setUp(() {
    mockRepository = MockLocationRepository();
    bloc = LocationBloc(mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('LocationBloc', () {
    final testLocation = Location(
      latitude: 37.5665,
      longitude: 126.9780,
      timestamp: DateTime.now(),
    );

    blocTest<LocationBloc, LocationState>(
      'emits [loading, loaded] when getCurrentLocation succeeds',
      build: () {
        when(() => mockRepository.getCurrentLocation())
            .thenAnswer((_) async => right(testLocation));
        return bloc;
      },
      act: (bloc) => bloc.add(const LocationEvent.getCurrentLocation()),
      expect: () => [
        const LocationState.loading(),
        LocationState.loaded(testLocation, isTracking: false),
      ],
    );

    blocTest<LocationBloc, LocationState>(
      'emits [loading, error] when getCurrentLocation fails',
      build: () {
        when(() => mockRepository.getCurrentLocation())
            .thenAnswer((_) async => left(const Failure.locationServiceDisabled()));
        return bloc;
      },
      act: (bloc) => bloc.add(const LocationEvent.getCurrentLocation()),
      expect: () => [
        const LocationState.loading(),
        const LocationState.error('위치 서비스가 비활성화되어 있습니다'),
      ],
    );
  });
}
```

### 13.3 Widget Test

```dart
// test/features/maps/presentation/widgets/map_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_geolocation_example/features/maps/presentation/bloc/map_bloc.dart';
import 'package:maps_geolocation_example/features/maps/presentation/pages/map_page.dart';
import 'package:mocktail/mocktail.dart';

class MockMapBloc extends Mock implements MapBloc {}

void main() {
  late MockMapBloc mockMapBloc;

  setUp(() {
    mockMapBloc = MockMapBloc();
  });

  testWidgets('MapPage renders GoogleMap widget', (tester) async {
    when(() => mockMapBloc.state).thenReturn(const MapState.initial());
    when(() => mockMapBloc.stream).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<MapBloc>.value(
          value: mockMapBloc,
          child: const MapPage(),
        ),
      ),
    );

    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
```

---

## 14. Best Practices

### 14.1 Do / Don't 비교표

| 구분 | Do ✅ | Don't ❌ |
|------|-------|----------|
| **위치 권한** | 사용자에게 권한이 필요한 이유 명확히 설명 | 앱 시작 시 무조건 권한 요청 |
| **배터리** | `distanceFilter` 사용하여 불필요한 업데이트 방지 | 1초마다 위치 업데이트 |
| **정확도** | 용도에 맞는 `LocationAccuracy` 선택 | 항상 `LocationAccuracy.best` 사용 |
| **에러 처리** | Either 패턴으로 모든 실패 케이스 처리 | try-catch만 사용 |
| **마커** | 커스텀 BitmapDescriptor로 카테고리 구분 | 모든 마커에 같은 아이콘 사용 |
| **클러스터링** | 100개 이상 마커는 클러스터링 적용 | 모든 마커 개별 표시 |
| **Polyline** | 복잡한 경로는 `simplifyTolerance` 사용 | 모든 포인트 그대로 렌더링 |
| **캐싱** | 자주 사용하는 타일은 로컬 캐시 | 매번 네트워크 요청 |
| **메모리** | 사용하지 않는 MapController dispose | Controller 누수 방지 안 함 |

### 14.2 성능 최적화 체크리스트

```dart
// lib/core/utils/performance_tips.dart

/// 성능 최적화 가이드라인

// ✅ 1. 위치 업데이트 최적화
const optimizedLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.high, // best 대신 high 사용
  distanceFilter: 10, // 10m 이동 시만 업데이트
  timeLimit: Duration(minutes: 5), // 최대 업데이트 시간 제한
);

// ✅ 2. 마커 최적화
// - 100개 이상 → 클러스터링
// - 커스텀 아이콘은 Future 캐싱
final Map<String, BitmapDescriptor> _iconCache = {};

Future<BitmapDescriptor> getCachedIcon(String key) async {
  if (_iconCache.containsKey(key)) {
    return _iconCache[key]!;
  }

  final icon = await createCustomIcon();
  _iconCache[key] = icon;
  return icon;
}

// ✅ 3. Polyline 간소화
List<LatLng> simplifyPolyline(List<LatLng> points, {double tolerance = 0.0001}) {
  // Douglas-Peucker 알고리즘
  if (points.length < 3) return points;
  // ... 구현
}

// ✅ 4. 타일 캐싱
// - WiFi 연결 시 자주 사용하는 영역 미리 다운로드
// - 오프라인 지도 기능 제공

// ✅ 5. Bloc 최적화
// - 불필요한 state 방출 방지
// - Equatable로 중복 state 필터링

// ✅ 6. 메모리 관리
@override
void dispose() {
  _mapController?.dispose();
  _locationSubscription?.cancel();
  super.dispose();
}
```

### 14.3 보안 체크리스트

| 항목 | 체크 |
|------|------|
| API 키를 `.gitignore`에 추가 | ☑️ |
| Android/iOS 각각 API 키 제한 설정 | ☑️ |
| 위치 권한 사용 목적 명시 (Info.plist) | ☑️ |
| 백그라운드 위치 권한은 필수인 경우만 요청 | ☑️ |
| HTTPS만 사용 (HTTP 차단) | ☑️ |
| 사용자 위치 데이터 암호화 저장 | ☑️ |

### 14.4 배터리 최적화

```dart
// lib/features/maps/data/services/battery_optimized_tracking.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class BatteryOptimizedTracking {
  StreamSubscription<Position>? _subscription;

  /// 배터리 효율적인 위치 추적
  void startTracking({
    required Function(Position) onLocationUpdate,
    TrackingMode mode = TrackingMode.balanced,
  }) {
    final settings = _getSettingsForMode(mode);

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(onLocationUpdate);
  }

  LocationSettings _getSettingsForMode(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.highAccuracy:
        // 정확도 우선 (배터리 소모 높음)
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        );

      case TrackingMode.balanced:
        // 균형 모드 (권장)
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          timeLimit: Duration(minutes: 5),
        );

      case TrackingMode.batterySaver:
        // 배터리 절약 (정확도 낮음)
        return const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 50,
          timeLimit: Duration(minutes: 10),
        );
    }
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }
}

enum TrackingMode {
  highAccuracy,
  balanced,
  batterySaver,
}
```

---

## 마무리

이 가이드는 Flutter에서 Google Maps와 위치 기반 서비스를 Clean Architecture, Bloc 패턴, injectable DI, fpdart Either, freezed로 구현하는 실전 예제를 다룹니다.

**핵심 요약:**
1. **기본 지도** - GoogleMap 위젯, 카메라 제어, 줌/틸트
2. **마커 관리** - Marker, InfoWindow, 커스텀 아이콘, 클러스터링
3. **위치 추적** - Geolocator, 권한 관리, 실시간 스트림
4. **Geocoding** - 주소 ↔ 좌표 변환
5. **경로 탐색** - Directions API, Polyline 표시
6. **Geofencing** - 영역 진입/이탈 감지
7. **성능 최적화** - 배터리 절약, 타일 캐싱, 마커 클러스터링
8. **테스트** - Mock Repository, Bloc Test, Widget Test

Clean Architecture를 통해 도메인 로직과 UI를 분리하고, Bloc으로 상태를 명확히 관리하며, Either로 에러를 타입 안전하게 처리하는 것이 핵심입니다.

## 실습 과제

### 과제 1: 기본 지도 및 현재 위치 표시
Google Maps를 표시하고, Geolocator로 현재 위치를 가져와 지도 중앙에 마커로 표시하세요. 위치 권한 요청 흐름과 위치 서비스 비활성화 시 에러 처리를 포함해야 합니다.

### 과제 2: 경로 탐색 구현
두 지점(출발지, 도착지)을 선택하면 Directions API를 호출하여 경로를 Polyline으로 표시하고, 예상 거리와 소요 시간을 화면에 출력하세요.

### 과제 3: Geofencing 적용
반경 500m의 Geofence 영역을 지도 위에 Circle로 표시하고, 실시간 위치 추적으로 영역 진입/이탈 시 알림을 표시하는 기능을 구현하세요.

## Self-Check 퀴즈

- [ ] Google Maps API 키를 Android(AndroidManifest.xml)와 iOS(Info.plist)에 각각 설정하는 방법을 이해하고 있는가?
- [ ] `LocationAccuracy.best`와 `LocationAccuracy.high`의 차이점과 배터리 영향을 설명할 수 있는가?
- [ ] `distanceFilter`를 설정하는 이유와 적절한 값을 결정하는 기준을 이해하고 있는가?
- [ ] 마커가 100개 이상일 때 클러스터링을 적용해야 하는 이유를 성능 관점에서 설명할 수 있는가?
- [ ] API 키를 `.gitignore`에 추가하고, Android/iOS별로 키 사용을 제한해야 하는 보안상의 이유를 설명할 수 있는가?

## 체크리스트

- [ ] Google Maps API 키 발급 및 플랫폼별 설정
- [ ] google_maps_flutter, geolocator, geocoding 패키지 설치
- [ ] Android/iOS 위치 권한 설정 (Manifest, Info.plist)
- [ ] Location Repository 인터페이스 및 구현체 작성
- [ ] LocationBloc으로 현재 위치 조회 및 실시간 추적 구현
- [ ] 마커 추가/삭제/선택 관리 (MarkerBloc)
- [ ] Geocoding (주소 <-> 좌표 변환) 구현
- [ ] Directions API 연동 및 경로 표시
- [ ] Geofencing 구현 (필요시)
- [ ] 마커 클러스터링 적용 (대량 마커 시)
- [ ] 메모리 관리 (MapController dispose)
