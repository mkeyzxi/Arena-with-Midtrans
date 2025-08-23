// lib/services/firebase_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mendapatkan satu lapangan futsal
  Future<Field> getSingleField() async {
    final snapshot = await _db.collection('fields').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return Field.fromMap(data);
    }
    return Field(
      id: '',
      name: 'Lapangan tidak tersedia',
      openHour: '08:00',
      closeHour: '22:00',
      pricePerHour: 100000,
    );
  }

  // Mendapatkan semua pengguna
  Future<List<User>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((e) => User.fromMap(e.data())).toList();
  }

  // Mencari pengguna berdasarkan email
  Future<User?> findUserByEmail(String email) async {
    final snapshot =
        await _db
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
    if (snapshot.docs.isNotEmpty) {
      return User.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  // Mendaftarkan pengguna baru
  Future<void> registerUser(User user) async {
    await _db.collection('users').doc(user.email).set(user.toMap());
  }

  // Menambahkan booking
  Future<String> addBooking(Booking b) async {
    final docRef = await _db.collection('bookings').add(b.toMap());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  // Menambahkan booking member berulang
  Future<void> addMemberBooking(Booking b, int repeatCount) async {
    final CollectionReference bookings = _db.collection('bookings');
    for (int i = 0; i < repeatCount; i++) {
      final bookingTime = b.startTime.add(Duration(days: i * 7));
      final newBooking = b.toMap();
      newBooking['startTime'] = bookingTime.toIso8601String();
      final docRef = await bookings.add(newBooking);
      await docRef.update({'id': docRef.id});
    }
  }

  // Stream semua booking untuk admin (real-time)
  Stream<List<Booking>> streamAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Booking.fromMap(doc.data()))
              .toList();
        });
  }

  // Mendapatkan booking untuk tanggal tertentu
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot =
        await _db
            .collection('bookings')
            .where(
              'startTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
            )
            .where('startTime', isLessThan: endOfDay.toIso8601String())
            .get();

    return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
  }

  // Mendapatkan booking untuk pengguna tertentu
  Future<List<Booking>> getUserBookings(String userEmail) async {
    final snapshot =
        await _db
            .collection('bookings')
            .where('customerEmail', isEqualTo: userEmail)
            .orderBy('startTime', descending: true)
            .get();
    return snapshot.docs.map((doc) => Booking.fromMap(doc.data())).toList();
  }

  // Mengupdate booking
  Future<void> updateBooking(String id, Map<String, dynamic> data) async {
    await _db.collection('bookings').doc(id).update(data);
  }
}
