// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:arena_futsal_app/models/user.dart';
import 'package:arena_futsal_app/services/sqlite_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  String _err = '';
  final SqliteService _dbService = SqliteService();

  Future<void> _register() async {
    final e = _email.text.trim();
    final p = _pass.text.trim();
    final cp = _confirmPass.text.trim();

    if (e.isEmpty || p.isEmpty || cp.isEmpty) {
      setState(() => _err = 'Semua field harus diisi.');
      return;
    }
    if (p != cp) {
      setState(() => _err = 'Password tidak cocok.');
      return;
    }

    // Cek apakah email sudah terdaftar
    final existingUser = await _dbService.findUserByEmail(e);
    if (existingUser != null) {
      setState(() => _err = 'Email sudah terdaftar.');
      return;
    }

    final newUser = User(email: e, password: p, role: 'user');
    await _dbService.registerUser(newUser);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan login.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi')),
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
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPass,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: const Text('Daftar')),
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
