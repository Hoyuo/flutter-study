import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

/// Category entity representing a task category
@freezed
abstract class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    required String colorHex,
    String? iconName,
    required DateTime createdAt,
    @Default(0) int taskCount,
  }) = _Category;

  /// Get a display-friendly color string
  String get displayColor => '#$colorHex';

  /// Check if category has an icon
  bool get hasIcon => iconName != null && iconName!.isNotEmpty;
}
