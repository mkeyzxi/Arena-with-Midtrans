// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:arena_futsal_app/models/user.dart';
import 'user_booking_screen.dart';
import 'admin_screen.dart';
import 'package:arena_futsal_app/services/sqlite_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _err = '';
  final SqliteService _dbService = SqliteService();

  Future<void> _login() async {
    final e = _email.text.trim();
    final p = _pass.text.trim();

    // Cari user di database
    final User? user = await _dbService.findUserByEmail(e);

    if (user != null && user.password == p) {
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserBookingScreen()),
        );
      }
    } else {
      setState(() => _err = 'Email/password salah.');
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Daftar Sekarang'),
            ),
            if (_err.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
