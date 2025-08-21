// lib/screens/admin_monitor_screen.dart

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
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<List<dynamic>> _fetchData() {
    return Future.wait([
      db.getSingleField(),
      db.getBookingsForDate(_selectedDate),
    ]);
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
        _dataFuture = _fetchData();
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  List<Map<String, dynamic>> _generateTimeSlots(
    Field field,
    List<Booking> bookings,
  ) {
    final List<Map<String, dynamic>> slots = [];
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

    DateTime currentTime = openTime;

    bookings.sort((a, b) => a.startTime.compareTo(b.startTime));

    for (var booking in bookings) {
      if (booking.startTime.isAfter(currentTime)) {
        slots.add({
          'startTime': currentTime,
          'endTime': booking.startTime,
          'status': 'Tersedia',
        });
      }

      slots.add({
        'startTime': booking.startTime,
        'endTime': booking.endTime,
        'status': 'Booked',
        'customerName': booking.customerName,
      });
      currentTime = booking.endTime;
    }

    if (currentTime.isBefore(closeTime)) {
      slots.add({
        'startTime': currentTime,
        'endTime': closeTime,
        'status': 'Tersedia',
      });
    }

    final List<Map<String, dynamic>> finalSlots = [];
    final currentDay = DateTime(now.year, now.month, now.day);
    if (_selectedDate.isAtSameMomentAs(currentDay)) {
      DateTime pastTime = openTime;
      for (var slot in slots) {
        if (pastTime.isBefore(now)) {
          if (slot['startTime'].isAfter(now)) {
            finalSlots.add({
              'startTime': pastTime,
              'endTime': now,
              'status': 'Lewat Waktu',
            });
            pastTime = now;
          } else {
            finalSlots.add({
              'startTime': pastTime,
              'endTime': slot['endTime'],
              'status': 'Lewat Waktu',
            });
            pastTime = slot['endTime'];
          }
        }
        if (slot['startTime'].isAfter(now)) {
          finalSlots.add(slot);
        }
      }
    } else {
      finalSlots.addAll(slots);
    }

    finalSlots.removeWhere(
      (slot) =>
          slot['status'] == 'Lewat Waktu' &&
          slot['endTime'].isAtSameMomentAs(slot['startTime']),
    );

    return finalSlots;
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
        future: _dataFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }

          final field = snap.data![0] as Field;
          final bookings = snap.data![1] as List<Booking>;
          final scheduleItems = _generateTimeSlots(field, bookings);

          // Pastikan locale diatur ke 'id_ID' untuk format tanggal
          Intl.defaultLocale = 'id_ID';

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
                child: ListView.builder(
                  itemCount: scheduleItems.length,
                  itemBuilder: (_, i) {
                    final item = scheduleItems[i];
                    final String status = item['status'];
                    final Color color =
                        status == 'Tersedia'
                            ? Colors.green.shade100
                            : status == 'Booked'
                            ? Colors.red.shade100
                            : Colors.grey.shade300;

                    return Card(
                      color: color,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          '${_formatTime(item['startTime'])} - ${_formatTime(item['endTime'])}',
                        ),
                        trailing:
                            status == 'Booked'
                                ? Text('Booked oleh ${item['customerName']}')
                                : Text(status),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
