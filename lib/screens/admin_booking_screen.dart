// lib/screens/admin_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../services/midtrans_service.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart';
import 'booking_detail_screen.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final db = SqliteService();
  final md = MidtransService();
  late Future<Field> _fieldFuture;
  late Future<List<User>> _usersFuture;

  User? _selectedUser;
  final TextEditingController _manualUsernameCtl = TextEditingController();
  final TextEditingController _manualEmailCtl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationHours = 1;
  bool _payFull = false;

  List<Booking> _bookingsOnDate = [];
  bool? _isSlotAvailable;

  @override
  void initState() {
    super.initState();
    _fieldFuture = _loadFieldAndBookings();
    _usersFuture = db.getAllUsers();
  }

  Future<Field> _loadFieldAndBookings() async {
    await db.init();
    final field = await db.getSingleField();
    await _updateBookings();
    return field;
  }

  Future<void> _updateBookings() async {
    _bookingsOnDate = await db.getBookingsForDate(_selectedDate);
    final field = await db.getSingleField();
    setState(() {
      _isSlotAvailable = _checkSlotAvailability(field);
    });
  }

  int _total(Field field) => (field.pricePerHour * _durationHours);
  int _dp(Field field) => (_total(field) / 2).round();

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _selectedDate,
    );
    if (r != null) {
      setState(() => _selectedDate = r);
      await _updateBookings();
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
      setState(() => _selectedTime = r);
      _isSlotAvailable = _checkSlotAvailability(field);
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
    if (!_isSlotAvailable! ||
        (_selectedUser == null &&
            (_manualUsernameCtl.text.isEmpty ||
                _manualEmailCtl.text.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tidak valid atau slot terisi.')),
      );
      return;
    }

    final String customerName =
        _selectedUser?.username ?? _manualUsernameCtl.text.trim();
    final String customerEmail =
        _selectedUser?.email ?? _manualEmailCtl.text.trim();

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
      customerName: customerName,
      customerEmail: customerEmail,
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

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isSlotValid = _isSlotAvailable ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking untuk User')),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FutureBuilder<List<User>>(
                future: _usersFuture,
                builder: (_, userSnap) {
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (userSnap.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<User>(
                          decoration: const InputDecoration(
                            labelText: 'Pilih Pengguna Terdaftar',
                          ),
                          value: _selectedUser,
                          items:
                              userSnap.data!
                                  .map(
                                    (user) => DropdownMenuItem(
                                      value: user,
                                      child: Text(user.username),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedUser = v;
                              _manualUsernameCtl.clear();
                              _manualEmailCtl.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text('Atau masukkan detail pengguna baru:'),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              TextField(
                controller: _manualUsernameCtl,
                decoration: const InputDecoration(labelText: 'Nama Pengguna'),
                enabled: _selectedUser == null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _manualEmailCtl,
                decoration: const InputDecoration(labelText: 'Email Pengguna'),
                enabled: _selectedUser == null,
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
                    List.generate(
                          int.parse(field.closeHour.split(':')[0]) -
                              int.parse(field.openHour.split(':')[0]),
                          (i) => i + 1,
                        )
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
