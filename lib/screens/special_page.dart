import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_app/model/cart_item.dart';
import 'package:final_app/screens/item_details_page.dart';
import 'package:final_app/services/cart_page.dart';
import 'package:final_app/utils/provider/cart_provider.dart';
import 'package:final_app/utils/provider/discount_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class SpecialPage extends StatelessWidget {
  const SpecialPage({super.key});

  Stream<QuerySnapshot> _getSpecialItems() {
    return FirebaseFirestore.instance
        .collection('menu')
        .where('special', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final discProvider = Provider.of<DiscountProvider>(context);
    final disc = discProvider.discount;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Row(
          children: const [
            Text(
              "Today's Specials",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            FaIcon(FontAwesomeIcons.medal),
          ],
        ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _getSpecialItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No specials today 😔"));
          }

          final specialItems = snapshot.data!.docs;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.8,
                    autoPlayInterval: const Duration(seconds: 2),
                  ),
                  items: specialItems.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade300,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          border: BoxBorder.all(color: Colors.yellow),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${(discProvider.discount * 100).toStringAsFixed(0)}% off in every item ",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FaIcon(FontAwesomeIcons.utensils, size: 32),
                    const SizedBox(width: 10),
                  ],
                ),

                const SizedBox(height: 20),

                GridView.builder(
                  itemCount: specialItems.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 25,
                    childAspectRatio: 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final doc = specialItems[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final menuId = doc.id;
                    final originalPrice = (data['price'] ?? 0).toDouble();
                    final discountedPrice = originalPrice * (1 - disc);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsPage(
                              menuId: menuId,
                              name: data['name'],
                              description: data['description'],
                              price: discountedPrice,
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child:
                                    data['imageUrl'] != null &&
                                        data['imageUrl'].toString().isNotEmpty
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
                                          child: Icon(Icons.fastfood, size: 50),
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                data['name'] ?? 'Unnamed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Text(
                                data['description'] ?? '',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Rs. $originalPrice",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.brown,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 2,
                                ),
                              ),
                              Text(
                                "Rs. ${discountedPrice.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Spacer(),

                              Consumer<CartProvider>(
                                builder: (_, cartProvider, __) {
                                  final isAdded = cartProvider.isInCart(menuId);
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: FaIcon(
                                        isAdded
                                            ? FontAwesomeIcons.check
                                            : FontAwesomeIcons.basketShopping,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isAdded ? "Added" : "Add to Basket",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.brown.shade600,
                                        iconColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
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
                                                  price: discountedPrice,
                                                  imageUrl:
                                                      data['imageUrl'] ?? '',
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
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
