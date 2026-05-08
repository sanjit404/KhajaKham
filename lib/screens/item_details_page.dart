// ignore_for_file: use_build_context_synchronously

import 'package:final_app/services/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:final_app/model/cart_item.dart';
import 'package:final_app/utils/provider/cart_provider.dart';

class ItemDetailsPage extends StatelessWidget {
  final String menuId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  const ItemDetailsPage({
    super.key,
    required this.menuId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
         actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                ),
                if (cart.items.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        cart.items.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.fastfood, size: 100),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Rs. ${price.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color.fromARGB(255, 151, 114, 102),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    description.isNotEmpty
                        ? description
                        : "No description available.",
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  
                  Consumer<CartProvider>(
                    builder: (_, cartProvider, __) {
                      final isAdded = cartProvider.isInCart(menuId);
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  Colors.brown.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            isAdded
                                ? Icons.check_circle
                                : Icons.add_shopping_cart,
                            color: Colors.white,
                          ),
                          label: Text(
                            isAdded ? "Added to Basket" : "Add to Basket",
                            style: const TextStyle(color: Colors.white),
                          ),
                          onPressed: isAdded
                              ? null
                              : () {
                                  cartProvider.addItem(
                                    CartItem(
                                      menuId: menuId,
                                      name: name,
                                      price: price,
                                      imageUrl: imageUrl,
                                    ),
                                  );
                                  HapticFeedback.lightImpact();
                                },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
