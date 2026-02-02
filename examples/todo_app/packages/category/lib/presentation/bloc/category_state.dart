part of 'category_bloc.dart';

/// States for CategoryBloc
@freezed
sealed class CategoryState with _$CategoryState {
  /// Initial state
  const factory CategoryState.initial({
    @Default([]) List<Category> categories,
  }) = _Initial;

  /// Loading state
  const factory CategoryState.loading({
    @Default([]) List<Category> categories,
  }) = _Loading;

  /// Loaded state
  const factory CategoryState.loaded({
    required List<Category> categories,
  }) = _Loaded;

  /// Error state
  const factory CategoryState.error({
    @Default([]) List<Category> categories,
    required Failure failure,
  }) = _Error;
}

/// Extension for CategoryState
extension CategoryStateX on CategoryState {
  /// Check if loading
  bool get isLoading => this is _Loading;

  /// Check if error
  bool get isError => this is _Error;

  /// Get error failure if present
  Failure? get failure => mapOrNull(error: (state) => state.failure);

  /// Check if categories are empty
  bool get isEmpty => categories.isEmpty;

  /// Get categories count
  int get count => categories.length;
}
