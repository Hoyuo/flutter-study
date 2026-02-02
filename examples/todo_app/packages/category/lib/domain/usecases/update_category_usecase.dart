import 'package:core/core.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Parameters for UpdateCategoryUseCase
class UpdateCategoryParams {
  final Category category;

  const UpdateCategoryParams(this.category);
}

/// Use case for updating an existing category
class UpdateCategoryUseCase implements UseCase<Category, UpdateCategoryParams> {
  final CategoryRepository _repository;

  const UpdateCategoryUseCase(this._repository);

  @override
  Future<Either<Failure, Category>> call(UpdateCategoryParams params) async {
    return _repository.updateCategory(params.category);
  }
}
