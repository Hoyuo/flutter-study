# Server-Driven UI - Flutter 서버 주도 UI 패턴

> **난이도**: 시니어 | **카테고리**: advanced
> **선행 학습**: [Architecture](../core/Architecture.md), [Freezed](../core/Freezed.md)
> **예상 학습 시간**: 3h

> **학습 목표**
> - Server-Driven UI(SDUI) 개념과 동작 원리 이해
> - JSON 스키마를 Flutter 위젯으로 변환하는 렌더링 엔진 구현
> - Widget Registry 패턴으로 확장 가능한 위젯 시스템 설계
> - Action 시스템으로 사용자 인터랙션 처리
> - 3-tier 캐싱 전략으로 오프라인 지원 및 성능 최적화
> - A/B 테스트와 Feature Flag를 통한 동적 UI 실험
> - 프로덕션 환경의 SDUI 아키텍처 구축

## 목차

1. [개요](#1-개요)
2. [설치 및 설정](#2-설치-및-설정)
3. [JSON 스키마 설계](#3-json-스키마-설계)
4. [Widget Registry 패턴](#4-widget-registry-패턴)
5. [SDUI 렌더링 엔진](#5-sdui-렌더링-엔진)
6. [Action 시스템](#6-action-시스템)
7. [서버 API 연동](#7-서버-api-연동)
8. [캐싱 전략](#8-캐싱-전략)
9. [A/B 테스트 & Feature Flag](#9-ab-테스트--feature-flag)
10. [성능 최적화](#10-성능-최적화)
11. [보안](#11-보안)
12. [테스트](#12-테스트)
13. [실전 예제: 동적 홈 화면](#13-실전-예제-동적-홈-화면)
14. [Best Practices](#14-best-practices)
15. [관련 문서](#15-관련-문서)

## 1. 개요

### 1.1 SDUI란 무엇인가

Server-Driven UI(SDUI)는 앱의 UI 구조와 레이아웃을 서버에서 JSON 형태로 전달받아 동적으로 렌더링하는 아키텍처 패턴입니다. 네이티브 앱에서 UI 변경을 위해 앱 스토어 배포를 기다리지 않고, 서버 설정만으로 즉시 UI를 변경할 수 있습니다.

```dart
// 전통적인 방식
class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductImage(),
        ProductTitle(),
        ProductPrice(),
        BuyButton(),
      ],
    );
  }
}

// SDUI 방식
class ProductScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchemaBloc, SchemaState>(
      builder: (context, state) {
        if (state is SchemaLoaded) {
          return SDUIRenderer(
            node: state.schema,
            registry: getIt<WidgetRegistry>(),
            actionHandler: getIt<ActionHandler>(),
          );
        }
        return LoadingIndicator();
      },
    );
  }
}
```

### 1.2 왜 사용하는가

**주요 기업 사례:**

| 회사 | 사용 사례 | 효과 |
|------|----------|------|
| **Airbnb** | 검색 결과, 숙소 상세 페이지 | 배포 없이 A/B 테스트, 실험 주기 80% 단축 |
| **Netflix** | 홈 화면, 추천 섹션 | 개인화된 레이아웃, 빠른 실험 반복 |
| **Lyft** | 프로모션 배너, 온보딩 플로우 | 즉시 마케팅 캠페인 반영, 전환율 35% 향상 |
| **DoorDash** | 메뉴 레이아웃, 주문 플로우 | 지역별 맞춤 UI, 개발 속도 2배 향상 |

**핵심 장점:**

1. **빠른 배포**: 앱 스토어 승인 없이 UI 변경
2. **A/B 테스트**: 서버에서 사용자 그룹별 다른 UI 제공
3. **개인화**: 사용자별 맞춤 레이아웃
4. **일관성**: iOS/Android 동일 스키마 사용
5. **비즈니스 민첩성**: 마케팅 캠페인 즉시 반영

### 1.3 정적 UI vs SDUI 비교

| 측면 | 정적 UI | SDUI |
|------|---------|------|
| **배포 주기** | 앱 스토어 승인 필요 (수일~수주) | 즉시 (수분) |
| **개발 속도** | 빠름 (컴파일 타임 체크) | 중간 (스키마 설계 필요) |
| **유연성** | 낮음 (하드코딩) | 높음 (서버 제어) |
| **A/B 테스트** | 복잡 (Feature Flag + 조건 분기) | 간단 (서버에서 스키마 분기) |
| **성능** | 매우 빠름 | 빠름 (파싱 오버헤드 존재) |
| **타입 안전성** | 높음 (컴파일 타임) | 중간 (런타임 검증) |
| **디버깅** | 쉬움 | 어려움 (JSON 추적 필요) |
| **초기 구축 비용** | 낮음 | 높음 (인프라 구축) |
| **유지보수** | UI 변경마다 배포 | 스키마 버전 관리 |

### 1.4 언제 SDUI를 선택하는가

**적합한 경우:**

- 빈번한 UI 실험이 필요한 화면 (홈, 프로모션, 온보딩)
- 지역/사용자별 맞춤 레이아웃이 필요한 경우
- 마케팅 주도 화면 (배너, 캠페인 페이지)
- 콘텐츠 중심 화면 (뉴스피드, 탐색 화면)

**부적합한 경우:**

- 복잡한 인터랙션이 많은 화면 (게임, 복잡한 애니메이션)
- 높은 성능이 필수인 화면 (실시간 차트, 비디오 에디터)
- 네이티브 기능이 많이 필요한 화면 (카메라, AR)
- 정적이고 거의 변경되지 않는 화면 (설정, 프로필)

## 2. 설치 및 설정

### 2.1 의존성 추가

```yaml
# pubspec.yaml
name: flutter_sdui_app
description: Server-Driven UI implementation
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # 상태 관리
  flutter_bloc: ^9.1.1

  # 네트워킹
  dio: ^5.8.0+1
  retrofit: ^4.5.0
  pretty_dio_logger: ^1.4.0

  # JSON 직렬화
  json_annotation: ^4.10.0
  freezed_annotation: ^3.2.5

  # 함수형 프로그래밍
  fpdart: ^1.2.0

  # 의존성 주입
  get_it: ^8.0.3
  injectable: ^2.7.1

  # 라우팅
  go_router: ^14.8.1

  # 캐싱
  hive: ^2.2.3  # 유지보수 모드 - Hive 4.x(CE) 또는 Drift 검토 권장
  hive_flutter: ^1.1.0
  path_provider: ^2.1.5

  # 이미지 캐싱
  cached_network_image: ^3.4.1

  # 유틸리티
  equatable: ^2.0.8
  intl: ^0.19.0
  logger: ^2.5.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

  # 코드 생성
  build_runner: ^2.11.0
  json_serializable: ^6.12.0
  freezed: ^3.2.5
  retrofit_generator: ^9.1.4
  injectable_generator: ^2.7.0
  hive_generator: ^2.0.1

  # 테스트
  bloc_test: ^10.0.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
  assets:
    - assets/schemas/
    - assets/images/
```

### 2.2 코드 생성

```bash
# 초기 빌드
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 개발 중 자동 생성 (watch 모드)
dart run build_runner watch --delete-conflicting-outputs
```

### 2.3 프로젝트 구조

```
lib/
├── core/
│   ├── sdui/
│   │   ├── models/
│   │   │   ├── sdui_node.dart          # 스키마 노드 모델
│   │   │   ├── sdui_action.dart        # 액션 모델
│   │   │   ├── widget_type.dart        # 위젯 타입 enum
│   │   │   └── sdui_response.dart      # API 응답 모델
│   │   ├── registry/
│   │   │   ├── widget_registry.dart    # 위젯 레지스트리
│   │   │   ├── default_builders.dart   # 기본 위젯 빌더
│   │   │   └── custom_builders.dart    # 커스텀 위젯 빌더
│   │   ├── renderer/
│   │   │   ├── sdui_renderer.dart      # 렌더링 엔진
│   │   │   ├── attribute_parser.dart   # 속성 파서
│   │   │   └── error_widgets.dart      # 에러 위젯
│   │   ├── actions/
│   │   │   ├── action_handler.dart     # 액션 핸들러
│   │   │   ├── action_types.dart       # 액션 타입 정의
│   │   │   └── action_executor.dart    # 액션 실행기
│   │   ├── cache/
│   │   │   ├── schema_cache.dart       # 스키마 캐시
│   │   │   ├── memory_cache.dart       # 메모리 캐시
│   │   │   └── disk_cache.dart         # 디스크 캐시
│   │   └── validation/
│   │       ├── schema_validator.dart   # 스키마 검증
│   │       └── security_validator.dart # 보안 검증
│   ├── network/
│   │   ├── api_client.dart
│   │   └── interceptors/
│   ├── di/
│   │   └── injection.dart
│   └── error/
│       └── failures.dart
├── features/
│   └── schema/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── schema_remote_datasource.dart
│       │   │   ├── schema_local_datasource.dart
│       │   │   └── schema_asset_datasource.dart
│       │   └── repositories/
│       │       └── schema_repository_impl.dart
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── schema_repository.dart
│       │   └── usecases/
│       │       ├── fetch_schema_usecase.dart
│       │       └── refresh_schema_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── schema_bloc.dart
│           │   ├── schema_event.dart
│           │   └── schema_state.dart
│           └── pages/
│               └── sdui_page.dart
└── main.dart

assets/
└── schemas/
    ├── home_fallback.json
    ├── product_fallback.json
    └── profile_fallback.json
```

## 3. JSON 스키마 설계

### 3.1 핵심 구조

SDUI 스키마는 **트리 구조**로 설계됩니다. 각 노드는 위젯을 표현하며, `type`, `attributes`, `children`, `action` 속성을 가집니다.

```
SDUINode
├── type: String              # 위젯 타입 (예: "Column", "Text", "Button")
├── id: String?               # 선택적 고유 식별자 (A/B 테스트, 분석)
├── attributes: Map           # 위젯 속성 (색상, 크기, 텍스트 등)
├── children: List<SDUINode>  # 자식 노드 (재귀 구조)
└── action: SDUIAction?       # 사용자 인터랙션 액션
```

**스키마 예시:**

```json
{
  "version": "1.0",
  "screen": "home",
  "timestamp": "2026-02-07T10:00:00Z",
  "node": {
    "type": "Scaffold",
    "attributes": {
      "backgroundColor": "#FFFFFF",
      "appBar": {
        "title": "홈",
        "centerTitle": true
      }
    },
    "children": [
      {
        "type": "Column",
        "id": "home_content",
        "attributes": {
          "crossAxisAlignment": "stretch",
          "padding": "16,16,16,16"
        },
        "children": [
          {
            "type": "Text",
            "id": "welcome_text",
            "attributes": {
              "text": "환영합니다!",
              "fontSize": 24,
              "fontWeight": "bold",
              "color": "#000000"
            }
          },
          {
            "type": "SizedBox",
            "attributes": {
              "height": 20
            }
          },
          {
            "type": "ElevatedButton",
            "id": "cta_button",
            "attributes": {
              "text": "시작하기",
              "backgroundColor": "#2196F3",
              "textColor": "#FFFFFF",
              "padding": "16,32,16,32",
              "borderRadius": 8
            },
            "action": {
              "type": "navigate",
              "url": "/products",
              "params": {
                "category": "featured"
              }
            }
          }
        ]
      }
    ]
  }
}
```

### 3.2 스키마 버전 관리

```dart
// lib/core/sdui/models/schema_version.dart
enum SchemaVersion {
  v1_0('1.0'),
  v1_1('1.1'),
  v2_0('2.0');

  const SchemaVersion(this.version);
  final String version;

  static SchemaVersion fromString(String version) {
    return SchemaVersion.values.firstWhere(
      (v) => v.version == version,
      orElse: () => SchemaVersion.v1_0,
    );
  }

  bool isCompatible(SchemaVersion other) {
    final thisMajor = int.parse(version.split('.')[0]);
    final otherMajor = int.parse(other.version.split('.')[0]);
    return thisMajor == otherMajor;
  }
}
```

### 3.3 위젯 타입 정의

```dart
// lib/core/sdui/models/widget_type.dart
enum WidgetType {
  // 레이아웃
  scaffold,
  container,
  column,
  row,
  stack,
  center,
  padding,
  sizedBox,
  expanded,
  flexible,
  wrap,

  // 스크롤
  listView,
  gridView,
  singleChildScrollView,

  // 텍스트
  text,
  richText,

  // 버튼
  elevatedButton,
  textButton,
  outlinedButton,
  iconButton,

  // 입력
  textField,
  checkbox,
  radio,
  switchWidget,
  slider,

  // 이미지
  image,
  networkImage,
  assetImage,
  circleAvatar,

  // 카드
  card,
  listTile,

  // 기타
  icon,
  divider,
  spacer,
  chip,
  badge,
  circularProgressIndicator,

  // 커스텀
  custom;

  String toJson() => name;

  static WidgetType fromJson(String json) {
    return WidgetType.values.firstWhere(
      (type) => type.name == json,
      orElse: () => WidgetType.custom,
    );
  }
}
```

### 3.4 스키마 모델 (Freezed)

```dart
// lib/core/sdui/models/sdui_node.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'sdui_action.dart';

part 'sdui_node.freezed.dart';
part 'sdui_node.g.dart';

@freezed
class SDUINode with _$SDUINode {
  const factory SDUINode({
    required String type,
    String? id,
    @Default({}) Map<String, dynamic> attributes,
    @Default([]) List<SDUINode> children,
    SDUIAction? action,
  }) = _SDUINode;

  factory SDUINode.fromJson(Map<String, dynamic> json) =>
      _$SDUINodeFromJson(json);
}

// lib/core/sdui/models/sdui_action.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sdui_action.freezed.dart';
part 'sdui_action.g.dart';

@freezed
class SDUIAction with _$SDUIAction {
  const factory SDUIAction({
    required String type,
    String? url,
    String? method,
    Map<String, dynamic>? params,
    Map<String, String>? headers,
    SDUIAction? onSuccess,
    SDUIAction? onError,
    String? analyticsEvent,
    Map<String, dynamic>? analyticsParams,
  }) = _SDUIAction;

  factory SDUIAction.fromJson(Map<String, dynamic> json) =>
      _$SDUIActionFromJson(json);
}

// lib/core/sdui/models/sdui_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'sdui_node.dart';

part 'sdui_response.freezed.dart';
part 'sdui_response.g.dart';

@freezed
class SDUIResponse with _$SDUIResponse {
  const factory SDUIResponse({
    required String version,
    required String screen,
    required DateTime timestamp,
    required SDUINode node,
    Map<String, dynamic>? metadata,
    int? cacheTtl,
    String? etag,
  }) = _SDUIResponse;

  factory SDUIResponse.fromJson(Map<String, dynamic> json) =>
      _$SDUIResponseFromJson(json);
}
```

## 4. Widget Registry 패턴

### 4.1 Widget Registry 구현

Widget Registry는 **Factory 패턴**으로, 문자열 타입을 받아 해당하는 위젯을 생성합니다.

```dart
// lib/core/sdui/registry/widget_registry.dart
import 'package:flutter/widgets.dart';
import '../models/sdui_node.dart';
import '../renderer/sdui_renderer.dart';

typedef SDUIWidgetBuilder = Widget Function(
  SDUINode node,
  SDUIRenderer renderer,
);

class WidgetRegistry {
  final Map<String, SDUIWidgetBuilder> _builders = {};

  void register(String type, SDUIWidgetBuilder builder) {
    _builders[type] = builder;
  }

  void registerAll(Map<String, SDUIWidgetBuilder> builders) {
    _builders.addAll(builders);
  }

  bool isRegistered(String type) {
    return _builders.containsKey(type);
  }

  Widget build(SDUINode node, SDUIRenderer renderer) {
    final builder = _builders[node.type];
    if (builder == null) {
      return UnknownWidgetPlaceholder(
        type: node.type,
        nodeId: node.id,
      );
    }

    try {
      return builder(node, renderer);
    } catch (e, stackTrace) {
      return ErrorWidgetPlaceholder(
        type: node.type,
        error: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  List<String> getRegisteredTypes() {
    return _builders.keys.toList()..sort();
  }
}
```

### 4.2 기본 위젯 빌더

```dart
// lib/core/sdui/registry/default_builders.dart
import 'package:flutter/material.dart';
import '../models/sdui_node.dart';
import '../renderer/sdui_renderer.dart';
import '../renderer/attribute_parser.dart';
import 'widget_registry.dart';

class DefaultBuilders {
  static Map<String, SDUIWidgetBuilder> getBuilders() {
    return {
      'Scaffold': _buildScaffold,
      'Container': _buildContainer,
      'Column': _buildColumn,
      'Row': _buildRow,
      'Stack': _buildStack,
      'Center': _buildCenter,
      'Padding': _buildPadding,
      'SizedBox': _buildSizedBox,
      'Expanded': _buildExpanded,
      'Flexible': _buildFlexible,
      'Text': _buildText,
      'ElevatedButton': _buildElevatedButton,
      'TextButton': _buildTextButton,
      'OutlinedButton': _buildOutlinedButton,
      'Image': _buildImage,
      'NetworkImage': _buildNetworkImage,
      'Icon': _buildIcon,
      'Card': _buildCard,
      'ListTile': _buildListTile,
      'ListView': _buildListView,
      'Divider': _buildDivider,
      'Spacer': _buildSpacer,
      'CircularProgressIndicator': _buildCircularProgressIndicator,
    };
  }

  static Widget _buildScaffold(SDUINode node, SDUIRenderer renderer) {
    final attrs = node.attributes;
    final parser = AttributeParser(attrs);

    return Scaffold(
      backgroundColor: parser.parseColor('backgroundColor'),
      appBar: attrs.containsKey('appBar')
          ? AppBar(
              title: Text(attrs['appBar']['title'] ?? ''),
              centerTitle: attrs['appBar']['centerTitle'] ?? false,
              backgroundColor: parser.parseColor('appBar.backgroundColor'),
            )
          : null,
      body: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
      floatingActionButton: attrs.containsKey('fab')
          ? FloatingActionButton(
              onPressed: () {
                if (node.action != null) {
                  renderer.actionHandler.handle(node.action!);
                }
              },
              child: Icon(
                parser.parseIconData('fab.icon') ?? Icons.add,
              ),
            )
          : null,
    );
  }

  static Widget _buildContainer(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Container(
      width: parser.parseDouble('width'),
      height: parser.parseDouble('height'),
      padding: parser.parseEdgeInsets('padding'),
      margin: parser.parseEdgeInsets('margin'),
      decoration: BoxDecoration(
        color: parser.parseColor('backgroundColor'),
        borderRadius: parser.parseBorderRadius('borderRadius'),
        border: parser.parseBorder('border'),
        boxShadow: parser.parseBoxShadow('boxShadow'),
      ),
      alignment: parser.parseAlignment('alignment'),
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  static Widget _buildColumn(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Column(
      mainAxisAlignment: parser.parseMainAxisAlignment('mainAxisAlignment') ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          parser.parseCrossAxisAlignment('crossAxisAlignment') ??
              CrossAxisAlignment.center,
      mainAxisSize: parser.parseMainAxisSize('mainAxisSize') ?? MainAxisSize.max,
      children: renderer.buildChildren(node.children),
    );
  }

  static Widget _buildRow(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Row(
      mainAxisAlignment: parser.parseMainAxisAlignment('mainAxisAlignment') ??
          MainAxisAlignment.start,
      crossAxisAlignment:
          parser.parseCrossAxisAlignment('crossAxisAlignment') ??
              CrossAxisAlignment.center,
      mainAxisSize: parser.parseMainAxisSize('mainAxisSize') ?? MainAxisSize.max,
      children: renderer.buildChildren(node.children),
    );
  }

  static Widget _buildStack(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Stack(
      alignment: parser.parseAlignment('alignment') ?? Alignment.topLeft,
      fit: parser.parseStackFit('fit') ?? StackFit.loose,
      children: renderer.buildChildren(node.children),
    );
  }

  static Widget _buildCenter(SDUINode node, SDUIRenderer renderer) {
    return Center(
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  static Widget _buildPadding(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Padding(
      padding: parser.parseEdgeInsets('padding') ?? EdgeInsets.zero,
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  static Widget _buildSizedBox(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return SizedBox(
      width: parser.parseDouble('width'),
      height: parser.parseDouble('height'),
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  static Widget _buildExpanded(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Expanded(
      flex: parser.parseInt('flex') ?? 1,
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : const SizedBox.shrink(),
    );
  }

  static Widget _buildFlexible(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Flexible(
      flex: parser.parseInt('flex') ?? 1,
      fit: parser.parseFlexFit('fit') ?? FlexFit.loose,
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : const SizedBox.shrink(),
    );
  }

  static Widget _buildText(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final text = parser.parseString('text') ?? '';

    return Text(
      text,
      style: TextStyle(
        fontSize: parser.parseDouble('fontSize'),
        fontWeight: parser.parseFontWeight('fontWeight'),
        color: parser.parseColor('color'),
        fontStyle: parser.parseFontStyle('fontStyle'),
        decoration: parser.parseTextDecoration('decoration'),
        letterSpacing: parser.parseDouble('letterSpacing'),
        height: parser.parseDouble('lineHeight'),
      ),
      textAlign: parser.parseTextAlign('textAlign'),
      maxLines: parser.parseInt('maxLines'),
      overflow: parser.parseTextOverflow('overflow'),
    );
  }

  static Widget _buildElevatedButton(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final text = parser.parseString('text') ?? 'Button';

    return ElevatedButton(
      onPressed: node.action != null
          ? () => renderer.actionHandler.handle(node.action!)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: parser.parseColor('backgroundColor'),
        foregroundColor: parser.parseColor('textColor'),
        padding: parser.parseEdgeInsets('padding'),
        shape: RoundedRectangleBorder(
          borderRadius: parser.parseBorderRadius('borderRadius') ??
              BorderRadius.circular(4),
        ),
        elevation: parser.parseDouble('elevation'),
      ),
      child: Text(text),
    );
  }

  static Widget _buildTextButton(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final text = parser.parseString('text') ?? 'Button';

    return TextButton(
      onPressed: node.action != null
          ? () => renderer.actionHandler.handle(node.action!)
          : null,
      style: TextButton.styleFrom(
        foregroundColor: parser.parseColor('textColor'),
        padding: parser.parseEdgeInsets('padding'),
      ),
      child: Text(text),
    );
  }

  static Widget _buildOutlinedButton(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final text = parser.parseString('text') ?? 'Button';

    return OutlinedButton(
      onPressed: node.action != null
          ? () => renderer.actionHandler.handle(node.action!)
          : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: parser.parseColor('textColor'),
        padding: parser.parseEdgeInsets('padding'),
        side: BorderSide(
          color: parser.parseColor('borderColor') ?? Colors.grey,
          width: parser.parseDouble('borderWidth') ?? 1.0,
        ),
      ),
      child: Text(text),
    );
  }

  static Widget _buildImage(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final url = parser.parseString('url');
    final assetPath = parser.parseString('asset');

    if (url != null) {
      return Image.network(
        url,
        width: parser.parseDouble('width'),
        height: parser.parseDouble('height'),
        fit: parser.parseBoxFit('fit'),
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.broken_image, size: 50);
        },
      );
    } else if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: parser.parseDouble('width'),
        height: parser.parseDouble('height'),
        fit: parser.parseBoxFit('fit'),
      );
    }

    return Icon(Icons.image_not_supported);
  }

  static Widget _buildNetworkImage(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final url = parser.parseString('url') ?? '';

    return Image.network(
      url,
      width: parser.parseDouble('width'),
      height: parser.parseDouble('height'),
      fit: parser.parseBoxFit('fit'),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.broken_image, size: 50);
      },
    );
  }

  static Widget _buildIcon(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Icon(
      parser.parseIconData('icon') ?? Icons.help_outline,
      size: parser.parseDouble('size'),
      color: parser.parseColor('color'),
    );
  }

  static Widget _buildCard(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Card(
      color: parser.parseColor('backgroundColor'),
      elevation: parser.parseDouble('elevation') ?? 1.0,
      margin: parser.parseEdgeInsets('margin'),
      shape: RoundedRectangleBorder(
        borderRadius: parser.parseBorderRadius('borderRadius') ??
            BorderRadius.circular(4),
      ),
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  static Widget _buildListTile(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return ListTile(
      title: parser.parseString('title') != null
          ? Text(parser.parseString('title')!)
          : null,
      subtitle: parser.parseString('subtitle') != null
          ? Text(parser.parseString('subtitle')!)
          : null,
      leading: parser.parseIconData('leadingIcon') != null
          ? Icon(parser.parseIconData('leadingIcon'))
          : null,
      trailing: parser.parseIconData('trailingIcon') != null
          ? Icon(parser.parseIconData('trailingIcon'))
          : null,
      onTap: node.action != null
          ? () => renderer.actionHandler.handle(node.action!)
          : null,
    );
  }

  static Widget _buildListView(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return ListView(
      padding: parser.parseEdgeInsets('padding'),
      shrinkWrap: parser.parseBool('shrinkWrap') ?? false,
      physics: parser.parseBool('shrinkWrap') == true
          ? const NeverScrollableScrollPhysics()
          : null,
      children: renderer.buildChildren(node.children),
    );
  }

  static Widget _buildDivider(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Divider(
      height: parser.parseDouble('height'),
      thickness: parser.parseDouble('thickness'),
      color: parser.parseColor('color'),
      indent: parser.parseDouble('indent'),
      endIndent: parser.parseDouble('endIndent'),
    );
  }

  static Widget _buildSpacer(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Spacer(
      flex: parser.parseInt('flex') ?? 1,
    );
  }

  static Widget _buildCircularProgressIndicator(
    SDUINode node,
    SDUIRenderer renderer,
  ) {
    final parser = AttributeParser(node.attributes);

    return CircularProgressIndicator(
      value: parser.parseDouble('value'),
      backgroundColor: parser.parseColor('backgroundColor'),
      color: parser.parseColor('color'),
      strokeWidth: parser.parseDouble('strokeWidth') ?? 4.0,
    );
  }
}
```

### 4.3 커스텀 위젯 확장

```dart
// lib/core/sdui/registry/custom_builders.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/sdui_node.dart';
import '../renderer/sdui_renderer.dart';
import '../renderer/attribute_parser.dart';
import 'widget_registry.dart';

class CustomBuilders {
  static Map<String, SDUIWidgetBuilder> getBuilders() {
    return {
      'CachedNetworkImage': _buildCachedNetworkImage,
      'Hero': _buildHero,
      'AnimatedContainer': _buildAnimatedContainer,
      'ProductCard': _buildProductCard,
      'UserAvatar': _buildUserAvatar,
      'RatingBar': _buildRatingBar,
    };
  }

  static Widget _buildCachedNetworkImage(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final url = parser.parseString('url') ?? '';

    return CachedNetworkImage(
      imageUrl: url,
      width: parser.parseDouble('width'),
      height: parser.parseDouble('height'),
      fit: parser.parseBoxFit('fit'),
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    );
  }

  static Widget _buildHero(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final tag = parser.parseString('tag') ?? 'hero';

    return Hero(
      tag: tag,
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : const SizedBox.shrink(),
    );
  }

  static Widget _buildAnimatedContainer(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return AnimatedContainer(
      duration: Duration(
        milliseconds: parser.parseInt('duration') ?? 300,
      ),
      curve: Curves.easeInOut,
      width: parser.parseDouble('width'),
      height: parser.parseDouble('height'),
      padding: parser.parseEdgeInsets('padding'),
      decoration: BoxDecoration(
        color: parser.parseColor('backgroundColor'),
        borderRadius: parser.parseBorderRadius('borderRadius'),
      ),
      child: node.children.isNotEmpty
          ? renderer.buildNode(node.children[0])
          : null,
    );
  }

  // 도메인 특화 위젯 예시
  static Widget _buildProductCard(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: node.action != null
            ? () => renderer.actionHandler.handle(node.action!)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: parser.parseString('imageUrl') ?? '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제품명
                  Text(
                    parser.parseString('title') ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  // 가격
                  Text(
                    parser.parseString('price') ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (parser.parseString('originalPrice') != null) ...[
                    SizedBox(height: 2),
                    Text(
                      parser.parseString('originalPrice')!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildUserAvatar(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final imageUrl = parser.parseString('imageUrl');
    final name = parser.parseString('name') ?? 'U';
    final size = parser.parseDouble('size') ?? 40.0;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: parser.parseColor('backgroundColor') ?? Colors.blue,
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl)
          : null,
      child: imageUrl == null
          ? Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: size / 2,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  static Widget _buildRatingBar(SDUINode node, SDUIRenderer renderer) {
    final parser = AttributeParser(node.attributes);
    final rating = parser.parseDouble('rating') ?? 0.0;
    final maxRating = parser.parseInt('maxRating') ?? 5;
    final size = parser.parseDouble('size') ?? 20.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey, size: size);
        }
      }),
    );
  }
}
```

## 5. SDUI 렌더링 엔진

### 5.1 속성 파서

```dart
// lib/core/sdui/renderer/attribute_parser.dart
import 'package:flutter/material.dart';

class AttributeParser {
  final Map<String, dynamic> attributes;

  AttributeParser(this.attributes);

  // 기본 타입
  String? parseString(String key) {
    return attributes[key]?.toString();
  }

  int? parseInt(String key) {
    final value = attributes[key];
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  double? parseDouble(String key) {
    final value = attributes[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool? parseBool(String key) {
    final value = attributes[key];
    if (value == null) return null;
    if (value is bool) return value;
    return value.toString().toLowerCase() == 'true';
  }

  // 색상
  Color? parseColor(String key) {
    final value = parseString(key);
    if (value == null) return null;

    // #RRGGBB 또는 #AARRGGBB
    if (value.startsWith('#')) {
      final hexCode = value.substring(1);
      if (hexCode.length == 6) {
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (hexCode.length == 8) {
        return Color(int.parse(hexCode, radix: 16));
      }
    }

    // 이름으로 색상 찾기
    return _colorMap[value.toLowerCase()];
  }

  static final Map<String, Color> _colorMap = {
    'transparent': Colors.transparent,
    'black': Colors.black,
    'white': Colors.white,
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'yellow': Colors.yellow,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'grey': Colors.grey,
    'brown': Colors.brown,
  };

  // EdgeInsets
  EdgeInsets? parseEdgeInsets(String key) {
    final value = parseString(key);
    if (value == null) return null;

    final parts = value.split(',').map((e) => double.tryParse(e.trim())).toList();

    if (parts.length == 1 && parts[0] != null) {
      return EdgeInsets.all(parts[0]!);
    } else if (parts.length == 2 && parts.every((e) => e != null)) {
      return EdgeInsets.symmetric(
        vertical: parts[0]!,
        horizontal: parts[1]!,
      );
    } else if (parts.length == 4 && parts.every((e) => e != null)) {
      return EdgeInsets.fromLTRB(parts[0]!, parts[1]!, parts[2]!, parts[3]!);
    }

    return null;
  }

  // BorderRadius
  BorderRadius? parseBorderRadius(String key) {
    final value = attributes[key];
    if (value == null) return null;

    if (value is num) {
      return BorderRadius.circular(value.toDouble());
    }

    if (value is String) {
      final radius = double.tryParse(value);
      if (radius != null) {
        return BorderRadius.circular(radius);
      }
    }

    return null;
  }

  // Border
  Border? parseBorder(String key) {
    final value = attributes[key];
    if (value == null) return null;

    if (value is Map) {
      final color = AttributeParser(value).parseColor('color') ?? Colors.black;
      final width = AttributeParser(value).parseDouble('width') ?? 1.0;

      return Border.all(color: color, width: width);
    }

    return null;
  }

  // BoxShadow
  List<BoxShadow>? parseBoxShadow(String key) {
    final value = attributes[key];
    if (value == null) return null;

    if (value is List) {
      return value.map((item) {
        if (item is Map<String, dynamic>) {
          final parser = AttributeParser(item);
          return BoxShadow(
            color: parser.parseColor('color') ?? Colors.black26,
            offset: Offset(
              parser.parseDouble('offsetX') ?? 0,
              parser.parseDouble('offsetY') ?? 2,
            ),
            blurRadius: parser.parseDouble('blurRadius') ?? 4,
            spreadRadius: parser.parseDouble('spreadRadius') ?? 0,
          );
        }
        return BoxShadow();
      }).toList();
    }

    return null;
  }

  // Alignment
  Alignment? parseAlignment(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'topleft':
        return Alignment.topLeft;
      case 'topcenter':
        return Alignment.topCenter;
      case 'topright':
        return Alignment.topRight;
      case 'centerleft':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'centerright':
        return Alignment.centerRight;
      case 'bottomleft':
        return Alignment.bottomLeft;
      case 'bottomcenter':
        return Alignment.bottomCenter;
      case 'bottomright':
        return Alignment.bottomRight;
      default:
        return null;
    }
  }

  // MainAxisAlignment
  MainAxisAlignment? parseMainAxisAlignment(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spacebetween':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return null;
    }
  }

  // CrossAxisAlignment
  CrossAxisAlignment? parseCrossAxisAlignment(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return null;
    }
  }

  // MainAxisSize
  MainAxisSize? parseMainAxisSize(String key) {
    final value = parseString(key);
    if (value == null) return null;

    return value.toLowerCase() == 'min' ? MainAxisSize.min : MainAxisSize.max;
  }

  // StackFit
  StackFit? parseStackFit(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'loose':
        return StackFit.loose;
      case 'expand':
        return StackFit.expand;
      case 'passthrough':
        return StackFit.passthrough;
      default:
        return null;
    }
  }

  // FlexFit
  FlexFit? parseFlexFit(String key) {
    final value = parseString(key);
    if (value == null) return null;

    return value.toLowerCase() == 'tight' ? FlexFit.tight : FlexFit.loose;
  }

  // FontWeight
  FontWeight? parseFontWeight(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'thin':
      case '100':
        return FontWeight.w100;
      case 'extralight':
      case '200':
        return FontWeight.w200;
      case 'light':
      case '300':
        return FontWeight.w300;
      case 'normal':
      case 'regular':
      case '400':
        return FontWeight.w400;
      case 'medium':
      case '500':
        return FontWeight.w500;
      case 'semibold':
      case '600':
        return FontWeight.w600;
      case 'bold':
      case '700':
        return FontWeight.w700;
      case 'extrabold':
      case '800':
        return FontWeight.w800;
      case 'black':
      case '900':
        return FontWeight.w900;
      default:
        return null;
    }
  }

  // FontStyle
  FontStyle? parseFontStyle(String key) {
    final value = parseString(key);
    if (value == null) return null;

    return value.toLowerCase() == 'italic' ? FontStyle.italic : FontStyle.normal;
  }

  // TextDecoration
  TextDecoration? parseTextDecoration(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'none':
        return TextDecoration.none;
      case 'underline':
        return TextDecoration.underline;
      case 'overline':
        return TextDecoration.overline;
      case 'linethrough':
        return TextDecoration.lineThrough;
      default:
        return null;
    }
  }

  // TextAlign
  TextAlign? parseTextAlign(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        return null;
    }
  }

  // TextOverflow
  TextOverflow? parseTextOverflow(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'clip':
        return TextOverflow.clip;
      case 'fade':
        return TextOverflow.fade;
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'visible':
        return TextOverflow.visible;
      default:
        return null;
    }
  }

  // BoxFit
  BoxFit? parseBoxFit(String key) {
    final value = parseString(key);
    if (value == null) return null;

    switch (value.toLowerCase()) {
      case 'fill':
        return BoxFit.fill;
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fitwidth':
        return BoxFit.fitWidth;
      case 'fitheight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
        return BoxFit.scaleDown;
      default:
        return null;
    }
  }

  // IconData
  IconData? parseIconData(String key) {
    final value = parseString(key);
    if (value == null) return null;

    // Material Icons 매핑
    return _iconMap[value.toLowerCase()];
  }

  static final Map<String, IconData> _iconMap = {
    'home': Icons.home,
    'search': Icons.search,
    'settings': Icons.settings,
    'person': Icons.person,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'add': Icons.add,
    'remove': Icons.remove,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'close': Icons.close,
    'check': Icons.check,
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'arrow_up': Icons.arrow_upward,
    'arrow_down': Icons.arrow_downward,
    'menu': Icons.menu,
    'more_vert': Icons.more_vert,
    'more_horiz': Icons.more_horiz,
    'refresh': Icons.refresh,
    'info': Icons.info,
    'warning': Icons.warning,
    'error': Icons.error,
    'shopping_cart': Icons.shopping_cart,
    'email': Icons.email,
    'phone': Icons.phone,
    'location': Icons.location_on,
  };
}
```

### 5.2 SDUIRenderer 위젯

```dart
// lib/core/sdui/renderer/sdui_renderer.dart
import 'package:flutter/material.dart';
import '../models/sdui_node.dart';
import '../registry/widget_registry.dart';
import '../actions/action_handler.dart';

class SDUIRenderer extends StatelessWidget {
  final SDUINode node;
  final WidgetRegistry registry;
  final ActionHandler actionHandler;

  const SDUIRenderer({
    super.key,
    required this.node,
    required this.registry,
    required this.actionHandler,
  });

  @override
  Widget build(BuildContext context) {
    return buildNode(node);
  }

  Widget buildNode(SDUINode node) {
    try {
      return registry.build(node, this);
    } catch (e, stackTrace) {
      debugPrint('Error building node: ${node.type}');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');

      return ErrorWidgetPlaceholder(
        type: node.type,
        error: e.toString(),
        stackTrace: stackTrace,
      );
    }
  }

  List<Widget> buildChildren(List<SDUINode> children) {
    return children.map(buildNode).toList();
  }
}

// lib/core/sdui/renderer/error_widgets.dart
import 'package:flutter/material.dart';

class UnknownWidgetPlaceholder extends StatelessWidget {
  final String type;
  final String? nodeId;

  const UnknownWidgetPlaceholder({
    super.key,
    required this.type,
    this.nodeId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(
            'Unknown Widget Type',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type: $type',
            style: TextStyle(color: Colors.red.shade700),
          ),
          if (nodeId != null)
            Text(
              'ID: $nodeId',
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
    );
  }
}

class ErrorWidgetPlaceholder extends StatelessWidget {
  final String type;
  final String error;
  final StackTrace stackTrace;

  const ErrorWidgetPlaceholder({
    super.key,
    required this.type,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Widget Rendering Error',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Type: $type',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Error: $error',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

## 6. Action 시스템

### 6.1 Action 타입 정의

```dart
// lib/core/sdui/actions/action_types.dart
enum SDUIActionType {
  navigate,
  apiCall,
  share,
  analytics,
  dialog,
  bottomSheet,
  snackbar,
  url,
  deepLink,
  custom;

  static SDUIActionType fromString(String value) {
    return SDUIActionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SDUIActionType.custom,
    );
  }
}
```

### 6.2 ActionHandler 구현

```dart
// lib/core/sdui/actions/action_handler.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sdui_action.dart';
import 'action_types.dart';

class ActionHandler {
  final GoRouter router;
  final Dio dio;
  final Logger logger;

  ActionHandler({
    required this.router,
    required this.dio,
    required this.logger,
  });

  Future<void> handle(
    SDUIAction action, {
    BuildContext? context,
  }) async {
    final actionType = SDUIActionType.fromString(action.type);

    logger.d('Handling action: ${action.type}');

    try {
      switch (actionType) {
        case SDUIActionType.navigate:
          await _handleNavigate(action, context);
          break;
        case SDUIActionType.apiCall:
          await _handleApiCall(action, context);
          break;
        case SDUIActionType.share:
          await _handleShare(action);
          break;
        case SDUIActionType.analytics:
          await _handleAnalytics(action);
          break;
        case SDUIActionType.dialog:
          await _handleDialog(action, context);
          break;
        case SDUIActionType.bottomSheet:
          await _handleBottomSheet(action, context);
          break;
        case SDUIActionType.snackbar:
          await _handleSnackbar(action, context);
          break;
        case SDUIActionType.url:
          await _handleUrl(action);
          break;
        case SDUIActionType.deepLink:
          await _handleDeepLink(action);
          break;
        case SDUIActionType.custom:
          await _handleCustom(action, context);
          break;
      }

      // 성공 시 onSuccess 액션 실행
      if (action.onSuccess != null) {
        await handle(action.onSuccess!, context: context);
      }
    } catch (e, stackTrace) {
      logger.e('Error handling action: ${action.type}', error: e, stackTrace: stackTrace);

      // 실패 시 onError 액션 실행
      if (action.onError != null) {
        await handle(action.onError!, context: context);
      }
    }
  }

  Future<void> _handleNavigate(SDUIAction action, BuildContext? context) async {
    final url = action.url;
    if (url == null) {
      throw ArgumentError('Navigate action requires url');
    }

    // GoRouter로 네비게이션
    if (action.params != null && action.params!.isNotEmpty) {
      router.push(url, extra: action.params);
    } else {
      router.push(url);
    }
  }

  Future<void> _handleApiCall(SDUIAction action, BuildContext? context) async {
    final url = action.url;
    if (url == null) {
      throw ArgumentError('API call action requires url');
    }

    final method = action.method?.toUpperCase() ?? 'GET';

    Response response;
    switch (method) {
      case 'GET':
        response = await dio.get(
          url,
          queryParameters: action.params,
          options: Options(headers: action.headers),
        );
        break;
      case 'POST':
        response = await dio.post(
          url,
          data: action.params,
          options: Options(headers: action.headers),
        );
        break;
      case 'PUT':
        response = await dio.put(
          url,
          data: action.params,
          options: Options(headers: action.headers),
        );
        break;
      case 'DELETE':
        response = await dio.delete(
          url,
          data: action.params,
          options: Options(headers: action.headers),
        );
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    logger.d('API call successful: ${response.statusCode}');
  }

  Future<void> _handleShare(SDUIAction action) async {
    final text = action.params?['text'] as String?;
    if (text == null) {
      throw ArgumentError('Share action requires text parameter');
    }

    await Share.share(
      text,
      subject: action.params?['subject'] as String?,
    );
  }

  Future<void> _handleAnalytics(SDUIAction action) async {
    final eventName = action.analyticsEvent ?? action.params?['event'] as String?;
    if (eventName == null) {
      throw ArgumentError('Analytics action requires event name');
    }

    final params = action.analyticsParams ?? action.params ?? {};

    // Firebase Analytics 등 분석 도구 연동
    logger.i('Analytics event: $eventName, params: $params');
    // await FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: params,
    // );
  }

  Future<void> _handleDialog(SDUIAction action, BuildContext? context) async {
    if (context == null) {
      throw ArgumentError('Dialog action requires BuildContext');
    }

    final title = action.params?['title'] as String? ?? '알림';
    final message = action.params?['message'] as String? ?? '';
    final confirmText = action.params?['confirmText'] as String? ?? '확인';
    final cancelText = action.params?['cancelText'] as String?;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBottomSheet(SDUIAction action, BuildContext? context) async {
    if (context == null) {
      throw ArgumentError('Bottom sheet action requires BuildContext');
    }

    // Bottom sheet 구현 (스키마 기반 렌더링 필요 시 확장)
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Text(action.params?['content'] as String? ?? ''),
      ),
    );
  }

  Future<void> _handleSnackbar(SDUIAction action, BuildContext? context) async {
    if (context == null) {
      throw ArgumentError('Snackbar action requires BuildContext');
    }

    final message = action.params?['message'] as String? ?? '';
    final duration = Duration(
      seconds: action.params?['duration'] as int? ?? 3,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  Future<void> _handleUrl(SDUIAction action) async {
    final urlString = action.url;
    if (urlString == null) {
      throw ArgumentError('URL action requires url');
    }

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch $urlString');
    }
  }

  Future<void> _handleDeepLink(SDUIAction action) async {
    final urlString = action.url;
    if (urlString == null) {
      throw ArgumentError('Deep link action requires url');
    }

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
    } else {
      throw Exception('Could not launch deep link: $urlString');
    }
  }

  Future<void> _handleCustom(SDUIAction action, BuildContext? context) async {
    // 커스텀 액션 처리 (앱별로 확장)
    logger.w('Custom action not implemented: ${action.type}');
  }
}
```

## 7. 서버 API 연동

### 7.1 Schema API 서비스

```dart
// lib/features/schema/data/datasources/schema_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../../core/sdui/models/sdui_response.dart';

part 'schema_remote_datasource.g.dart';

@RestApi()
abstract class SchemaRemoteDataSource {
  factory SchemaRemoteDataSource(Dio dio, {String baseUrl}) =
      _SchemaRemoteDataSource;

  @GET('/schemas/{screen}')
  Future<SDUIResponse> fetchSchema(
    @Path('screen') String screen, {
    @Query('version') String? version,
    @Query('userId') String? userId,
    @Query('abVariant') String? abVariant,
  });

  @GET('/schemas/{screen}/version/{version}')
  Future<SDUIResponse> fetchSchemaVersion(
    @Path('screen') String screen,
    @Path('version') String version,
  );
}
```

### 7.2 SchemaBloc

```dart
// lib/features/schema/presentation/bloc/schema_event.dart
import 'package:equatable/equatable.dart';

abstract class SchemaEvent extends Equatable {
  const SchemaEvent();

  @override
  List<Object?> get props => [];
}

class SchemaFetched extends SchemaEvent {
  final String screen;
  final bool forceRefresh;
  final Map<String, String>? params;

  const SchemaFetched({
    required this.screen,
    this.forceRefresh = false,
    this.params,
  });

  @override
  List<Object?> get props => [screen, forceRefresh, params];
}

class SchemaRefreshed extends SchemaEvent {
  final String screen;

  const SchemaRefreshed(this.screen);

  @override
  List<Object?> get props => [screen];
}

// lib/features/schema/presentation/bloc/schema_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/sdui/models/sdui_response.dart';
import '../../../../core/error/failures.dart';

abstract class SchemaState extends Equatable {
  const SchemaState();

  @override
  List<Object?> get props => [];
}

class SchemaInitial extends SchemaState {}

class SchemaLoading extends SchemaState {
  final String screen;

  const SchemaLoading(this.screen);

  @override
  List<Object?> get props => [screen];
}

class SchemaLoaded extends SchemaState {
  final SDUIResponse response;
  final bool isFromCache;

  const SchemaLoaded({
    required this.response,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [response, isFromCache];
}

class SchemaError extends SchemaState {
  final Failure failure;
  final SDUIResponse? fallbackSchema;

  const SchemaError({
    required this.failure,
    this.fallbackSchema,
  });

  @override
  List<Object?> get props => [failure, fallbackSchema];
}

// lib/features/schema/presentation/bloc/schema_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import '../../domain/repositories/schema_repository.dart';
import 'schema_event.dart';
import 'schema_state.dart';

class SchemaBloc extends Bloc<SchemaEvent, SchemaState> {
  final SchemaRepository repository;

  SchemaBloc({required this.repository}) : super(SchemaInitial()) {
    on<SchemaFetched>(_onSchemaFetched);
    on<SchemaRefreshed>(_onSchemaRefreshed);
  }

  Future<void> _onSchemaFetched(
    SchemaFetched event,
    Emitter<SchemaState> emit,
  ) async {
    emit(SchemaLoading(event.screen));

    final result = await repository.fetchSchema(
      screen: event.screen,
      forceRefresh: event.forceRefresh,
      params: event.params,
    );

    result.fold(
      (failure) {
        // 폴백 스키마 시도
        repository.getFallbackSchema(event.screen).fold(
          (fallbackFailure) => emit(SchemaError(failure: failure)),
          (fallbackSchema) => emit(SchemaError(
            failure: failure,
            fallbackSchema: fallbackSchema,
          )),
        );
      },
      (response) => emit(SchemaLoaded(response: response)),
    );
  }

  Future<void> _onSchemaRefreshed(
    SchemaRefreshed event,
    Emitter<SchemaState> emit,
  ) async {
    // 현재 상태 유지하면서 백그라운드 새로고침
    final result = await repository.fetchSchema(
      screen: event.screen,
      forceRefresh: true,
    );

    result.fold(
      (failure) {
        // 새로고침 실패는 무시 (현재 캐시 유지)
      },
      (response) => emit(SchemaLoaded(response: response)),
    );
  }
}
```

### 7.3 SchemaRepository

```dart
// lib/features/schema/domain/repositories/schema_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sdui/models/sdui_response.dart';

abstract class SchemaRepository {
  Future<Either<Failure, SDUIResponse>> fetchSchema({
    required String screen,
    bool forceRefresh = false,
    Map<String, String>? params,
  });

  Either<Failure, SDUIResponse> getFallbackSchema(String screen);

  Future<void> clearCache(String screen);

  Future<void> clearAllCache();
}

// lib/features/schema/data/repositories/schema_repository_impl.dart
import 'package:fpdart/fpdart.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/sdui/models/sdui_response.dart';
import '../../../../core/sdui/cache/schema_cache.dart';
import '../../domain/repositories/schema_repository.dart';
import '../datasources/schema_remote_datasource.dart';
import '../datasources/schema_asset_datasource.dart';

class SchemaRepositoryImpl implements SchemaRepository {
  final SchemaRemoteDataSource remoteDataSource;
  final SchemaAssetDataSource assetDataSource;
  final SchemaCache cache;

  SchemaRepositoryImpl({
    required this.remoteDataSource,
    required this.assetDataSource,
    required this.cache,
  });

  @override
  Future<Either<Failure, SDUIResponse>> fetchSchema({
    required String screen,
    bool forceRefresh = false,
    Map<String, String>? params,
  }) async {
    // 1. 캐시 확인 (forceRefresh가 아닌 경우)
    if (!forceRefresh) {
      final cachedSchema = await cache.get(screen);
      if (cachedSchema != null) {
        return Right(cachedSchema);
      }
    }

    // 2. 네트워크에서 가져오기
    try {
      final response = await remoteDataSource.fetchSchema(
        screen,
        userId: params?['userId'],
        abVariant: params?['abVariant'],
      );

      // 3. 캐시에 저장
      await cache.set(screen, response);

      return Right(response);
    } on DioException catch (e) {
      // 4. 네트워크 실패 시 캐시 재시도 (stale data 허용)
      final staleCache = await cache.get(screen, allowStale: true);
      if (staleCache != null) {
        return Right(staleCache);
      }

      // 5. 모든 시도 실패
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Either<Failure, SDUIResponse> getFallbackSchema(String screen) {
    try {
      final fallbackSchema = assetDataSource.loadFallbackSchema(screen);
      return Right(fallbackSchema);
    } catch (e) {
      return Left(CacheFailure(message: 'No fallback schema available'));
    }
  }

  @override
  Future<void> clearCache(String screen) async {
    await cache.remove(screen);
  }

  @override
  Future<void> clearAllCache() async {
    await cache.clear();
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return ServerFailure(message: 'Schema not found');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerFailure(message: 'Server error: $statusCode');
        }
        return ServerFailure(message: 'Bad response: $statusCode');
      default:
        return ServerFailure(message: error.message ?? 'Unknown error');
    }
  }
}

// lib/features/schema/data/datasources/schema_asset_datasource.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/sdui/models/sdui_response.dart';

class SchemaAssetDataSource {
  Future<SDUIResponse> loadFallbackSchema(String screen) async {
    final jsonString = await rootBundle.loadString(
      'assets/schemas/${screen}_fallback.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return SDUIResponse.fromJson(json);
  }
}
```

## 8. 캐싱 전략

### 8.1 3-Tier 캐싱 아키텍처

```
┌─────────────────────────────────────────┐
│         Schema Request Flow             │
└─────────────────────────────────────────┘
            │
            ▼
    ┌──────────────┐
    │  Tier 1:     │  ← 가장 빠름 (메모리)
    │ Memory Cache │    TTL: 5분
    └──────────────┘
            │ Cache Miss
            ▼
    ┌──────────────┐
    │  Tier 2:     │  ← 빠름 (디스크)
    │  Disk Cache  │    TTL: 24시간
    │   (Hive)     │
    └──────────────┘
            │ Cache Miss
            ▼
    ┌──────────────┐
    │  Tier 3:     │  ← 느림 (네트워크)
    │ Remote API   │    Always fresh
    └──────────────┘
            │ Network Fail
            ▼
    ┌──────────────┐
    │ Fallback:    │  ← 최후 수단 (번들 에셋)
    │ Asset Bundle │    항상 사용 가능
    └──────────────┘
```

### 8.2 SchemaCache 구현

```dart
// lib/core/sdui/cache/schema_cache.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sdui_response.dart';
import 'memory_cache.dart';

class SchemaCache {
  static const String _boxName = 'schema_cache';
  static const Duration _defaultTtl = Duration(hours: 24);

  late final Box<Map<dynamic, dynamic>> _box;
  final MemoryCache<SDUIResponse> _memoryCache;

  SchemaCache() : _memoryCache = MemoryCache(maxSize: 20);

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  Future<SDUIResponse?> get(
    String screen, {
    bool allowStale = false,
  }) async {
    // Tier 1: 메모리 캐시
    final memoryResult = _memoryCache.get(screen);
    if (memoryResult != null) {
      if (allowStale || !_isExpired(memoryResult.timestamp, Duration(minutes: 5))) {
        return memoryResult;
      }
    }

    // Tier 2: 디스크 캐시
    final diskData = _box.get(screen);
    if (diskData != null) {
      try {
        final response = SDUIResponse.fromJson(
          Map<String, dynamic>.from(diskData),
        );

        if (allowStale || !_isExpired(response.timestamp, _defaultTtl)) {
          // 메모리 캐시에 프로모션
          _memoryCache.set(screen, response);
          return response;
        } else {
          // 만료된 경우 삭제
          await remove(screen);
        }
      } catch (e) {
        // 손상된 데이터 삭제
        await remove(screen);
      }
    }

    return null;
  }

  Future<void> set(String screen, SDUIResponse response) async {
    // Tier 1: 메모리 캐시
    _memoryCache.set(screen, response);

    // Tier 2: 디스크 캐시
    await _box.put(screen, response.toJson());
  }

  Future<void> remove(String screen) async {
    _memoryCache.remove(screen);
    await _box.delete(screen);
  }

  Future<void> clear() async {
    _memoryCache.clear();
    await _box.clear();
  }

  bool _isExpired(DateTime timestamp, Duration ttl) {
    final now = DateTime.now();
    return now.difference(timestamp) > ttl;
  }

  // 프리페칭
  Future<void> prefetch(List<String> screens) async {
    // 백그라운드에서 여러 스키마를 미리 로드
    for (final screen in screens) {
      final cached = await get(screen);
      if (cached == null) {
        // 네트워크 요청 (repository를 통해)
        // 이 부분은 repository에서 처리하도록 위임
      }
    }
  }
}

// lib/core/sdui/cache/memory_cache.dart
class MemoryCache<T> {
  final int maxSize;
  final Map<String, _CacheEntry<T>> _cache = {};

  MemoryCache({this.maxSize = 50});

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // LRU: 접근 시간 업데이트
    entry.lastAccessed = DateTime.now();
    return entry.value;
  }

  void set(String key, T value) {
    // 크기 제한 확인
    if (_cache.length >= maxSize && !_cache.containsKey(key)) {
      _evictLRU();
    }

    _cache[key] = _CacheEntry(
      value: value,
      lastAccessed: DateTime.now(),
    );
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
  }

  void _evictLRU() {
    if (_cache.isEmpty) return;

    // 가장 오래 접근되지 않은 항목 제거
    final oldestKey = _cache.entries
        .reduce((a, b) =>
            a.value.lastAccessed.isBefore(b.value.lastAccessed) ? a : b)
        .key;

    _cache.remove(oldestKey);
  }
}

class _CacheEntry<T> {
  final T value;
  DateTime lastAccessed;

  _CacheEntry({
    required this.value,
    required this.lastAccessed,
  });
}
```

## 9. A/B 테스트 & Feature Flag

### 9.1 서버 사이드 배리언트

```dart
// 서버 응답 예시
// GET /schemas/home?userId=user123&abVariant=variant_b
{
  "version": "1.0",
  "screen": "home",
  "variant": "variant_b",
  "experiment": "home_layout_test",
  "timestamp": "2026-02-07T10:00:00Z",
  "node": {
    "type": "Column",
    "children": [
      {
        "type": "Text",
        "id": "hero_text_variant_b",
        "attributes": {
          "text": "새로운 디자인을 경험해보세요! 🎨",
          "fontSize": 28,
          "fontWeight": "bold"
        }
      }
      // ... variant B 전용 레이아웃
    ]
  }
}
```

### 9.2 Firebase Remote Config 연동

```dart
// lib/core/sdui/experiments/ab_test_manager.dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logger/logger.dart';

class ABTestManager {
  final FirebaseRemoteConfig remoteConfig;
  final Logger logger;

  ABTestManager({
    required this.remoteConfig,
    required this.logger,
  });

  Future<void> init() async {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await remoteConfig.setDefaults({
      'home_layout_variant': 'control',
      'product_card_style': 'default',
      'checkout_flow_version': 'v1',
    });

    await remoteConfig.fetchAndActivate();
  }

  String getVariant(String experimentKey) {
    final variant = remoteConfig.getString(experimentKey);
    logger.d('Experiment: $experimentKey, Variant: $variant');
    return variant;
  }

  bool isFeatureEnabled(String featureKey) {
    return remoteConfig.getBool(featureKey);
  }

  Map<String, String> getAllExperiments() {
    return {
      'home_layout_variant': getVariant('home_layout_variant'),
      'product_card_style': getVariant('product_card_style'),
      'checkout_flow_version': getVariant('checkout_flow_version'),
    };
  }
}
```

### 9.3 실험 추적

```dart
// lib/core/sdui/experiments/experiment_tracker.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class ExperimentTracker {
  final FirebaseAnalytics analytics;

  ExperimentTracker({required this.analytics});

  Future<void> trackExperimentExposure({
    required String experimentName,
    required String variant,
    Map<String, dynamic>? additionalParams,
  }) async {
    await analytics.logEvent(
      name: 'experiment_exposure',
      parameters: {
        'experiment_name': experimentName,
        'variant': variant,
        ...?additionalParams,
      },
    );
  }

  Future<void> trackConversion({
    required String experimentName,
    required String variant,
    required String conversionEvent,
    Map<String, dynamic>? additionalParams,
  }) async {
    await analytics.logEvent(
      name: 'experiment_conversion',
      parameters: {
        'experiment_name': experimentName,
        'variant': variant,
        'conversion_event': conversionEvent,
        ...?additionalParams,
      },
    );
  }
}
```

## 10. 성능 최적화

### 10.1 스키마 압축

```dart
// 서버에서 gzip 압축된 스키마 전송
// Response Header: Content-Encoding: gzip

// Dio에서 자동 압축 해제 설정
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://api.example.com',
    headers: {
      'Accept-Encoding': 'gzip',
    },
  ),
);
```

### 10.2 지연 로딩 & 페이지네이션

```json
{
  "type": "ListView",
  "id": "product_list",
  "attributes": {
    "pagination": {
      "enabled": true,
      "pageSize": 20,
      "loadMoreUrl": "/api/products?page={page}"
    }
  },
  "children": []
}
```

```dart
// lib/core/sdui/widgets/lazy_list_builder.dart
import 'package:flutter/material.dart';
import '../models/sdui_node.dart';
import '../renderer/sdui_renderer.dart';

class LazyListBuilder extends StatefulWidget {
  final SDUINode node;
  final SDUIRenderer renderer;

  const LazyListBuilder({
    super.key,
    required this.node,
    required this.renderer,
  });

  @override
  State<LazyListBuilder> createState() => _LazyListBuilderState();
}

class _LazyListBuilderState extends State<LazyListBuilder> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  List<SDUINode> _items = [];
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _items = widget.node.children;
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    // API 호출로 다음 페이지 로드
    // final newItems = await fetchNextPage(_currentPage + 1);

    setState(() {
      // _items.addAll(newItems);
      _currentPage++;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return widget.renderer.buildNode(_items[index]);
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

### 10.3 Skeleton 로더

```dart
// lib/core/sdui/widgets/skeleton_loader.dart
import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 11. 보안

### 11.1 스키마 검증

```dart
// lib/core/sdui/validation/schema_validator.dart
import '../models/sdui_response.dart';
import '../models/sdui_node.dart';

class SchemaValidator {
  static const int _maxDepth = 50;
  static const int _maxChildren = 1000;

  ValidationResult validate(SDUIResponse response) {
    final errors = <String>[];

    // 버전 체크
    if (!_isValidVersion(response.version)) {
      errors.add('Invalid schema version: ${response.version}');
    }

    // 노드 검증
    final nodeErrors = _validateNode(response.node, depth: 0);
    errors.addAll(nodeErrors);

    if (errors.isEmpty) {
      return ValidationResult.success();
    } else {
      return ValidationResult.failure(errors);
    }
  }

  bool _isValidVersion(String version) {
    final versionPattern = RegExp(r'^\d+\.\d+$');
    return versionPattern.hasMatch(version);
  }

  List<String> _validateNode(SDUINode node, {required int depth}) {
    final errors = <String>[];

    // 깊이 제한
    if (depth > _maxDepth) {
      errors.add('Maximum depth exceeded at node: ${node.id ?? node.type}');
      return errors;
    }

    // 자식 수 제한
    if (node.children.length > _maxChildren) {
      errors.add(
          'Too many children (${node.children.length}) at node: ${node.id ?? node.type}');
    }

    // Action URL 화이트리스트 체크
    if (node.action != null) {
      final actionErrors = _validateAction(node.action!);
      errors.addAll(actionErrors);
    }

    // 재귀적으로 자식 노드 검증
    for (final child in node.children) {
      final childErrors = _validateNode(child, depth: depth + 1);
      errors.addAll(childErrors);
    }

    return errors;
  }

  List<String> _validateAction(SDUIAction action) {
    final errors = <String>[];

    if (action.url != null && !_isAllowedUrl(action.url!)) {
      errors.add('Disallowed URL in action: ${action.url}');
    }

    return errors;
  }

  bool _isAllowedUrl(String url) {
    // URL 화이트리스트 체크
    final allowedDomains = [
      'api.example.com',
      'cdn.example.com',
      // 앱 내부 라우트
    ];

    if (url.startsWith('/')) {
      // 상대 경로는 허용
      return true;
    }

    try {
      final uri = Uri.parse(url);
      return allowedDomains.any((domain) => uri.host == domain);
    } catch (e) {
      return false;
    }
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult.success()
      : isValid = true,
        errors = [];

  ValidationResult.failure(this.errors) : isValid = false;
}
```

### 11.2 XSS 방지

```dart
// lib/core/sdui/security/sanitizer.dart
class Sanitizer {
  static String sanitizeText(String text) {
    // HTML 태그 제거
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  static String? sanitizeUrl(String url) {
    // javascript: 프로토콜 차단
    if (url.toLowerCase().startsWith('javascript:')) {
      return null;
    }

    // data: URL 차단 (이미지 제외)
    if (url.toLowerCase().startsWith('data:') &&
        !url.toLowerCase().startsWith('data:image/')) {
      return null;
    }

    return url;
  }
}
```

## 12. 테스트

### 12.1 WidgetRegistry 테스트

```dart
// test/core/sdui/registry/widget_registry_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sdui_app/core/sdui/models/sdui_node.dart';
import 'package:flutter_sdui_app/core/sdui/registry/widget_registry.dart';
import 'package:flutter_sdui_app/core/sdui/renderer/sdui_renderer.dart';
import 'package:mocktail/mocktail.dart';

class MockSDUIRenderer extends Mock implements SDUIRenderer {}

void main() {
  group('WidgetRegistry', () {
    late WidgetRegistry registry;
    late MockSDUIRenderer mockRenderer;

    setUp(() {
      registry = WidgetRegistry();
      mockRenderer = MockSDUIRenderer();
    });

    test('register and build widget', () {
      // Arrange
      final node = SDUINode(type: 'CustomWidget');
      registry.register('CustomWidget', (node, renderer) {
        return Container(key: Key('custom'));
      });

      // Act
      final widget = registry.build(node, mockRenderer);

      // Assert
      expect(widget, isA<Container>());
      expect((widget as Container).key, equals(Key('custom')));
    });

    test('returns UnknownWidgetPlaceholder for unregistered type', () {
      // Arrange
      final node = SDUINode(type: 'UnknownType');

      // Act
      final widget = registry.build(node, mockRenderer);

      // Assert
      expect(widget, isA<UnknownWidgetPlaceholder>());
    });

    test('isRegistered returns correct status', () {
      // Arrange
      registry.register('RegisteredType', (node, renderer) => Container());

      // Assert
      expect(registry.isRegistered('RegisteredType'), isTrue);
      expect(registry.isRegistered('UnregisteredType'), isFalse);
    });
  });
}
```

### 12.2 SDUIRenderer 테스트

```dart
// test/core/sdui/renderer/sdui_renderer_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sdui_app/core/sdui/models/sdui_node.dart';
import 'package:flutter_sdui_app/core/sdui/registry/widget_registry.dart';
import 'package:flutter_sdui_app/core/sdui/renderer/sdui_renderer.dart';
import 'package:flutter_sdui_app/core/sdui/actions/action_handler.dart';
import 'package:mocktail/mocktail.dart';

class MockActionHandler extends Mock implements ActionHandler {}

void main() {
  group('SDUIRenderer', () {
    late WidgetRegistry registry;
    late MockActionHandler mockActionHandler;

    setUp(() {
      registry = WidgetRegistry();
      mockActionHandler = MockActionHandler();

      // 기본 빌더 등록
      registry.register('Container', (node, renderer) => Container());
      registry.register('Text', (node, renderer) {
        final text = node.attributes['text'] as String? ?? '';
        return Text(text);
      });
      registry.register('Column', (node, renderer) {
        return Column(
          children: renderer.buildChildren(node.children),
        );
      });
    });

    testWidgets('renders simple node', (tester) async {
      // Arrange
      final node = SDUINode(
        type: 'Text',
        attributes: {'text': 'Hello World'},
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SDUIRenderer(
            node: node,
            registry: registry,
            actionHandler: mockActionHandler,
          ),
        ),
      );

      // Assert
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders nested nodes', (tester) async {
      // Arrange
      final node = SDUINode(
        type: 'Column',
        children: [
          SDUINode(
            type: 'Text',
            attributes: {'text': 'First'},
          ),
          SDUINode(
            type: 'Text',
            attributes: {'text': 'Second'},
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: SDUIRenderer(
            node: node,
            registry: registry,
            actionHandler: mockActionHandler,
          ),
        ),
      );

      // Assert
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
  });
}
```

### 12.3 SchemaBloc 테스트

```dart
// test/features/schema/presentation/bloc/schema_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_sdui_app/core/error/failures.dart';
import 'package:flutter_sdui_app/core/sdui/models/sdui_response.dart';
import 'package:flutter_sdui_app/core/sdui/models/sdui_node.dart';
import 'package:flutter_sdui_app/features/schema/domain/repositories/schema_repository.dart';
import 'package:flutter_sdui_app/features/schema/presentation/bloc/schema_bloc.dart';

class MockSchemaRepository extends Mock implements SchemaRepository {}

void main() {
  late MockSchemaRepository mockRepository;

  setUp(() {
    mockRepository = MockSchemaRepository();
  });

  group('SchemaBloc', () {
    final tResponse = SDUIResponse(
      version: '1.0',
      screen: 'home',
      timestamp: DateTime(2026, 2, 7),
      node: SDUINode(type: 'Container'),
    );

    blocTest<SchemaBloc, SchemaState>(
      'emits [SchemaLoading, SchemaLoaded] when fetch succeeds',
      build: () {
        when(() => mockRepository.fetchSchema(
              screen: any(named: 'screen'),
              forceRefresh: any(named: 'forceRefresh'),
              params: any(named: 'params'),
            )).thenAnswer((_) async => Right(tResponse));
        return SchemaBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(SchemaFetched(screen: 'home')),
      expect: () => [
        SchemaLoading('home'),
        SchemaLoaded(response: tResponse),
      ],
      verify: (_) {
        verify(() => mockRepository.fetchSchema(
              screen: 'home',
              forceRefresh: false,
              params: null,
            )).called(1);
      },
    );

    blocTest<SchemaBloc, SchemaState>(
      'emits [SchemaLoading, SchemaError] when fetch fails without fallback',
      build: () {
        when(() => mockRepository.fetchSchema(
              screen: any(named: 'screen'),
              forceRefresh: any(named: 'forceRefresh'),
              params: any(named: 'params'),
            )).thenAnswer((_) async => Left(NetworkFailure()));

        when(() => mockRepository.getFallbackSchema(any()))
            .thenReturn(Left(CacheFailure()));

        return SchemaBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(SchemaFetched(screen: 'home')),
      expect: () => [
        SchemaLoading('home'),
        isA<SchemaError>()
            .having((s) => s.failure, 'failure', isA<NetworkFailure>())
            .having((s) => s.fallbackSchema, 'fallbackSchema', isNull),
      ],
    );
  });
}
```

## 13. 실전 예제: 동적 홈 화면

### 13.1 서버 스키마 (JSON)

```json
{
  "version": "1.0",
  "screen": "home",
  "timestamp": "2026-02-07T10:00:00Z",
  "cacheTtl": 3600,
  "node": {
    "type": "Scaffold",
    "attributes": {
      "backgroundColor": "#F5F5F5",
      "appBar": {
        "title": "홈",
        "centerTitle": false,
        "backgroundColor": "#FFFFFF"
      }
    },
    "children": [
      {
        "type": "SingleChildScrollView",
        "children": [
          {
            "type": "Column",
            "attributes": {
              "crossAxisAlignment": "stretch"
            },
            "children": [
              {
                "type": "Container",
                "id": "hero_banner",
                "attributes": {
                  "height": 200,
                  "margin": "16,16,16,8",
                  "borderRadius": 12
                },
                "children": [
                  {
                    "type": "CachedNetworkImage",
                    "attributes": {
                      "url": "https://cdn.example.com/banners/spring_sale.jpg",
                      "fit": "cover"
                    }
                  }
                ],
                "action": {
                  "type": "navigate",
                  "url": "/promotion/spring-sale",
                  "analyticsEvent": "banner_clicked",
                  "analyticsParams": {
                    "banner_id": "spring_sale_2026"
                  }
                }
              },
              {
                "type": "Padding",
                "attributes": {
                  "padding": "16,16,16,8"
                },
                "children": [
                  {
                    "type": "Text",
                    "attributes": {
                      "text": "추천 상품",
                      "fontSize": 20,
                      "fontWeight": "bold"
                    }
                  }
                ]
              },
              {
                "type": "SizedBox",
                "attributes": {
                  "height": 250
                },
                "children": [
                  {
                    "type": "ListView",
                    "attributes": {
                      "scrollDirection": "horizontal",
                      "padding": "16,0,16,0"
                    },
                    "children": [
                      {
                        "type": "ProductCard",
                        "id": "product_1",
                        "attributes": {
                          "imageUrl": "https://cdn.example.com/products/laptop.jpg",
                          "title": "고성능 노트북",
                          "price": "1,299,000원",
                          "originalPrice": "1,499,000원"
                        },
                        "action": {
                          "type": "navigate",
                          "url": "/products/laptop-pro-2026"
                        }
                      },
                      {
                        "type": "ProductCard",
                        "id": "product_2",
                        "attributes": {
                          "imageUrl": "https://cdn.example.com/products/phone.jpg",
                          "title": "스마트폰",
                          "price": "899,000원"
                        },
                        "action": {
                          "type": "navigate",
                          "url": "/products/smartphone-x"
                        }
                      }
                    ]
                  }
                ]
              },
              {
                "type": "Padding",
                "attributes": {
                  "padding": "16,16,16,8"
                },
                "children": [
                  {
                    "type": "Text",
                    "attributes": {
                      "text": "카테고리",
                      "fontSize": 20,
                      "fontWeight": "bold"
                    }
                  }
                ]
              },
              {
                "type": "GridView",
                "attributes": {
                  "crossAxisCount": 2,
                  "padding": "16,0,16,16",
                  "crossAxisSpacing": 12,
                  "mainAxisSpacing": 12
                },
                "children": [
                  {
                    "type": "Card",
                    "attributes": {
                      "elevation": 2
                    },
                    "children": [
                      {
                        "type": "InkWell",
                        "children": [
                          {
                            "type": "Column",
                            "attributes": {
                              "mainAxisAlignment": "center",
                              "padding": "16,16,16,16"
                            },
                            "children": [
                              {
                                "type": "Icon",
                                "attributes": {
                                  "icon": "shopping_cart",
                                  "size": 48,
                                  "color": "#2196F3"
                                }
                              },
                              {
                                "type": "SizedBox",
                                "attributes": {
                                  "height": 12
                                }
                              },
                              {
                                "type": "Text",
                                "attributes": {
                                  "text": "전자기기",
                                  "fontSize": 16,
                                  "fontWeight": "600"
                                }
                              }
                            ]
                          }
                        ],
                        "action": {
                          "type": "navigate",
                          "url": "/categories/electronics"
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### 13.2 Flutter 화면 구현

```dart
// lib/features/schema/presentation/pages/sdui_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/sdui/registry/widget_registry.dart';
import '../../../../core/sdui/renderer/sdui_renderer.dart';
import '../../../../core/sdui/actions/action_handler.dart';
import '../bloc/schema_bloc.dart';

class SDUIPage extends StatelessWidget {
  final String screen;

  const SDUIPage({
    super.key,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.I<SchemaBloc>()
        ..add(SchemaFetched(screen: screen)),
      child: SDUIPageContent(screen: screen),
    );
  }
}

class SDUIPageContent extends StatelessWidget {
  final String screen;

  const SDUIPageContent({
    super.key,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SchemaBloc, SchemaState>(
      builder: (context, state) {
        if (state is SchemaLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('로딩 중...')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('화면을 불러오는 중...'),
                ],
              ),
            ),
          );
        }

        if (state is SchemaLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<SchemaBloc>().add(SchemaRefreshed(screen));
              await Future.delayed(Duration(seconds: 1));
            },
            child: SDUIRenderer(
              node: state.response.node,
              registry: GetIt.I<WidgetRegistry>(),
              actionHandler: GetIt.I<ActionHandler>(),
            ),
          );
        }

        if (state is SchemaError) {
          if (state.fallbackSchema != null) {
            // 폴백 스키마로 렌더링
            return SDUIRenderer(
              node: state.fallbackSchema!.node,
              registry: GetIt.I<WidgetRegistry>(),
              actionHandler: GetIt.I<ActionHandler>(),
            );
          }

          return Scaffold(
            appBar: AppBar(title: Text('오류 발생')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    '화면을 불러올 수 없습니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.failure.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SchemaBloc>().add(
                            SchemaFetched(screen: screen, forceRefresh: true),
                          );
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox.shrink();
      },
    );
  }
}
```

### 13.3 의존성 주입 설정

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../sdui/registry/widget_registry.dart';
import '../sdui/registry/default_builders.dart';
import '../sdui/registry/custom_builders.dart';
import '../sdui/actions/action_handler.dart';
import '../sdui/cache/schema_cache.dart';
import '../../features/schema/data/datasources/schema_remote_datasource.dart';
import '../../features/schema/data/datasources/schema_asset_datasource.dart';
import '../../features/schema/data/repositories/schema_repository_impl.dart';
import '../../features/schema/domain/repositories/schema_repository.dart';
import '../../features/schema/presentation/bloc/schema_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // Logger
  getIt.registerSingleton<Logger>(Logger());

  // Dio
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );
  getIt.registerSingleton<Dio>(dio);

  // GoRouter (앱에서 제공)
  // getIt.registerSingleton<GoRouter>(router);

  // Schema Cache
  final schemaCache = SchemaCache();
  await schemaCache.init();
  getIt.registerSingleton<SchemaCache>(schemaCache);

  // Data Sources
  getIt.registerLazySingleton<SchemaRemoteDataSource>(
    () => SchemaRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<SchemaAssetDataSource>(
    () => SchemaAssetDataSource(),
  );

  // Repository
  getIt.registerLazySingleton<SchemaRepository>(
    () => SchemaRepositoryImpl(
      remoteDataSource: getIt<SchemaRemoteDataSource>(),
      assetDataSource: getIt<SchemaAssetDataSource>(),
      cache: getIt<SchemaCache>(),
    ),
  );

  // Bloc
  getIt.registerFactory<SchemaBloc>(
    () => SchemaBloc(repository: getIt<SchemaRepository>()),
  );

  // Widget Registry
  final widgetRegistry = WidgetRegistry();
  widgetRegistry.registerAll(DefaultBuilders.getBuilders());
  widgetRegistry.registerAll(CustomBuilders.getBuilders());
  getIt.registerSingleton<WidgetRegistry>(widgetRegistry);

  // Action Handler
  getIt.registerLazySingleton<ActionHandler>(
    () => ActionHandler(
      router: getIt<GoRouter>(),
      dio: getIt<Dio>(),
      logger: getIt<Logger>(),
    ),
  );
}
```

## 14. Best Practices

### 14.1 스키마 설계 원칙

| 원칙 | 설명 | 예시 |
|------|------|------|
| **최소 깊이** | 트리 깊이를 5레벨 이하로 유지 | `Scaffold → Column → Card → ListTile` (4레벨) |
| **ID 부여** | A/B 테스트 대상 노드에 고유 ID | `"id": "cta_button_v2"` |
| **속성 검증** | 필수 속성 명시 (타입 안전성) | `"text": "Required"` |
| **폴백 제공** | 모든 화면에 번들 폴백 준비 | `assets/schemas/home_fallback.json` |
| **버전 명시** | 스키마 버전 항상 포함 | `"version": "1.0"` |

### 14.2 성능 가이드라인

1. **캐싱 우선**: TTL 기반 캐싱으로 네트워크 요청 최소화
2. **지연 로딩**: 큰 리스트는 페이지네이션 적용
3. **이미지 최적화**: CDN + 이미지 압축 + 캐싱
4. **스키마 압축**: gzip으로 전송 (50-70% 크기 감소)
5. **프리페칭**: 사용자가 방문할 가능성 높은 화면 미리 로드

### 14.3 보안 체크리스트

- [ ] URL 화이트리스트 검증
- [ ] 스키마 깊이 제한 (DoS 방지)
- [ ] XSS 방지 (텍스트 sanitize)
- [ ] HTTPS 강제
- [ ] 스키마 버전 검증
- [ ] Action 타입 제한

### 14.4 개발 워크플로우

```
1. 스키마 설계
   ↓
2. 로컬 JSON 파일로 테스트
   ↓
3. 위젯 빌더 구현/확장
   ↓
4. 서버 API 연동
   ↓
5. 캐싱 전략 설정
   ↓
6. A/B 테스트 설정
   ↓
7. 프로덕션 배포
```

### 14.5 모니터링

```dart
// lib/core/sdui/monitoring/sdui_monitor.dart
class SDUIMonitor {
  static void trackRenderTime(String screen, Duration duration) {
    // Firebase Performance Monitoring
    debugPrint('Schema render time for $screen: ${duration.inMilliseconds}ms');
  }

  static void trackCacheHit(String screen, bool isHit) {
    // Analytics
    debugPrint('Cache hit for $screen: $isHit');
  }

  static void trackError(String screen, Exception error) {
    // Crashlytics
    debugPrint('Schema error for $screen: $error');
  }
}
```

## 15. 관련 문서

- **Architecture.md** - Clean Architecture 구조와 레이어 분리
- **Bloc.md** - SchemaBloc 상태 관리 패턴
- **Networking_Dio.md** - API 통신 및 인터셉터 설정
- **Networking_Retrofit.md** - Schema API 서비스 정의
- **ErrorHandling.md** - Failure 패턴과 에러 처리
- **Navigation.md** - GoRouter 통합 네비게이션
- **Analytics.md** - 이벤트 추적 및 A/B 테스트 분석
- **OfflineSupport.md** - 오프라인 폴백 전략
- **CachingStrategy.md** - 3-tier 캐싱 구현
- **Performance.md** - 렌더링 최적화 및 프로파일링
- **Testing.md** - BLoC 및 위젯 테스트 전략
- **DI.md** - get_it + injectable 의존성 주입

---

## 체크리스트

### 기본 구현
- [ ] SDUINode, SDUIAction, SDUIResponse 모델 정의 (Freezed)
- [ ] WidgetRegistry 구현 및 기본 빌더 등록
- [ ] AttributeParser로 JSON 속성 파싱
- [ ] SDUIRenderer 위젯 구현
- [ ] ActionHandler로 사용자 인터랙션 처리

### API 연동
- [ ] Retrofit으로 Schema API 정의
- [ ] SchemaBloc (Event/State) 구현
- [ ] SchemaRepository로 데이터 소스 통합
- [ ] 에러 처리 (Either<Failure, T>)

### 캐싱
- [ ] 메모리 캐시 구현 (LRU)
- [ ] 디스크 캐시 구현 (Hive)
- [ ] 번들 폴백 스키마 준비
- [ ] TTL 기반 캐시 무효화

### 보안
- [ ] 스키마 검증 (깊이, 자식 수 제한)
- [ ] URL 화이트리스트
- [ ] XSS 방지 (텍스트 sanitize)

### 성능 최적화
- [ ] 스키마 압축 (gzip)
- [ ] 지연 로딩 및 페이지네이션
- [ ] 이미지 캐싱 (CachedNetworkImage)
- [ ] Skeleton 로더

### 테스트
- [ ] WidgetRegistry 유닛 테스트
- [ ] SDUIRenderer 위젯 테스트
- [ ] SchemaBloc 테스트 (bloc_test)
- [ ] 스키마 검증 테스트

## 실습 과제

### 과제 1: 동적 프로필 화면
서버 스키마로 제어되는 프로필 화면 구현:
- 사용자 정보 표시 (이름, 이메일, 프로필 이미지)
- 설정 메뉴 (A/B 테스트로 순서 변경 가능)
- 로그아웃 버튼 (Action 처리)

**목표**: 전체 SDUI 플로우 이해

### 과제 2: 커스텀 위젯 빌더
도메인 특화 위젯 빌더 3개 이상 구현:
- `ReviewCard` - 리뷰 카드 (별점, 텍스트)
- `CountdownBanner` - 타이머 배너
- `VideoPlayer` - 비디오 플레이어

**목표**: Widget Registry 확장 패턴 습득

### 과제 3: A/B 테스트
Firebase Remote Config로 2개 배리언트 테스트:
- Variant A: 세로 레이아웃
- Variant B: 가로 스크롤 레이아웃
- 전환율 추적 (Analytics)

**목표**: 실험 기반 개발 경험

### 과제 4: 오프라인 모드
완전한 오프라인 지원 구현:
- 3-tier 캐싱 전체 구현
- 네트워크 상태 감지
- Stale-while-revalidate 패턴
- 폴백 스키마 자동 전환

**목표**: 프로덕션 레벨 안정성 확보

## Self-Check

1. **개념 이해**
   - [ ] SDUI의 장단점을 설명할 수 있나요?
   - [ ] 3-tier 캐싱 전략을 설명할 수 있나요?
   - [ ] Widget Registry 패턴의 목적을 이해하나요?

2. **구현 능력**
   - [ ] JSON 스키마를 Flutter 위젯으로 변환할 수 있나요?
   - [ ] 새로운 위젯 타입을 추가할 수 있나요?
   - [ ] Action 시스템에 커스텀 액션을 추가할 수 있나요?

3. **아키텍처**
   - [ ] Clean Architecture와 SDUI를 통합할 수 있나요?
   - [ ] Bloc으로 스키마 상태를 관리할 수 있나요?
   - [ ] 의존성 주입으로 컴포넌트를 조립할 수 있나요?

4. **프로덕션 준비**
   - [ ] 스키마 버전 관리 전략이 있나요?
   - [ ] 보안 검증 (URL 화이트리스트 등)을 구현했나요?
   - [ ] 에러 시나리오 (네트워크 실패, 잘못된 스키마)를 처리하나요?
   - [ ] 성능 모니터링 (렌더링 시간, 캐시 히트율)을 하고 있나요?

5. **A/B 테스트**
   - [ ] 서버 사이드 배리언트를 구현할 수 있나요?
   - [ ] 실험 노출 및 전환을 추적하나요?
   - [ ] Remote Config와 통합할 수 있나요?

**모든 항목에 체크할 수 있다면, Server-Driven UI 패턴을 마스터했습니다! 🎉**
