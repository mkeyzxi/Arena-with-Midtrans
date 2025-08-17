// lib/services/sqlite_service.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() {
    return _instance;
  }
  SqliteService._internal();

  late Database _db;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'arena_app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE fields (
            id TEXT PRIMARY KEY,
            name TEXT,
            openHour TEXT,
            closeHour TEXT,
            pricePerHour INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE bookings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fieldId TEXT,
            fieldName TEXT,
            startTime TEXT,
            durationHours INTEGER,
            pricePerHour INTEGER,
            total INTEGER,
            downPayment INTEGER,
            status TEXT,
            snapToken TEXT,
            redirectUrl TEXT,
            customerName TEXT,
            customerEmail TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE users (
            email TEXT PRIMARY KEY,
            password TEXT,
            role TEXT,
            username TEXT
          )
        ''');
      },
    );
    _isInitialized = true;
    await seedFieldsIfEmpty();
    await seedAdminIfEmpty();
  }

  Future<void> seedFieldsIfEmpty() async {
    final existingFields = await _db.query('fields');
    if (existingFields.isEmpty) {
      final field = Field(
        id: 'finyl_futsal_id',
        name: 'Lapangan Futsal Finyl',
        openHour: '08:00',
        closeHour: '22:00',
        pricePerHour: 100000,
      );
      await _db.insert('fields', field.toMap());
    }
  }

  Future<void> seedAdminIfEmpty() async {
    final existingAdmin = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['admin@arena.com'],
    );
    if (existingAdmin.isEmpty) {
      final admin = User(
        email: 'admin@arena.com',
        password: 'admin',
        role: 'admin',
        username: 'Admin Arena',
      );
      await _db.insert('users', admin.toMap());
    }
  }

  Future<List<User>> getAllUsers() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'users',
      orderBy: 'username ASC',
    );
    return maps.map((e) => User.fromMap(e)).toList();
  }

  Future<User?> findUserByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> registerUser(User user) async {
    await _db.insert('users', user.toMap());
  }

  Future<Field> getSingleField() async {
    final fields = await _db.query('fields', limit: 1);
    if (fields.isNotEmpty) {
      return Field.fromMap(fields.first);
    }
    return Field(
      id: '',
      name: 'Lapangan tidak tersedia',
      openHour: '08:00',
      closeHour: '22:00',
      pricePerHour: 100000,
    );
  }

  Future<String> addBooking(Booking b) async {
    final id = await _db.insert('bookings', b.toMap());
    return id.toString();
  }

  // --- PERBAIKAN DI addMemberBooking: 13 kali booking ---
  Future<void> addMemberBooking(Booking b, int repeatCount) async {
    final batch = _db.batch();
    for (int i = 0; i < repeatCount; i++) {
      final bookingTime = b.startTime.add(Duration(days: i * 7));
      final newBooking = b.toMap();
      newBooking['startTime'] = bookingTime.toIso8601String();
      batch.insert('bookings', newBooking);
    }
    await batch.commit();
    _refreshBookings();
  }
  // ------------------------------------------

  final _bookingController = StreamController<List<Booking>>.broadcast();
  Stream<List<Booking>> streamBookings() {
    _refreshBookings();
    return _bookingController.stream;
  }

  Future<void> _refreshBookings() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'bookings',
      orderBy: 'startTime DESC',
    );
    _bookingController.sink.add(maps.map((e) => Booking.fromMap(e)).toList());
  }

  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final List<Map<String, dynamic>> maps = await _db.query(
      'bookings',
      where: 'strftime(\'%Y-%m-%d\', startTime) = ? AND status IN (?, ?)',
      whereArgs: [dateString, 'paid', 'pending_payment'],
      orderBy: 'startTime ASC',
    );
    return maps.map((e) => Booking.fromMap(e)).toList();
  }

  Future<List<Booking>> getUserBookings(String userEmail) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'bookings',
      where: 'customerEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'startTime DESC',
    );
    return maps.map((e) => Booking.fromMap(e)).toList();
  }

  Future<void> updateBooking(String id, Map<String, dynamic> data) async {
    await _db.update(
      'bookings',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
    _refreshBookings();
  }
}
