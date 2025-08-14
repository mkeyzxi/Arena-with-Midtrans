// lib/services/sqlite_service.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/field.dart';
import '../models/booking.dart';
import '../models/user.dart'; // Import model User

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
            date TEXT,
            startHour INTEGER,
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
        // --- TABEL BARU UNTUK USERS ---
        await db.execute('''
          CREATE TABLE users (
            email TEXT PRIMARY KEY,
            password TEXT,
            role TEXT
          )
        ''');
      },
    );
    _isInitialized = true;
    await seedFieldsIfEmpty();
    await seedAdminIfEmpty(); // Tambahkan seeding admin
  }

  Future<void> seedFieldsIfEmpty() async {
    // ... (kode seeding field)
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

  // --- FUNGSI BARU UNTUK AUTHENTIKASI ---
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
      );
      await _db.insert('users', admin.toMap());
    }
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

  // ... (fungsi lainnya)
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

  final _bookingController = StreamController<List<Booking>>.broadcast();
  Stream<List<Booking>> streamBookings() {
    _refreshBookings();
    return _bookingController.stream;
  }

  Future<void> _refreshBookings() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'bookings',
      orderBy: 'date DESC',
    );
    _bookingController.sink.add(maps.map((e) => Booking.fromMap(e)).toList());
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
