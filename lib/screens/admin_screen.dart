// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../models/booking.dart';
import 'login_screen.dart';
import 'admin_monitor_screen.dart';
import 'admin_booking_screen.dart'; // Import halaman admin booking

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final db = SqliteService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Daftar Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminBookingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminMonitorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Booking>>(
        stream: db.streamBookings(),
        builder: (_, snap) {
          final data = snap.data ?? [];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          if (data.isEmpty)
            return const Center(child: Text('Belum ada booking'));

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = data[i];
              final date = DateFormat('dd MMM').format(b.startTime);
              return ListTile(
                title: Text(
                  '${b.fieldName} • $date • ${_formatTime(b.startTime)} • ${b.durationHours} jam',
                ),
                subtitle: Text(
                  'Total: Rp ${NumberFormat('#,###', 'id_ID').format(b.total)}  |  DP: Rp ${NumberFormat('#,###', 'id_ID').format(b.downPayment)}\nStatus: ${b.status}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    db.updateBooking(b.id!, {'status': v});
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'pending', child: Text('pending')),
                        PopupMenuItem(value: 'paid', child: Text('paid')),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Text('cancelled'),
                        ),
                      ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
