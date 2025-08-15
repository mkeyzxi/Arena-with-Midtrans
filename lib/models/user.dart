// lib/models/user.dart

class User {
  final String email;
  final String password;
  final String role;
  final String username;

  User({
    required this.email,
    required this.password,
    required this.role,
    required this.username,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'role': role,
      'username': username,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'user',
      username: map['username'] ?? '',
    );
  }
}
