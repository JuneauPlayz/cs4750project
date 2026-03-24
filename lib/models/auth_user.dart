class AuthUser {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
