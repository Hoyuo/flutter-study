# Flutter 다국어 처리 가이드 (easy_localization)

## 개요

easy_localization은 Flutter에서 다국어 처리를 간편하게 구현할 수 있는 패키지입니다. JSON, YAML, CSV 등 다양한 포맷을 지원하고, 컨텍스트 확장 메서드를 통해 직관적인 API를 제공합니다.

## 설치 및 설정

### 의존성 추가

```yaml
# pubspec.yaml (2026년 1월 기준)
dependencies:
  easy_localization: ^3.0.8  # 3.x 최신 stable

flutter:
  assets:
    - assets/translations/
```

### 번역 파일 구조

```
assets/
└── translations/
    ├── ko.json
    ├── ja.json
    └── zh_TW.json
```

### 번역 파일 예시

**assets/translations/ko.json:**

```json
{
  "app_name": "내 앱",
  "common": {
    "confirm": "확인",
    "cancel": "취소",
    "save": "저장",
    "delete": "삭제",
    "loading": "로딩 중...",
    "error": "오류가 발생했습니다",
    "retry": "다시 시도"
  },
  "auth": {
    "login": "로그인",
    "logout": "로그아웃",
    "email": "이메일",
    "password": "비밀번호",
    "forgot_password": "비밀번호를 잊으셨나요?",
    "login_failed": "로그인에 실패했습니다"
  },
  "home": {
    "welcome": "환영합니다, {name}님!",
    "item_count": {
      "zero": "아이템이 없습니다",
      "one": "아이템 1개",
      "other": "아이템 {count}개"
    }
  },
  "settings": {
    "title": "설정",
    "language": "언어",
    "theme": "테마",
    "notification": "알림"
  }
}
```

**assets/translations/ja.json:**

```json
{
  "app_name": "マイアプリ",
  "common": {
    "confirm": "確認",
    "cancel": "キャンセル",
    "save": "保存",
    "delete": "削除",
    "loading": "読み込み中...",
    "error": "エラーが発生しました",
    "retry": "再試行"
  },
  "auth": {
    "login": "ログイン",
    "logout": "ログアウト",
    "email": "メールアドレス",
    "password": "パスワード",
    "forgot_password": "パスワードをお忘れですか？",
    "login_failed": "ログインに失敗しました"
  },
  "home": {
    "welcome": "ようこそ、{name}さん！",
    "item_count": {
      "zero": "アイテムがありません",
      "one": "アイテム1件",
      "other": "アイテム{count}件"
    }
  },
  "settings": {
    "title": "設定",
    "language": "言語",
    "theme": "テーマ",
    "notification": "通知"
  }
}
```

**assets/translations/zh_TW.json:**

```json
{
  "app_name": "我的應用",
  "common": {
    "confirm": "確認",
    "cancel": "取消",
    "save": "儲存",
    "delete": "刪除",
    "loading": "載入中...",
    "error": "發生錯誤",
    "retry": "重試"
  },
  "auth": {
    "login": "登入",
    "logout": "登出",
    "email": "電子郵件",
    "password": "密碼",
    "forgot_password": "忘記密碼？",
    "login_failed": "登入失敗"
  },
  "home": {
    "welcome": "歡迎，{name}！",
    "item_count": {
      "zero": "沒有項目",
      "one": "1個項目",
      "other": "{count}個項目"
    }
  },
  "settings": {
    "title": "設定",
    "language": "語言",
    "theme": "主題",
    "notification": "通知"
  }
}
```

## 앱 초기화

### main.dart 설정

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('ja'),
        Locale('zh', 'TW'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      startLocale: const Locale('ko'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // ⚠️ 주의: title은 앱 스위처에 표시되며,
      // EasyLocalization 초기화 전에 빌드될 수 있어 번역이 적용 안 될 수 있음
      // 권장: 고정 문자열 사용하거나 onGenerateTitle 활용
      title: 'MyApp',  // 또는
      // onGenerateTitle: (context) => 'app_name'.tr(),
      home: const HomeScreen(),
    );
  }
}
```

### Environment별 기본 로케일 설정

```dart
// lib/core/config/locale_config.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../env/env_config.dart';

class LocaleConfig {
  static const supportedLocales = [
    Locale('ko'),
    Locale('ja'),
    Locale('zh', 'TW'),
  ];

  /// 국가별 기본 로케일
  static Locale get defaultLocale {
    switch (EnvConfig.country) {
      case Country.kr:
        return const Locale('ko');
      case Country.jp:
        return const Locale('ja');
      case Country.tw:
        return const Locale('zh', 'TW');
    }
  }

  /// 로케일 초기화
  static Future<void> initialize() async {
    await EasyLocalization.ensureInitialized();
  }

  /// 지원하는 로케일인지 확인
  static bool isSupported(Locale locale) {
    return supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }
}
```

## 기본 사용법

### 단순 번역

```dart
import 'package:easy_localization/easy_localization.dart';

// 확장 메서드 사용
Text('common.confirm'.tr())

// 함수 사용
Text(tr('common.confirm'))

// 중첩 키
Text('auth.login'.tr())
```

### 매개변수 사용 (Named Arguments)

```dart
// JSON: "welcome": "환영합니다, {name}님!"

// 단일 매개변수
Text('home.welcome'.tr(namedArgs: {'name': '홍길동'}))
// 결과: "환영합니다, 홍길동님!"

// 여러 매개변수
// JSON: "order_info": "{name}님의 주문 {count}건"
Text('order.order_info'.tr(namedArgs: {
  'name': '홍길동',
  'count': '5',
}))
```

### 위치 매개변수 (Positional Arguments)

```dart
// JSON: "greeting": "안녕하세요, {}! 오늘은 {}입니다."
Text('greeting'.tr(args: ['홍길동', '월요일']))
// 결과: "안녕하세요, 홍길동! 오늘은 월요일입니다."
```

### 복수형 처리 (Plural)

```dart
// JSON:
// "item_count": {
//   "zero": "아이템이 없습니다",
//   "one": "아이템 1개",
//   "other": "아이템 {count}개"
// }

Text('home.item_count'.plural(0))   // 아이템이 없습니다
Text('home.item_count'.plural(1))   // 아이템 1개
Text('home.item_count'.plural(5))   // 아이템 5개
```

### 복수형 + 매개변수

```dart
// JSON:
// "cart_items": {
//   "zero": "{name}님의 장바구니가 비어있습니다",
//   "one": "{name}님의 장바구니에 상품 1개",
//   "other": "{name}님의 장바구니에 상품 {count}개"
// }

Text('cart_items'.plural(3, namedArgs: {'name': '홍길동'}))
// 결과: "홍길동님의 장바구니에 상품 3개"
```

## 언어 변경

### 런타임 언어 변경

```dart
// 언어 변경
await context.setLocale(const Locale('ja'));

// 현재 로케일 확인
Locale currentLocale = context.locale;

// 디바이스 기본 로케일로 리셋
await context.resetLocale();

// 특정 로케일로 삭제 (저장된 로케일 제거)
await context.deleteSaveLocale();
```

### 언어 설정 화면 예시

```dart
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.language'.tr()),
      ),
      body: ListView(
        children: [
          _LanguageTile(
            locale: const Locale('ko'),
            title: '한국어',
            isSelected: context.locale.languageCode == 'ko',
          ),
          _LanguageTile(
            locale: const Locale('ja'),
            title: '日本語',
            isSelected: context.locale.languageCode == 'ja',
          ),
          _LanguageTile(
            locale: const Locale('zh', 'TW'),
            title: '繁體中文',
            isSelected: context.locale == const Locale('zh', 'TW'),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Locale locale;
  final String title;
  final bool isSelected;

  const _LanguageTile({
    required this.locale,
    required this.title,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () async {
        await context.setLocale(locale);
      },
    );
  }
}
```

### 로케일 Fallback 체인 설정

로케일을 찾지 못할 때 여러 단계의 fallback을 거쳐 적절한 번역을 제공할 수 있습니다.

```dart
/// 로케일 Fallback 체인 설정
/// zh_TW → zh → ko 순서로 fallback
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('ja'),
        Locale('zh', 'TW'),  // 대만 번체 중국어
        Locale('zh'),        // 중국어 기본
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      // startLocale이 없으면 시스템 로케일 → fallbackLocale 순서로 시도
      child: const MyApp(),
    ),
  );
}
```

**Fallback 동작 방식:**
1. 사용자 디바이스의 시스템 로케일 확인
2. `supportedLocales`에서 일치하는 로케일 찾기
3. 정확히 일치하지 않으면 언어 코드만으로 매칭 시도 (예: zh_CN → zh)
4. 그래도 없으면 `fallbackLocale` 사용
5. `fallbackLocale`도 없으면 `supportedLocales`의 첫 번째 로케일 사용

```dart
// 예시: zh_CN 사용자의 경우
// 1. zh_CN (없음)
// 2. zh (있음) → zh 번역 사용
// 3. ko (fallback) → 있지만 2단계에서 찾았으므로 사용 안 함
```

## 번역 키 타입 안전성

### 코드 생성 사용 (권장)

번역 키를 하드코딩하지 않고 타입 안전하게 사용하기 위해 코드 생성을 활용합니다.

```yaml
# pubspec.yaml
# ⚠️ 주의: easy_localization_generator는 2022년 이후 업데이트 없음
# Dart 3 호환성 문제가 있을 수 있음
# 대안: slang 패키지 또는 수동 LocaleKeys 관리 권장
dev_dependencies:
  # easy_localization_generator: ^1.4.0  # deprecated
  build_runner: ^2.10.5
```

```dart
// lib/core/l10n/locale_keys.dart
// 수동으로 관리하거나 코드 생성

abstract class LocaleKeys {
  // Common
  static const commonConfirm = 'common.confirm';
  static const commonCancel = 'common.cancel';
  static const commonSave = 'common.save';
  static const commonDelete = 'common.delete';
  static const commonLoading = 'common.loading';
  static const commonError = 'common.error';
  static const commonRetry = 'common.retry';

  // Auth
  static const authLogin = 'auth.login';
  static const authLogout = 'auth.logout';
  static const authEmail = 'auth.email';
  static const authPassword = 'auth.password';
  static const authForgotPassword = 'auth.forgot_password';
  static const authLoginFailed = 'auth.login_failed';

  // Home
  static const homeWelcome = 'home.welcome';
  static const homeItemCount = 'home.item_count';

  // Settings
  static const settingsTitle = 'settings.title';
  static const settingsLanguage = 'settings.language';
  static const settingsTheme = 'settings.theme';
  static const settingsNotification = 'settings.notification';
}
```

### 사용 예시

```dart
import 'locale_keys.dart';

// 단순 번역
Text(LocaleKeys.commonConfirm.tr())

// 매개변수
Text(LocaleKeys.homeWelcome.tr(namedArgs: {'name': userName}))

// 복수형
Text(LocaleKeys.homeItemCount.plural(itemCount))
```

## Bloc과 통합

### 언어 설정 Bloc

```dart
// lib/features/settings/presentation/bloc/language_event.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'language_event.freezed.dart';

@freezed
class LanguageEvent with _$LanguageEvent {
  const factory LanguageEvent.changed(Locale locale) = _Changed;
  const factory LanguageEvent.loaded() = _Loaded;
}
```

```dart
// lib/features/settings/presentation/bloc/language_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'language_state.freezed.dart';

@freezed
class LanguageState with _$LanguageState {
  const factory LanguageState({
    required Locale currentLocale,
    required List<Locale> supportedLocales,
    required bool isLoading,
  }) = _LanguageState;

  factory LanguageState.initial() => LanguageState(
        currentLocale: const Locale('ko'),
        supportedLocales: const [
          Locale('ko'),
          Locale('ja'),
          Locale('zh', 'TW'),
        ],
        isLoading: false,
      );
}
```

```dart
// lib/features/settings/presentation/bloc/language_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_saved_locale_usecase.dart';
import '../../domain/usecases/save_locale_usecase.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final GetSavedLocaleUseCase _getSavedLocaleUseCase;
  final SaveLocaleUseCase _saveLocaleUseCase;

  LanguageBloc({
    required GetSavedLocaleUseCase getSavedLocaleUseCase,
    required SaveLocaleUseCase saveLocaleUseCase,
  })  : _getSavedLocaleUseCase = getSavedLocaleUseCase,
        _saveLocaleUseCase = saveLocaleUseCase,
        super(LanguageState.initial()) {
    on<LanguageEvent>((event, emit) async {
      await event.when(
        loaded: () => _onLoaded(emit),
        changed: (locale) => _onChanged(locale, emit),
      );
    });
  }

  Future<void> _onLoaded(Emitter<LanguageState> emit) async {
    emit(state.copyWith(isLoading: true));

    final result = await _getSavedLocaleUseCase();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false)),
      (locale) => emit(state.copyWith(
        currentLocale: locale ?? state.currentLocale,
        isLoading: false,
      )),
    );
  }

  Future<void> _onChanged(Locale locale, Emitter<LanguageState> emit) async {
    emit(state.copyWith(isLoading: true));

    final result = await _saveLocaleUseCase(locale);

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false)),
      (_) => emit(state.copyWith(
        currentLocale: locale,
        isLoading: false,
      )),
    );
  }
}
```

### UI 연동

```dart
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LanguageBloc, LanguageState>(
      listenWhen: (prev, curr) => prev.currentLocale != curr.currentLocale,
      listener: (context, state) async {
        // Bloc 상태가 변경되면 easy_localization도 업데이트
        await context.setLocale(state.currentLocale);
      },
      child: BlocBuilder<LanguageBloc, LanguageState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(title: Text(LocaleKeys.settingsLanguage.tr())),
            body: ListView.builder(
              itemCount: state.supportedLocales.length,
              itemBuilder: (context, index) {
                final locale = state.supportedLocales[index];
                final isSelected = locale == state.currentLocale;

                return ListTile(
                  title: Text(_getLanguageName(locale)),
                  trailing: isSelected
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    context.read<LanguageBloc>().add(
                      LanguageEvent.changed(locale),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'ja':
        return '日本語';
      case 'zh':
        return '繁體中文';
      default:
        return locale.languageCode;
    }
  }
}
```

## 고급 기능

### Linked Translations (번역 참조)

```json
{
  "app_name": "마이앱",
  "welcome_to": "Welcome to @:app_name!"
}
```

```dart
Text('welcome_to'.tr())  // "Welcome to 마이앱!"
```

### Gender 처리

```json
{
  "greeting": {
    "male": "안녕하세요, {name}씨",
    "female": "안녕하세요, {name}양",
    "other": "안녕하세요, {name}님"
  }
}
```

```dart
// gender 확장 메서드 사용
Text('greeting'.tr(gender: 'male', namedArgs: {'name': '철수'}))
// 결과: "안녕하세요, 철수씨"
```

### 날짜/시간 포맷팅

```dart
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

// 로케일에 맞는 날짜 포맷
String formatDate(DateTime date, BuildContext context) {
  return DateFormat.yMMMMd(context.locale.toString()).format(date);
}

// 결과:
// ko: 2024년 1월 15일
// ja: 2024年1月15日
// zh_TW: 2024年1月15日
```

### 숫자 포맷팅

```dart
import 'package:intl/intl.dart';

String formatCurrency(int amount, BuildContext context) {
  final locale = context.locale.toString();

  switch (context.locale.languageCode) {
    case 'ko':
      return NumberFormat.currency(locale: locale, symbol: '₩', decimalDigits: 0).format(amount);
    case 'ja':
      return NumberFormat.currency(locale: locale, symbol: '¥', decimalDigits: 0).format(amount);
    case 'zh':
      return NumberFormat.currency(locale: locale, symbol: 'NT\$', decimalDigits: 0).format(amount);
    default:
      return NumberFormat.currency(locale: locale).format(amount);
  }
}
```

## 테스트

### 위젯 테스트에서 로케일 설정

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // SharedPreferences mock 설정 필요
    SharedPreferences.setMockInitialValues({});

    // 테스트용 번역 초기화
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('should display translated text', (tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ko'), Locale('ja')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ko'),
        // useOnlyLangCode: true 사용 시 테스트 단순화
        useOnlyLangCode: true,
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationsDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: Text('common.confirm'.tr()),
            ),
          ),
        ),
      ),
    );

    // 초기화 완료 대기
    await tester.pumpAndSettle();

    expect(find.text('확인'), findsOneWidget);
  });
}
```

### Mock 번역 사용

```dart
// 테스트용 번역 데이터
class MockTranslations {
  static const Map<String, String> ko = {
    'common.confirm': '확인',
    'common.cancel': '취소',
  };
}

// 테스트에서 사용
testWidgets('test with mock translations', (tester) async {
  // AssetLoader 커스터마이징으로 mock 데이터 주입
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko')],
      path: 'assets/translations',
      assetLoader: _MockAssetLoader(),
      child: const MyApp(),
    ),
  );
});
```

## 모범 사례

### 번역 키 네이밍 컨벤션

```json
{
  // ✅ 좋은 예: 기능/화면별 그룹화
  "auth": {
    "login": "로그인",
    "login_button": "로그인하기",
    "login_error": "로그인에 실패했습니다"
  },

  // ✅ 좋은 예: 재사용 가능한 공통 키
  "common": {
    "confirm": "확인",
    "cancel": "취소"
  },

  // ❌ 나쁜 예: 플랫한 구조
  "login": "로그인",
  "loginButton": "로그인하기",
  "loginError": "로그인 실패"
}
```

### 번역 파일 관리

```
assets/
└── translations/
    ├── ko.json           # 한국어 (기본)
    ├── ja.json           # 일본어
    ├── zh_TW.json        # 대만 번체
    └── _template.json    # 번역 템플릿 (새 키 추가용)
```

### Context 없이 번역 사용

일부 상황(UseCase, Repository 등)에서는 BuildContext 없이 번역이 필요할 수 있습니다.

```dart
// ❌ 비권장: 비즈니스 로직에서 직접 번역
class SomeUseCase {
  String execute() {
    return 'error.message'.tr();  // Context 필요 없지만 권장하지 않음
  }
}

// ✅ 권장: 에러 키만 반환하고 UI에서 번역
class SomeUseCase {
  Either<Failure, String> execute() {
    return Left(Failure.server(messageKey: 'error.server'));
  }
}

// UI에서 번역
BlocListener<SomeBloc, SomeState>(
  listener: (context, state) {
    if (state.failure != null) {
      showSnackBar(context, state.failure!.messageKey.tr());
    }
  },
)
```

### 번역 누락 처리

```dart
// easy_localization은 번역 누락 시 자동으로 fallbackLocale 사용
EasyLocalization(
  supportedLocales: const [
    Locale('ko'),
    Locale('ja'),
    Locale('zh', 'TW'),
  ],
  path: 'assets/translations',

  // 번역이 없을 때 키 대신 fallback 텍스트 표시
  fallbackLocale: const Locale('ko'),

  // 번역 누락 로깅
  useOnlyLangCode: true,

  child: const MyApp(),
)
```

## 11. RTL (Right-to-Left) 언어 지원

### 11.1 RTL 언어란?

아랍어, 히브리어, 페르시아어 등은 **오른쪽에서 왼쪽**으로 읽습니다.
글로벌 앱을 위해 RTL 지원은 필수입니다.

### 11.2 Flutter의 RTL 자동 지원

Flutter는 locale에 따라 자동으로 방향을 조정합니다:

```dart
MaterialApp(
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    const Locale('ko'),
    const Locale('en'),
    const Locale('ar'), // 아랍어 (RTL)
    const Locale('he'), // 히브리어 (RTL)
  ],
);
```

### 11.3 방향 감지 및 조건부 스타일

```dart
class DirectionalWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Row(
      children: [
        // RTL에서는 아이콘이 오른쪽에
        if (!isRTL) const Icon(Icons.arrow_back),
        Expanded(child: Text('콘텐츠')),
        if (isRTL) const Icon(Icons.arrow_forward),
      ],
    );
  }
}

// 또는 Directionality 위젯으로 명시적 설정
Directionality(
  textDirection: TextDirection.rtl,
  child: MyWidget(),
)
```

### 11.4 RTL 안전한 여백/패딩

```dart
// ❌ 잘못된 예: LTR 고정
Padding(
  padding: EdgeInsets.only(left: 16, right: 8),
  child: Text('텍스트'),
)

// ✅ 올바른 예: 방향 인식
Padding(
  padding: EdgeInsetsDirectional.only(start: 16, end: 8),
  child: Text('텍스트'),
)

// RTL에서: start=오른쪽, end=왼쪽으로 자동 변환
```

### 11.5 RTL 안전한 위치/정렬

```dart
// ❌ 잘못된 예
Positioned(left: 16, child: widget)
Align(alignment: Alignment.centerLeft, child: widget)

// ✅ 올바른 예
PositionedDirectional(start: 16, child: widget)
Align(alignment: AlignmentDirectional.centerStart, child: widget)
```

### 11.6 아이콘 미러링

일부 아이콘은 RTL에서 뒤집어야 합니다:

```dart
class DirectionalIcon extends StatelessWidget {
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // 방향성 있는 아이콘만 뒤집기
    final shouldMirror = _isDirectionalIcon(icon) && isRTL;

    return Transform(
      alignment: Alignment.center,
      transform: shouldMirror
          ? Matrix4.rotationY(3.14159) // 180도 회전
          : Matrix4.identity(),
      child: Icon(icon),
    );
  }

  bool _isDirectionalIcon(IconData icon) {
    // 방향성 아이콘 목록
    const directionalIcons = [
      Icons.arrow_back,
      Icons.arrow_forward,
      Icons.chevron_left,
      Icons.chevron_right,
      Icons.keyboard_arrow_left,
      Icons.keyboard_arrow_right,
    ];
    return directionalIcons.contains(icon);
  }
}
```

### 11.7 테스트 방법

```dart
testWidgets('RTL layout test', (tester) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        home: MyPage(),
      ),
    ),
  );

  // RTL에서 시작 위치가 오른쪽인지 확인
  final startButton = find.byKey(const Key('start_button'));
  final buttonPosition = tester.getTopRight(startButton);

  expect(buttonPosition.dx, greaterThan(300)); // 오른쪽에 위치
});
```

### 11.8 RTL 체크리스트

| 항목 | 확인 |
|-----|-----|
| EdgeInsets → EdgeInsetsDirectional | ☐ |
| Alignment → AlignmentDirectional | ☐ |
| Positioned → PositionedDirectional | ☐ |
| left/right → start/end | ☐ |
| 방향성 아이콘 미러링 | ☐ |
| 숫자/전화번호 방향 유지 | ☐ |
| RTL 언어로 실제 테스트 | ☐ |

## 체크리스트

- [ ] easy_localization 패키지 설치
- [ ] 번역 파일 (JSON) 생성 및 assets 등록
- [ ] main.dart에서 EasyLocalization 초기화
- [ ] MaterialApp에 localizationsDelegates, supportedLocales, locale 설정
- [ ] LocaleKeys 클래스로 타입 안전한 키 관리
- [ ] 언어 변경 UI 구현
- [ ] Bloc과 연동하여 상태 관리
- [ ] 날짜/숫자 포맷팅 로케일 적용
- [ ] 테스트 환경에서 번역 설정
