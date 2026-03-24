import '../models/auth_session.dart';

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<AuthSession?> restoreSession();

  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> createAccount({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithGoogle();

  Future<void> signOut();
}
