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

  // Map untuk konversi nama hari ke Bahasa Indonesia
  final Map<int, String> indonesianDays = {
    DateTime.monday: 'Senin',
    DateTime.tuesday: 'Selasa',
    DateTime.wednesday: 'Rabu',
    DateTime.thursday: 'Kamis',
    DateTime.friday: 'Jumat',
    DateTime.saturday: 'Sabtu',
    DateTime.sunday: 'Minggu',
  };

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
      // Validasi jam booking
      if (r.hour < 8 || r.hour >= 22) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking hanya dapat dilakukan antara jam 08:00-22:00.',
            ),
          ),
        );
        return;
      }
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

    // Validasi jam booking
    if (_selectedTime.hour < 8 || _selectedTime.hour >= 22) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking hanya dapat dilakukan antara jam 08:00-22:00.',
          ),
        ),
      );
      return;
    }

    // Menghitung tanggal booking pertama
    DateTime firstBookingDate = DateTime.now();
    while (firstBookingDate.weekday != _selectedDayOfWeek) {
      firstBookingDate = firstBookingDate.add(const Duration(days: 1));
    }

    // Menentukan harga tetap untuk member
    const int memberPrice = 1100000;
    const int normalPrice = 1300000; // Harga normal untuk referensi
    const int totalWeeks = 13; // 3 bulan = 13 minggu

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
      pricePerHour:
          field.pricePerHour, // Harga per jam tetap, tapi total disesuaikan
      total: memberPrice,
      downPayment: memberPrice, // Admin langsung set dibayar penuh
      status: 'paid', // Admin langsung set paid
      customerName: _selectedUser!.username,
      customerEmail: _selectedUser!.email,
    );

    // Menambahkan booking berulang selama 13 minggu
    await db.addMemberBooking(newBooking, totalWeeks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal booking member berhasil dibuat!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Member (3 Bulan)')),
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
                decoration: const InputDecoration(labelText: 'Pilih Pengguna'),
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
                items:
                    indonesianDays.keys.map((day) {
                      return DropdownMenuItem<int>(
                        value: day,
                        child: Text(indonesianDays[day]!),
                      );
                    }).toList(),
                onChanged: (v) => setState(() => _selectedDayOfWeek = v!),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Jam Mulai'),
                subtitle: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
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
                          // Batasi pilihan durasi hingga jam 22:00
                          22 - _selectedTime.hour,
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
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Ringkasan Booking Member:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total Minggu: 13 Minggu'),
              Text('Harga Member: Rp 1.100.000'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _selectedUser != null ? () => _submit(field) : null,
                child: const Text('Buat Jadwal Member'),
              ),
            ],
          );
        },
      ),
    );
  }
}
