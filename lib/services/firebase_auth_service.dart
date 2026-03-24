import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  bool _googleInitialized = false;

  @override
  Future<AuthSession?> restoreSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _sessionFromUser(user);
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in did not return a valid user.');
      }
      return _sessionFromUser(user);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForError(error));
    }
  }

  @override
  Future<AuthSession> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Account creation did not return a user.');
      }

      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
        await user.reload();
      }

      final refreshedUser = _firebaseAuth.currentUser;
      if (refreshedUser == null) {
        throw const AuthException('Unable to load the new account session.');
      }

      return _sessionFromUser(refreshedUser);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForError(error));
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    try {
      await _initializeGoogleSignIn();
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Google sign-in did not return an ID token.');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(
          'Google sign-in did not return a valid user.',
        );
      }
      return _sessionFromUser(user);
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageForError(error));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _firebaseAuth.signOut();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  AuthSession _sessionFromUser(User user) {
    return AuthSession(
      user: AuthUser(
        id: user.uid,
        name: _displayNameForUser(user),
        email: user.email ?? '',
        createdAt: user.metadata.creationTime ?? DateTime.now(),
      ),
      accessToken: user.refreshToken ?? user.uid,
    );
  }

  String _displayNameForUser(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Creator';
  }

  String _messageForError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign in is not enabled in Firebase yet.';
      case 'account-exists-with-different-credential':
        return 'That email already uses another sign-in method.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
