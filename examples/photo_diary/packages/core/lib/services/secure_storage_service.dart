import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage operations
///
/// Wraps flutter_secure_storage to provide a simple interface
/// for storing and retrieving sensitive data like tokens, passwords, etc.
class SecureStorageService {
  SecureStorageService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Write a value to secure storage
  ///
  /// [key] The key to store the value under
  /// [value] The value to store
  Future<void> write({
    required String key,
    required String value,
  }) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  ///
  /// [key] The key to read the value from
  /// Returns the value or null if not found
  Future<String?> read({
    required String key,
  }) async {
    return _storage.read(key: key);
  }

  /// Delete a value from secure storage
  ///
  /// [key] The key to delete
  Future<void> delete({
    required String key,
  }) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage
  ///
  /// WARNING: This will remove all stored values
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  ///
  /// [key] The key to check
  /// Returns true if the key exists
  Future<bool> containsKey({
    required String key,
  }) async {
    return await _storage.containsKey(key: key);
  }

  /// Read all keys and values from secure storage
  ///
  /// Returns a map of all stored key-value pairs
  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }

  // Common storage keys as constants
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyBiometricEnabled = 'biometric_enabled';

  // Convenience methods for common operations

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await write(key: keyAuthToken, value: token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    return read(key: keyAuthToken);
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await delete(key: keyAuthToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(key: keyRefreshToken, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return read(key: keyRefreshToken);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await delete(key: keyRefreshToken);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await write(key: keyUserId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return read(key: keyUserId);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await write(key: keyUserEmail, value: email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return read(key: keyUserEmail);
  }

  /// Clear all authentication data
  ///
  /// Removes auth token, refresh token, user ID, and user email
  Future<void> clearAuthData() async {
    await deleteAuthToken();
    await deleteRefreshToken();
    await delete(key: keyUserId);
    await delete(key: keyUserEmail);
  }
}
