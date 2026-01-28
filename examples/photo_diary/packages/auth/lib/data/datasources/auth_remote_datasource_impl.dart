import 'package:auth/data/datasources/auth_remote_datasource.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Firebase implementation of AuthRemoteDataSource
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    // GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;
  // _googleSignIn = googleSignIn ?? GoogleSignIn();

  final firebase_auth.FirebaseAuth _firebaseAuth;
  // TODO: Add GoogleSignIn when implementing Google Sign In
  // final GoogleSignIn _googleSignIn;

  @override
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found after sign in',
      );
    }

    return user;
  }

  @override
  Future<firebase_auth.User> signInWithGoogle() async {
    // TODO: Implement Google Sign In
    // 1. Trigger the authentication flow
    // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    //
    // if (googleUser == null) {
    //   throw FirebaseAuthException(
    //     code: 'google-sign-in-cancelled',
    //     message: 'Google Sign In was cancelled',
    //   );
    // }
    //
    // 2. Obtain the auth details from the request
    // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    //
    // 3. Create a new credential
    // final credential = firebase_auth.GoogleAuthProvider.credential(
    //   accessToken: googleAuth.accessToken,
    //   idToken: googleAuth.idToken,
    // );
    //
    // 4. Sign in to Firebase with the credential
    // final userCredential = await _firebaseAuth.signInWithCredential(credential);
    //
    // final user = userCredential.user;
    // if (user == null) {
    //   throw firebase_auth.FirebaseAuthException(
    //     code: 'user-not-found',
    //     message: 'User not found after Google sign in',
    //   );
    // }
    //
    // return user;

    throw firebase_auth.FirebaseAuthException(
      code: 'unavailable',
      message: 'Google Sign In is not available at this time',
    );
  }

  @override
  Future<firebase_auth.User> signInWithApple() async {
    // TODO: Implement Apple Sign In
    // 1. Create Apple Sign In provider
    // final appleProvider = firebase_auth.AppleAuthProvider();
    //
    // 2. Sign in with popup/redirect (for web) or native (for mobile)
    // final userCredential = await _firebaseAuth.signInWithProvider(appleProvider);
    //
    // final user = userCredential.user;
    // if (user == null) {
    //   throw firebase_auth.FirebaseAuthException(
    //     code: 'user-not-found',
    //     message: 'User not found after Apple sign in',
    //   );
    // }
    //
    // return user;

    throw firebase_auth.FirebaseAuthException(
      code: 'unavailable',
      message: 'Apple Sign In is not available at this time',
    );
  }

  @override
  Future<firebase_auth.User> createUserWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found after sign up',
      );
    }

    // Update display name if provided
    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
      await user.reload();
      return _firebaseAuth.currentUser!;
    }

    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      // TODO: Sign out from Google when implementing
      // _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<firebase_auth.User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  @override
  Stream<firebase_auth.User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
