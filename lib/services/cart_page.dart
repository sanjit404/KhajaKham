import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:final_app/utils/provider/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _loadingUserData = false;

  @override
  void initState() {
    super.initState();
    Provider.of<CartProvider>(context, listen: false).loadCart();
  }

  void _showNotification(String title, String message, {bool error = true}) {
    ElegantNotification.error(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      description: Text(message, style: const TextStyle(color: Colors.white)),
      background: const Color.fromARGB(255, 114, 69, 21),
      icon: Icon(error ? Icons.error : Icons.check, color: Colors.white),
      toastDuration: const Duration(seconds: 1),
    ).show(context);
  }

  Future<void> _fillUserDetails() async {
    setState(() => _loadingUserData = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _locationController.text = data['address'] ?? '';
        _phoneController.text = data['phone'] ?? '';
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    setState(() => _loadingUserData = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Basket")),
        body: const Center(child: Text("Your Basket is empty 😔")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Basket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: item.imageUrl.isNotEmpty
                        ? Image.network(item.imageUrl, width: 50, height: 50)
                        : const Icon(Icons.fastfood),
                    title: Text(item.name),
                    subtitle: Text(
                      "Rs.${(item.price).toStringAsFixed(1)} x ${item.quantity} = Rs.${(item.price * item.quantity).toStringAsFixed(2)}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            cart.updateQuantity(item.menuId, -1);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            cart.updateQuantity(item.menuId, 1);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Delivery Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Delivery Location",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _notesController,
              maxLines: 5,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: "Notes (Optional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _loadingUserData ? null : _fillUserDetails,
                icon: const Icon(Icons.person_pin_circle, color: Colors.white),
                label: _loadingUserData
                    ? const Text(
                        "Loading...",
                        style: TextStyle(color: Colors.white),
                      )
                    : const Text(
                        "Use My Info",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Column(
              children: [
                Text(
                  "Total: Rs.${cart.totalPrice.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();

                          final location = _locationController.text.trim();
                          final phone = _phoneController.text.trim();
                          final notes = _notesController.text.trim();

                          if (location.isEmpty || phone.isEmpty) {
                            _showNotification(
                              "Error",
                              "Fill All Fields",
                              error: true,
                            );
                            return;
                          }

                          cart.checkout(
                            context,
                            deliveryLocation: location,
                            phone: phone,
                            notes: notes,
                          );
                        },
                        child: cart.isCheckingOut
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Check Out",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: cart.isClearingCart
                                  ? null
                                  : () async {
                                      HapticFeedback.lightImpact();
                                      await cart.clearCart(context);
                                    },
                              child: cart.isClearingCart
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Clear Basket",
                                      style: TextStyle(color: Colors.white),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
