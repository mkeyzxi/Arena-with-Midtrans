// lib/models/booking.dart

import 'package:flutter/material.dart';

class Booking {
  final String? id;
  final String fieldId;
  final String fieldName;
  final DateTime date;
  final double startHour;
  final double durationHours;
  final int pricePerHour;
  final int total;
  final int downPayment;
  final String status;
  final String? snapToken;
  final String? redirectUrl;
  final String customerName;
  final String customerEmail;

  Booking({
    this.id,
    required this.fieldId,
    required this.fieldName,
    required this.date,
    required this.startHour,
    required this.durationHours,
    required this.pricePerHour,
    required this.total,
    required this.downPayment,
    required this.status,
    required this.customerName,
    required this.customerEmail,
    this.snapToken,
    this.redirectUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'fieldId': fieldId,
    'fieldName': fieldName,
    'date': date.toIso8601String(),
    'startHour': startHour,
    'durationHours': durationHours,
    'pricePerHour': pricePerHour,
    'total': total,
    'downPayment': downPayment,
    'status': status,
    'snapToken': snapToken,
    'redirectUrl': redirectUrl,
    'customerName': customerName,
    'customerEmail': customerEmail,
  };

  factory Booking.fromMap(Map<String, dynamic> d) => Booking(
    id: d['id'].toString(),
    fieldId: d['fieldId'],
    fieldName: d['fieldName'],
    date: DateTime.parse(d['date']),
    startHour: d['startHour'],
    durationHours: d['durationHours'],
    pricePerHour: d['pricePerHour'],
    total: d['total'],
    downPayment: d['downPayment'],
    status: d['status'],
    snapToken: d['snapToken'],
    redirectUrl: d['redirectUrl'],
    customerName: d['customerName'] ?? 'Guest',
    customerEmail: d['customerEmail'] ?? 'guest@example.com',
  );
}
