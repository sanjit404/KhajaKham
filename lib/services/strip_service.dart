// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeService {
  static const _secretKey = 'sk_test_xxxx'; // test key only

  static Future<String?> createPaymentIntent(double amount) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(),
          'currency': 'npr',
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['client_secret'];
      } else {
        print('Stripe error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }
}
