// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoryEvent()';
}


}

/// @nodoc
class $CategoryEventCopyWith<$Res>  {
$CategoryEventCopyWith(CategoryEvent _, $Res Function(CategoryEvent) __);
}


/// Adds pattern-matching-related methods to [CategoryEvent].
extension CategoryEventPatterns on CategoryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadCategories value)?  loadCategories,TResult Function( _CreateCategory value)?  createCategory,TResult Function( _UpdateCategory value)?  updateCategory,TResult Function( _DeleteCategory value)?  deleteCategory,TResult Function( _DeleteConfirmed value)?  deleteConfirmed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadCategories() when loadCategories != null:
return loadCategories(_that);case _CreateCategory() when createCategory != null:
return createCategory(_that);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that);case _DeleteCategory() when deleteCategory != null:
return deleteCategory(_that);case _DeleteConfirmed() when deleteConfirmed != null:
return deleteConfirmed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadCategories value)  loadCategories,required TResult Function( _CreateCategory value)  createCategory,required TResult Function( _UpdateCategory value)  updateCategory,required TResult Function( _DeleteCategory value)  deleteCategory,required TResult Function( _DeleteConfirmed value)  deleteConfirmed,}){
final _that = this;
switch (_that) {
case _LoadCategories():
return loadCategories(_that);case _CreateCategory():
return createCategory(_that);case _UpdateCategory():
return updateCategory(_that);case _DeleteCategory():
return deleteCategory(_that);case _DeleteConfirmed():
return deleteConfirmed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadCategories value)?  loadCategories,TResult? Function( _CreateCategory value)?  createCategory,TResult? Function( _UpdateCategory value)?  updateCategory,TResult? Function( _DeleteCategory value)?  deleteCategory,TResult? Function( _DeleteConfirmed value)?  deleteConfirmed,}){
final _that = this;
switch (_that) {
case _LoadCategories() when loadCategories != null:
return loadCategories(_that);case _CreateCategory() when createCategory != null:
return createCategory(_that);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that);case _DeleteCategory() when deleteCategory != null:
return deleteCategory(_that);case _DeleteConfirmed() when deleteConfirmed != null:
return deleteConfirmed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadCategories,TResult Function( Category category)?  createCategory,TResult Function( Category category)?  updateCategory,TResult Function( String categoryId,  String categoryName)?  deleteCategory,TResult Function( String categoryId,  String categoryName)?  deleteConfirmed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadCategories() when loadCategories != null:
return loadCategories();case _CreateCategory() when createCategory != null:
return createCategory(_that.category);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that.category);case _DeleteCategory() when deleteCategory != null:
return deleteCategory(_that.categoryId,_that.categoryName);case _DeleteConfirmed() when deleteConfirmed != null:
return deleteConfirmed(_that.categoryId,_that.categoryName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadCategories,required TResult Function( Category category)  createCategory,required TResult Function( Category category)  updateCategory,required TResult Function( String categoryId,  String categoryName)  deleteCategory,required TResult Function( String categoryId,  String categoryName)  deleteConfirmed,}) {final _that = this;
switch (_that) {
case _LoadCategories():
return loadCategories();case _CreateCategory():
return createCategory(_that.category);case _UpdateCategory():
return updateCategory(_that.category);case _DeleteCategory():
return deleteCategory(_that.categoryId,_that.categoryName);case _DeleteConfirmed():
return deleteConfirmed(_that.categoryId,_that.categoryName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadCategories,TResult? Function( Category category)?  createCategory,TResult? Function( Category category)?  updateCategory,TResult? Function( String categoryId,  String categoryName)?  deleteCategory,TResult? Function( String categoryId,  String categoryName)?  deleteConfirmed,}) {final _that = this;
switch (_that) {
case _LoadCategories() when loadCategories != null:
return loadCategories();case _CreateCategory() when createCategory != null:
return createCategory(_that.category);case _UpdateCategory() when updateCategory != null:
return updateCategory(_that.category);case _DeleteCategory() when deleteCategory != null:
return deleteCategory(_that.categoryId,_that.categoryName);case _DeleteConfirmed() when deleteConfirmed != null:
return deleteConfirmed(_that.categoryId,_that.categoryName);case _:
  return null;

}
}

}

/// @nodoc


class _LoadCategories implements CategoryEvent {
  const _LoadCategories();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadCategories);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoryEvent.loadCategories()';
}


}




/// @nodoc


class _CreateCategory implements CategoryEvent {
  const _CreateCategory({required this.category});
  

 final  Category category;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateCategoryCopyWith<_CreateCategory> get copyWith => __$CreateCategoryCopyWithImpl<_CreateCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateCategory&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,category);

@override
String toString() {
  return 'CategoryEvent.createCategory(category: $category)';
}


}

/// @nodoc
abstract mixin class _$CreateCategoryCopyWith<$Res> implements $CategoryEventCopyWith<$Res> {
  factory _$CreateCategoryCopyWith(_CreateCategory value, $Res Function(_CreateCategory) _then) = __$CreateCategoryCopyWithImpl;
@useResult
$Res call({
 Category category
});


$CategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$CreateCategoryCopyWithImpl<$Res>
    implements _$CreateCategoryCopyWith<$Res> {
  __$CreateCategoryCopyWithImpl(this._self, this._then);

  final _CreateCategory _self;
  final $Res Function(_CreateCategory) _then;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? category = null,}) {
  return _then(_CreateCategory(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,
  ));
}

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc


class _UpdateCategory implements CategoryEvent {
  const _UpdateCategory({required this.category});
  

 final  Category category;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateCategoryCopyWith<_UpdateCategory> get copyWith => __$UpdateCategoryCopyWithImpl<_UpdateCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateCategory&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,category);

@override
String toString() {
  return 'CategoryEvent.updateCategory(category: $category)';
}


}

/// @nodoc
abstract mixin class _$UpdateCategoryCopyWith<$Res> implements $CategoryEventCopyWith<$Res> {
  factory _$UpdateCategoryCopyWith(_UpdateCategory value, $Res Function(_UpdateCategory) _then) = __$UpdateCategoryCopyWithImpl;
@useResult
$Res call({
 Category category
});


$CategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$UpdateCategoryCopyWithImpl<$Res>
    implements _$UpdateCategoryCopyWith<$Res> {
  __$UpdateCategoryCopyWithImpl(this._self, this._then);

  final _UpdateCategory _self;
  final $Res Function(_UpdateCategory) _then;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? category = null,}) {
  return _then(_UpdateCategory(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,
  ));
}

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc


class _DeleteCategory implements CategoryEvent {
  const _DeleteCategory({required this.categoryId, required this.categoryName});
  

 final  String categoryId;
 final  String categoryName;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteCategoryCopyWith<_DeleteCategory> get copyWith => __$DeleteCategoryCopyWithImpl<_DeleteCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteCategory&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName);

@override
String toString() {
  return 'CategoryEvent.deleteCategory(categoryId: $categoryId, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$DeleteCategoryCopyWith<$Res> implements $CategoryEventCopyWith<$Res> {
  factory _$DeleteCategoryCopyWith(_DeleteCategory value, $Res Function(_DeleteCategory) _then) = __$DeleteCategoryCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName
});




}
/// @nodoc
class __$DeleteCategoryCopyWithImpl<$Res>
    implements _$DeleteCategoryCopyWith<$Res> {
  __$DeleteCategoryCopyWithImpl(this._self, this._then);

  final _DeleteCategory _self;
  final $Res Function(_DeleteCategory) _then;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,}) {
  return _then(_DeleteCategory(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _DeleteConfirmed implements CategoryEvent {
  const _DeleteConfirmed({required this.categoryId, required this.categoryName});
  

 final  String categoryId;
 final  String categoryName;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteConfirmedCopyWith<_DeleteConfirmed> get copyWith => __$DeleteConfirmedCopyWithImpl<_DeleteConfirmed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteConfirmed&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName);

@override
String toString() {
  return 'CategoryEvent.deleteConfirmed(categoryId: $categoryId, categoryName: $categoryName)';
}


}

/// @nodoc
abstract mixin class _$DeleteConfirmedCopyWith<$Res> implements $CategoryEventCopyWith<$Res> {
  factory _$DeleteConfirmedCopyWith(_DeleteConfirmed value, $Res Function(_DeleteConfirmed) _then) = __$DeleteConfirmedCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName
});




}
/// @nodoc
class __$DeleteConfirmedCopyWithImpl<$Res>
    implements _$DeleteConfirmedCopyWith<$Res> {
  __$DeleteConfirmedCopyWithImpl(this._self, this._then);

  final _DeleteConfirmed _self;
  final $Res Function(_DeleteConfirmed) _then;

/// Create a copy of CategoryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,}) {
  return _then(_DeleteConfirmed(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CategoryState {

 List<Category> get categories;
/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryStateCopyWith<CategoryState> get copyWith => _$CategoryStateCopyWithImpl<CategoryState>(this as CategoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryState&&const DeepCollectionEquality().equals(other.categories, categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'CategoryState(categories: $categories)';
}


}

/// @nodoc
abstract mixin class $CategoryStateCopyWith<$Res>  {
  factory $CategoryStateCopyWith(CategoryState value, $Res Function(CategoryState) _then) = _$CategoryStateCopyWithImpl;
@useResult
$Res call({
 List<Category> categories
});




}
/// @nodoc
class _$CategoryStateCopyWithImpl<$Res>
    implements $CategoryStateCopyWith<$Res> {
  _$CategoryStateCopyWithImpl(this._self, this._then);

  final CategoryState _self;
  final $Res Function(CategoryState) _then;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryState].
extension CategoryStatePatterns on CategoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<Category> categories)?  initial,TResult Function( List<Category> categories)?  loading,TResult Function( List<Category> categories)?  loaded,TResult Function( List<Category> categories,  Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.categories);case _Loading() when loading != null:
return loading(_that.categories);case _Loaded() when loaded != null:
return loaded(_that.categories);case _Error() when error != null:
return error(_that.categories,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<Category> categories)  initial,required TResult Function( List<Category> categories)  loading,required TResult Function( List<Category> categories)  loaded,required TResult Function( List<Category> categories,  Failure failure)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial(_that.categories);case _Loading():
return loading(_that.categories);case _Loaded():
return loaded(_that.categories);case _Error():
return error(_that.categories,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<Category> categories)?  initial,TResult? Function( List<Category> categories)?  loading,TResult? Function( List<Category> categories)?  loaded,TResult? Function( List<Category> categories,  Failure failure)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that.categories);case _Loading() when loading != null:
return loading(_that.categories);case _Loaded() when loaded != null:
return loaded(_that.categories);case _Error() when error != null:
return error(_that.categories,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements CategoryState {
  const _Initial({final  List<Category> categories = const []}): _categories = categories;
  

 final  List<Category> _categories;
@override@JsonKey() List<Category> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InitialCopyWith<_Initial> get copyWith => __$InitialCopyWithImpl<_Initial>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'CategoryState.initial(categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$InitialCopyWith<$Res> implements $CategoryStateCopyWith<$Res> {
  factory _$InitialCopyWith(_Initial value, $Res Function(_Initial) _then) = __$InitialCopyWithImpl;
@override @useResult
$Res call({
 List<Category> categories
});




}
/// @nodoc
class __$InitialCopyWithImpl<$Res>
    implements _$InitialCopyWith<$Res> {
  __$InitialCopyWithImpl(this._self, this._then);

  final _Initial _self;
  final $Res Function(_Initial) _then;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(_Initial(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,
  ));
}


}

/// @nodoc


class _Loading implements CategoryState {
  const _Loading({final  List<Category> categories = const []}): _categories = categories;
  

 final  List<Category> _categories;
@override@JsonKey() List<Category> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadingCopyWith<_Loading> get copyWith => __$LoadingCopyWithImpl<_Loading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'CategoryState.loading(categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$LoadingCopyWith<$Res> implements $CategoryStateCopyWith<$Res> {
  factory _$LoadingCopyWith(_Loading value, $Res Function(_Loading) _then) = __$LoadingCopyWithImpl;
@override @useResult
$Res call({
 List<Category> categories
});




}
/// @nodoc
class __$LoadingCopyWithImpl<$Res>
    implements _$LoadingCopyWith<$Res> {
  __$LoadingCopyWithImpl(this._self, this._then);

  final _Loading _self;
  final $Res Function(_Loading) _then;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(_Loading(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,
  ));
}


}

/// @nodoc


class _Loaded implements CategoryState {
  const _Loaded({required final  List<Category> categories}): _categories = categories;
  

 final  List<Category> _categories;
@override List<Category> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'CategoryState.loaded(categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $CategoryStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@override @useResult
$Res call({
 List<Category> categories
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(_Loaded(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,
  ));
}


}

/// @nodoc


class _Error implements CategoryState {
  const _Error({final  List<Category> categories = const [], required this.failure}): _categories = categories;
  

 final  List<Category> _categories;
@override@JsonKey() List<Category> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  Failure failure;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),failure);

@override
String toString() {
  return 'CategoryState.error(categories: $categories, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $CategoryStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@override @useResult
$Res call({
 List<Category> categories, Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? failure = null,}) {
  return _then(_Error(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<Category>,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CategoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc
mixin _$CategoryUiEffect {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryUiEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CategoryUiEffect()';
}


}

/// @nodoc
class $CategoryUiEffectCopyWith<$Res>  {
$CategoryUiEffectCopyWith(CategoryUiEffect _, $Res Function(CategoryUiEffect) __);
}


/// Adds pattern-matching-related methods to [CategoryUiEffect].
extension CategoryUiEffectPatterns on CategoryUiEffect {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  showSuccess,TResult Function( String message)?  showError,TResult Function( String categoryId,  String categoryName,  void Function() onConfirmed)?  confirmDelete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that.categoryId,_that.categoryName,_that.onConfirmed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  showSuccess,required TResult Function( String message)  showError,required TResult Function( String categoryId,  String categoryName,  void Function() onConfirmed)  confirmDelete,}) {final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that.message);case _ShowError():
return showError(_that.message);case _ConfirmDelete():
return confirmDelete(_that.categoryId,_that.categoryName,_that.onConfirmed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  showSuccess,TResult? Function( String message)?  showError,TResult? Function( String categoryId,  String categoryName,  void Function() onConfirmed)?  confirmDelete,}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _ConfirmDelete() when confirmDelete != null:
return confirmDelete(_that.categoryId,_that.categoryName,_that.onConfirmed);case _:
  return null;

}
}

}

/// @nodoc


class _ShowSuccess implements CategoryUiEffect {
  const _ShowSuccess(this.message);
  

 final  String message;

/// Create a copy of CategoryUiEffect
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
  return 'CategoryUiEffect.showSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowSuccessCopyWith<$Res> implements $CategoryUiEffectCopyWith<$Res> {
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

/// Create a copy of CategoryUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowSuccess(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ShowError implements CategoryUiEffect {
  const _ShowError(this.message);
  

 final  String message;

/// Create a copy of CategoryUiEffect
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
  return 'CategoryUiEffect.showError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowErrorCopyWith<$Res> implements $CategoryUiEffectCopyWith<$Res> {
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

/// Create a copy of CategoryUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ConfirmDelete implements CategoryUiEffect {
  const _ConfirmDelete({required this.categoryId, required this.categoryName, required this.onConfirmed});
  

 final  String categoryId;
 final  String categoryName;
 final  void Function() onConfirmed;

/// Create a copy of CategoryUiEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmDeleteCopyWith<_ConfirmDelete> get copyWith => __$ConfirmDeleteCopyWithImpl<_ConfirmDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmDelete&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.onConfirmed, onConfirmed) || other.onConfirmed == onConfirmed));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,onConfirmed);

@override
String toString() {
  return 'CategoryUiEffect.confirmDelete(categoryId: $categoryId, categoryName: $categoryName, onConfirmed: $onConfirmed)';
}


}

/// @nodoc
abstract mixin class _$ConfirmDeleteCopyWith<$Res> implements $CategoryUiEffectCopyWith<$Res> {
  factory _$ConfirmDeleteCopyWith(_ConfirmDelete value, $Res Function(_ConfirmDelete) _then) = __$ConfirmDeleteCopyWithImpl;
@useResult
$Res call({
 String categoryId, String categoryName, void Function() onConfirmed
});




}
/// @nodoc
class __$ConfirmDeleteCopyWithImpl<$Res>
    implements _$ConfirmDeleteCopyWith<$Res> {
  __$ConfirmDeleteCopyWithImpl(this._self, this._then);

  final _ConfirmDelete _self;
  final $Res Function(_ConfirmDelete) _then;

/// Create a copy of CategoryUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? onConfirmed = null,}) {
  return _then(_ConfirmDelete(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,onConfirmed: null == onConfirmed ? _self.onConfirmed : onConfirmed // ignore: cast_nullable_to_non_nullable
as void Function(),
  ));
}


}

// dart format on
