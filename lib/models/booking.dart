// lib/models/booking.dart

import 'package:flutter/material.dart';

class Booking {
  final String? id;
  final String fieldId;
  final String fieldName;
  final DateTime startTime;
  final int durationHours;
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
    required this.startTime,
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

  DateTime get endTime => startTime.add(Duration(hours: durationHours));

  Map<String, dynamic> toMap() => {
    'id': id,
    'fieldId': fieldId,
    'fieldName': fieldName,
    'startTime': startTime.toIso8601String(),
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
    startTime: DateTime.parse(d['startTime']),
    durationHours:
        d['durationHours'] is int
            ? d['durationHours']
            : int.tryParse(d['durationHours'].toString()) ?? 1,
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
