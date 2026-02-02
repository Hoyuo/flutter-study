/// Task feature package for TODO App
library;

// Domain - Entities
export 'domain/entities/task.dart';

// Domain - Repositories
export 'domain/repositories/task_repository.dart';

// Domain - Use Cases
export 'domain/usecases/get_tasks_params.dart';
export 'domain/usecases/get_tasks_usecase.dart';
export 'domain/usecases/get_task_by_id_usecase.dart';
export 'domain/usecases/create_task_usecase.dart';
export 'domain/usecases/update_task_usecase.dart';
export 'domain/usecases/delete_task_usecase.dart';
export 'domain/usecases/toggle_task_completion_usecase.dart';
export 'domain/usecases/search_tasks_usecase.dart';
export 'domain/usecases/get_task_count_by_category_usecase.dart';

// Data - Models
export 'data/models/task_model.dart';

// Data - Data Sources
export 'data/datasources/task_local_datasource.dart';

// Data - Repositories
export 'data/repositories/task_repository_impl.dart';

// Presentation - BLoC
export 'presentation/bloc/task_bloc.dart';
export 'presentation/bloc/task_edit_bloc.dart';
