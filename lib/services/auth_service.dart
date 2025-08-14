// Untuk kemudahan, kita tidak akan pakai Firebase Auth
// melainkan otentikasi sederhana dengan hardcoded email/password.
// Dalam implementasi nyata, ini harus diganti dengan Firebase Auth.
class AuthService {
  static const String _adminEmail = 'admin@arena.com';
  static const String _adminPassword = 'admin';

  static const String _userEmail = 'user@arena.com';
  static const String _userPassword = 'user';

  Future<String?> login(String email, String password) async {
    if (email == _adminEmail && password == _adminPassword) {
      return 'admin';
    } else if (email == _userEmail && password == _userPassword) {
      return 'user';
    }
    return null; // Login gagal
  }
}
