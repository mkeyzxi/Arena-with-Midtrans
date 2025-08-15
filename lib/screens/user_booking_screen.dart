import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../services/midtrans_service.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart';
import 'booking_detail_screen.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class UserBookingScreen extends StatefulWidget {
  final User user;
  const UserBookingScreen({super.key, required this.user});

  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen> {
  final db = SqliteService();
  final md = MidtransService();
  late Future<Field> _fieldFuture;
  DateTime _date = DateTime.now();
  double? _startHour;
  double _hours = 0.5;
  late final TextEditingController _nameCtl;
  late final TextEditingController _emailCtl;
  bool _payFull = false;
  List<Booking> _bookingsOnDate = [];

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.user.username);
    _emailCtl = TextEditingController(text: widget.user.email);
    _fieldFuture = _loadFieldAndBookings();
  }

  Future<Field> _loadFieldAndBookings() async {
    await db.init();
    final field = await db.getSingleField();
    _bookingsOnDate = await db.getBookingsForDate(_date);
    if (field.id.isNotEmpty) {
      final availableHours = _availableHours(field);
      if (availableHours.isNotEmpty) {
        _startHour = availableHours.first;
      }
    }
    return field;
  }

  Future<void> _updateBookings() async {
    _bookingsOnDate = await db.getBookingsForDate(_date);
    setState(() {
      final availableHours = _availableHours(
        Field(
          id: '',
          name: '',
          openHour: '08:00',
          closeHour: '22:00',
          pricePerHour: 100000,
        ),
      );
      if (!availableHours.contains(_startHour) && availableHours.isNotEmpty) {
        _startHour = availableHours.first;
      } else if (availableHours.isEmpty) {
        _startHour = null;
      }
    });
  }

  int _total(Field field) => (field.pricePerHour * _hours).round();
  int _dp(Field field) => (_total(field) / 2).round();

  Future<void> _pickDate() async {
    final r = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _date,
    );
    if (r != null) {
      setState(() => _date = r);
      await _updateBookings();
    }
  }

  Future<void> _submit(Field field) async {
    final total = _total(field);
    final amount = _payFull ? total : _dp(field);
    final orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    final booking = Booking(
      fieldId: field.id,
      fieldName: field.name,
      date: DateTime(_date.year, _date.month, _date.day),
      startHour: _startHour!,
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

  bool _isSlotBooked(double hour) {
    for (var b in _bookingsOnDate) {
      if (hour >= b.startHour && hour < b.startHour + b.durationHours) {
        return true;
      }
    }
    return false;
  }

  List<double> _availableHours(Field field) {
    final openHour = int.parse(field.openHour.split(':').first);
    final closeHour = int.parse(field.closeHour.split(':').first);
    final hours = <double>[];

    final now = DateTime.now();
    final startHourForToday =
        _date.day == now.day &&
                _date.month == now.month &&
                _date.year == now.year
            ? (now.hour.toDouble() + (now.minute > 30 ? 1.0 : 0.5))
            : openHour.toDouble();

    for (var h = openHour.toDouble(); h < closeHour; h += 0.5) {
      if (h >= startHourForToday && !_isSlotBooked(h)) {
        hours.add(h);
      }
    }
    return hours;
  }

  String _formatTime(double time) {
    final int hour = time.floor();
    final int minute = ((time - hour) * 60).round();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Lapangan')),
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
          final dateLabel = DateFormat('EEE, dd MMM yyyy').format(_date);
          final availableHours = _availableHours(field);
          final total = _total(field);
          final toPay = _payFull ? total : _dp(field);

          if (!availableHours.contains(_startHour) &&
              availableHours.isNotEmpty) {
            _startHour = availableHours.first;
          } else if (availableHours.isEmpty) {
            _startHour = null;
          }

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
                    'Buka ${_formatTime(double.parse(field.openHour.split(':')[0]))} - Tutup ${_formatTime(double.parse(field.closeHour.split(':')[0]))}',
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
              DropdownButtonFormField<double>(
                decoration: const InputDecoration(labelText: 'Jam Mulai'),
                value: _startHour,
                items:
                    availableHours
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(_formatTime(h)),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _startHour = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                decoration: const InputDecoration(labelText: 'Durasi (jam)'),
                value: _hours,
                items:
                    _startHour != null
                        ? List.generate(
                              ((int.parse(field.closeHour.split(':')[0]) -
                                          _startHour!) *
                                      2)
                                  .toInt(),
                              (i) => (i + 1) * 0.5,
                            )
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text('${d} jam'),
                              ),
                            )
                            .toList()
                        : [],
                onChanged: (v) => setState(() => _hours = v ?? _hours),
                disabledHint: const Text('Pilih jam mulai terlebih dahulu'),
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
                onPressed: _startHour != null ? () => _submit(field) : null,
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
