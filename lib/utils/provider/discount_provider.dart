import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountProvider extends ChangeNotifier {
  double _disc = 0.0; 
  double get discount => _disc;

  DiscountProvider() {
    _loadDiscount();
  }

  void _loadDiscount() {
    FirebaseFirestore.instance
        .collection('config')
        .doc('discount')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _disc = (doc.data()?['rate'] ?? 0.0).toDouble();
        notifyListeners();
      }
    });
  }

  Future<void> setDiscount(double disc) async {
    _disc = disc;
    notifyListeners();
    await FirebaseFirestore.instance
        .collection('config')
        .doc('discount')
        .set({'rate': disc});
  }
}
