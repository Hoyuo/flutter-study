// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEvent()';
}


}

/// @nodoc
class $TaskEventCopyWith<$Res>  {
$TaskEventCopyWith(TaskEvent _, $Res Function(TaskEvent) __);
}


/// Adds pattern-matching-related methods to [TaskEvent].
extension TaskEventPatterns on TaskEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadTasks value)?  loadTasks,TResult Function( _LoadMoreTasks value)?  loadMoreTasks,TResult Function( _SearchTasks value)?  searchTasks,TResult Function( _ToggleCompletion value)?  toggleCompletion,TResult Function( _DeleteTask value)?  deleteTask,TResult Function( _ApplyFilter value)?  applyFilter,TResult Function( _ClearFilter value)?  clearFilter,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTasks() when loadTasks != null:
return loadTasks(_that);case _LoadMoreTasks() when loadMoreTasks != null:
return loadMoreTasks(_that);case _SearchTasks() when searchTasks != null:
return searchTasks(_that);case _ToggleCompletion() when toggleCompletion != null:
return toggleCompletion(_that);case _DeleteTask() when deleteTask != null:
return deleteTask(_that);case _ApplyFilter() when applyFilter != null:
return applyFilter(_that);case _ClearFilter() when clearFilter != null:
return clearFilter(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadTasks value)  loadTasks,required TResult Function( _LoadMoreTasks value)  loadMoreTasks,required TResult Function( _SearchTasks value)  searchTasks,required TResult Function( _ToggleCompletion value)  toggleCompletion,required TResult Function( _DeleteTask value)  deleteTask,required TResult Function( _ApplyFilter value)  applyFilter,required TResult Function( _ClearFilter value)  clearFilter,}){
final _that = this;
switch (_that) {
case _LoadTasks():
return loadTasks(_that);case _LoadMoreTasks():
return loadMoreTasks(_that);case _SearchTasks():
return searchTasks(_that);case _ToggleCompletion():
return toggleCompletion(_that);case _DeleteTask():
return deleteTask(_that);case _ApplyFilter():
return applyFilter(_that);case _ClearFilter():
return clearFilter(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadTasks value)?  loadTasks,TResult? Function( _LoadMoreTasks value)?  loadMoreTasks,TResult? Function( _SearchTasks value)?  searchTasks,TResult? Function( _ToggleCompletion value)?  toggleCompletion,TResult? Function( _DeleteTask value)?  deleteTask,TResult? Function( _ApplyFilter value)?  applyFilter,TResult? Function( _ClearFilter value)?  clearFilter,}){
final _that = this;
switch (_that) {
case _LoadTasks() when loadTasks != null:
return loadTasks(_that);case _LoadMoreTasks() when loadMoreTasks != null:
return loadMoreTasks(_that);case _SearchTasks() when searchTasks != null:
return searchTasks(_that);case _ToggleCompletion() when toggleCompletion != null:
return toggleCompletion(_that);case _DeleteTask() when deleteTask != null:
return deleteTask(_that);case _ApplyFilter() when applyFilter != null:
return applyFilter(_that);case _ClearFilter() when clearFilter != null:
return clearFilter(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadTasks,TResult Function()?  loadMoreTasks,TResult Function( String query)?  searchTasks,TResult Function( String taskId)?  toggleCompletion,TResult Function( String taskId,  String taskTitle)?  deleteTask,TResult Function( bool? isCompleted,  Priority? priority,  String? categoryId,  TaskSortBy? sortBy,  bool? ascending,  bool? todayOnly)?  applyFilter,TResult Function()?  clearFilter,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTasks() when loadTasks != null:
return loadTasks();case _LoadMoreTasks() when loadMoreTasks != null:
return loadMoreTasks();case _SearchTasks() when searchTasks != null:
return searchTasks(_that.query);case _ToggleCompletion() when toggleCompletion != null:
return toggleCompletion(_that.taskId);case _DeleteTask() when deleteTask != null:
return deleteTask(_that.taskId,_that.taskTitle);case _ApplyFilter() when applyFilter != null:
return applyFilter(_that.isCompleted,_that.priority,_that.categoryId,_that.sortBy,_that.ascending,_that.todayOnly);case _ClearFilter() when clearFilter != null:
return clearFilter();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadTasks,required TResult Function()  loadMoreTasks,required TResult Function( String query)  searchTasks,required TResult Function( String taskId)  toggleCompletion,required TResult Function( String taskId,  String taskTitle)  deleteTask,required TResult Function( bool? isCompleted,  Priority? priority,  String? categoryId,  TaskSortBy? sortBy,  bool? ascending,  bool? todayOnly)  applyFilter,required TResult Function()  clearFilter,}) {final _that = this;
switch (_that) {
case _LoadTasks():
return loadTasks();case _LoadMoreTasks():
return loadMoreTasks();case _SearchTasks():
return searchTasks(_that.query);case _ToggleCompletion():
return toggleCompletion(_that.taskId);case _DeleteTask():
return deleteTask(_that.taskId,_that.taskTitle);case _ApplyFilter():
return applyFilter(_that.isCompleted,_that.priority,_that.categoryId,_that.sortBy,_that.ascending,_that.todayOnly);case _ClearFilter():
return clearFilter();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadTasks,TResult? Function()?  loadMoreTasks,TResult? Function( String query)?  searchTasks,TResult? Function( String taskId)?  toggleCompletion,TResult? Function( String taskId,  String taskTitle)?  deleteTask,TResult? Function( bool? isCompleted,  Priority? priority,  String? categoryId,  TaskSortBy? sortBy,  bool? ascending,  bool? todayOnly)?  applyFilter,TResult? Function()?  clearFilter,}) {final _that = this;
switch (_that) {
case _LoadTasks() when loadTasks != null:
return loadTasks();case _LoadMoreTasks() when loadMoreTasks != null:
return loadMoreTasks();case _SearchTasks() when searchTasks != null:
return searchTasks(_that.query);case _ToggleCompletion() when toggleCompletion != null:
return toggleCompletion(_that.taskId);case _DeleteTask() when deleteTask != null:
return deleteTask(_that.taskId,_that.taskTitle);case _ApplyFilter() when applyFilter != null:
return applyFilter(_that.isCompleted,_that.priority,_that.categoryId,_that.sortBy,_that.ascending,_that.todayOnly);case _ClearFilter() when clearFilter != null:
return clearFilter();case _:
  return null;

}
}

}

/// @nodoc


class _LoadTasks implements TaskEvent {
  const _LoadTasks();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTasks);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEvent.loadTasks()';
}


}




/// @nodoc


class _LoadMoreTasks implements TaskEvent {
  const _LoadMoreTasks();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadMoreTasks);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEvent.loadMoreTasks()';
}


}




/// @nodoc


class _SearchTasks implements TaskEvent {
  const _SearchTasks(this.query);
  

 final  String query;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchTasksCopyWith<_SearchTasks> get copyWith => __$SearchTasksCopyWithImpl<_SearchTasks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchTasks&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'TaskEvent.searchTasks(query: $query)';
}


}

/// @nodoc
abstract mixin class _$SearchTasksCopyWith<$Res> implements $TaskEventCopyWith<$Res> {
  factory _$SearchTasksCopyWith(_SearchTasks value, $Res Function(_SearchTasks) _then) = __$SearchTasksCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class __$SearchTasksCopyWithImpl<$Res>
    implements _$SearchTasksCopyWith<$Res> {
  __$SearchTasksCopyWithImpl(this._self, this._then);

  final _SearchTasks _self;
  final $Res Function(_SearchTasks) _then;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(_SearchTasks(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ToggleCompletion implements TaskEvent {
  const _ToggleCompletion(this.taskId);
  

 final  String taskId;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleCompletionCopyWith<_ToggleCompletion> get copyWith => __$ToggleCompletionCopyWithImpl<_ToggleCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToggleCompletion&&(identical(other.taskId, taskId) || other.taskId == taskId));
}


@override
int get hashCode => Object.hash(runtimeType,taskId);

@override
String toString() {
  return 'TaskEvent.toggleCompletion(taskId: $taskId)';
}


}

/// @nodoc
abstract mixin class _$ToggleCompletionCopyWith<$Res> implements $TaskEventCopyWith<$Res> {
  factory _$ToggleCompletionCopyWith(_ToggleCompletion value, $Res Function(_ToggleCompletion) _then) = __$ToggleCompletionCopyWithImpl;
@useResult
$Res call({
 String taskId
});




}
/// @nodoc
class __$ToggleCompletionCopyWithImpl<$Res>
    implements _$ToggleCompletionCopyWith<$Res> {
  __$ToggleCompletionCopyWithImpl(this._self, this._then);

  final _ToggleCompletion _self;
  final $Res Function(_ToggleCompletion) _then;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,}) {
  return _then(_ToggleCompletion(
null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeleteTask implements TaskEvent {
  const _DeleteTask({required this.taskId, required this.taskTitle});
  

 final  String taskId;
 final  String taskTitle;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteTaskCopyWith<_DeleteTask> get copyWith => __$DeleteTaskCopyWithImpl<_DeleteTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteTask&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle);

@override
String toString() {
  return 'TaskEvent.deleteTask(taskId: $taskId, taskTitle: $taskTitle)';
}


}

/// @nodoc
abstract mixin class _$DeleteTaskCopyWith<$Res> implements $TaskEventCopyWith<$Res> {
  factory _$DeleteTaskCopyWith(_DeleteTask value, $Res Function(_DeleteTask) _then) = __$DeleteTaskCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle
});




}
/// @nodoc
class __$DeleteTaskCopyWithImpl<$Res>
    implements _$DeleteTaskCopyWith<$Res> {
  __$DeleteTaskCopyWithImpl(this._self, this._then);

  final _DeleteTask _self;
  final $Res Function(_DeleteTask) _then;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,}) {
  return _then(_DeleteTask(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ApplyFilter implements TaskEvent {
  const _ApplyFilter({this.isCompleted, this.priority, this.categoryId, this.sortBy, this.ascending, this.todayOnly});
  

 final  bool? isCompleted;
 final  Priority? priority;
 final  String? categoryId;
 final  TaskSortBy? sortBy;
 final  bool? ascending;
 final  bool? todayOnly;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplyFilterCopyWith<_ApplyFilter> get copyWith => __$ApplyFilterCopyWithImpl<_ApplyFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplyFilter&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.ascending, ascending) || other.ascending == ascending)&&(identical(other.todayOnly, todayOnly) || other.todayOnly == todayOnly));
}


@override
int get hashCode => Object.hash(runtimeType,isCompleted,priority,categoryId,sortBy,ascending,todayOnly);

@override
String toString() {
  return 'TaskEvent.applyFilter(isCompleted: $isCompleted, priority: $priority, categoryId: $categoryId, sortBy: $sortBy, ascending: $ascending, todayOnly: $todayOnly)';
}


}

/// @nodoc
abstract mixin class _$ApplyFilterCopyWith<$Res> implements $TaskEventCopyWith<$Res> {
  factory _$ApplyFilterCopyWith(_ApplyFilter value, $Res Function(_ApplyFilter) _then) = __$ApplyFilterCopyWithImpl;
@useResult
$Res call({
 bool? isCompleted, Priority? priority, String? categoryId, TaskSortBy? sortBy, bool? ascending, bool? todayOnly
});




}
/// @nodoc
class __$ApplyFilterCopyWithImpl<$Res>
    implements _$ApplyFilterCopyWith<$Res> {
  __$ApplyFilterCopyWithImpl(this._self, this._then);

  final _ApplyFilter _self;
  final $Res Function(_ApplyFilter) _then;

/// Create a copy of TaskEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isCompleted = freezed,Object? priority = freezed,Object? categoryId = freezed,Object? sortBy = freezed,Object? ascending = freezed,Object? todayOnly = freezed,}) {
  return _then(_ApplyFilter(
isCompleted: freezed == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as TaskSortBy?,ascending: freezed == ascending ? _self.ascending : ascending // ignore: cast_nullable_to_non_nullable
as bool?,todayOnly: freezed == todayOnly ? _self.todayOnly : todayOnly // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc


class _ClearFilter implements TaskEvent {
  const _ClearFilter();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClearFilter);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEvent.clearFilter()';
}


}




/// @nodoc
mixin _$TaskState {

/// List of tasks
 List<Task> get tasks;/// Loading state
 bool get isLoading;/// Loading more tasks (pagination)
 bool get isLoadingMore;/// Has reached end of list
 bool get hasReachedEnd;/// Current search query
 String get searchQuery;/// Current filter parameters
 GetTasksParams get currentParams;/// Error state
 Failure? get failure;
/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStateCopyWith<TaskState> get copyWith => _$TaskStateCopyWithImpl<TaskState>(this as TaskState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskState&&const DeepCollectionEquality().equals(other.tasks, tasks)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasReachedEnd, hasReachedEnd) || other.hasReachedEnd == hasReachedEnd)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.currentParams, currentParams) || other.currentParams == currentParams)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tasks),isLoading,isLoadingMore,hasReachedEnd,searchQuery,currentParams,failure);

@override
String toString() {
  return 'TaskState(tasks: $tasks, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasReachedEnd: $hasReachedEnd, searchQuery: $searchQuery, currentParams: $currentParams, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TaskStateCopyWith<$Res>  {
  factory $TaskStateCopyWith(TaskState value, $Res Function(TaskState) _then) = _$TaskStateCopyWithImpl;
@useResult
$Res call({
 List<Task> tasks, bool isLoading, bool isLoadingMore, bool hasReachedEnd, String searchQuery, GetTasksParams currentParams, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$TaskStateCopyWithImpl<$Res>
    implements $TaskStateCopyWith<$Res> {
  _$TaskStateCopyWithImpl(this._self, this._then);

  final TaskState _self;
  final $Res Function(TaskState) _then;

/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tasks = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasReachedEnd = null,Object? searchQuery = null,Object? currentParams = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasReachedEnd: null == hasReachedEnd ? _self.hasReachedEnd : hasReachedEnd // ignore: cast_nullable_to_non_nullable
as bool,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,currentParams: null == currentParams ? _self.currentParams : currentParams // ignore: cast_nullable_to_non_nullable
as GetTasksParams,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskState].
extension TaskStatePatterns on TaskState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskState value)  $default,){
final _that = this;
switch (_that) {
case _TaskState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Task> tasks,  bool isLoading,  bool isLoadingMore,  bool hasReachedEnd,  String searchQuery,  GetTasksParams currentParams,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskState() when $default != null:
return $default(_that.tasks,_that.isLoading,_that.isLoadingMore,_that.hasReachedEnd,_that.searchQuery,_that.currentParams,_that.failure);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Task> tasks,  bool isLoading,  bool isLoadingMore,  bool hasReachedEnd,  String searchQuery,  GetTasksParams currentParams,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _TaskState():
return $default(_that.tasks,_that.isLoading,_that.isLoadingMore,_that.hasReachedEnd,_that.searchQuery,_that.currentParams,_that.failure);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Task> tasks,  bool isLoading,  bool isLoadingMore,  bool hasReachedEnd,  String searchQuery,  GetTasksParams currentParams,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _TaskState() when $default != null:
return $default(_that.tasks,_that.isLoading,_that.isLoadingMore,_that.hasReachedEnd,_that.searchQuery,_that.currentParams,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _TaskState extends TaskState {
  const _TaskState({final  List<Task> tasks = const [], this.isLoading = false, this.isLoadingMore = false, this.hasReachedEnd = false, this.searchQuery = '', this.currentParams = const GetTasksParams.defaults(), this.failure}): _tasks = tasks,super._();
  

/// List of tasks
 final  List<Task> _tasks;
/// List of tasks
@override@JsonKey() List<Task> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

/// Loading state
@override@JsonKey() final  bool isLoading;
/// Loading more tasks (pagination)
@override@JsonKey() final  bool isLoadingMore;
/// Has reached end of list
@override@JsonKey() final  bool hasReachedEnd;
/// Current search query
@override@JsonKey() final  String searchQuery;
/// Current filter parameters
@override@JsonKey() final  GetTasksParams currentParams;
/// Error state
@override final  Failure? failure;

/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskStateCopyWith<_TaskState> get copyWith => __$TaskStateCopyWithImpl<_TaskState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskState&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasReachedEnd, hasReachedEnd) || other.hasReachedEnd == hasReachedEnd)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.currentParams, currentParams) || other.currentParams == currentParams)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),isLoading,isLoadingMore,hasReachedEnd,searchQuery,currentParams,failure);

@override
String toString() {
  return 'TaskState(tasks: $tasks, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasReachedEnd: $hasReachedEnd, searchQuery: $searchQuery, currentParams: $currentParams, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$TaskStateCopyWith<$Res> implements $TaskStateCopyWith<$Res> {
  factory _$TaskStateCopyWith(_TaskState value, $Res Function(_TaskState) _then) = __$TaskStateCopyWithImpl;
@override @useResult
$Res call({
 List<Task> tasks, bool isLoading, bool isLoadingMore, bool hasReachedEnd, String searchQuery, GetTasksParams currentParams, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$TaskStateCopyWithImpl<$Res>
    implements _$TaskStateCopyWith<$Res> {
  __$TaskStateCopyWithImpl(this._self, this._then);

  final _TaskState _self;
  final $Res Function(_TaskState) _then;

/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? isLoading = null,Object? isLoadingMore = null,Object? hasReachedEnd = null,Object? searchQuery = null,Object? currentParams = null,Object? failure = freezed,}) {
  return _then(_TaskState(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasReachedEnd: null == hasReachedEnd ? _self.hasReachedEnd : hasReachedEnd // ignore: cast_nullable_to_non_nullable
as bool,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,currentParams: null == currentParams ? _self.currentParams : currentParams // ignore: cast_nullable_to_non_nullable
as GetTasksParams,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of TaskState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$TaskUiEffect {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskUiEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskUiEffect()';
}


}

/// @nodoc
class $TaskUiEffectCopyWith<$Res>  {
$TaskUiEffectCopyWith(TaskUiEffect _, $Res Function(TaskUiEffect) __);
}


/// Adds pattern-matching-related methods to [TaskUiEffect].
extension TaskUiEffectPatterns on TaskUiEffect {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ShowSuccess value)?  showSuccess,TResult Function( _ShowError value)?  showError,TResult Function( _ConfirmDelete value)?  confirmDelete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ShowSuccess value)  showSuccess,required TResult Function( _ShowError value)  showError,required TResult Function( _ConfirmDelete value)  confirmDelete,}){
final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that);case _ShowError():
return showError(_that);case _ConfirmDelete():
return confirmDelete(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ShowSuccess value)?  showSuccess,TResult? Function( _ShowError value)?  showError,TResult? Function( _ConfirmDelete value)?  confirmDelete,}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  showSuccess,TResult Function( String message)?  showError,TResult Function( String taskId,  String taskTitle,  Future<void> Function() onConfirm)?  confirmDelete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that.taskId,_that.taskTitle,_that.onConfirm);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  showSuccess,required TResult Function( String message)  showError,required TResult Function( String taskId,  String taskTitle,  Future<void> Function() onConfirm)  confirmDelete,}) {final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that.message);case _ShowError():
return showError(_that.message);case _ConfirmDelete():
return confirmDelete(_that.taskId,_that.taskTitle,_that.onConfirm);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  showSuccess,TResult? Function( String message)?  showError,TResult? Function( String taskId,  String taskTitle,  Future<void> Function() onConfirm)?  confirmDelete,}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that.taskId,_that.taskTitle,_that.onConfirm);case _:
  return null;

}
}

}

/// @nodoc


class _ShowSuccess implements TaskUiEffect {
  const _ShowSuccess(this.message);
  

 final  String message;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowSuccessCopyWith<_ShowSuccess> get copyWith => __$ShowSuccessCopyWithImpl<_ShowSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TaskUiEffect.showSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowSuccessCopyWith<$Res> implements $TaskUiEffectCopyWith<$Res> {
  factory _$ShowSuccessCopyWith(_ShowSuccess value, $Res Function(_ShowSuccess) _then) = __$ShowSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ShowSuccessCopyWithImpl<$Res>
    implements _$ShowSuccessCopyWith<$Res> {
  __$ShowSuccessCopyWithImpl(this._self, this._then);

  final _ShowSuccess _self;
  final $Res Function(_ShowSuccess) _then;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowSuccess(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ShowError implements TaskUiEffect {
  const _ShowError(this.message);
  

 final  String message;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShowErrorCopyWith<_ShowError> get copyWith => __$ShowErrorCopyWithImpl<_ShowError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TaskUiEffect.showError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowErrorCopyWith<$Res> implements $TaskUiEffectCopyWith<$Res> {
  factory _$ShowErrorCopyWith(_ShowError value, $Res Function(_ShowError) _then) = __$ShowErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ShowErrorCopyWithImpl<$Res>
    implements _$ShowErrorCopyWith<$Res> {
  __$ShowErrorCopyWithImpl(this._self, this._then);

  final _ShowError _self;
  final $Res Function(_ShowError) _then;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ConfirmDelete implements TaskUiEffect {
  const _ConfirmDelete({required this.taskId, required this.taskTitle, required this.onConfirm});
  

 final  String taskId;
 final  String taskTitle;
 final  Future<void> Function() onConfirm;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmDeleteCopyWith<_ConfirmDelete> get copyWith => __$ConfirmDeleteCopyWithImpl<_ConfirmDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmDelete&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.onConfirm, onConfirm) || other.onConfirm == onConfirm));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,onConfirm);

@override
String toString() {
  return 'TaskUiEffect.confirmDelete(taskId: $taskId, taskTitle: $taskTitle, onConfirm: $onConfirm)';
}


}

/// @nodoc
abstract mixin class _$ConfirmDeleteCopyWith<$Res> implements $TaskUiEffectCopyWith<$Res> {
  factory _$ConfirmDeleteCopyWith(_ConfirmDelete value, $Res Function(_ConfirmDelete) _then) = __$ConfirmDeleteCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle, Future<void> Function() onConfirm
});




}
/// @nodoc
class __$ConfirmDeleteCopyWithImpl<$Res>
    implements _$ConfirmDeleteCopyWith<$Res> {
  __$ConfirmDeleteCopyWithImpl(this._self, this._then);

  final _ConfirmDelete _self;
  final $Res Function(_ConfirmDelete) _then;

/// Create a copy of TaskUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,Object? onConfirm = null,}) {
  return _then(_ConfirmDelete(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,onConfirm: null == onConfirm ? _self.onConfirm : onConfirm // ignore: cast_nullable_to_non_nullable
as Future<void> Function(),
  ));
}


}

// dart format on
