// lib/screens/user_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/midtrans_service.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart';
import 'booking_detail_screen.dart';
import 'home_screen.dart';

class UserBookingScreen extends StatefulWidget {
  final User user;
  const UserBookingScreen({super.key, required this.user});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  final db = FirebaseService();
  final md = MidtransService();
  late Future<Field> _fieldFuture;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;
  late final TextEditingController _nameCtl;
  late final TextEditingController _emailCtl;
  bool _payFull = false;

  List<Booking> _bookingsOnDate = [];
  bool? _isSlotAvailable;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.user.username);
    _emailCtl = TextEditingController(text: widget.user.email);
    _fieldFuture = _loadFieldAndBookings();
  }

  Future<Field> _loadFieldAndBookings() async {
    final field = await db.getSingleField();
    await _updateBookings(field);
    return field;
  }

  Future<void> _updateBookings(Field field) async {
    _bookingsOnDate = await db.getBookingsForDate(_selectedDate);
    setState(() {
      _isSlotAvailable = _checkSlotAvailability(field);
    });
  }

  int _calculateMaxDuration(Field field) {
    final closeHour = int.parse(field.closeHour.split(':')[0]);
    final selectedHour = _selectedTime.hour;
    return closeHour - selectedHour;
  }

  int _total(Field field) => (field.pricePerHour * _durationHours);
  int _dp(Field field) => (_total(field) / 2).round();

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDate: _selectedDate,
    );
    if (r != null) {
      setState(() => _selectedDate = r);
      final field = await db.getSingleField();
      await _updateBookings(field);
    }
  }

  Future<void> _pickTime(Field field) async {
    final now = DateTime.now();
    final TimeOfDay? r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (r != null) {
      setState(() {
        _selectedTime = r;
        _isSlotAvailable = _checkSlotAvailability(field);
        final maxDuration = _calculateMaxDuration(field);
        if (_durationHours > maxDuration) {
          _durationHours = maxDuration;
        }
      });
    }
  }

  bool _checkSlotAvailability(Field field) {
    final now = DateTime.now();
    final selectedStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final selectedEnd = selectedStart.add(Duration(hours: _durationHours));

    if (selectedStart.isBefore(now)) {
      return false;
    }

    for (var b in _bookingsOnDate) {
      if (b.customerEmail == widget.user.email) {
        continue;
      }
      final existingEnd = b.endTime;
      if (selectedStart.isBefore(existingEnd) &&
          selectedEnd.isAfter(b.startTime)) {
        return false;
      }
    }

    final openTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(field.openHour.split(':')[0]),
    );
    final closeTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(field.closeHour.split(':')[0]),
    );
    if (selectedStart.isBefore(openTime) || selectedEnd.isAfter(closeTime)) {
      return false;
    }

    return true;
  }

  Future<void> _submit(Field field) async {
    if (!_isSlotAvailable!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jam yang dipilih sudah terisi atau tidak valid.'),
        ),
      );
      return;
    }

    final total = _total(field);
    final amount = _payFull ? total : _dp(field);
    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    final booking = Booking(
      fieldId: field.id,
      fieldName: field.name,
      startTime: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      durationHours: _durationHours,
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
                user: widget.user,
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

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isSlotValid = _isSlotAvailable ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Lapangan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => HomeScreen(user: widget.user),
                ),
              ),
        ),
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
          if (snap.data == null || snap.data!.id.isEmpty) {
            return const Center(
              child: Text('Lapangan tidak ditemukan. Mohon coba lagi.'),
            );
          }
          final field = snap.data!;
          final dateLabel = DateFormat(
            'EEE, dd MMM yyyy',
          ).format(_selectedDate);

          final total = _total(field);
          final toPay = _payFull ? total : _dp(field);
          final maxDuration = _calculateMaxDuration(field);

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
                enabled: false,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
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
              ListTile(
                title: const Text('Jam Mulai'),
                subtitle: Text(
                  '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: TextButton(
                  onPressed: () => _pickTime(field),
                  child: const Text('Pilih'),
                ),
              ),
              if (!isSlotValid)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Slot waktu ini tidak tersedia atau tidak valid.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Durasi (jam)'),
                value: _durationHours,
                items:
                    List.generate(maxDuration, (i) => i + 1)
                        .map(
                          (d) =>
                              DropdownMenuItem(value: d, child: Text('$d jam')),
                        )
                        .toList(),
                onChanged:
                    (v) => setState(() => _durationHours = v ?? _durationHours),
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
                      Text('Durasi: $_durationHours jam'),
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
                onPressed: isSlotValid ? () => _submit(field) : null,
                child: Text(
                  'Bayar Sekarang: Rp ${NumberFormat('#,###', 'id_ID').format(isSlotValid ? (_payFull ? total : _dp(field)) : 0)}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
