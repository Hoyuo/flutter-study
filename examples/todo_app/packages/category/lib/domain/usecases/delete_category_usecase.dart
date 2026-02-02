import 'package:core/core.dart';
import '../repositories/category_repository.dart';

/// Parameters for DeleteCategoryUseCase
class DeleteCategoryParams {
  final String id;

  const DeleteCategoryParams(this.id);
}

/// Use case for deleting a category
class DeleteCategoryUseCase implements UseCase<Unit, DeleteCategoryParams> {
  final CategoryRepository _repository;

  const DeleteCategoryUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteCategoryParams params) async {
    return _repository.deleteCategory(params.id);
  }
}
