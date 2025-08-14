import 'package:flutter/material.dart';
import 'user_booking_screen.dart';
import 'admin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _err = '';

  Future<void> _login() async {
    final e = _email.text.trim();
    final p = _pass.text.trim();
    if (e == 'admin@arena.com' && p == 'admin') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminScreen()));
    } else if (e == 'user@arena.com' && p == 'user') {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserBookingScreen()));
    } else {
      setState(() => _err =
          'Email/password salah. Gunakan admin@arena.com/admin atau user@arena.com/user');
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _login, child: const Text('Login')),
          if (_err.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_err, style: const TextStyle(color: Colors.red)))
        ]),
      ),
    );
  }
}
