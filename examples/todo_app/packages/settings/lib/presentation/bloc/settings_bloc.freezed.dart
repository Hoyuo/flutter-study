// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsEvent()';
}


}

/// @nodoc
class $SettingsEventCopyWith<$Res>  {
$SettingsEventCopyWith(SettingsEvent _, $Res Function(SettingsEvent) __);
}


/// Adds pattern-matching-related methods to [SettingsEvent].
extension SettingsEventPatterns on SettingsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsEventLoadSettings value)?  loadSettings,TResult Function( SettingsEventUpdateTheme value)?  updateTheme,TResult Function( SettingsEventUpdateLanguage value)?  updateLanguage,TResult Function( SettingsEventToggleNotifications value)?  toggleNotifications,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsEventLoadSettings() when loadSettings != null:
return loadSettings(_that);case SettingsEventUpdateTheme() when updateTheme != null:
return updateTheme(_that);case SettingsEventUpdateLanguage() when updateLanguage != null:
return updateLanguage(_that);case SettingsEventToggleNotifications() when toggleNotifications != null:
return toggleNotifications(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsEventLoadSettings value)  loadSettings,required TResult Function( SettingsEventUpdateTheme value)  updateTheme,required TResult Function( SettingsEventUpdateLanguage value)  updateLanguage,required TResult Function( SettingsEventToggleNotifications value)  toggleNotifications,}){
final _that = this;
switch (_that) {
case SettingsEventLoadSettings():
return loadSettings(_that);case SettingsEventUpdateTheme():
return updateTheme(_that);case SettingsEventUpdateLanguage():
return updateLanguage(_that);case SettingsEventToggleNotifications():
return toggleNotifications(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsEventLoadSettings value)?  loadSettings,TResult? Function( SettingsEventUpdateTheme value)?  updateTheme,TResult? Function( SettingsEventUpdateLanguage value)?  updateLanguage,TResult? Function( SettingsEventToggleNotifications value)?  toggleNotifications,}){
final _that = this;
switch (_that) {
case SettingsEventLoadSettings() when loadSettings != null:
return loadSettings(_that);case SettingsEventUpdateTheme() when updateTheme != null:
return updateTheme(_that);case SettingsEventUpdateLanguage() when updateLanguage != null:
return updateLanguage(_that);case SettingsEventToggleNotifications() when toggleNotifications != null:
return toggleNotifications(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadSettings,TResult Function( ThemeMode themeMode)?  updateTheme,TResult Function( String language)?  updateLanguage,TResult Function()?  toggleNotifications,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsEventLoadSettings() when loadSettings != null:
return loadSettings();case SettingsEventUpdateTheme() when updateTheme != null:
return updateTheme(_that.themeMode);case SettingsEventUpdateLanguage() when updateLanguage != null:
return updateLanguage(_that.language);case SettingsEventToggleNotifications() when toggleNotifications != null:
return toggleNotifications();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadSettings,required TResult Function( ThemeMode themeMode)  updateTheme,required TResult Function( String language)  updateLanguage,required TResult Function()  toggleNotifications,}) {final _that = this;
switch (_that) {
case SettingsEventLoadSettings():
return loadSettings();case SettingsEventUpdateTheme():
return updateTheme(_that.themeMode);case SettingsEventUpdateLanguage():
return updateLanguage(_that.language);case SettingsEventToggleNotifications():
return toggleNotifications();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadSettings,TResult? Function( ThemeMode themeMode)?  updateTheme,TResult? Function( String language)?  updateLanguage,TResult? Function()?  toggleNotifications,}) {final _that = this;
switch (_that) {
case SettingsEventLoadSettings() when loadSettings != null:
return loadSettings();case SettingsEventUpdateTheme() when updateTheme != null:
return updateTheme(_that.themeMode);case SettingsEventUpdateLanguage() when updateLanguage != null:
return updateLanguage(_that.language);case SettingsEventToggleNotifications() when toggleNotifications != null:
return toggleNotifications();case _:
  return null;

}
}

}

/// @nodoc


class SettingsEventLoadSettings implements SettingsEvent {
  const SettingsEventLoadSettings();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEventLoadSettings);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsEvent.loadSettings()';
}


}




/// @nodoc


class SettingsEventUpdateTheme implements SettingsEvent {
  const SettingsEventUpdateTheme(this.themeMode);
  

 final  ThemeMode themeMode;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsEventUpdateThemeCopyWith<SettingsEventUpdateTheme> get copyWith => _$SettingsEventUpdateThemeCopyWithImpl<SettingsEventUpdateTheme>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEventUpdateTheme&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode);

@override
String toString() {
  return 'SettingsEvent.updateTheme(themeMode: $themeMode)';
}


}

/// @nodoc
abstract mixin class $SettingsEventUpdateThemeCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory $SettingsEventUpdateThemeCopyWith(SettingsEventUpdateTheme value, $Res Function(SettingsEventUpdateTheme) _then) = _$SettingsEventUpdateThemeCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode
});




}
/// @nodoc
class _$SettingsEventUpdateThemeCopyWithImpl<$Res>
    implements $SettingsEventUpdateThemeCopyWith<$Res> {
  _$SettingsEventUpdateThemeCopyWithImpl(this._self, this._then);

  final SettingsEventUpdateTheme _self;
  final $Res Function(SettingsEventUpdateTheme) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? themeMode = null,}) {
  return _then(SettingsEventUpdateTheme(
null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,
  ));
}


}

/// @nodoc


class SettingsEventUpdateLanguage implements SettingsEvent {
  const SettingsEventUpdateLanguage(this.language);
  

 final  String language;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsEventUpdateLanguageCopyWith<SettingsEventUpdateLanguage> get copyWith => _$SettingsEventUpdateLanguageCopyWithImpl<SettingsEventUpdateLanguage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEventUpdateLanguage&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,language);

@override
String toString() {
  return 'SettingsEvent.updateLanguage(language: $language)';
}


}

/// @nodoc
abstract mixin class $SettingsEventUpdateLanguageCopyWith<$Res> implements $SettingsEventCopyWith<$Res> {
  factory $SettingsEventUpdateLanguageCopyWith(SettingsEventUpdateLanguage value, $Res Function(SettingsEventUpdateLanguage) _then) = _$SettingsEventUpdateLanguageCopyWithImpl;
@useResult
$Res call({
 String language
});




}
/// @nodoc
class _$SettingsEventUpdateLanguageCopyWithImpl<$Res>
    implements $SettingsEventUpdateLanguageCopyWith<$Res> {
  _$SettingsEventUpdateLanguageCopyWithImpl(this._self, this._then);

  final SettingsEventUpdateLanguage _self;
  final $Res Function(SettingsEventUpdateLanguage) _then;

/// Create a copy of SettingsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? language = null,}) {
  return _then(SettingsEventUpdateLanguage(
null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SettingsEventToggleNotifications implements SettingsEvent {
  const SettingsEventToggleNotifications();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsEventToggleNotifications);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsEvent.toggleNotifications()';
}


}




/// @nodoc
mixin _$SettingsState {

 AppSettings get settings; bool get isLoading;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,settings,isLoading);

@override
String toString() {
  return 'SettingsState(settings: $settings, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 AppSettings settings, bool isLoading
});


$AppSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? settings = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as AppSettings,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<$Res> get settings {
  
  return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppSettings settings,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.settings,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppSettings settings,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.settings,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppSettings settings,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.settings,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState extends SettingsState {
  const _SettingsState({this.settings = const AppSettings(), this.isLoading = false}): super._();
  

@override@JsonKey() final  AppSettings settings;
@override@JsonKey() final  bool isLoading;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,settings,isLoading);

@override
String toString() {
  return 'SettingsState(settings: $settings, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 AppSettings settings, bool isLoading
});


@override $AppSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? settings = null,Object? isLoading = null,}) {
  return _then(_SettingsState(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as AppSettings,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<$Res> get settings {
  
  return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc
mixin _$SettingsUiEffect {

 String get message;
/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsUiEffectCopyWith<SettingsUiEffect> get copyWith => _$SettingsUiEffectCopyWithImpl<SettingsUiEffect>(this as SettingsUiEffect, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsUiEffect&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SettingsUiEffect(message: $message)';
}


}

/// @nodoc
abstract mixin class $SettingsUiEffectCopyWith<$Res>  {
  factory $SettingsUiEffectCopyWith(SettingsUiEffect value, $Res Function(SettingsUiEffect) _then) = _$SettingsUiEffectCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SettingsUiEffectCopyWithImpl<$Res>
    implements $SettingsUiEffectCopyWith<$Res> {
  _$SettingsUiEffectCopyWithImpl(this._self, this._then);

  final SettingsUiEffect _self;
  final $Res Function(SettingsUiEffect) _then;

/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingsUiEffect].
extension SettingsUiEffectPatterns on SettingsUiEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ShowSuccess value)?  showSuccess,TResult Function( _ShowError value)?  showError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ShowSuccess value)  showSuccess,required TResult Function( _ShowError value)  showError,}){
final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that);case _ShowError():
return showError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ShowSuccess value)?  showSuccess,TResult? Function( _ShowError value)?  showError,}){
final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that);case _ShowError() when showError != null:
return showError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  showSuccess,TResult Function( String message)?  showError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  showSuccess,required TResult Function( String message)  showError,}) {final _that = this;
switch (_that) {
case _ShowSuccess():
return showSuccess(_that.message);case _ShowError():
return showError(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  showSuccess,TResult? Function( String message)?  showError,}) {final _that = this;
switch (_that) {
case _ShowSuccess() when showSuccess != null:
return showSuccess(_that.message);case _ShowError() when showError != null:
return showError(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _ShowSuccess implements SettingsUiEffect {
  const _ShowSuccess(this.message);
  

@override final  String message;

/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
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
  return 'SettingsUiEffect.showSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowSuccessCopyWith<$Res> implements $SettingsUiEffectCopyWith<$Res> {
  factory _$ShowSuccessCopyWith(_ShowSuccess value, $Res Function(_ShowSuccess) _then) = __$ShowSuccessCopyWithImpl;
@override @useResult
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

/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowSuccess(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ShowError implements SettingsUiEffect {
  const _ShowError(this.message);
  

@override final  String message;

/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
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
  return 'SettingsUiEffect.showError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ShowErrorCopyWith<$Res> implements $SettingsUiEffectCopyWith<$Res> {
  factory _$ShowErrorCopyWith(_ShowError value, $Res Function(_ShowError) _then) = __$ShowErrorCopyWithImpl;
@override @useResult
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

/// Create a copy of SettingsUiEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ShowError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
