// lib/screens/admin_member_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../models/field.dart';
import 'admin_screen.dart';

class AdminMemberBookingScreen extends StatefulWidget {
  const AdminMemberBookingScreen({super.key});

  @override
  State<AdminMemberBookingScreen> createState() =>
      _AdminMemberBookingScreenState();
}

class _AdminMemberBookingScreenState extends State<AdminMemberBookingScreen> {
  final db = SqliteService();
  late Future<List<User>> _usersFuture;
  late Future<Field> _fieldFuture;

  User? _selectedUser;
  int _selectedDayOfWeek = DateTime.monday;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _durationHours = 1;

  @override
  void initState() {
    super.initState();
    _usersFuture = db.getAllUsers();
    _fieldFuture = db.getSingleField();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? r = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (r != null) {
      setState(() => _selectedTime = r);
    }
  }

  Future<void> _submit(Field field) async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih pengguna terlebih dahulu.')),
      );
      return;
    }

    final int total = (field.pricePerHour * _durationHours);
    final int downPayment = (total / 2).round();

    final now = DateTime.now();
    DateTime firstBookingDate = now.add(const Duration(days: 90));
    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      if (date.weekday == _selectedDayOfWeek) {
        firstBookingDate = date;
        break;
      }
    }

    final newBooking = Booking(
      fieldId: field.id,
      fieldName: field.name,
      startTime: DateTime(
        firstBookingDate.year,
        firstBookingDate.month,
        firstBookingDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      durationHours: _durationHours,
      pricePerHour: field.pricePerHour,
      total: total,
      downPayment: downPayment,
      status: 'paid', // Admin langsung set paid
      customerName: _selectedUser!.username,
      customerEmail: _selectedUser!.email,
    );

    await db.addMemberBooking(newBooking, 12); // 12 minggu = ~3 bulan

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berulang berhasil dibuat!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Berulang untuk Member')),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_fieldFuture, _usersFuture]),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }

          final field = snap.data![0] as Field;
          final users = snap.data![1] as List<User>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<User>(
                decoration: const InputDecoration(
                  labelText: 'Pilih Pengguna Terdaftar',
                ),
                value: _selectedUser,
                items:
                    users
                        .map(
                          (user) => DropdownMenuItem(
                            value: user,
                            child: Text(user.username),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => _selectedUser = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Pilih Hari'),
                value: _selectedDayOfWeek,
                items: [
                  for (var i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        DateFormat('EEEE').format(DateTime(2025, 1, i)),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedDayOfWeek = v!),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Jam Mulai'),
                subtitle: Text(
                  '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: TextButton(
                  onPressed: _pickTime,
                  child: const Text('Pilih'),
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
              ElevatedButton(
                onPressed: _selectedUser != null ? () => _submit(field) : null,
                child: const Text('Buat Jadwal Berulang'),
              ),
            ],
          );
        },
      ),
    );
  }
}
