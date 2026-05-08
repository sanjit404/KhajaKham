// ignore_for_file: prefer_is_empty

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_app/model/cart_item.dart';
import 'package:final_app/screens/item_details_page.dart';
import 'package:final_app/services/cart_page.dart';
import 'package:final_app/utils/provider/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String searchQuery = "";

  Stream<QuerySnapshot> _getMenuItems() {
    return FirebaseFirestore.instance
        .collection('menu')
        .orderBy('name')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Menu", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            FaIcon(FontAwesomeIcons.book),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cartProvider, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.basketShopping),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    );
                  },
                ),
                if (cartProvider.items.isNotEmpty)
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
                        cartProvider.items.length.toString(),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for food...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMenuItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No menu items available"));
                }

                final menuItems = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (menuItems.isEmpty) {
                  return const Center(child: Text("No matching items found"));
                }

                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GridView.builder(
                    itemCount: menuItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 25,
                          childAspectRatio: 0.55,
                        ),
                    itemBuilder: (context, index) {
                      final doc = menuItems[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final menuId = doc.id;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsPage(
                                menuId: menuId,
                                name: data['name'],
                                description: data['description'],
                                price: data['price'],
                                imageUrl: data['imageUrl'],
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          shadowColor: Colors.grey.shade300,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child:
                                      (data['imageUrl'] != null &&
                                          data['imageUrl']
                                              .toString()
                                              .isNotEmpty)
                                      ? Image.network(
                                          data['imageUrl'],
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 120,
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    data['name'] ?? 'Unnamed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    data['description'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    "Rs. ${(data['price'] ?? 0).toString()}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 173, 122, 106),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                const Spacer(),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Consumer<CartProvider>(
                                    builder: (_, cartProvider, __) {
                                      final isAdded = cartProvider.isInCart(
                                        menuId,
                                      );
                                      return ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 40,
                                        ),
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.brown.shade600,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                              horizontal: 6,
                                            ),
                                          ),

                                          label: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                children: [
                                                  Text(
                                                    isAdded
                                                        ? "Added"
                                                        : "Add to Basket",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  FaIcon(
                                                    isAdded
                                                        ? FontAwesomeIcons.check
                                                        : FontAwesomeIcons
                                                              .basketShopping,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          onPressed: isAdded
                                              ? null
                                              : () {
                                                  cartProvider.addItem(
                                                    CartItem(
                                                      menuId: menuId,
                                                      name: data['name'] ?? '',
                                                      price:
                                                          (data['price'] ?? 0)
                                                              .toDouble(),
                                                      imageUrl:
                                                          data['imageUrl'] ??
                                                          '',
                                                    ),
                                                  );
                                                  HapticFeedback.lightImpact();
                                                },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
