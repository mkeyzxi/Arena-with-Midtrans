// lib/screens/admin_monitor_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart'; // Ganti dengan FirebaseService
import '../models/booking.dart';
import '../models/field.dart';

class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key});

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen> {
  final db = FirebaseService();
  DateTime _selectedDate = DateTime.now();
  late Stream<List<Booking>> _bookingsStream;
  late Future<Field> _fieldFuture;

  @override
  void initState() {
    super.initState();
    _bookingsStream = db.streamAllBookings();
    _fieldFuture = db.getSingleField();
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
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  // Mengubah logika _generateTimeSlots agar sesuai dengan data dari StreamBuilder
  List<Map<String, dynamic>> _generateTimeSlots(
    Field field,
    List<Booking> allBookings,
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

    // Filter booking untuk tanggal yang dipilih
    final bookingsOnDate =
        allBookings.where((b) {
          final bookingDate = b.startTime;
          return bookingDate.year == _selectedDate.year &&
              bookingDate.month == _selectedDate.month &&
              bookingDate.day == _selectedDate.day;
        }).toList();

    // Urutkan booking
    bookingsOnDate.sort((a, b) => a.startTime.compareTo(b.startTime));

    DateTime currentTime = openTime;

    for (var booking in bookingsOnDate) {
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
      for (var slot in slots) {
        if (slot['endTime'].isAfter(now)) {
          finalSlots.add(slot);
        } else {
          finalSlots.add({
            'startTime': slot['startTime'],
            'endTime': slot['endTime'],
            'status': 'Lewat Waktu',
          });
        }
      }
    } else {
      finalSlots.addAll(slots);
    }

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
      body: FutureBuilder<Field>(
        future: _fieldFuture,
        builder: (_, fieldSnap) {
          if (fieldSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (fieldSnap.hasError) {
            return Center(child: Text('Terjadi error: ${fieldSnap.error}'));
          }

          final field = fieldSnap.data!;
          final dateLabel = DateFormat(
            'EEE, dd MMM yyyy',
            'id_ID',
          ).format(_selectedDate);

          return StreamBuilder<List<Booking>>(
            stream: _bookingsStream,
            builder: (_, bookingSnap) {
              if (bookingSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (bookingSnap.hasError) {
                return Center(
                  child: Text('Terjadi error: ${bookingSnap.error}'),
                );
              }

              final allBookings = bookingSnap.data ?? [];
              final scheduleItems = _generateTimeSlots(field, allBookings);

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Jadwal untuk: $dateLabel',
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
                                    ? Text(
                                      'Booked oleh ${item['customerName']}',
                                    )
                                    : Text(status),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
