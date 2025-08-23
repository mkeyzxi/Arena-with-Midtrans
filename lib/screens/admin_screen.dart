// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/booking.dart';
import 'login_screen.dart';
import 'admin_monitor_screen.dart';
import 'admin_booking_screen.dart';
import 'admin_member_booking_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Booking'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'Tambah Booking Member',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminMemberBookingScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Tambah Booking',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminBookingScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Monitoring Jadwal',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminMonitorScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
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
        stream: db.streamAllBookings(),
        builder: (_, snap) {
          final data = snap.data ?? [];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada booking'));
          }

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = data[i];
              final date = DateFormat('dd MMM').format(b.startTime);
              final statusColor =
                  b.status == 'paid'
                      ? Colors.green
                      : b.status == 'pending_payment'
                      ? Colors.orange
                      : Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    '${b.customerName} - ${b.fieldName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${date} • ${_formatTime(b.startTime)} • ${b.durationHours} jam',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: (v) {
                        db.updateBooking(b.id!, {'status': v});
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'pending_payment',
                              child: Text('pending_payment'),
                            ),
                            PopupMenuItem(value: 'paid', child: Text('paid')),
                            PopupMenuItem(
                              value: 'canceled',
                              child: Text('canceled'),
                            ),
                          ],
                      child: Text(
                        b.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
