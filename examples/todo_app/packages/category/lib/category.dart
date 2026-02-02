/// Category package for TODO app
///
/// This package provides category management functionality following Clean Architecture.
library;

// Domain layer
export 'domain/entities/category.dart';
export 'domain/repositories/category_repository.dart';
export 'domain/usecases/get_categories_usecase.dart';
export 'domain/usecases/get_category_by_id_usecase.dart';
export 'domain/usecases/create_category_usecase.dart';
export 'domain/usecases/update_category_usecase.dart';
export 'domain/usecases/delete_category_usecase.dart';

// Data layer
export 'data/models/category_model.dart';
export 'data/datasources/category_local_datasource.dart';
export 'data/repositories/category_repository_impl.dart';

// Presentation layer
export 'presentation/bloc/category_bloc.dart';
