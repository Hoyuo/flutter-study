import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_ui_effect_mixin.dart';

/// Bloc의 UI 이펙트를 리스닝하는 위젯
///
/// [BlocUiEffectMixin]을 사용하는 Bloc의 일회성 UI 이벤트를 처리합니다.
/// 예: 스낵바, 다이얼로그, 네비게이션 등
///
/// 사용 예:
/// ```dart
/// BlocUiEffectListener<MyBloc, MyState, MyUiEffect>(
///   listener: (context, effect) {
///     if (effect is ShowSnackbar) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(effect.message)),
///       );
///     }
///   },
///   child: MyWidget(),
/// )
/// ```
class BlocUiEffectListener<B extends BlocBase<S>, S, E> extends StatefulWidget {
  /// Bloc의 UI 이펙트를 처리할 리스너 함수
  final void Function(BuildContext context, E effect) listener;

  /// 자식 위젯
  final Widget child;

  /// Bloc 인스턴스 (선택사항)
  ///
  /// 제공되지 않으면 [context.read<B>()]를 통해 가져옵니다.
  final B? bloc;

  const BlocUiEffectListener({
    super.key,
    required this.listener,
    required this.child,
    this.bloc,
  });

  @override
  State<BlocUiEffectListener<B, S, E>> createState() =>
      _BlocUiEffectListenerState<B, S, E>();
}

class _BlocUiEffectListenerState<B extends BlocBase<S>, S, E>
    extends State<BlocUiEffectListener<B, S, E>> {
  StreamSubscription<E>? _subscription;
  B? _bloc;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocUiEffectListener<B, S, E> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? _bloc;
    final currentBloc = widget.bloc ?? _bloc;
    if (oldBloc != currentBloc) {
      _unsubscribe();
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _unsubscribe();
      _bloc = bloc;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    final bloc = widget.bloc ?? _bloc ?? context.read<B>();
    if (bloc is BlocUiEffectMixin<E, S>) {
      _subscription = (bloc as BlocUiEffectMixin<E, S>).effectStream.listen(
        (effect) {
          if (mounted) {
            widget.listener(context, effect);
          }
        },
      );
    }
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
