import 'package:flutter/material.dart';

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

enum AuthMode { signIn, createAccount }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthSession? _session;
  AuthMode _mode = AuthMode.signIn;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthUser? get currentUser => _session?.user;
  AuthMode get mode => _mode;
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  bool get isAuthenticated => _session != null;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    try {
      _session = await _authService.restoreSession();
    } catch (_) {
      _errorMessage = 'Unable to restore your session right now.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  void setMode(AuthMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    return _runAuthAction(() async {
      _session = await _authService.signIn(email: email, password: password);
    });
  }

  Future<bool> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      _session = await _authService.createAccount(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<bool> signInWithGoogle() async {
    return _runAuthAction(() async {
      _session = await _authService.signInWithGoogle();
    });
  }

  Future<void> signOut() async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _session = null;
      _mode = AuthMode.signIn;
    } catch (_) {
      _errorMessage = 'Unable to sign out right now.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
