// lib/services/midtrans_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class MidtransService {
  final String _serverKey = 'SB-Mid-server-CFY3sNf0svF0yQL7lOcGybxB';
  final String _clientKey = 'SB-Mid-client-AuJdg2WzPtuHZvVP';
  final String _midtransApiUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';

  Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
  }) async {
    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$_serverKey:'));

    final Map<String, dynamic> body = {
      'transaction_details': {'order_id': orderId, 'gross_amount': amount},
      'customer_details': {'first_name': customerName, 'email': customerEmail},
    };

    try {
      final response = await http.post(
        Uri.parse(_midtransApiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'token': responseBody['token'],
          'redirect_url': responseBody['redirect_url'],
        };
      } else {
        throw Exception(
          'Failed to create transaction: ${responseBody['error_messages']}',
        );
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
