import 'package:core/core.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Parameters for CreateCategoryUseCase
class CreateCategoryParams {
  final Category category;

  const CreateCategoryParams(this.category);
}

/// Use case for creating a new category
class CreateCategoryUseCase implements UseCase<Category, CreateCategoryParams> {
  final CategoryRepository _repository;

  const CreateCategoryUseCase(this._repository);

  @override
  Future<Either<Failure, Category>> call(CreateCategoryParams params) async {
    return _repository.createCategory(params.category);
  }
}
