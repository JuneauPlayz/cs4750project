import 'auth_user.dart';

class AuthSession {
  final AuthUser user;
  final String accessToken;

  const AuthSession({required this.user, required this.accessToken});
}
