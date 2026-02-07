# Flutter Web & Desktop 멀티플랫폼 가이드

> Flutter를 사용하여 단일 코드베이스로 Web과 Desktop(Windows, macOS, Linux) 애플리케이션을 개발하는 완벽 가이드. Clean Architecture, Bloc 패턴, 플랫폼별 최적화 전략을 포함합니다.

> **학습 목표**: 이 문서를 학습하면 다음을 할 수 있습니다:
> - Flutter로 Web/Desktop 앱을 빌드하고 배포할 수 있다
> - 조건부 Import로 플랫폼별 코드를 분리할 수 있다
> - 반응형 UI와 플랫폼 특화 기능을 구현할 수 있다

## 1. 개요

### 1.1 Flutter 멀티플랫폼 전략

Flutter는 단일 코드베이스로 모바일, 웹, 데스크톱 애플리케이션을 개발할 수 있는 크로스 플랫폼 프레임워크입니다.

**지원 플랫폼:**
- Mobile: iOS, Android
- Web: 모든 모던 브라우저 (Chrome, Safari, Firefox, Edge)
- Desktop: Windows, macOS, Linux

### 1.2 플랫폼별 비교

| 플랫폼 | 렌더링 엔진 | 배포 방식 | 주요 사용 사례 |
|--------|------------|----------|---------------|
| **Web** | HTML Renderer / CanvasKit | Static hosting | 포트폴리오, 랜딩 페이지, 관리자 도구 |
| **Windows** | Skia + Windows API | MSIX, Installer | 생산성 도구, 엔터프라이즈 앱 |
| **macOS** | Skia + Cocoa | DMG, App Store | 크리에이티브 도구, 유틸리티 |
| **Linux** | Skia + GTK | Snap, AppImage, Deb | 개발자 도구, 시스템 유틸리티 |

### 1.3 언제 멀티플랫폼을 사용하는가?

**적합한 경우:**
- 단일 코드베이스로 여러 플랫폼 지원 필요
- 일관된 UI/UX 요구
- 빠른 프로토타이핑
- 중소규모 팀

**주의가 필요한 경우:**
- 플랫폼별 네이티브 기능을 많이 사용하는 경우
- 극도로 높은 성능이 필요한 경우 (3D 게임, 비디오 편집 등)
- 웹 SEO가 중요한 경우 (SPA 한계)

---

## 2. 프로젝트 설정

### 2.1 Web 및 Desktop 활성화

```bash
# Web 활성화
flutter create --platforms=web .

# Desktop 활성화
flutter create --platforms=windows,macos,linux .

# 모든 플랫폼 활성화
flutter create --platforms=web,windows,macos,linux .

# 현재 활성화된 플랫폼 확인
flutter devices
```

### 2.2 프로젝트 구조

```
my_app/
├── lib/
│   ├── core/
│   │   ├── di/
│   │   │   └── injection.dart
│   │   ├── platform/
│   │   │   ├── platform_detector.dart
│   │   │   └── conditional_imports/
│   │   │       ├── platform_stub.dart
│   │   │       ├── platform_web.dart
│   │   │       └── platform_io.dart
│   │   └── utils/
│   │       └── responsive_builder.dart
│   ├── features/
│   │   └── home/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │           ├── bloc/
│   │           ├── widgets/
│   │           │   ├── home_page_desktop.dart
│   │           │   ├── home_page_mobile.dart
│   │           │   └── home_page_web.dart
│   │           └── home_page.dart
│   └── main.dart
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── favicon.png
├── windows/
│   └── runner/
├── macos/
│   └── Runner/
├── linux/
│   └── flutter/
└── pubspec.yaml
```

### 2.3 pubspec.yaml 설정 (2026년 버전)

```yaml
# pubspec.yaml
name: my_app
description: Multi-platform Flutter application
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.5

  # Functional Programming
  fpdart: ^1.2.0

  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.9.0

  # Dependency Injection
  injectable: ^2.5.0
  get_it: ^9.2.0

  # Responsive Design
  responsive_framework: ^1.5.1
  flutter_adaptive_scaffold: ^0.2.3

  # Platform Detection
  universal_io: ^2.2.2

  # Web Specific
  url_strategy: ^0.3.0
  js: ^0.7.1  # ⚠️ deprecated - dart:js_interop 사용 권장

  # Desktop Specific
  window_manager: ^0.4.2
  tray_manager: ^0.2.3
  file_picker: ^8.1.2
  path_provider: ^2.1.4

  # Storage
  shared_preferences: ^2.3.2
  isar: ^3.1.0+1  # ⚠️ 개발 중단 - drift, objectbox 사용 권장
  isar_flutter_libs: ^3.1.0+1

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.15
  freezed: ^3.2.4
  json_serializable: ^6.9.5
  injectable_generator: ^2.7.0

  # Linting
  flutter_lints: ^5.0.0

  # Testing
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.ttf
        - asset: assets/fonts/Pretendard-Bold.ttf
          weight: 700
```

### 2.4 플랫폼별 빌드 명령

```bash
# Web 빌드
flutter build web --release --web-renderer canvaskit

# Windows 빌드
flutter build windows --release

# macOS 빌드
flutter build macos --release

# Linux 빌드
flutter build linux --release

# 개발 모드 실행
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos           # macOS
flutter run -d linux           # Linux
```

---

## 3. Flutter Web

### 3.1 Web 렌더러 비교

| 렌더러 | 성능 | 호환성 | 번들 크기 | 사용 시기 |
|--------|------|--------|----------|----------|
| **HTML** | 보통 | 최고 | 작음 (~2MB) | 텍스트 중심 앱, SEO 중요 |
| **CanvasKit** | 높음 | 좋음 | 큼 (~4-5MB) | 애니메이션, 커스텀 그래픽 |
| **Auto** | - | - | - | 모바일: HTML, 데스크톱: CanvasKit |

```dart
// web/index.html - 렌더러 선택
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Flutter App</title>

  <!-- PWA 메타 태그 -->
  <meta name="description" content="Flutter multi-platform application">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icons/icon-192.png">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
  <script>
    window.addEventListener('load', function(ev) {
      // CanvasKit 렌더러 강제
      _flutter.loader.load({
        config: {
          renderer: "canvaskit",
          canvasKitMaximumSurfaces: 4,
        }
      });
    });
  </script>
</body>
</html>
```

### 3.2 URL 전략 설정

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'core/di/injection.dart';

void main() {
  // Hash 제거 (#/ -> /)
  setPathUrlStrategy();

  configureDependencies();

  runApp(const MyApp());
}
```

### 3.3 Web 라우팅 설정

```dart
// lib/core/router/app_router.dart
import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case '/about':
        return MaterialPageRoute(
          builder: (_) => const AboutPage(),
          settings: settings,
        );
      case '/products':
        return MaterialPageRoute(
          builder: (_) => const ProductsPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
          settings: settings,
        );
    }
  }
}

// MaterialApp 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}
```

### 3.4 Web SEO 최적화

```html
<!-- web/index.html - SEO 메타 태그 -->
<head>
  <title>My Flutter App - 최고의 멀티플랫폼 앱</title>
  <meta name="description" content="Flutter로 만든 웹, 데스크톱 앱">
  <meta name="keywords" content="flutter, web, desktop, cross-platform">

  <!-- Open Graph -->
  <meta property="og:title" content="My Flutter App">
  <meta property="og:description" content="Flutter 멀티플랫폼 애플리케이션">
  <meta property="og:image" content="https://myapp.com/og-image.png">
  <meta property="og:url" content="https://myapp.com">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="My Flutter App">
  <meta name="twitter:description" content="Flutter 멀티플랫폼 애플리케이션">
  <meta name="twitter:image" content="https://myapp.com/twitter-card.png">
</head>
```

**주의:** Flutter Web은 Client-Side Rendering이므로 SEO가 제한적입니다. 중요한 SEO가 필요한 경우 Server-Side Rendering을 고려하거나 정적 메타 태그를 충분히 설정하세요.

---

## 4. Flutter Desktop

### 4.1 플랫폼별 설정 차이

| 플랫폼 | 최소 버전 | 네이티브 언어 | 패키지 형식 |
|--------|----------|--------------|------------|
| **Windows** | Windows 10 1809+ | C++ | MSIX, Inno Setup |
| **macOS** | macOS 10.14+ | Swift/Objective-C | DMG, PKG, App Store |
| **Linux** | Ubuntu 18.04+ | C++ | Snap, AppImage, Deb |

### 4.2 Windows 설정

```cpp
// windows/runner/main.cpp - 윈도우 설정
// ⚠️ 주의: FlutterWindowController는 Flutter Windows embedding API에 존재하지 않는 클래스입니다.
// 실제로는 flutter::FlutterEngine + flutter::FlutterViewController를 사용하거나,
// window_manager 패키지를 사용하세요.
#include <flutter/flutter_window_controller.h>
#include <windows.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 윈도우 크기 설정
  const int window_width = 1280;
  const int window_height = 720;

  flutter::FlutterWindowController controller(
      window_width,
      window_height,
      L"My Flutter App"
  );

  return controller.RunEngine(instance);
}
```

```xml
<!-- windows/runner/Runner.exe.manifest - DPI 인식 설정 -->
<application xmlns="urn:schemas-microsoft-com:asm.v3">
  <windowsSettings>
    <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware>
    <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
  </windowsSettings>
</application>
```

### 4.3 macOS 설정

```xml
<!-- macos/Runner/Info.plist - 권한 설정 -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>My Flutter App</string>

  <key>CFBundleVersion</key>
  <string>1.0.0</string>

  <!-- 최소 macOS 버전 -->
  <key>LSMinimumSystemVersion</key>
  <string>10.14</string>

  <!-- 파일 시스템 접근 권한 -->
  <key>NSDocumentsFolderUsageDescription</key>
  <string>This app needs access to documents folder</string>

  <key>NSDownloadsFolderUsageDescription</key>
  <string>This app needs access to downloads folder</string>

  <!-- 네트워크 권한 -->
  <key>NSAppTransportSecurity</key>
  <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
  </dict>
</dict>
</plist>
```

### 4.4 Linux 설정

```cmake
# linux/CMakeLists.txt - 패키지 의존성
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

# GTK 3.0 의존성
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)
pkg_check_modules(GLIB REQUIRED IMPORTED_TARGET glib-2.0)

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
)

target_link_libraries(${BINARY_NAME} PRIVATE
  PkgConfig::GTK
  PkgConfig::GLIB
)
```

---

## 5. Conditional Import

### 5.1 플랫폼 감지 패턴

```dart
// lib/core/platform/platform_detector.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

enum PlatformType {
  web,
  windows,
  macos,
  linux,
  android,
  ios,
  unknown;
}

class PlatformDetector {
  static PlatformType get currentPlatform {
    if (kIsWeb) {
      return PlatformType.web;
    }

    try {
      if (Platform.isWindows) return PlatformType.windows;
      if (Platform.isMacOS) return PlatformType.macos;
      if (Platform.isLinux) return PlatformType.linux;
      if (Platform.isAndroid) return PlatformType.android;
      if (Platform.isIOS) return PlatformType.ios;
    } catch (_) {
      // Web에서 Platform 접근 시 에러 방지
    }

    return PlatformType.unknown;
  }

  static bool get isDesktop =>
      currentPlatform == PlatformType.windows ||
      currentPlatform == PlatformType.macos ||
      currentPlatform == PlatformType.linux;

  static bool get isMobile =>
      currentPlatform == PlatformType.android ||
      currentPlatform == PlatformType.ios;

  static bool get isWeb => currentPlatform == PlatformType.web;
}
```

### 5.2 Conditional Import 패턴

```dart
// lib/core/platform/conditional_imports/platform_stub.dart
class PlatformService {
  String getStoragePath() {
    throw UnimplementedError('Platform not supported');
  }

  Future<void> saveFile(String path, List<int> bytes) {
    throw UnimplementedError('Platform not supported');
  }
}
```

```dart
// lib/core/platform/conditional_imports/platform_web.dart
// ⚠️ 주의: dart:html은 Dart 3.4/Flutter 3.22부터 deprecated입니다.
// 실제 프로젝트에서는 package:web을 사용하세요.
// import 'package:web/web.dart' as web;
import 'dart:html' as html;
import 'dart:convert';

class PlatformService {
  String getStoragePath() {
    return '/web-storage';
  }

  Future<void> saveFile(String filename, List<int> bytes) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
```

```dart
// lib/core/platform/conditional_imports/platform_io.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlatformService {
  String getStoragePath() {
    if (Platform.isWindows) {
      return Platform.environment['APPDATA'] ?? '';
    } else if (Platform.isMacOS) {
      return Platform.environment['HOME'] ?? '';
    } else if (Platform.isLinux) {
      return Platform.environment['HOME'] ?? '';
    }
    return '';
  }

  Future<void> saveFile(String filename, List<int> bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
  }
}
```

```dart
// lib/core/platform/platform_service.dart
export 'conditional_imports/platform_stub.dart'
    if (dart.library.html) 'conditional_imports/platform_web.dart'
    if (dart.library.io) 'conditional_imports/platform_io.dart';
```

### 5.3 실제 사용 예제

```dart
// lib/features/file_manager/data/repositories/file_repository_impl.dart
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/platform/platform_service.dart';

@Injectable(as: FileRepository)
class FileRepositoryImpl implements FileRepository {
  final PlatformService _platformService;

  FileRepositoryImpl(this._platformService);

  @override
  Future<Either<FileFailure, Unit>> saveDocument(
    String filename,
    List<int> data,
  ) async {
    try {
      await _platformService.saveFile(filename, data);
      return right(unit);
    } catch (e) {
      return left(FileFailure.saveFailed(e.toString()));
    }
  }
}
```

---

## 6. 반응형 레이아웃

> 📖 **반응형 디자인 패턴, Breakpoint 시스템, ResponsiveBuilder 위젯**은 [ResponsiveDesign.md](../patterns/ResponsiveDesign.md)를 참조하세요.

**핵심 개념:**
- **Breakpoint 기반 레이아웃 전환**: 화면 크기에 따라 Mobile/Tablet/Desktop 레이아웃 분기
- **MediaQuery와 LayoutBuilder**: 런타임에 화면 크기 감지 및 동적 UI 구성
- **Adaptive Navigation**: BottomNavigationBar → NavigationRail → NavigationDrawer 전환

**간단한 예제:**

```dart
// 화면 크기에 따라 다른 레이아웃 표시
class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return const MobileLayout();
        } else if (constraints.maxWidth < 1200) {
          return const TabletLayout();
        } else {
          return const DesktopLayout();
        }
      },
    );
  }
}
```

---

## 7. 플랫폼별 UI

### 7.1 플랫폼별 위젯 선택

```dart
// lib/core/widgets/platform_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../platform/platform_detector.dart';

class PlatformWidget extends StatelessWidget {
  final WidgetBuilder materialBuilder;
  final WidgetBuilder? cupertinoBuilder;
  final WidgetBuilder? webBuilder;

  const PlatformWidget({
    super.key,
    required this.materialBuilder,
    this.cupertinoBuilder,
    this.webBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformDetector.isWeb && webBuilder != null) {
      return webBuilder!(context);
    }

    if (PlatformDetector.currentPlatform == PlatformType.macos ||
        PlatformDetector.currentPlatform == PlatformType.ios) {
      return cupertinoBuilder?.call(context) ?? materialBuilder(context);
    }

    return materialBuilder(context);
  }
}
```

### 7.2 플랫폼별 다이얼로그

```dart
// lib/core/widgets/platform_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../platform/platform_detector.dart';

class PlatformDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'OK',
    String? cancelText,
  }) {
    final isCupertino = PlatformDetector.currentPlatform == PlatformType.macos ||
                       PlatformDetector.currentPlatform == PlatformType.ios;

    if (isCupertino) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDefaultAction: true,
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }

    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelText),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
```

### 7.3 Fluent Design (Windows 11)

```yaml
# pubspec.yaml
dependencies:
  fluent_ui: ^4.9.1
  window_manager: ^0.4.2
```

```dart
// lib/main_windows.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyFluentApp());
}

class MyFluentApp extends StatelessWidget {
  const MyFluentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'My Windows App',
      theme: FluentThemeData(
        accentColor: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: FluentThemeData(
        accentColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const FluentHomePage(),
    );
  }
}

class FluentHomePage extends StatefulWidget {
  const FluentHomePage({super.key});

  @override
  State<FluentHomePage> createState() => _FluentHomePageState();
}

class _FluentHomePageState extends State<FluentHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        displayMode: PaneDisplayMode.open,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Home'),
            body: const Center(child: Text('Home Page')),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const Center(child: Text('Settings Page')),
          ),
        ],
      ),
    );
  }
}
```

---

## 8. 플랫폼별 기능

### 8.1 Web: localStorage & IndexedDB

```dart
// lib/features/storage/data/datasources/web_storage_datasource.dart
// ⚠️ 주의: dart:html은 Dart 3.4/Flutter 3.22부터 deprecated입니다.
// 실제 프로젝트에서는 package:web을 사용하세요.
// import 'package:web/web.dart' as web;
import 'dart:html' as html;
import 'dart:convert';
import 'package:injectable/injectable.dart';

@web
@Injectable(as: StorageDataSource)
class WebStorageDataSource implements StorageDataSource {
  final html.Storage _localStorage = html.window.localStorage;

  @override
  Future<String?> getString(String key) async {
    return _localStorage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _localStorage[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = _localStorage[key];
    if (jsonString == null) return null;
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _localStorage[key] = json.encode(value);
  }

  @override
  Future<void> remove(String key) async {
    _localStorage.remove(key);
  }

  @override
  Future<void> clear() async {
    _localStorage.clear();
  }
}
```

### 8.2 Desktop: 파일 시스템 접근

```dart
// lib/features/storage/data/datasources/desktop_storage_datasource.dart
import 'dart:io';
import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@desktop
@Injectable(as: StorageDataSource)
class DesktopStorageDataSource implements StorageDataSource {
  Future<File> _getFile(String key) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$key.json');
  }

  @override
  Future<String?> getString(String key) async {
    try {
      final file = await _getFile(key);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final file = await _getFile(key);
    await file.writeAsString(value);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, json.encode(value));
  }

  @override
  Future<void> remove(String key) async {
    final file = await _getFile(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        await file.delete();
      }
    }
  }
}
```

### 8.3 Desktop: 윈도우 관리

```dart
// lib/features/window/presentation/bloc/window_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'window_bloc.freezed.dart';
part 'window_event.dart';
part 'window_state.dart';

class WindowBloc extends Bloc<WindowEvent, WindowState> with WindowListener {
  WindowBloc() : super(const WindowState.initial()) {
    on<WindowEventInitialize>(_onInitialize);
    on<WindowEventMaximize>(_onMaximize);
    on<WindowEventMinimize>(_onMinimize);
    on<WindowEventClose>(_onClose);
    on<WindowEventFullscreen>(_onFullscreen);

    windowManager.addListener(this);
  }

  Future<void> _onInitialize(
    WindowEventInitialize event,
    Emitter<WindowState> emit,
  ) async {
    final isMaximized = await windowManager.isMaximized();
    final isFullscreen = await windowManager.isFullScreen();

    emit(WindowState.loaded(
      isMaximized: isMaximized,
      isFullscreen: isFullscreen,
    ));
  }

  Future<void> _onMaximize(
    WindowEventMaximize event,
    Emitter<WindowState> emit,
  ) async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _onMinimize(
    WindowEventMinimize event,
    Emitter<WindowState> emit,
  ) async {
    await windowManager.minimize();
  }

  Future<void> _onClose(
    WindowEventClose event,
    Emitter<WindowState> emit,
  ) async {
    await windowManager.close();
  }

  Future<void> _onFullscreen(
    WindowEventFullscreen event,
    Emitter<WindowState> emit,
  ) async {
    final isFullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFullscreen);
  }

  @override
  void onWindowMaximize() {
    add(const WindowEvent.initialize());
  }

  @override
  void onWindowUnmaximize() {
    add(const WindowEvent.initialize());
  }

  @override
  Future<void> close() {
    windowManager.removeListener(this);
    return super.close();
  }
}
```

### 8.4 Desktop: 시스템 트레이

```dart
// lib/features/tray/tray_manager.dart
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class AppTrayManager with TrayListener {
  Future<void> initialize() async {
    await trayManager.setIcon(
      'assets/icons/tray_icon.png',
    );

    final menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Show Window',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Exit',
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        break;
      case 'exit':
        windowManager.close();
        break;
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
```

---

## 9. 웹 특화

### 9.1 PWA (Progressive Web App)

```json
// web/manifest.json
{
  "name": "My Flutter App",
  "short_name": "Flutter App",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "description": "Flutter multi-platform application",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ]
}
```

### 9.2 Service Worker

```javascript
// web/flutter_service_worker.js
const CACHE_NAME = 'flutter-app-cache-v1';
const RESOURCES = {
  '/': 'index.html',
  'main.dart.js': 'main.dart.js',
  'assets/FontManifest.json': 'assets/FontManifest.json',
  // ... 기타 리소스
};

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(Object.keys(RESOURCES)))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => response || fetch(event.request))
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
});
```

### 9.3 Web JavaScript Interop

```dart
// lib/core/platform/web_interop.dart
// ⚠️ 주의: dart:js는 Dart 3.4부터 deprecated입니다.
// 실제 프로젝트에서는 dart:js_interop를 사용하세요.
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class WebInterop {
  static void callJavaScriptFunction(String functionName, List<dynamic> args) {
    if (!kIsWeb) return;

    js.context.callMethod(functionName, args);
  }

  static dynamic getJavaScriptProperty(String propertyName) {
    if (!kIsWeb) return null;

    return js.context[propertyName];
  }

  static void setJavaScriptProperty(String propertyName, dynamic value) {
    if (!kIsWeb) return;

    js.context[propertyName] = value;
  }

  // 사용 예: Google Analytics
  static void trackPageView(String pageName) {
    if (!kIsWeb) return;

    js.context.callMethod('gtag', [
      'event',
      'page_view',
      js.JsObject.jsify({
        'page_title': pageName,
        'page_path': '/$pageName',
      }),
    ]);
  }
}
```

```html
<!-- web/index.html - Google Analytics -->
<head>
  <!-- Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'GA_MEASUREMENT_ID');
  </script>
</head>
```

---

## 10. 데스크톱 특화

### 10.1 다중 윈도우 관리

```dart
// lib/features/multi_window/window_controller.dart
// ⚠️ 주의: WindowController 클래스는 Flutter에 존재하지 않습니다.
// 실제로는 window_manager 패키지의 windowManager 싱글톤을 사용하세요.
// 예: await windowManager.setTitle('...');
import 'package:window_manager/window_manager.dart';

class MultiWindowController {
  final Map<String, WindowController> _windows = {};

  Future<void> createWindow({
    required String id,
    required String title,
    double width = 800,
    double height = 600,
  }) async {
    if (_windows.containsKey(id)) {
      // 이미 존재하면 포커스
      await _windows[id]!.focus();
      return;
    }

    final controller = WindowController();
    await controller.ensureInitialized();

    await controller.setWindowOptions(
      WindowOptions(
        size: Size(width, height),
        center: true,
        title: title,
      ),
    );

    await controller.show();
    _windows[id] = controller;
  }

  Future<void> closeWindow(String id) async {
    if (!_windows.containsKey(id)) return;

    await _windows[id]!.close();
    _windows.remove(id);
  }

  Future<void> closeAllWindows() async {
    for (final controller in _windows.values) {
      await controller.close();
    }
    _windows.clear();
  }
}
```

### 10.2 키보드 단축키

```dart
// lib/features/shortcuts/keyboard_shortcuts.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSave;
  final VoidCallback? onOpen;
  final VoidCallback? onNew;
  final VoidCallback? onQuit;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.onSave,
    this.onOpen,
    this.onNew,
    this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyS,
        ): const SaveIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyO,
        ): const OpenIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyN,
        ): const NewIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyQ,
        ): const QuitIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (_) => onSave?.call(),
          ),
          OpenIntent: CallbackAction<OpenIntent>(
            onInvoke: (_) => onOpen?.call(),
          ),
          NewIntent: CallbackAction<NewIntent>(
            onInvoke: (_) => onNew?.call(),
          ),
          QuitIntent: CallbackAction<QuitIntent>(
            onInvoke: (_) => onQuit?.call(),
          ),
        },
        child: child,
      ),
    );
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NewIntent extends Intent {
  const NewIntent();
}

class QuitIntent extends Intent {
  const QuitIntent();
}
```

### 10.3 네이티브 메뉴 바 (macOS)

```dart
// lib/features/menu/macos_menu.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacOSMenuBar extends StatelessWidget {
  final Widget child;

  const MacOSMenuBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'File',
          menus: [
            PlatformMenuItem(
              label: 'New',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
              ),
              onSelected: () {
                // New file action
              },
            ),
            PlatformMenuItem(
              label: 'Open...',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyO,
                meta: true,
              ),
              onSelected: () {
                // Open file action
              },
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Save',
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyS,
                    meta: true,
                  ),
                ),
                PlatformMenuItem(
                  label: 'Save As...',
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyS,
                    meta: true,
                    shift: true,
                  ),
                ),
              ],
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),
        PlatformMenu(
          label: 'Edit',
          menus: [
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.undo,
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.redo,
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.cut,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.copy,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.paste,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.selectAll,
                ),
              ],
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
```

---

## 11. CI/CD

### 11.1 GitHub Actions - Web 배포

```yaml
# .github/workflows/deploy-web.yml
name: Deploy Flutter Web

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      - name: Build web
        run: flutter build web --release --web-renderer canvaskit

      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: my-flutter-app
```

### 11.2 GitHub Actions - Windows 빌드

```yaml
# .github/workflows/build-windows.yml
name: Build Windows

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build Windows
        run: flutter build windows --release

      - name: Create MSIX package
        run: |
          flutter pub add msix
          flutter pub run msix:create

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: windows-release
          path: build/windows/x64/runner/Release/
```

### 11.3 GitHub Actions - macOS 빌드

```yaml
# .github/workflows/build-macos.yml
name: Build macOS

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Build macOS
        run: flutter build macos --release

      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "My Flutter App" \
            --window-pos 200 120 \
            --window-size 800 400 \
            --icon-size 100 \
            --app-drop-link 600 185 \
            "MyFlutterApp.dmg" \
            "build/macos/Build/Products/Release/my_app.app"

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: macos-release
          path: MyFlutterApp.dmg
```

### 11.4 Firebase Hosting 설정

```json
// firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(wasm|js|css|png|jpg|jpeg|svg|woff|woff2)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

---

## 12. 성능 최적화

### 12.1 플랫폼별 최적화 전략

| 플랫폼 | 최적화 포인트 | 도구 |
|--------|--------------|------|
| **Web** | 번들 크기, 초기 로딩 속도, 이미지 최적화 | Tree-shaking, Lazy loading, WebP |
| **Windows** | 실행 파일 크기, 시작 속도 | AOT 컴파일, 리소스 압축 |
| **macOS** | 메모리 사용량, 배터리 효율 | Instruments, Metal API |
| **Linux** | 의존성 크기, 호환성 | Static linking, AppImage |

### 12.2 Web 번들 크기 최적화

```dart
// lib/core/lazy_loading/lazy_widget.dart
import 'package:flutter/material.dart';

class LazyWidget extends StatefulWidget {
  final Future<Widget> Function() builder;
  final Widget placeholder;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder = const CircularProgressIndicator(),
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _loadedWidget;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  Future<void> _loadWidget() async {
    final widget = await widget.builder();
    if (mounted) {
      setState(() {
        _loadedWidget = widget;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loadedWidget ?? widget.placeholder;
  }
}

// 사용 예
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LazyWidget(
      builder: () async {
        // 동적으로 로드되는 무거운 위젯
        await Future.delayed(const Duration(milliseconds: 100));
        return const HeavyWidget();
      },
      placeholder: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### 12.3 이미지 최적화

```dart
// lib/core/widgets/optimized_image.dart
import 'package:flutter/material.dart';
import '../../platform/platform_detector.dart';

class OptimizedImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const OptimizedImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // Web에서는 WebP, 네이티브에서는 PNG/JPG
    final optimizedPath = PlatformDetector.isWeb
        ? assetPath.replaceAll('.png', '.webp').replaceAll('.jpg', '.webp')
        : assetPath;

    return Image.asset(
      optimizedPath,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      },
    );
  }
}
```

### 12.4 Desktop 시작 속도 최적화

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'core/di/injection.dart';

void main() async {
  // 최소한의 초기화만 수행
  WidgetsFlutterBinding.ensureInitialized();

  // 빠른 UI 표시
  runApp(const SplashScreen());

  // 백그라운드에서 의존성 초기화
  await configureDependencies();

  // 실제 앱 실행
  runApp(const MyApp());
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlutterLogo(size: 100),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 13. 테스트

### 13.1 플랫폼별 테스트 전략

```dart
// test/core/platform/platform_detector_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/platform/platform_detector.dart';

void main() {
  group('PlatformDetector', () {
    test('should detect platform correctly', () {
      final platform = PlatformDetector.currentPlatform;

      expect(platform, isIn([
        PlatformType.web,
        PlatformType.windows,
        PlatformType.macos,
        PlatformType.linux,
        PlatformType.android,
        PlatformType.ios,
      ]));
    });

    test('isDesktop should return true for desktop platforms', () {
      final isDesktop = PlatformDetector.isDesktop;

      if (PlatformDetector.currentPlatform == PlatformType.windows ||
          PlatformDetector.currentPlatform == PlatformType.macos ||
          PlatformDetector.currentPlatform == PlatformType.linux) {
        expect(isDesktop, true);
      } else {
        expect(isDesktop, false);
      }
    });
  });
}
```

### 13.2 Web 브라우저 테스트

```dart
// integration_test/web_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web Integration Tests', () {
    testWidgets('should navigate between pages', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 홈 페이지 확인
      expect(find.text('Home'), findsOneWidget);

      // About 페이지로 이동
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('About Page'), findsOneWidget);
    });

    testWidgets('should handle responsive layout', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Desktop 크기
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);

      // Mobile 크기
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
    });
  });
}
```

```bash
# Web 테스트 실행
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/web_test.dart \
  -d web-server
```

### 13.3 Desktop 통합 테스트

```dart
// integration_test/desktop_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:window_manager/window_manager.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Desktop Integration Tests', () {
    testWidgets('should initialize window correctly', (tester) async {
      await windowManager.ensureInitialized();

      app.main();
      await tester.pumpAndSettle();

      final size = await windowManager.getSize();
      expect(size.width, greaterThanOrEqualTo(800));
      expect(size.height, greaterThanOrEqualTo(600));
    });

    testWidgets('should handle window maximize/minimize', (tester) async {
      await windowManager.maximize();
      await tester.pumpAndSettle();

      final isMaximized = await windowManager.isMaximized();
      expect(isMaximized, true);

      await windowManager.unmaximize();
      await tester.pumpAndSettle();

      final isUnmaximized = await windowManager.isMaximized();
      expect(isUnmaximized, false);
    });
  });
}
```

```bash
# Desktop 테스트 실행
flutter test integration_test/desktop_test.dart -d windows
flutter test integration_test/desktop_test.dart -d macos
flutter test integration_test/desktop_test.dart -d linux
```

---

## 14. Best Practices

### 14.1 Do / Don't

| Do ✅ | Don't ❌ |
|-------|----------|
| **플랫폼 감지는 런타임에 수행** | 빌드 타임에 플랫폼 가정 |
| **Conditional Import로 플랫폼 분기** | `if (kIsWeb)` 남용 |
| **반응형 레이아웃 설계** | 고정 픽셀 크기 사용 |
| **각 플랫폼에 맞는 UI/UX 제공** | 모든 플랫폼에 동일한 UI |
| **플랫폼별 최적화 (번들 크기, 성능)** | One-size-fits-all 접근 |
| **Web SEO 메타 태그 설정** | SEO 무시 |
| **Desktop 키보드 단축키 지원** | 마우스만 의존 |
| **PWA로 웹 앱 경험 개선** | 일반 웹사이트로만 배포 |
| **플랫폼별 테스트 작성** | 한 플랫폼만 테스트 |
| **CI/CD로 자동 배포** | 수동 빌드/배포 |

### 14.2 아키텍처 패턴

```dart
// Clean Architecture + Platform Abstraction
// lib/features/storage/domain/repositories/storage_repository.dart
import 'package:fpdart/fpdart.dart';
import '../entities/storage_entity.dart';
import '../failures/storage_failure.dart';

abstract class StorageRepository {
  Future<Either<StorageFailure, String?>> getString(String key);
  Future<Either<StorageFailure, Unit>> setString(String key, String value);
  Future<Either<StorageFailure, Map<String, dynamic>?>> getJson(String key);
  Future<Either<StorageFailure, Unit>> setJson(String key, Map<String, dynamic> value);
  Future<Either<StorageFailure, Unit>> remove(String key);
  Future<Either<StorageFailure, Unit>> clear();
}

// lib/features/storage/data/repositories/storage_repository_impl.dart
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/storage_datasource.dart';

@Injectable(as: StorageRepository)
class StorageRepositoryImpl implements StorageRepository {
  final StorageDataSource _dataSource;

  StorageRepositoryImpl(this._dataSource);

  @override
  Future<Either<StorageFailure, String?>> getString(String key) async {
    try {
      final result = await _dataSource.getString(key);
      return right(result);
    } catch (e) {
      return left(StorageFailure.readFailed(e.toString()));
    }
  }

  // ... 나머지 메서드 구현
}
```

### 14.3 의존성 주입 설정

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();
}

// 플랫폼별 환경
const web = Environment('web');
const desktop = Environment('desktop');
const mobile = Environment('mobile');
```

```dart
// lib/features/storage/data/datasources/storage_datasource.dart
abstract class StorageDataSource {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> setJson(String key, Map<String, dynamic> value);
  Future<void> remove(String key);
  Future<void> clear();
}

// Web 구현은 @web 환경에서만 등록
// Desktop 구현은 @desktop 환경에서만 등록
```

### 14.4 상태 관리 패턴

```dart
// lib/features/home/presentation/bloc/home_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetUserDataUseCase _getUserData;

  HomeBloc(this._getUserData) : super(const HomeState.initial()) {
    on<HomeEventLoad>(_onLoad);
  }

  Future<void> _onLoad(
    HomeEventLoad event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeState.loading());

    final result = await _getUserData();

    result.fold(
      (failure) => emit(HomeState.error(failure.message)),
      (data) => emit(HomeState.loaded(data)),
    );
  }
}

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.load() = HomeEventLoad;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded(UserData data) = _Loaded;
  const factory HomeState.error(String message) = _Error;
}
```

### 14.5 체크리스트

**프로젝트 시작 전:**
- [ ] 타겟 플랫폼 결정 (Web, Windows, macOS, Linux)
- [ ] 플랫폼별 요구사항 정리
- [ ] Clean Architecture + Bloc 구조 설계
- [ ] 반응형 레이아웃 브레이크포인트 정의
- [ ] 플랫폼별 패키지 의존성 확인

**개발 중:**
- [ ] Conditional Import로 플랫폼 분기
- [ ] 반응형 UI 구현 (Mobile/Tablet/Desktop)
- [ ] 플랫폼별 기능 구현 (Storage, File, Window)
- [ ] 단위 테스트 + 통합 테스트 작성
- [ ] 각 플랫폼에서 실제 테스트

**배포 전:**
- [ ] Web: HTML/CanvasKit 렌더러 선택
- [ ] Web: SEO 메타 태그 설정
- [ ] Web: PWA manifest.json 작성
- [ ] Desktop: 윈도우 크기/권한 설정
- [ ] Desktop: 키보드 단축키 구현
- [ ] CI/CD 파이프라인 설정
- [ ] 플랫폼별 빌드 테스트

**성능 최적화:**
- [ ] Web 번들 크기 최적화 (Tree-shaking, Lazy loading)
- [ ] 이미지 최적화 (WebP 변환)
- [ ] Desktop 시작 속도 개선
- [ ] 메모리 사용량 프로파일링

---

## 마치며

이 가이드는 Flutter로 Web과 Desktop 애플리케이션을 개발할 때 필요한 핵심 개념과 실전 패턴을 다룹니다.

**주요 포인트:**
1. **단일 코드베이스, 플랫폼별 최적화**: Conditional Import와 플랫폼 감지로 각 플랫폼에 최적화된 경험 제공
2. **Clean Architecture + Bloc**: 유지보수 가능하고 테스트하기 쉬운 구조
3. **반응형 디자인**: Mobile, Tablet, Desktop에 맞는 적응형 UI
4. **플랫폼별 기능**: Web(PWA, localStorage), Desktop(파일 시스템, 윈도우 관리, 트레이)
5. **성능 최적화**: 번들 크기, 로딩 속도, 메모리 사용량
6. **CI/CD 자동화**: GitHub Actions로 자동 빌드/배포

**다음 단계:**
- 실제 프로젝트에 적용해보기
- 플랫폼별 테스트 환경 구축
- CI/CD 파이프라인 설정
- 사용자 피드백을 통한 플랫폼별 UX 개선

**참고 자료:**
- [Flutter Web 공식 문서](https://docs.flutter.dev/platform-integration/web)
- [Flutter Desktop 공식 문서](https://docs.flutter.dev/platform-integration/desktop)
- [Responsive Framework](https://pub.dev/packages/responsive_framework)
- [Window Manager](https://pub.dev/packages/window_manager)

---

## 실습 과제

### 과제 1: 반응형 레이아웃
모바일(< 600px), 태블릿(600-1200px), 데스크톱(> 1200px)에서 다른 레이아웃을 보여주는 반응형 화면을 구현하세요.

### 과제 2: 플랫폼별 조건부 Import
Web에서는 html 렌더러, 모바일에서는 네이티브 기능을 사용하는 조건부 Import 패턴을 구현하세요.

## Self-Check

- [ ] Flutter Web 빌드와 배포(Firebase Hosting 등)를 수행할 수 있는가?
- [ ] 조건부 Import(`dart:io` vs `dart:html`)를 사용할 수 있는가?
- [ ] 반응형 UI를 LayoutBuilder와 MediaQuery로 구현할 수 있는가?
- [ ] 데스크톱 앱에서 메뉴바, 시스템 트레이 등 플랫폼 특화 기능을 구현할 수 있는가?
