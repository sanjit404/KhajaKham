import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  bool _isNotifOn = true;
  bool get isNotifOn => _isNotifOn;


  NotificationProvider() {
    _loadFromPrefs();
  }

  void toggleNotification() {
    _isNotifOn = !_isNotifOn;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isNotifOn = prefs.getBool("isNotifOn") ?? false; 
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isNotifOn", _isNotifOn);
  }
}
