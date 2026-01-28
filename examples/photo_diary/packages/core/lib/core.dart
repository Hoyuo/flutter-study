/// Photo Diary 앱을 위한 코어 공유 기능
library core;

// 에러 처리
export 'error/failure.dart';

// Bloc
export 'bloc/bloc.dart';

// 타입
export 'types/types.dart';

// 확장 메서드
export 'extensions/extensions.dart'; // 배럴 파일

// 유틸리티
export 'utils/app_logger.dart';
export 'utils/validators.dart';
export 'utils/accessibility_utils.dart';

// 위젯
export 'widgets/widgets.dart';

// 테스팅
export 'testing/accessibility_test_utils.dart';

// 네트워크
export 'network/network.dart';

// 서비스
export 'services/services.dart';

// 테마
export 'theme/theme.dart';

// 다국어 지원
export 'l10n/l10n.dart';

// 서드파티 패키지 재수출
export 'package:equatable/equatable.dart';
export 'package:fpdart/fpdart.dart';
export 'package:freezed_annotation/freezed_annotation.dart';
