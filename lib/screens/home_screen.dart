// // lib/screens/home_screen.dart

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../models/user.dart';
// import '../models/booking.dart';
// import '../services/firebase_service.dart';
// import 'user_booking_screen.dart';
// import 'transaction_history_screen.dart';
// import 'login_screen.dart';
// import '../models/field.dart';

// class HomeScreen extends StatefulWidget {
//   final User user;
//   const HomeScreen({super.key, required this.user});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final db = FirebaseService();
//   late Future<List<Booking>> _latestBookingFuture;
//   late Future<List<DateTime>> _availableSlotsFuture;
//   late Future<Field> _fieldFuture;
//   DateTime _selectedDate = DateTime.now();

//   @override
//   void initState() {
//     super.initState();
//     Intl.defaultLocale = 'id_ID';
//     _fetchData();
//   }

//   void _fetchData() {
//     _latestBookingFuture = _getLatestBooking();
//     _fieldFuture = db.getSingleField();
//     _availableSlotsFuture = _getAvailableSlots();
//   }

//   Future<List<Booking>> _getLatestBooking() async {
//     final allBookings = await db.getUserBookings(widget.user.email);
//     final now = DateTime.now();
//     final upcomingBookings =
//         allBookings
//             .where((b) => b.status == 'paid' && b.startTime.isAfter(now))
//             .toList();
//     if (upcomingBookings.isNotEmpty) {
//       upcomingBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
//       return [upcomingBookings.first];
//     }
//     return [];
//   }

//   Future<List<DateTime>> _getAvailableSlots() async {
//     final field = await db.getSingleField();
//     final bookings = await db.getBookingsForDate(_selectedDate);
//     final List<DateTime> availableSlots = [];
//     final openTime = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//       int.parse(field.openHour.split(':')[0]),
//     );
//     final closeTime = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//       int.parse(field.closeHour.split(':')[0]),
//     );
//     final now = DateTime.now();

//     DateTime currentTime = openTime;
//     while (currentTime.isBefore(closeTime)) {
//       final isBooked = bookings.any((b) {
//         return (currentTime.isAfter(b.startTime) ||
//                 currentTime.isAtSameMomentAs(b.startTime)) &&
//             (currentTime.isBefore(b.endTime));
//       });
//       final isPast = _selectedDate.day == now.day && currentTime.isBefore(now);

//       if (!isBooked && !isPast) {
//         availableSlots.add(currentTime);
//       }
//       currentTime = currentTime.add(const Duration(minutes: 60));
//     }
//     return availableSlots;
//   }

//   Future<void> _pickDate() async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 60)),
//       initialDate: _selectedDate,
//     );
//     if (pickedDate != null && pickedDate != _selectedDate) {
//       setState(() {
//         _selectedDate = pickedDate;
//         _availableSlotsFuture = _getAvailableSlots();
//       });
//     }
//   }

//   String _formatTime(DateTime time) {
//     return DateFormat('HH:mm').format(time);
//   }

//   String _formatDay(DateTime time) {
//     return DateFormat.EEEE('id_ID').format(time);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Arena Booking'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               Navigator.of(context).pushAndRemoveUntil(
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//                 (Route<dynamic> route) => false,
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           children: [
//             UserAccountsDrawerHeader(
//               accountName: Text(widget.user.username),
//               accountEmail: Text(widget.user.email),
//               currentAccountPicture: const CircleAvatar(
//                 child: Icon(Icons.person),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.calendar_month),
//               title: const Text('Booking Lapangan'),
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => UserBookingScreen(user: widget.user),
//                   ),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.history),
//               title: const Text('Riwayat Transaksi'),
//               onTap: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => TransactionHistoryScreen(user: widget.user),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Card(
//                 color: Theme.of(context).primaryColor,
//                 child: Padding(
//                   padding: const EdgeInsets.all(24.0),
//                   child: Row(
//                     children: [
//                       const Icon(
//                         Icons.sports_soccer,
//                         color: Colors.white,
//                         size: 50,
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Selamat Datang!',
//                               style: TextStyle(color: Colors.white70),
//                             ),
//                             Text(
//                               widget.user.username,
//                               style: Theme.of(
//                                 context,
//                               ).textTheme.headlineSmall?.copyWith(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Booking Terbaru Anda',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               const SizedBox(height: 8),
//               FutureBuilder<List<Booking>>(
//                 future: _latestBookingFuture,
//                 builder: (_, snap) {
//                   if (snap.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (snap.hasData && snap.data!.isNotEmpty) {
//                     final booking = snap.data!.first;
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(
//                             builder:
//                                 (_) =>
//                                     TransactionHistoryScreen(user: widget.user),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         child: ListTile(
//                           title: Text(booking.fieldName),
//                           subtitle: Text(
//                             '${_formatDay(booking.startTime)}, '
//                             '${DateFormat('dd MMM yyyy').format(booking.startTime)} • '
//                             'Jam: ${_formatTime(booking.startTime)}',
//                           ),
//                           trailing: const Icon(Icons.arrow_forward_ios),
//                         ),
//                       ),
//                     );
//                   }
//                   return const Text('Belum ada booking terbaru.');
//                 },
//               ),
//               const SizedBox(height: 24),
//               Card(
//                 child: ListTile(
//                   leading: const Icon(Icons.add_circle, color: Colors.green),
//                   title: const Text('Booking Lapangan'),
//                   subtitle: const Text('Pesan lapangan sekarang juga!'),
//                   trailing: const Icon(Icons.chevron_right),
//                   onTap: () {
//                     Navigator.of(context).push(
//                       MaterialPageRoute(
//                         builder: (_) => UserBookingScreen(user: widget.user),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Jadwal Ketersediaan',
//                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                   ),
//                   IconButton(
//                     onPressed: _pickDate,
//                     icon: const Icon(Icons.calendar_today),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               FutureBuilder<List<DateTime>>(
//                 future: _availableSlotsFuture,
//                 builder: (ctx, snap) {
//                   if (snap.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (snap.hasError) {
//                     return Center(child: Text('Terjadi error: ${snap.error}'));
//                   }
//                   final availableSlots = snap.data ?? [];

//                   return Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Tanggal: ${DateFormat('EEE, dd MMM yyyy', 'id_ID').format(_selectedDate)}',
//                         style: TextStyle(fontSize: 16, color: Colors.grey[700]),
//                       ),
//                       const SizedBox(height: 16),
//                       if (availableSlots.isEmpty)
//                         const Text('Tidak ada slot tersedia di hari ini.')
//                       else
//                         SizedBox(
//                           height: 50,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: availableSlots.length,
//                             itemBuilder:
//                                 (_, i) => Padding(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 4.0,
//                                   ),
//                                   child: Chip(
//                                     label: Text(_formatTime(availableSlots[i])),
//                                     backgroundColor: Colors.green.shade100,
//                                   ),
//                                 ),
//                           ),
//                         ),
//                     ],
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Keunggulan Lapangan',
//                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//               ),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: 120,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: [
//                     _advantageCard('Fasilitas Lengkap', Icons.shower),
//                     _advantageCard('Lokasi Strategis', Icons.location_on),
//                     _advantageCard(
//                       'Sistem Booking Mudah',
//                       Icons.calendar_today,
//                     ),
//                     _advantageCard('Harga Terjangkau', Icons.attach_money),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _advantageCard(String title, IconData icon) {
//     return Card(
//       child: Container(
//         width: 150,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 40, color: Theme.of(context).primaryColor),
//             const SizedBox(height: 8),
//             Text(title, textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }
// }

// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';
import 'user_booking_screen.dart';
import 'transaction_history_screen.dart';
import 'login_screen.dart';
import '../models/field.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseService();
  late Future<List<Booking>> _latestBookingFuture;
  late Future<List<DateTime>> _availableSlotsFuture;
  late Future<Field> _fieldFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _fetchData();
  }

  void _fetchData() {
    _latestBookingFuture = _getLatestBooking();
    _fieldFuture = db.getSingleField();
    _availableSlotsFuture = _getAvailableSlots();
  }

  Future<List<Booking>> _getLatestBooking() async {
    final allBookings = await db.getUserBookings(widget.user.email);
    final now = DateTime.now();
    final upcomingBookings = allBookings
        .where((b) => b.status == 'paid' && b.startTime.isAfter(now))
        .toList();
    if (upcomingBookings.isNotEmpty) {
      upcomingBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      return [upcomingBookings.first];
    }
    return [];
  }

  Future<List<DateTime>> _getAvailableSlots() async {
    final field = await db.getSingleField();
    final bookings = await db.getBookingsForDate(_selectedDate);
    final List<DateTime> availableSlots = [];
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
    while (currentTime.isBefore(closeTime)) {
      final isBooked = bookings.any((b) {
        return (currentTime.isAfter(b.startTime) ||
                currentTime.isAtSameMomentAs(b.startTime)) &&
            (currentTime.isBefore(b.endTime));
      });
      final isPast = _selectedDate.day == now.day && currentTime.isBefore(now);

      if (!isBooked && !isPast) {
        availableSlots.add(currentTime);
      }
      currentTime = currentTime.add(const Duration(minutes: 60));
    }
    return availableSlots;
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _selectedDate,
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _availableSlotsFuture = _getAvailableSlots();
      });
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDay(DateTime time) {
    return DateFormat.EEEE('id_ID').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.user.username),
              accountEmail: Text(widget.user.email),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Booking Lapangan'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserBookingScreen(user: widget.user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat Transaksi'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionHistoryScreen(user: widget.user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Theme.of(context).primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.sports_soccer,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selamat Datang!',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      widget.user.username,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Booking Terbaru Anda',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<Booking>>(
                        future: _latestBookingFuture,
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snap.hasData && snap.data!.isNotEmpty) {
                            final booking = snap.data!.first;
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TransactionHistoryScreen(
                                        user: widget.user),
                                  ),
                                );
                              },
                              child: Card(
                                child: ListTile(
                                  title: Text(booking.fieldName),
                                  subtitle: Text(
                                    '${_formatDay(booking.startTime)}, '
                                    '${DateFormat('dd MMM yyyy').format(booking.startTime)} • '
                                    'Jam: ${_formatTime(booking.startTime)}',
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                ),
                              ),
                            );
                          }
                          return const Text('Belum ada booking terbaru.');
                        },
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: ListTile(
                          leading:
                              const Icon(Icons.add_circle, color: Colors.green),
                          title: const Text('Booking Lapangan'),
                          subtitle: const Text('Pesan lapangan sekarang juga!'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserBookingScreen(user: widget.user),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jadwal Ketersediaan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          IconButton(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_today),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<DateTime>>(
                        future: _availableSlotsFuture,
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return Center(
                                child: Text('Terjadi error: ${snap.error}'));
                          }
                          final availableSlots = snap.data ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal: ${DateFormat('EEE, dd MMM yyyy', 'id_ID').format(_selectedDate)}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              if (availableSlots.isEmpty)
                                const Text(
                                    'Tidak ada slot tersedia di hari ini.')
                              else
                                SizedBox(
                                  height: 50,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: availableSlots.length,
                                    itemBuilder: (_, i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: Chip(
                                        label: Text(
                                            _formatTime(availableSlots[i])),
                                        backgroundColor: Colors.green.shade100,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Keunggulan Lapangan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _advantageCard('Fasilitas Lengkap', Icons.shower),
                            _advantageCard(
                                'Lokasi Strategis', Icons.location_on),
                            _advantageCard(
                                'Sistem Booking Mudah', Icons.calendar_today),
                            _advantageCard(
                                'Harga Terjangkau', Icons.attach_money),
                          ],
                        ),
                      ),
                      const Spacer(), // isi space kosong biar full 10/10
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _advantageCard(String title, IconData icon) {
    return Card(
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
