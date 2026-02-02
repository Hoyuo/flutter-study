import 'package:core/core.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Parameters for GetCategoryByIdUseCase
class GetCategoryByIdParams {
  final String id;

  const GetCategoryByIdParams(this.id);
}

/// Use case for getting a category by ID
class GetCategoryByIdUseCase implements UseCase<Category, GetCategoryByIdParams> {
  final CategoryRepository _repository;

  const GetCategoryByIdUseCase(this._repository);

  @override
  Future<Either<Failure, Category>> call(GetCategoryByIdParams params) async {
    return _repository.getCategoryById(params.id);
  }
}
