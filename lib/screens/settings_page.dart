// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:final_app/main.dart';
import 'package:final_app/utils/provider/notification_provider.dart';
import 'package:final_app/utils/provider/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthRepository _authRepository = AuthRepository();
  final User? user = FirebaseAuth.instance.currentUser;

  final ValueNotifier<bool> isNotificationOn = ValueNotifier(
    NotificationProvider().isNotifOn,
  );
  final ValueNotifier<String> currentName = ValueNotifier('');
  final ValueNotifier<String> currentAddress = ValueNotifier('');
  final ValueNotifier<String> currentPhone = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenOrderStatusChanges();
  }

  void _loadUserProfile() async {
    final uid = user?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();

    currentName.value = data?['name'] ?? user?.displayName ?? '';
    currentAddress.value = data?['address'] ?? '';
    currentPhone.value = data?['phone'] ?? '';
  }

  void _listenOrderStatusChanges() {
    final userId = user?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
          for (var docChange in snapshot.docChanges) {
            if (docChange.type == DocumentChangeType.modified &&
                isNotificationOn.value) {
              final data = docChange.doc.data();
              if (data != null) {
                final status = data['status'] ?? 'Pending';
                flutterLocalNotificationsPlugin.show(
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  "Order Update",
                  "Your order #${data['orderId'] ?? ''} is now $status",
                  const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'order_channel',
                      'Order Updates',
                      importance: Importance.high,
                      priority: Priority.high,
                    ),
                  ),
                );
              }
            }
          }
        });
  }

  void _showNotification(String title, String message, {bool error = true}) {
    ElegantNotification.info(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      description: Text(message, style: const TextStyle(color: Colors.white)),
      background: const Color(0xFF8B5E3C),
      icon: Icon(error ? Icons.error : Icons.check_circle, color: Colors.white),
      toastDuration: const Duration(seconds: 2),
    ).show(context);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authRepository.signOut();
        _showNotification("Success", "Logged Out", error: false);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } catch (e) {
        _showNotification("Error", e.toString());
      }
    }
  }

  Stream<QuerySnapshot> _getUserOrders() {
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      "Personal Info",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FaIcon(FontAwesomeIcons.infoCircle),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(width: 0),
                          Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editProfileDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/MainLogo.png')
                                  as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<String>(
                        valueListenable: currentName,
                        builder: (context, name, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 255, 128, 0),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder<String>(
                        valueListenable: currentAddress,
                        builder: (context, address, _) => Text(
                          "🏠 $address",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 128, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: currentPhone,
                        builder: (context, phone, _) => Text(
                          "📞 $phone",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 128, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 20),
              Divider(height: 2.0),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FaIcon(FontAwesomeIcons.userGear),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              _buildSettingTile(
                icon: themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                color: themeProvider.isDark ? Colors.amber : Colors.blueGrey,
                title: "Dark Mode",
                subtitle: themeProvider.isDark
                    ? "Switch to light mode"
                    : "Switch to dark mode",
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    themeProvider.toggleTheme();
                  },
                ),
              ),

              _buildSettingTile(
                icon: notificationProvider.isNotifOn
                    ? FontAwesomeIcons.bell
                    : FontAwesomeIcons.bellSlash,
                color: notificationProvider.isNotifOn
                    ? Colors.lightGreenAccent
                    : Colors.redAccent,
                title: "Notifications",
                subtitle: notificationProvider.isNotifOn
                    ? "Enabled"
                    : "Disabled",
                trailing: Switch(
                  value: notificationProvider.isNotifOn,
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    notificationProvider.toggleNotification();
                  },
                ),
              ),

              _buildSettingTile(
                icon: Icons.logout,
                color: Colors.redAccent,
                title: "Log Out",
                subtitle: "Sign out of your account",
                trailing: IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.redAccent,
                  onPressed: _logout,
                ),
              ),

              SizedBox(height: 30),

              Center(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 0.5),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(FontAwesomeIcons.solidCopyright),
                      SizedBox(width: 10),
                      Text("All rights reserved @KhajaKham v1.0.0"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Divider(height: 2.0),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      "Order History",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    FaIcon(FontAwesomeIcons.list),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: _getUserOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text("Error: ${snapshot.error}"),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No order history found 😔"),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: orders.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = orders[index].data() as Map<String, dynamic>;
                      final items = List.from(data['items'] ?? []);
                      final totalPrice = data['totalPrice'] ?? '--';
                      final status = data['status'] ?? 'Processing';
                      final pStatus = data['pStatus'] ?? 'Pending';
                      final orderId = data['orderId'] ?? "#";
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      final dateStr = timestamp != null
                          ? DateFormat('y-M-d E, h:mm a').format(timestamp)
                          : 'Unknown date';
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ExpansionTile(
                          leading: Icon(
                            Icons.fastfood_rounded,
                            color: _getStatusColor(status),
                          ),
                          title: Text("Order #$orderId"),
                          subtitle: Text(
                            "Total: Rs.$totalPrice\nStatus: $status\nPayment: $pStatus\n$dateStr",
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: items.isEmpty
                              ? const [ListTile(title: Text("Cart was empty"))]
                              : items.map((item) {
                                  return ListTile(
                                    title: Text(item['name'] ?? 'Unknown Item'),
                                    subtitle: Text(
                                      "Rs.${(item['price']).toStringAsFixed(2) ?? '--'} x ${item['quantity'] ?? 1}",
                                    ),
                                  );
                                }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
      ),
    );
  }

  void _editProfileDialog(BuildContext context) async {
    final uid = user?.uid;
    if (uid == null) return;

    final nameController = TextEditingController(text: currentName.value);
    final addressController = TextEditingController(text: currentAddress.value);
    final phoneController = TextEditingController(text: currentPhone.value);

    showDialog(
      context: context,
      builder: (_) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inputField("Full Name", nameController),
                  const SizedBox(height: 12),
                  _inputField("Address", addressController),
                  const SizedBox(height: 12),
                  _inputField("Phone Number", phoneController, isPhone: true),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final address = addressController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty ||
                              address.isEmpty ||
                              phone.isEmpty) {
                            _showNotification(
                              "Error",
                              "Please fill all fields",
                            );
                            return;
                          }
                          if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phone)) {
                            _showNotification(
                              "Error",
                              "Enter a valid phone number",
                            );
                            return;
                          }

                          try {
                            setDialogState(() => isSaving = true);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                                  'name': name,
                                  'address': address,
                                  'phone': phone,
                                  'email': user?.email ?? '',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                            await user?.updateDisplayName(name);
                            await user?.reload();

                            currentName.value = name;
                            currentAddress.value = address;
                            currentPhone.value = phone;

                            Navigator.pop(context);
                            _showNotification(
                              "Updated",
                              "Profile updated successfully",
                              error: false,
                            );
                          } catch (e) {
                            _showNotification("Error", e.toString());
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return TextField(
      maxLength: isPhone ? 15 : 20,
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(isPhone ? Icons.phone : Icons.person),
      ),
    );
  }
}
