// import 'package:flutter/material.dart';
// import 'package:arena_app/screens/login_screen.dart';
// import 'package:arena_app/screens/user_booking_screen.dart'; // Opsional, jika user bisa langsung masuk

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Arena Booking App'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               'Selamat Datang!',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(builder: (_) => const LoginScreen()),
//                 );
//               },
//               child: const Text('Login sebagai Admin / User'),
//             ),
//             const SizedBox(height: 16),
//             // Opsi ini bisa digunakan jika Anda ingin user bisa langsung booking tanpa login
//             // ElevatedButton(
//             //   onPressed: () {
//             //     Navigator.of(context).push(
//             //       MaterialPageRoute(builder: (_) => const UserBookingScreen()),
//             //     );
//             //   },
//             //   child: const Text('Booking Lapangan (sebagai Guest)'),
//             // ),
//           ],
//         ),
//       ),
//     );
//   }
// }
