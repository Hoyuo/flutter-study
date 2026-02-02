import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/bloc/bloc_ui_effect_mixin.dart';

// Test state
abstract class TestState {}

class TestStateInitial extends TestState {}

class TestStateLoading extends TestState {}

class TestStateSuccess extends TestState {
  final String message;
  TestStateSuccess(this.message);
}

// Test UI effect
abstract class TestUiEffect {}

class ShowSnackbar extends TestUiEffect {
  final String message;
  ShowSnackbar(this.message);
}

class NavigateToHome extends TestUiEffect {}

class ShowDialog extends TestUiEffect {
  final String title;
  final String content;
  ShowDialog(this.title, this.content);
}

// Test event
abstract class TestEvent {}

class TriggerSuccessEvent extends TestEvent {}

class TriggerSnackbarEvent extends TestEvent {
  final String message;
  TriggerSnackbarEvent(this.message);
}

class TriggerNavigationEvent extends TestEvent {}

class TriggerDialogEvent extends TestEvent {}

class TriggerMultipleEffectsEvent extends TestEvent {}

// Test Bloc with mixin
class TestBloc extends Bloc<TestEvent, TestState>
    with BlocUiEffectMixin<TestUiEffect, TestState> {
  TestBloc() : super(TestStateInitial()) {
    on<TriggerSuccessEvent>(_onTriggerSuccess);
    on<TriggerSnackbarEvent>(_onTriggerSnackbar);
    on<TriggerNavigationEvent>(_onTriggerNavigation);
    on<TriggerDialogEvent>(_onTriggerDialog);
    on<TriggerMultipleEffectsEvent>(_onTriggerMultipleEffects);
  }

  Future<void> _onTriggerSuccess(
    TriggerSuccessEvent event,
    Emitter<TestState> emit,
  ) async {
    emit(TestStateLoading());
    await Future.delayed(const Duration(milliseconds: 10));
    emit(TestStateSuccess('Success!'));
    emitUiEffect(ShowSnackbar('Operation completed'));
  }

  Future<void> _onTriggerSnackbar(
    TriggerSnackbarEvent event,
    Emitter<TestState> emit,
  ) async {
    emitUiEffect(ShowSnackbar(event.message));
  }

  Future<void> _onTriggerNavigation(
    TriggerNavigationEvent event,
    Emitter<TestState> emit,
  ) async {
    emitUiEffect(NavigateToHome());
  }

  Future<void> _onTriggerDialog(
    TriggerDialogEvent event,
    Emitter<TestState> emit,
  ) async {
    emitUiEffect(ShowDialog('Alert', 'This is a test dialog'));
  }

  Future<void> _onTriggerMultipleEffects(
    TriggerMultipleEffectsEvent event,
    Emitter<TestState> emit,
  ) async {
    emitUiEffect(ShowSnackbar('First effect'));
    await Future.delayed(const Duration(milliseconds: 10));
    emitUiEffect(ShowSnackbar('Second effect'));
    await Future.delayed(const Duration(milliseconds: 10));
    emitUiEffect(NavigateToHome());
  }
}

void main() {
  group('BlocUiEffectMixin', () {
    late TestBloc bloc;

    setUp(() {
      bloc = TestBloc();
    });

    tearDown(() {
      bloc.close();
    });

    group('effectStream', () {
      test('should provide a broadcast stream', () {
        expect(bloc.effectStream, isA<Stream<TestUiEffect>>());
        expect(bloc.effectStream.isBroadcast, true);
      });

      test('should allow multiple listeners', () async {
        final effects1 = <TestUiEffect>[];
        final effects2 = <TestUiEffect>[];

        bloc.effectStream.listen(effects1.add);
        bloc.effectStream.listen(effects2.add);

        bloc.add(TriggerSnackbarEvent('Test message'));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects1.length, 1);
        expect(effects2.length, 1);
        expect((effects1.first as ShowSnackbar).message, 'Test message');
        expect((effects2.first as ShowSnackbar).message, 'Test message');
      });
    });

    group('emitUiEffect', () {
      test('should emit UI effect through stream', () async {
        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        bloc.add(TriggerSnackbarEvent('Test message'));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 1);
        expect(effects.first, isA<ShowSnackbar>());
        expect((effects.first as ShowSnackbar).message, 'Test message');
      });

      test('should emit multiple different UI effects', () async {
        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        bloc.add(TriggerSnackbarEvent('Snackbar'));
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(TriggerNavigationEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(TriggerDialogEvent());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 3);
        expect(effects[0], isA<ShowSnackbar>());
        expect(effects[1], isA<NavigateToHome>());
        expect(effects[2], isA<ShowDialog>());
      });

      test('should emit UI effects in order', () async {
        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        bloc.add(TriggerMultipleEffectsEvent());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(effects.length, 3);
        expect((effects[0] as ShowSnackbar).message, 'First effect');
        expect((effects[1] as ShowSnackbar).message, 'Second effect');
        expect(effects[2], isA<NavigateToHome>());
      });

      test('should not emit UI effect after bloc is closed', () async {
        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        await bloc.close();

        // Try to emit after close (should not throw, but shouldn't emit either)
        bloc.emitUiEffect(ShowSnackbar('Should not emit'));

        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 0);
      });
    });

    group('integration with bloc state', () {
      test('should emit both state and UI effect', () async {
        final testBloc = TestBloc();
        final states = <TestState>[];
        final effects = <TestUiEffect>[];

        testBloc.stream.listen(states.add);
        testBloc.effectStream.listen(effects.add);

        testBloc.add(TriggerSuccessEvent());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, 2);
        expect(states[0], isA<TestStateLoading>());
        expect(states[1], isA<TestStateSuccess>());
        expect(effects.length, 1);
        expect(effects[0], isA<ShowSnackbar>());

        await testBloc.close();
      });

      test('should handle UI effects independent of state changes', () async {
        final states = <TestState>[];
        final effects = <TestUiEffect>[];

        bloc.stream.listen(states.add);
        bloc.effectStream.listen(effects.add);

        bloc.add(TriggerSnackbarEvent('Test'));

        await Future.delayed(const Duration(milliseconds: 50));

        // No state change expected
        expect(states.length, 0);
        // But UI effect should be emitted
        expect(effects.length, 1);
      });
    });

    group('close', () {
      test('should close effect stream controller', () async {
        final effects = <TestUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        await bloc.close();

        expect(() => bloc.emitUiEffect(ShowSnackbar('Test')), returnsNormally);

        await subscription.cancel();
      });

      test('should close effect stream before closing bloc', () async {
        var streamClosed = false;

        bloc.effectStream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        await bloc.close();

        await Future.delayed(const Duration(milliseconds: 50));

        expect(streamClosed, true);
      });

      test('should handle multiple close calls gracefully', () async {
        await bloc.close();
        // Second close should not throw
        expect(() => bloc.close(), returnsNormally);
      });
    });

    group('stream subscription', () {
      test('should handle subscription cancellation', () async {
        final effects = <TestUiEffect>[];
        final subscription = bloc.effectStream.listen(effects.add);

        bloc.add(TriggerSnackbarEvent('Before cancel'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 1);

        await subscription.cancel();

        bloc.add(TriggerSnackbarEvent('After cancel'));
        await Future.delayed(const Duration(milliseconds: 50));

        // Should not receive the second effect
        expect(effects.length, 1);
      });

      test('should handle late subscription', () async {
        bloc.add(TriggerSnackbarEvent('Early effect'));
        await Future.delayed(const Duration(milliseconds: 50));

        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        // Should not receive effects emitted before subscription
        expect(effects.length, 0);

        bloc.add(TriggerSnackbarEvent('Late effect'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 1);
        expect((effects.first as ShowSnackbar).message, 'Late effect');
      });
    });

    group('edge cases', () {
      test('should handle rapid successive effect emissions', () async {
        final effects = <TestUiEffect>[];
        bloc.effectStream.listen(effects.add);

        // Emit multiple effects rapidly
        for (var i = 0; i < 10; i++) {
          bloc.emitUiEffect(ShowSnackbar('Effect $i'));
        }

        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 10);
        for (var i = 0; i < 10; i++) {
          expect((effects[i] as ShowSnackbar).message, 'Effect $i');
        }
      });

      test('should handle effect emission with error in handler', () async {
        final effects = <TestUiEffect>[];
        final errors = <Object>[];

        bloc.effectStream.listen(
          effects.add,
          onError: errors.add,
        );

        bloc.add(TriggerSnackbarEvent('Test'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 1);
        expect(errors.length, 0);
      });

      test('should maintain effect stream independence from state stream', () async {
        final states = <TestState>[];
        final effects = <TestUiEffect>[];

        final stateSubscription = bloc.stream.listen(states.add);
        final effectSubscription = bloc.effectStream.listen(effects.add);

        await stateSubscription.cancel();

        // Effect stream should still work after state stream is cancelled
        bloc.add(TriggerSnackbarEvent('Test'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(effects.length, 1);

        await effectSubscription.cancel();
      });
    });
  });
}
