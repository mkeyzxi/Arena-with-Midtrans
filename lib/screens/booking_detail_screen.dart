// lib/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:arena_futsal_app/screens/admin_monitor_screen.dart';
import 'package:arena_futsal_app/screens/home_screen.dart';
import 'package:arena_futsal_app/models/user.dart';
import 'package:arena_futsal_app/screens/login_screen.dart';
import '../services/firebase_service.dart'; // Ganti dengan FirebaseService

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String orderId;
  final String redirectUrl;
  final User? user;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.orderId,
    required this.redirectUrl,
    this.user,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final WebViewController _controller;
  final db = FirebaseService(); // Ganti dengan FirebaseService
  bool _paidHandled = false;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (req) {
                final url = req.url;

                if ((url.contains('status_code=200') ||
                        url.contains('status_code=201') ||
                        url.contains('mockpay.local/success')) &&
                    !_paidHandled) {
                  _paidHandled = true;
                  db.updateBooking(widget.bookingId, {'status': 'paid'});
                  _showSuccessDialog();
                  return NavigationDecision.prevent;
                }

                if (url.contains('status_code=202') ||
                    url.contains('status_code=4xx')) {
                  db.updateBooking(widget.bookingId, {'status': 'canceled'});
                  _showFailureDialog();
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  void _showSuccessDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Pembayaran Berhasil'),
              content: const Text(
                'Pembayaran berhasil. Status booking diupdate menjadi PAID.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.user != null && widget.user!.role == 'admin') {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AdminMonitorScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else if (widget.user != null) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(user: widget.user!),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  void _showFailureDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Pembayaran Gagal'),
              content: const Text(
                'Pembayaran gagal atau dibatalkan. Status booking diupdate menjadi CANCELLED.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.user != null && widget.user!.role == 'admin') {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const AdminMonitorScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else if (widget.user != null) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(user: widget.user!),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran (Midtrans)')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
