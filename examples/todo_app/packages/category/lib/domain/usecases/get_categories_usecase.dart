import 'package:core/core.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// Use case for getting all categories
class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository _repository;

  const GetCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return _repository.getCategories();
  }
}
