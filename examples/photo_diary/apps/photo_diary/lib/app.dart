import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';

import 'package:auth/auth.dart';
import 'package:settings/settings.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

final getIt = GetIt.instance;

/// Photo Diary 앱의 루트 위젯
///
/// MultiBlocProvider를 통해 전역 Bloc들을 제공하고,
/// GoRouter를 통한 선언적 라우팅을 설정합니다.
class PhotoDiaryApp extends StatelessWidget {
  const PhotoDiaryApp({super.key, this.debugShowCheckedModeBanner = false});

  final bool debugShowCheckedModeBanner;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 인증 상태 관리
        BlocProvider<AuthBloc>(
          create: (_) =>
              getIt<AuthBloc>()..add(const AuthEvent.checkAuthStatus()),
        ),
        // 설정 (테마, 언어 등) 관리
        BlocProvider<SettingsBloc>(
          create: (_) =>
              getIt<SettingsBloc>()..add(const SettingsEvent.loadSettings()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (prev, curr) => prev.settings?.themeMode != curr.settings?.themeMode || prev.settings?.languageCode != curr.settings?.languageCode,
        builder: (context, settingsState) {
          final appRouter = getIt<AppRouter>();

          return MaterialApp.router(
            debugShowCheckedModeBanner: debugShowCheckedModeBanner,

            // Localization
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            // Theme - SettingsBloc에서 테마 모드 가져오기
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.settings?.themeMode ?? ThemeMode.system,

            // Routing
            routerConfig: appRouter.router,

            // App Info
            title: 'Photo Diary',
          );
        },
      ),
    );
  }
}
