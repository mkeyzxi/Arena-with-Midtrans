import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../services/sqlite_service.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final User user;
  const TransactionHistoryScreen({super.key, required this.user});

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final db = SqliteService();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: StreamBuilder<List<Booking>>(
        stream: db.streamBookings(),
        builder: (_, snap) {
          final data =
              snap.data?.where((b) => b.customerEmail == user.email).toList() ??
              [];
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          if (data.isEmpty)
            return const Center(child: Text('Belum ada riwayat transaksi.'));

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = data[i];
              return ListTile(
                title: Text(
                  '${b.fieldName} • ${DateFormat('dd MMM yyyy').format(b.startTime)} • ${_formatTime(b.startTime)} • ${b.durationHours} jam',
                ),
                subtitle: Text('Status: ${b.status}'),
                isThreeLine: false,
              );
            },
          );
        },
      ),
    );
  }
}
