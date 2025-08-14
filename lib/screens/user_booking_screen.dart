// lib/screens/user_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../services/midtrans_service.dart';
import '../models/field.dart';
import '../models/booking.dart';
import 'booking_detail_screen.dart';
import 'login_screen.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});
  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  final db = SqliteService();
  final md = MidtransService();
  late Future<Field> _fieldFuture;
  DateTime _date = DateTime.now();
  int _startHour = 8;
  int _hours = 1;
  final _nameCtl = TextEditingController(text: 'User Demo');
  final _emailCtl = TextEditingController(text: 'user@arena.com');
  bool _payFull = false;

  @override
  void initState() {
    super.initState();
    _fieldFuture = _loadField();
  }

  Future<Field> _loadField() async {
    await db.init(); // Pastikan database terinisialisasi
    await db.seedFieldsIfEmpty();
    return await db.getSingleField();
  }

  int _total(Field field) => field.pricePerHour * _hours;
  int _dp(Field field) => (_total(field) / 2).round();

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _date,
    );
    if (r != null) setState(() => _date = r);
  }

  Future<void> _submit(Field field) async {
    final total = _total(field);
    final amount = _payFull ? total : _dp(field);
    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    final booking = Booking(
      fieldId: field.id,
      fieldName: field.name,
      date: DateTime(_date.year, _date.month, _date.day),
      startHour: _startHour,
      durationHours: _hours,
      pricePerHour: field.pricePerHour,
      total: total,
      downPayment: _dp(field),
      status: 'pending',
      customerName: _nameCtl.text.trim(),
      customerEmail: _emailCtl.text.trim(),
    );

    final bookingId = await db.addBooking(booking);

    try {
      final tx = await md.createTransaction(
        orderId: orderId,
        amount: amount,
        customerName: booking.customerName,
        customerEmail: booking.customerEmail,
      );

      await db.updateBooking(bookingId, {
        'snapToken': tx['token'],
        'redirectUrl': tx['redirect_url'],
        'status': 'pending_payment',
      });

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => BookingDetailScreen(
                bookingId: bookingId,
                orderId: orderId,
                redirectUrl: tx['redirect_url'],
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error pembayaran: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Lapangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Field>(
        future: _fieldFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          if (snap.data == null) {
            return const Center(
              child: Text('Lapangan tidak ditemukan. Mohon coba lagi.'),
            );
          }
          final field = snap.data!;
          final dateLabel = DateFormat('EEE, dd MMM yyyy').format(_date);
          final total = _total(field);
          final toPay = _payFull ? total : _dp(field);
          final openHour = int.parse(field.openHour.split(':').first);
          final closeHour = int.parse(field.closeHour.split(':').first);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Detail Lapangan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(field.name),
                  subtitle: Text(
                    'Buka ${field.openHour} - Tutup ${field.closeHour}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(labelText: 'Nama Pemesan'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Tanggal'),
                subtitle: Text(dateLabel),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pilih'),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Jam Mulai'),
                value: _startHour,
                items:
                    List.generate(closeHour - openHour, (i) => openHour + i)
                        .map(
                          (h) =>
                              DropdownMenuItem(value: h, child: Text('$h:00')),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _startHour = v ?? _startHour),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Durasi (jam)'),
                value: _hours,
                items:
                    List.generate(closeHour - _startHour, (i) => i + 1)
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text('$d')),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _hours = v ?? _hours),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga/jam: Rp ${NumberFormat('#,###', 'id_ID').format(field.pricePerHour)}',
                      ),
                      Text('Durasi: $_hours jam'),
                      const Divider(),
                      Text(
                        'Total: Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'DP (50%): Rp ${NumberFormat('#,###', 'id_ID').format(_dp(field))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Text(
                        'Uang muka (50%): Rp ${NumberFormat('#,###', 'id_ID').format(_dp(field))}',
                      ),
                      value: false,
                      groupValue: _payFull,
                      onChanged: (v) => setState(() => _payFull = v!),
                    ),
                    RadioListTile<bool>(
                      title: Text(
                        'Bayar lunas: Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
                      ),
                      value: true,
                      groupValue: _payFull,
                      onChanged: (v) => setState(() => _payFull = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _submit(field),
                child: Text(
                  'Bayar Sekarang: Rp ${NumberFormat('#,###', 'id_ID').format(toPay)}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
