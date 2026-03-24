import 'package:uuid/uuid.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  static final Map<String, _MockAccount> _accountsByEmail = {};

  final Uuid _uuid = const Uuid();
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _session;
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final normalizedEmail = email.trim().toLowerCase();
    final account = _accountsByEmail[normalizedEmail];

    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email or password.');
    }

    final session = AuthSession(
      user: account.user,
      accessToken: 'mock-token-${account.user.id}',
    );
    _session = session;
    return session;
  }

  @override
  Future<AuthSession> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists.');
    }

    final user = AuthUser(
      id: _uuid.v4(),
      name: trimmedName,
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );
    _accountsByEmail[normalizedEmail] = _MockAccount(
      user: user,
      password: password,
    );

    final session = AuthSession(
      user: user,
      accessToken: 'mock-token-${user.id}',
    );
    _session = session;
    return session;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    throw const AuthException(
      'Google sign-in is only available with the Firebase auth service.',
    );
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _session = null;
  }
}

class _MockAccount {
  final AuthUser user;
  final String password;

  const _MockAccount({required this.user, required this.password});
}
