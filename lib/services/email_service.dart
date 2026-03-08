import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _base = 'https://tma-app-emails.vercel.app';

  // triggered after student completes a pro shop purchase
  static Future<void> purchaseConfirmation({
    required String userId,
    required String productName,
    required double price,
    String? size,
  }) async {
    await _post('/api/purchase-confirmation', {
      'userId': userId,
      'productName': productName,
      'price': price,
      if (size != null) 'size': size,
    });
  }

  // triggered when admin logs a monthly tuition payment
  static Future<void> paymentConfirmation({
    required String userId,
    required double amount,
    String? desc,
  }) async {
    await _post('/api/payment-confirmation', {
      'userId': userId,
      'amount': amount,
      'description': desc,
      'date': DateTime.now().toIso8601String(),
    });
  }

  // fire once and forget so failed email doesn't block purchase flow
  static Future<void> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$_base$path'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode != 200) {
        print('email error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('email failed: $e');
    }
  }
}