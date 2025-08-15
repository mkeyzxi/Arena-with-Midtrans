import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/sqlite_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String orderId;
  final String redirectUrl;
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.orderId,
    required this.redirectUrl,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final WebViewController _controller;
  final fs = SqliteService();
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
                if (url.contains('mockpay.local/success') && !_paidHandled) {
                  _paidHandled = true;
                  fs.updateBooking(widget.bookingId, {'status': 'paid'});
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: const Text('Pembayaran Berhasil'),
                            content: const Text(
                              'Pembayaran mock berhasil. Status booking diupdate menjadi PAID.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  }
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran (Mock Midtrans)')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
