// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_edit_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskEditEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskEditEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEditEvent()';
}


}

/// @nodoc
class $TaskEditEventCopyWith<$Res>  {
$TaskEditEventCopyWith(TaskEditEvent _, $Res Function(TaskEditEvent) __);
}


/// Adds pattern-matching-related methods to [TaskEditEvent].
extension TaskEditEventPatterns on TaskEditEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadTask value)?  loadTask,TResult Function( _UpdateTitle value)?  updateTitle,TResult Function( _UpdateDescription value)?  updateDescription,TResult Function( _UpdatePriority value)?  updatePriority,TResult Function( _UpdateDueDate value)?  updateDueDate,TResult Function( _UpdateCategory value)?  updateCategory,TResult Function( _SaveTask value)?  saveTask,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTask() when loadTask != null:
return loadTask(_that);case _UpdateTitle() when updateTitle != null:
return updateTitle(_that);case _UpdateDescription() when updateDescription != null:
return updateDescription(_that);case _UpdatePriority() when updatePriority != null:
return updatePriority(_that);case _UpdateDueDate() when updateDueDate != null:
return updateDueDate(_that);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that);case _SaveTask() when saveTask != null:
return saveTask(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadTask value)  loadTask,required TResult Function( _UpdateTitle value)  updateTitle,required TResult Function( _UpdateDescription value)  updateDescription,required TResult Function( _UpdatePriority value)  updatePriority,required TResult Function( _UpdateDueDate value)  updateDueDate,required TResult Function( _UpdateCategory value)  updateCategory,required TResult Function( _SaveTask value)  saveTask,}){
final _that = this;
switch (_that) {
case _LoadTask():
return loadTask(_that);case _UpdateTitle():
return updateTitle(_that);case _UpdateDescription():
return updateDescription(_that);case _UpdatePriority():
return updatePriority(_that);case _UpdateDueDate():
return updateDueDate(_that);case _UpdateCategory():
return updateCategory(_that);case _SaveTask():
return saveTask(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadTask value)?  loadTask,TResult? Function( _UpdateTitle value)?  updateTitle,TResult? Function( _UpdateDescription value)?  updateDescription,TResult? Function( _UpdatePriority value)?  updatePriority,TResult? Function( _UpdateDueDate value)?  updateDueDate,TResult? Function( _UpdateCategory value)?  updateCategory,TResult? Function( _SaveTask value)?  saveTask,}){
final _that = this;
switch (_that) {
case _LoadTask() when loadTask != null:
return loadTask(_that);case _UpdateTitle() when updateTitle != null:
return updateTitle(_that);case _UpdateDescription() when updateDescription != null:
return updateDescription(_that);case _UpdatePriority() when updatePriority != null:
return updatePriority(_that);case _UpdateDueDate() when updateDueDate != null:
return updateDueDate(_that);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that);case _SaveTask() when saveTask != null:
return saveTask(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? taskId)?  loadTask,TResult Function( String title)?  updateTitle,TResult Function( String description)?  updateDescription,TResult Function( Priority priority)?  updatePriority,TResult Function( DateTime? dueDate)?  updateDueDate,TResult Function( String? categoryId)?  updateCategory,TResult Function()?  saveTask,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTask() when loadTask != null:
return loadTask(_that.taskId);case _UpdateTitle() when updateTitle != null:
return updateTitle(_that.title);case _UpdateDescription() when updateDescription != null:
return updateDescription(_that.description);case _UpdatePriority() when updatePriority != null:
return updatePriority(_that.priority);case _UpdateDueDate() when updateDueDate != null:
return updateDueDate(_that.dueDate);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that.categoryId);case _SaveTask() when saveTask != null:
return saveTask();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? taskId)  loadTask,required TResult Function( String title)  updateTitle,required TResult Function( String description)  updateDescription,required TResult Function( Priority priority)  updatePriority,required TResult Function( DateTime? dueDate)  updateDueDate,required TResult Function( String? categoryId)  updateCategory,required TResult Function()  saveTask,}) {final _that = this;
switch (_that) {
case _LoadTask():
return loadTask(_that.taskId);case _UpdateTitle():
return updateTitle(_that.title);case _UpdateDescription():
return updateDescription(_that.description);case _UpdatePriority():
return updatePriority(_that.priority);case _UpdateDueDate():
return updateDueDate(_that.dueDate);case _UpdateCategory():
return updateCategory(_that.categoryId);case _SaveTask():
return saveTask();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? taskId)?  loadTask,TResult? Function( String title)?  updateTitle,TResult? Function( String description)?  updateDescription,TResult? Function( Priority priority)?  updatePriority,TResult? Function( DateTime? dueDate)?  updateDueDate,TResult? Function( String? categoryId)?  updateCategory,TResult? Function()?  saveTask,}) {final _that = this;
switch (_that) {
case _LoadTask() when loadTask != null:
return loadTask(_that.taskId);case _UpdateTitle() when updateTitle != null:
return updateTitle(_that.title);case _UpdateDescription() when updateDescription != null:
return updateDescription(_that.description);case _UpdatePriority() when updatePriority != null:
return updatePriority(_that.priority);case _UpdateDueDate() when updateDueDate != null:
return updateDueDate(_that.dueDate);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that.categoryId);case _SaveTask() when saveTask != null:
return saveTask();case _:
  return null;

}
}

}

/// @nodoc


class _LoadTask implements TaskEditEvent {
  const _LoadTask(this.taskId);
  

 final  String? taskId;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadTaskCopyWith<_LoadTask> get copyWith => __$LoadTaskCopyWithImpl<_LoadTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTask&&(identical(other.taskId, taskId) || other.taskId == taskId));
}


@override
int get hashCode => Object.hash(runtimeType,taskId);

@override
String toString() {
  return 'TaskEditEvent.loadTask(taskId: $taskId)';
}


}

/// @nodoc
abstract mixin class _$LoadTaskCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$LoadTaskCopyWith(_LoadTask value, $Res Function(_LoadTask) _then) = __$LoadTaskCopyWithImpl;
@useResult
$Res call({
 String? taskId
});




}
/// @nodoc
class __$LoadTaskCopyWithImpl<$Res>
    implements _$LoadTaskCopyWith<$Res> {
  __$LoadTaskCopyWithImpl(this._self, this._then);

  final _LoadTask _self;
  final $Res Function(_LoadTask) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = freezed,}) {
  return _then(_LoadTask(
freezed == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _UpdateTitle implements TaskEditEvent {
  const _UpdateTitle(this.title);
  

 final  String title;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateTitleCopyWith<_UpdateTitle> get copyWith => __$UpdateTitleCopyWithImpl<_UpdateTitle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateTitle&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,title);

@override
String toString() {
  return 'TaskEditEvent.updateTitle(title: $title)';
}


}

/// @nodoc
abstract mixin class _$UpdateTitleCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$UpdateTitleCopyWith(_UpdateTitle value, $Res Function(_UpdateTitle) _then) = __$UpdateTitleCopyWithImpl;
@useResult
$Res call({
 String title
});




}
/// @nodoc
class __$UpdateTitleCopyWithImpl<$Res>
    implements _$UpdateTitleCopyWith<$Res> {
  __$UpdateTitleCopyWithImpl(this._self, this._then);

  final _UpdateTitle _self;
  final $Res Function(_UpdateTitle) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,}) {
  return _then(_UpdateTitle(
null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdateDescription implements TaskEditEvent {
  const _UpdateDescription(this.description);
  

 final  String description;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateDescriptionCopyWith<_UpdateDescription> get copyWith => __$UpdateDescriptionCopyWithImpl<_UpdateDescription>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateDescription&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,description);

@override
String toString() {
  return 'TaskEditEvent.updateDescription(description: $description)';
}


}

/// @nodoc
abstract mixin class _$UpdateDescriptionCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$UpdateDescriptionCopyWith(_UpdateDescription value, $Res Function(_UpdateDescription) _then) = __$UpdateDescriptionCopyWithImpl;
@useResult
$Res call({
 String description
});




}
/// @nodoc
class __$UpdateDescriptionCopyWithImpl<$Res>
    implements _$UpdateDescriptionCopyWith<$Res> {
  __$UpdateDescriptionCopyWithImpl(this._self, this._then);

  final _UpdateDescription _self;
  final $Res Function(_UpdateDescription) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? description = null,}) {
  return _then(_UpdateDescription(
null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdatePriority implements TaskEditEvent {
  const _UpdatePriority(this.priority);
  

 final  Priority priority;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePriorityCopyWith<_UpdatePriority> get copyWith => __$UpdatePriorityCopyWithImpl<_UpdatePriority>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePriority&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,priority);

@override
String toString() {
  return 'TaskEditEvent.updatePriority(priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$UpdatePriorityCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$UpdatePriorityCopyWith(_UpdatePriority value, $Res Function(_UpdatePriority) _then) = __$UpdatePriorityCopyWithImpl;
@useResult
$Res call({
 Priority priority
});




}
/// @nodoc
class __$UpdatePriorityCopyWithImpl<$Res>
    implements _$UpdatePriorityCopyWith<$Res> {
  __$UpdatePriorityCopyWithImpl(this._self, this._then);

  final _UpdatePriority _self;
  final $Res Function(_UpdatePriority) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? priority = null,}) {
  return _then(_UpdatePriority(
null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,
  ));
}


}

/// @nodoc


class _UpdateDueDate implements TaskEditEvent {
  const _UpdateDueDate(this.dueDate);
  

 final  DateTime? dueDate;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateDueDateCopyWith<_UpdateDueDate> get copyWith => __$UpdateDueDateCopyWithImpl<_UpdateDueDate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateDueDate&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate));
}


@override
int get hashCode => Object.hash(runtimeType,dueDate);

@override
String toString() {
  return 'TaskEditEvent.updateDueDate(dueDate: $dueDate)';
}


}

/// @nodoc
abstract mixin class _$UpdateDueDateCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$UpdateDueDateCopyWith(_UpdateDueDate value, $Res Function(_UpdateDueDate) _then) = __$UpdateDueDateCopyWithImpl;
@useResult
$Res call({
 DateTime? dueDate
});




}
/// @nodoc
class __$UpdateDueDateCopyWithImpl<$Res>
    implements _$UpdateDueDateCopyWith<$Res> {
  __$UpdateDueDateCopyWithImpl(this._self, this._then);

  final _UpdateDueDate _self;
  final $Res Function(_UpdateDueDate) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dueDate = freezed,}) {
  return _then(_UpdateDueDate(
freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class _UpdateCategory implements TaskEditEvent {
  const _UpdateCategory(this.categoryId);
  

 final  String? categoryId;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCategoryCopyWith<_UpdateCategory> get copyWith => __$UpdateCategoryCopyWithImpl<_UpdateCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCategory&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId);

@override
String toString() {
  return 'TaskEditEvent.updateCategory(categoryId: $categoryId)';
}


}

/// @nodoc
abstract mixin class _$UpdateCategoryCopyWith<$Res> implements $TaskEditEventCopyWith<$Res> {
  factory _$UpdateCategoryCopyWith(_UpdateCategory value, $Res Function(_UpdateCategory) _then) = __$UpdateCategoryCopyWithImpl;
@useResult
$Res call({
 String? categoryId
});




}
/// @nodoc
class __$UpdateCategoryCopyWithImpl<$Res>
    implements _$UpdateCategoryCopyWith<$Res> {
  __$UpdateCategoryCopyWithImpl(this._self, this._then);

  final _UpdateCategory _self;
  final $Res Function(_UpdateCategory) _then;

/// Create a copy of TaskEditEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,}) {
  return _then(_UpdateCategory(
freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _SaveTask implements TaskEditEvent {
  const _SaveTask();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveTask);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEditEvent.saveTask()';
}


}




/// @nodoc
mixin _$TaskEditState {

/// Original task being edited (null for create mode)
 Task? get task;/// Current title value
 String get title;/// Current description value
 String get description;/// Current priority value
 Priority get priority;/// Current due date value
 DateTime? get dueDate;/// Current category ID value
 String? get categoryId;/// Loading state (when loading task)
 bool get isLoading;/// Saving state (when creating/updating)
 bool get isSaving;/// Edit mode flag (true = edit, false = create)
 bool get isEditMode;/// Error state
 Failure? get failure;
/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskEditStateCopyWith<TaskEditState> get copyWith => _$TaskEditStateCopyWithImpl<TaskEditState>(this as TaskEditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskEditState&&(identical(other.task, task) || other.task == task)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isEditMode, isEditMode) || other.isEditMode == isEditMode)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,task,title,description,priority,dueDate,categoryId,isLoading,isSaving,isEditMode,failure);

@override
String toString() {
  return 'TaskEditState(task: $task, title: $title, description: $description, priority: $priority, dueDate: $dueDate, categoryId: $categoryId, isLoading: $isLoading, isSaving: $isSaving, isEditMode: $isEditMode, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TaskEditStateCopyWith<$Res>  {
  factory $TaskEditStateCopyWith(TaskEditState value, $Res Function(TaskEditState) _then) = _$TaskEditStateCopyWithImpl;
@useResult
$Res call({
 Task? task, String title, String description, Priority priority, DateTime? dueDate, String? categoryId, bool isLoading, bool isSaving, bool isEditMode, Failure? failure
});


$TaskCopyWith<$Res>? get task;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$TaskEditStateCopyWithImpl<$Res>
    implements $TaskEditStateCopyWith<$Res> {
  _$TaskEditStateCopyWithImpl(this._self, this._then);

  final TaskEditState _self;
  final $Res Function(TaskEditState) _then;

/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? task = freezed,Object? title = null,Object? description = null,Object? priority = null,Object? dueDate = freezed,Object? categoryId = freezed,Object? isLoading = null,Object? isSaving = null,Object? isEditMode = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
task: freezed == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isEditMode: null == isEditMode ? _self.isEditMode : isEditMode // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res>? get task {
    if (_self.task == null) {
    return null;
  }

  return $TaskCopyWith<$Res>(_self.task!, (value) {
    return _then(_self.copyWith(task: value));
  });
}/// Create a copy of TaskEditState
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


/// Adds pattern-matching-related methods to [TaskEditState].
extension TaskEditStatePatterns on TaskEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskEditState value)  $default,){
final _that = this;
switch (_that) {
case _TaskEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskEditState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Task? task,  String title,  String description,  Priority priority,  DateTime? dueDate,  String? categoryId,  bool isLoading,  bool isSaving,  bool isEditMode,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskEditState() when $default != null:
return $default(_that.task,_that.title,_that.description,_that.priority,_that.dueDate,_that.categoryId,_that.isLoading,_that.isSaving,_that.isEditMode,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Task? task,  String title,  String description,  Priority priority,  DateTime? dueDate,  String? categoryId,  bool isLoading,  bool isSaving,  bool isEditMode,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _TaskEditState():
return $default(_that.task,_that.title,_that.description,_that.priority,_that.dueDate,_that.categoryId,_that.isLoading,_that.isSaving,_that.isEditMode,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Task? task,  String title,  String description,  Priority priority,  DateTime? dueDate,  String? categoryId,  bool isLoading,  bool isSaving,  bool isEditMode,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _TaskEditState() when $default != null:
return $default(_that.task,_that.title,_that.description,_that.priority,_that.dueDate,_that.categoryId,_that.isLoading,_that.isSaving,_that.isEditMode,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _TaskEditState extends TaskEditState {
  const _TaskEditState({this.task, this.title = '', this.description = '', this.priority = Priority.medium, this.dueDate, this.categoryId, this.isLoading = false, this.isSaving = false, this.isEditMode = false, this.failure}): super._();
  

/// Original task being edited (null for create mode)
@override final  Task? task;
/// Current title value
@override@JsonKey() final  String title;
/// Current description value
@override@JsonKey() final  String description;
/// Current priority value
@override@JsonKey() final  Priority priority;
/// Current due date value
@override final  DateTime? dueDate;
/// Current category ID value
@override final  String? categoryId;
/// Loading state (when loading task)
@override@JsonKey() final  bool isLoading;
/// Saving state (when creating/updating)
@override@JsonKey() final  bool isSaving;
/// Edit mode flag (true = edit, false = create)
@override@JsonKey() final  bool isEditMode;
/// Error state
@override final  Failure? failure;

/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskEditStateCopyWith<_TaskEditState> get copyWith => __$TaskEditStateCopyWithImpl<_TaskEditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskEditState&&(identical(other.task, task) || other.task == task)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isEditMode, isEditMode) || other.isEditMode == isEditMode)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,task,title,description,priority,dueDate,categoryId,isLoading,isSaving,isEditMode,failure);

@override
String toString() {
  return 'TaskEditState(task: $task, title: $title, description: $description, priority: $priority, dueDate: $dueDate, categoryId: $categoryId, isLoading: $isLoading, isSaving: $isSaving, isEditMode: $isEditMode, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$TaskEditStateCopyWith<$Res> implements $TaskEditStateCopyWith<$Res> {
  factory _$TaskEditStateCopyWith(_TaskEditState value, $Res Function(_TaskEditState) _then) = __$TaskEditStateCopyWithImpl;
@override @useResult
$Res call({
 Task? task, String title, String description, Priority priority, DateTime? dueDate, String? categoryId, bool isLoading, bool isSaving, bool isEditMode, Failure? failure
});


@override $TaskCopyWith<$Res>? get task;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$TaskEditStateCopyWithImpl<$Res>
    implements _$TaskEditStateCopyWith<$Res> {
  __$TaskEditStateCopyWithImpl(this._self, this._then);

  final _TaskEditState _self;
  final $Res Function(_TaskEditState) _then;

/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? task = freezed,Object? title = null,Object? description = null,Object? priority = null,Object? dueDate = freezed,Object? categoryId = freezed,Object? isLoading = null,Object? isSaving = null,Object? isEditMode = null,Object? failure = freezed,}) {
  return _then(_TaskEditState(
task: freezed == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isEditMode: null == isEditMode ? _self.isEditMode : isEditMode // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of TaskEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCopyWith<$Res>? get task {
    if (_self.task == null) {
    return null;
  }

  return $TaskCopyWith<$Res>(_self.task!, (value) {
    return _then(_self.copyWith(task: value));
  });
}/// Create a copy of TaskEditState
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
mixin _$TaskEditUiEffect {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskEditUiEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEditUiEffect()';
}


}

/// @nodoc
class $TaskEditUiEffectCopyWith<$Res>  {
$TaskEditUiEffectCopyWith(TaskEditUiEffect _, $Res Function(TaskEditUiEffect) __);
}


/// Adds pattern-matching-related methods to [TaskEditUiEffect].
extension TaskEditUiEffectPatterns on TaskEditUiEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ShowSuccess value)?  showSuccess,TResult Function( _ShowError value)?  showError,TResult Function( _NavigateBack value)?  navigateBack,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _NavigateBack() when navigateBack != null:
return navigateBack(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ShowSuccess value)  showSuccess,required TResult Function( _ShowError value)  showError,required TResult Function( _NavigateBack value)  navigateBack,}){
final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that);case _ShowError():
return showError(_that);case _NavigateBack():
return navigateBack(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ShowSuccess value)?  showSuccess,TResult? Function( _ShowError value)?  showError,TResult? Function( _NavigateBack value)?  navigateBack,}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _NavigateBack() when navigateBack != null:
return navigateBack(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  showSuccess,TResult Function( String message)?  showError,TResult Function()?  navigateBack,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _NavigateBack() when navigateBack != null:
return navigateBack();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  showSuccess,required TResult Function( String message)  showError,required TResult Function()  navigateBack,}) {final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that.message);case _ShowError():
return showError(_that.message);case _NavigateBack():
return navigateBack();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  showSuccess,TResult? Function( String message)?  showError,TResult? Function()?  navigateBack,}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _NavigateBack() when navigateBack != null:
return navigateBack();case _:
  return null;

}
}

}

/// @nodoc


class _ShowSuccess implements TaskEditUiEffect {
  const _ShowSuccess(this.message);
  

 final  String message;

/// Create a copy of TaskEditUiEffect
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
  return 'TaskEditUiEffect.showSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowSuccessCopyWith<$Res> implements $TaskEditUiEffectCopyWith<$Res> {
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

/// Create a copy of TaskEditUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowSuccess(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ShowError implements TaskEditUiEffect {
  const _ShowError(this.message);
  

 final  String message;

/// Create a copy of TaskEditUiEffect
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
  return 'TaskEditUiEffect.showError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowErrorCopyWith<$Res> implements $TaskEditUiEffectCopyWith<$Res> {
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

/// Create a copy of TaskEditUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _NavigateBack implements TaskEditUiEffect {
  const _NavigateBack();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NavigateBack);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskEditUiEffect.navigateBack()';
}


}




// dart format on
