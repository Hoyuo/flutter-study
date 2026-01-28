/// Permission status for the app
enum PermissionStatus {
  /// Permission is granted
  granted,

  /// Permission is denied
  denied,

  /// Permission is permanently denied (user selected "Don't ask again")
  permanentlyDenied,

  /// Permission is restricted (iOS)
  restricted,

  /// Permission status is not determined yet
  notDetermined,
}

/// Service for handling runtime permissions
///
/// Provides methods for checking and requesting various permissions
/// like camera, gallery, notifications, and location.
/// This is an abstract class that should be implemented in the app layer
/// with a specific package like permission_handler.
abstract class PermissionService {
  /// Check camera permission status
  Future<PermissionStatus> checkCameraPermission();

  /// Request camera permission
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestCameraPermission();

  /// Check if camera permission is granted
  Future<bool> get isCameraGranted async {
    final status = await checkCameraPermission();
    return status == PermissionStatus.granted;
  }

  /// Check photo library/gallery permission status
  Future<PermissionStatus> checkPhotosPermission();

  /// Request photo library/gallery permission
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestPhotosPermission();

  /// Check if photos permission is granted
  Future<bool> get isPhotosGranted async {
    final status = await checkPhotosPermission();
    return status == PermissionStatus.granted;
  }

  /// Check notification permission status
  Future<PermissionStatus> checkNotificationPermission();

  /// Request notification permission
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestNotificationPermission();

  /// Check if notification permission is granted
  Future<bool> get isNotificationGranted async {
    final status = await checkNotificationPermission();
    return status == PermissionStatus.granted;
  }

  /// Check location permission status
  Future<PermissionStatus> checkLocationPermission();

  /// Request location permission
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestLocationPermission();

  /// Check if location permission is granted
  Future<bool> get isLocationGranted async {
    final status = await checkLocationPermission();
    return status == PermissionStatus.granted;
  }

  /// Check location "always" permission status (background location)
  Future<PermissionStatus> checkLocationAlwaysPermission();

  /// Request location "always" permission (background location)
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestLocationAlwaysPermission();

  /// Check storage permission status
  Future<PermissionStatus> checkStoragePermission();

  /// Request storage permission
  ///
  /// Returns the new permission status after the request
  Future<PermissionStatus> requestStoragePermission();

  /// Check if storage permission is granted
  Future<bool> get isStorageGranted async {
    final status = await checkStoragePermission();
    return status == PermissionStatus.granted;
  }

  /// Open app settings
  ///
  /// Opens the device settings page for this app where the user
  /// can manually grant permissions.
  /// Returns true if settings were opened successfully
  Future<bool> openAppSettings();

  /// Check if permission is permanently denied
  ///
  /// When a permission is permanently denied, the only way to grant it
  /// is through app settings.
  bool isPermanentlyDenied(PermissionStatus status) {
    return status == PermissionStatus.permanentlyDenied;
  }

  /// Request multiple permissions at once
  ///
  /// [permissions] List of permission types to request
  /// Returns a map of permission status for each requested permission
  Future<Map<String, PermissionStatus>> requestMultiplePermissions(
    List<String> permissions,
  );
}
