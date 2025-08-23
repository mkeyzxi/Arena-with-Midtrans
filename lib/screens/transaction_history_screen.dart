// lib/screens/transaction_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final User user;
  const TransactionHistoryScreen({super.key, required this.user});

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green[600]!;
      case 'pending_payment':
        return Colors.orange[600]!;
      case 'canceled':
        return Colors.red[600]!;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Terbayar';
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'canceled':
        return 'Dibatalkan';
      default:
        return 'Tidak Diketahui';
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseService();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi'), centerTitle: true),
      body: FutureBuilder<List<Booking>>(
        future: db.getUserBookings(user.email),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          final data = snap.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Belum ada riwayat transaksi.'));
          }

          data.sort((a, b) => b.startTime.compareTo(a.startTime));

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: data.length,
            itemBuilder: (_, i) {
              final b = data[i];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            color: Colors.blue[700],
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b.fieldName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatTime(b.startTime)} • ${b.durationHours} jam',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMMM yyyy').format(b.startTime),
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            'Rp ${NumberFormat('#,###', 'id_ID').format(b.total)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(b.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _getStatusColor(b.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStatusText(b.status),
                              style: TextStyle(
                                color: _getStatusColor(b.status),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
