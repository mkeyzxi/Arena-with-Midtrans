import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sqlite_service.dart';
import '../models/booking.dart';

class AdminMonitorScreen extends StatefulWidget {
  const AdminMonitorScreen({super.key});

  @override
  State<AdminMonitorScreen> createState() => _AdminMonitorScreenState();
}

class _AdminMonitorScreenState extends State<AdminMonitorScreen> {
  final db = SqliteService();
  DateTime _selectedDate = DateTime.now();
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
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
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Terjadi error: ${snap.error}'));
          }
          final bookings = snap.data ?? [];
          final bookedSlots = <DateTime, Booking>{};
          for (var b in bookings) {
            bookedSlots[b.startTime] = b;
            for (var i = 1; i < b.durationHours; i++) {
              bookedSlots[b.startTime.add(Duration(hours: i))] = b;
            }
          }

          final int openHour = 8;
          final int closeHour = 22;

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
                  itemCount: closeHour - openHour,
                  itemBuilder: (_, i) {
                    final timeSlot = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      openHour + i,
                    );
                    final isBooked = bookedSlots.containsKey(timeSlot);

                    return Card(
                      color:
                          isBooked
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(_formatTime(timeSlot)),
                        subtitle:
                            isBooked
                                ? Text(
                                  'Booked by: ${bookedSlots[timeSlot]!.customerName}',
                                )
                                : const Text('Available'),
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
