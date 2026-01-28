import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Abstract remote data source for authentication
abstract class AuthRemoteDataSource {
  /// Sign in with email and password
  /// Returns FirebaseUser on success
  /// Throws [FirebaseAuthException] on error
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign in with Google
  /// Returns FirebaseUser on success
  /// Throws [FirebaseAuthException] on error
  Future<firebase_auth.User> signInWithGoogle();

  /// Sign in with Apple
  /// Returns FirebaseUser on success
  /// Throws [FirebaseAuthException] on error
  Future<firebase_auth.User> signInWithApple();

  /// Create user with email and password
  /// Returns FirebaseUser on success
  /// Throws [FirebaseAuthException] on error
  Future<firebase_auth.User> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user
  /// Throws [FirebaseAuthException] on error
  Future<void> signOut();

  /// Get the current authenticated user
  /// Returns null if no user is authenticated
  Future<firebase_auth.User?> getCurrentUser();

  /// Stream of authentication state changes
  /// Emits FirebaseUser when authenticated, null when not authenticated
  Stream<firebase_auth.User?> authStateChanges();
}
