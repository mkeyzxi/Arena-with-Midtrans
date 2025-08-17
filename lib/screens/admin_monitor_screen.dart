import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../models/booking.dart';
import '../models/field.dart';

class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key});

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen> {
  final db = SqliteService();
  DateTime _selectedDate = DateTime.now();
  late Future<List<Booking>> _bookingsFuture;
  late Future<Field> _fieldFuture;

  @override
  void initState() {
    super.initState();
    _fieldFuture = db.getSingleField();
    _bookingsFuture = db.getBookingsForDate(_selectedDate);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _selectedDate,
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _bookingsFuture = db.getBookingsForDate(_selectedDate);
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Jadwal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_fieldFuture, _bookingsFuture]),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }

          final field = snap.data![0] as Field;
          final bookings = snap.data![1] as List<Booking>;

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
          final now = DateTime.now();

          final List<Widget> scheduleCards = [];

          DateTime currentTime = openTime;

          // Blok Waktu Lewat
          if (now.isAfter(openTime) &&
              now.isBefore(closeTime) &&
              _selectedDate.isAtSameMomentAs(
                DateTime(now.year, now.month, now.day),
              )) {
            scheduleCards.add(
              Card(
                color: Colors.grey.shade300,
                child: ListTile(
                  title: Text('${_formatTime(openTime)} - ${_formatTime(now)}'),
                  trailing: const Text('Lewat Waktu'),
                ),
              ),
            );
            currentTime = now;
          }

          // Blok Waktu Terbooking dan Tersedia
          for (var booking in bookings) {
            if (booking.startTime.isAfter(currentTime)) {
              // Tambah kartu Tersedia
              scheduleCards.add(
                Card(
                  color: Colors.green.shade100,
                  child: ListTile(
                    title: Text(
                      '${_formatTime(currentTime)} - ${_formatTime(booking.startTime)}',
                    ),
                    trailing: const Text('Tersedia'),
                  ),
                ),
              );
            }
            // Tambah kartu Terbooking
            scheduleCards.add(
              Card(
                color: Colors.red.shade100,
                child: ListTile(
                  title: Text(
                    '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                  ),
                  trailing: Text('Booked oleh ${booking.customerName}'),
                ),
              ),
            );
            currentTime = booking.endTime;
          }

          // Blok Waktu Tersisa
          if (currentTime.isBefore(closeTime)) {
            scheduleCards.add(
              Card(
                color: Colors.green.shade100,
                child: ListTile(
                  title: Text(
                    '${_formatTime(currentTime)} - ${_formatTime(closeTime)}',
                  ),
                  trailing: const Text('Tersedia'),
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Jadwal untuk: ${DateFormat('EEE, dd MMM yyyy').format(_selectedDate)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children:
                      scheduleCards.isNotEmpty
                          ? scheduleCards
                          : [
                            const Center(
                              child: Text(
                                'Tidak ada booking untuk tanggal ini.',
                              ),
                            ),
                          ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
