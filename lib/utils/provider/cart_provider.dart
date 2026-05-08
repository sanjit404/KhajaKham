// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, avoid_types_as_parameter_names, unrelated_type_equality_checks

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:final_app/model/cart_item.dart';
import 'package:final_app/services/localnotification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class CartProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<CartItem> _items = [];
  bool _isCheckingOut = false;
bool _isClearingCart = false;
bool get isClearingCart => _isClearingCart;

  List<CartItem> get items => _items;
  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);
  bool get isCheckingOut => _isCheckingOut;

  bool isInCart(String menuId) =>
      _items.any((element) => element.menuId == menuId);

  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .get();

      _items = snapshot.docs.map((doc) => CartItem.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load Basket: $e");
    }
  }

  Future<void> _saveItemToFirestore(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(item.menuId)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> _deleteItemFromFirestore(String menuId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(menuId)
        .delete();
  }

  Future<void> _clearFirestoreCart() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final docs = await cartRef.get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  void addItem(CartItem item) {
    final index = _items.indexWhere((e) => e.menuId == item.menuId);
    if (index != -1) {
      _items[index].quantity++;
      _saveItemToFirestore(_items[index]);
    } else {
      _items.add(item);
      _saveItemToFirestore(item);
    }
    notifyListeners();
  }

Future<void> clearCart(BuildContext context) async {
  if (_isClearingCart) return; 

  final user = _auth.currentUser;
  if (user == null) return;

  _isClearingCart = true;
  notifyListeners();

  try {
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final docs = await cartRef.get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }

    _items.clear();
    notifyListeners();
    ElegantNotification.success(
      title: const Text("Success", style: TextStyle(color: Colors.white)),
      description:
          Text("Basket Cleared", style: const TextStyle(color: Colors.white)),
      background: const Color.fromARGB(255, 149, 84, 19),
      toastDuration: Duration(seconds: 1),
    ).show(context);

    debugPrint("Basket cleared successfully from Firestore");
  } catch (e) {
    ElegantNotification.error(
      title: const Text("Error", style: TextStyle(color: Colors.white)),
      description:
          Text("Failed to clear Basket: $e", style: const TextStyle(color: Colors.white)),
      background: const Color.fromARGB(255, 149, 84, 19),
    ).show(context);
  } finally {
    _isClearingCart = false;
    notifyListeners();
  }
}





  void updateQuantity(String menuId, int delta) {
    final index = _items.indexWhere((e) => e.menuId == menuId);
    if (index == -1) return;

    _items[index].quantity += delta;
    if (_items[index].quantity <= 0) {
      _deleteItemFromFirestore(menuId);
      _items.removeAt(index);
    } else {
      _saveItemToFirestore(_items[index]);
    }
    notifyListeners();
  }

  void _showElegant(
    BuildContext context,
    String title,
    String message, {
    bool success = false,
  }) {
    (success ? ElegantNotification.success : ElegantNotification.error)(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      background: success
          ? const Color.fromARGB(255, 30, 100, 30)
          : const Color.fromARGB(255, 149, 84, 19),
      description: Text(message, style: const TextStyle(color: Colors.white)),
      toastDuration: const Duration(seconds: 2),
    ).show(context);
  }

  Future<String?> _createPaymentIntent(double amountUSD) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      const secretKey =
          'sk_test_51SI1L3EyK7O5YZFDRhBH9xHiRpPcYm5Lf2qFVMNuorzDXa2EhGQGOEnLvEvTntILSaulFrQPrI5csd76FKqhzh6n00E7dQngJz';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amountUSD * 100).toInt().toString(),
          'currency': 'usd',
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['client_secret'];
      } else {
        debugPrint('Stripe error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  Future<void> checkout(
    BuildContext context, {
    required String deliveryLocation,
    required String phone,
    String? notes,
  }) async {
    if (_isCheckingOut) {
      _showElegant(context, "Wait", "Order is already being processed");
      return;
    }

    if (_items.isEmpty) {
      _showElegant(context, "Error", "Your Basket is empty");
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showElegant(context, "No Internet", "Please connect to the internet");
      return;
    }

    _isCheckingOut = true;
    notifyListeners();

    try {
      final nprAmount = totalPrice;
      final usdAmount = nprAmount / 133;

      final clientSecret = await _createPaymentIntent(usdAmount);
      if (clientSecret == null) {
        _showElegant(context, "Error", "Failed to create payment intent");
        return;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KhajaKham',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final now = DateTime.now();
      final orderId =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}";
      final userId = user.uid;


      await FirebaseFirestore.instance.collection('orders').add({
        'orderId': orderId,
        'userId': userId,
        'items': _items.map((e) => e.toMap()).toList(),
        'totalPrice': totalPrice,
        'status': 'Processing',
        'pStatus': 'Paid',
        'timestamp': FieldValue.serverTimestamp(),
        'location': deliveryLocation,
        'phone': phone,
        'notes': notes ?? '',
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'address': deliveryLocation,
        'phone': phone,
      }, SetOptions(merge: true));

      await _clearFirestoreCart();

      NotificationService().showNotification(
        "Order Placed",
        "Items: ${_items.map((e) => e.name).join(", ")}\nOrder Id: $orderId",
      );

      _items.clear();
      notifyListeners();

      _showElegant(
        context,
        "Success",
        "Payment successful & order placed!",
        success: true,
      );
    } catch (e) {
      _showElegant(context, "Error", "Payment failed or cancelled");
      debugPrint('Checkout error: $e');
    } finally {
      _isCheckingOut = false;
      notifyListeners();
    }
  }
}
