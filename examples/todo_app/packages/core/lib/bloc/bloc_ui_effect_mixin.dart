import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bloc에서 UI 이펙트를 처리하기 위한 Mixin
///
/// UI 이펙트는 일회성 이벤트로, State와는 달리 한 번만 발생하고 소비됩니다.
/// 예: 스낵바 표시, 네비게이션, 다이얼로그 표시 등
///
/// 사용 예:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with BlocUiEffectMixin<MyUiEffect, MyState> {
///   // bloc implementation
///
///   void _onSomeEvent(SomeEvent event, Emitter<MyState> emit) async {
///     // ... business logic
///     emitUiEffect(MyUiEffect.showSuccess('Operation completed'));
///   }
/// }
/// ```
mixin BlocUiEffectMixin<UiEffect, State> on BlocBase<State> {
  final _effectController = StreamController<UiEffect>.broadcast();

  /// UI 이펙트 스트림
  ///
  /// UI에서 이 스트림을 구독하여 일회성 이벤트를 처리합니다.
  Stream<UiEffect> get effectStream => _effectController.stream;

  /// UI 이펙트를 발생시킵니다
  ///
  /// [effect] 발생시킬 UI 이펙트
  void emitUiEffect(UiEffect effect) {
    if (!_effectController.isClosed) {
      _effectController.add(effect);
    }
  }

  @override
  Future<void> close() {
    _effectController.close();
    return super.close();
  }
}
