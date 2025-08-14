// lib/models/user.dart

class User {
  final String email;
  final String password;
  final String role; // 'admin' or 'user'

  User({required this.email, required this.password, required this.role});

  Map<String, dynamic> toMap() {
    return {'email': email, 'password': password, 'role': role};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'user',
    );
  }
}
