import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_app/screens/item_details_page.dart';
import 'package:final_app/screens/menu_page.dart';
import 'package:final_app/utils/provider/discount_provider.dart';
import 'package:final_app/utils/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:final_app/model/cart_item.dart';
import 'package:final_app/utils/provider/cart_provider.dart';
import 'package:final_app/services/cart_page.dart';
import 'package:final_app/screens/special_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  late final notifProv = Provider.of<NotificationProvider>(
    context,
    listen: false,
  );

  String _searchQuery = '';
  String? _selectedCategory;

  Stream<QuerySnapshot> _getSpecialItems() {
    return FirebaseFirestore.instance
        .collection('menu')
        .where('special', isEqualTo: true)
        .limit(5)
        .snapshots();
  }

  Stream<QuerySnapshot> _getAllMenuItems() {
    return FirebaseFirestore.instance
        .collection('menu')
        .orderBy('name')
        .limit(10)
        .snapshots();
  }

  void _addToCart(
    BuildContext context,
    Map<String, dynamic> data,
    String menuId,
  ) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (!cartProvider.isInCart(menuId)) {
      cartProvider.addItem(
        CartItem(
          menuId: menuId,
          name: data['name'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
        ),
      );
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final discProvider = Provider.of<DiscountProvider>(context);
    final disc = discProvider.discount;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.k,
              fontWeight: FontWeight.bold,
              size: 40.0,
              color: const Color.fromARGB(255, 242, 142, 27),
            ),
            const Text("haja", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            FaIcon(
              FontAwesomeIcons.k,
              fontWeight: FontWeight.bold,
              size: 40.0,
              color: const Color.fromARGB(255, 255, 161, 67),
            ),
            const Text("ham", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        scrolledUnderElevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.basketShopping),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search Food....",
                    prefixIcon: Icon(Icons.menu_book),
                    suffixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),

              const SizedBox(height: 5),

              if (!notifProv.isNotifOn)
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 249, 155, 74),
                  ),
                  child: Center(
                    child: Text(
                      "Turn on notification to get order updates !",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 200,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.8,
                          autoPlayInterval: Duration(seconds: 3),
                        ),
                        items:
                            [
                              'https://imgs.search.brave.com/Sk2mrK3t1ggkY2G_hUeOMDL9OPZTOCGmyMXPClkA0Fo/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pbWcu/ZnJlZXBpay5jb20v/ZnJlZS1wc2QvZm9v/ZC1tZW51LXJlc3Rh/dXJhbnQtc29jaWFs/LW1lZGlhLWJhbm5l/ci1pbnN0YWdyYW0t/cG9zdC10ZW1wbGF0/ZV8xMjAzMjktNDg0/NS5qcGc_c2VtdD1h/aXNfaHlicmlkJnc9/NzQwJnE9ODA',
                              'https://imgs.search.brave.com/UHVmr2HXKK1D9twLTPESDbHyVn4wgsrmyI1uc1RfrZY/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzlhL2Y1/LzhmLzlhZjU4ZjJm/MWI1OTY2NDg3N2E2/NDU5ZTUxNDhmNmZk/LmpwZw',
                              'https://imgs.search.brave.com/AGNZOHD65qa84J44SI0pkOTh0Qrn_kxnGrtjhRGMq5c/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9pbWFn/ZXMuZW10Y29udGVu/dC5jb20vb2ZmZXIt/aW1nL0VNVEhPVEVM/Uy0wNi1vY3QtMjUt/c20ud2VicA',
                              'https://imgs.search.brave.com/xxKyFnf-GZSZCDEfivcE3Yk2tU3KxadrVvDoBJW03t4/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly9pLnBp/bmltZy5jb20vb3Jp/Z2luYWxzLzJmL2Ji/LzAzLzJmYmIwMzQ3/NzdiODhjNzIzZmI2/M2EwMGUzZDVkZGQ4/LmpwZw',
                            ].map((imageUrl) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                      border: BoxBorder.all(
                                        color: Colors.yellow,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Today's Specials ${(disc * 100).toStringAsFixed(0)}% off",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 5),
                                FaIcon(FontAwesomeIcons.medal),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SpecialPage(),
                                  ),
                                );
                              },
                              child: const Text("See all"),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 280,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getSpecialItems(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text("No specials today 😔"),
                              );
                            }
                            final specials = snapshot.data!.docs;
                            final double disc = Provider.of<DiscountProvider>(
                              context,
                            ).discount;

                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: specials.length,
                              itemBuilder: (context, index) {
                                final data =
                                    specials[index].data()
                                        as Map<String, dynamic>;
                                final menuId = specials[index].id;
                                final price = (data['price'] ?? 0).toDouble();
                                final discountedPrice = price * (1 - disc);

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
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(10),
                                                ),
                                            child:
                                                (data['imageUrl'] != null &&
                                                    data['imageUrl']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? Image.network(
                                                    data['imageUrl'],
                                                    height: 110,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 110,
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
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              data['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.brown,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Rs. $price",
                                                  style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Text(
                                                  "Rs. ${discountedPrice.toStringAsFixed(2)}",
                                                  style: const TextStyle(
                                                    color: Colors.brown,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Consumer<CartProvider>(
                                              builder: (_, cart, __) {
                                                final isAdded = cart.isInCart(
                                                  menuId,
                                                );
                                                return SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.brown.shade600,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: isAdded
                                                        ? null
                                                        : () => _addToCart(
                                                            context,
                                                            data,
                                                            menuId,
                                                          ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Center(
                                                        child: Row(
                                                          children: [
                                                            Text(
                                                              isAdded
                                                                  ? "Added"
                                                                  : "Add to Basket",
                                                              style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            const FaIcon(
                                                              FontAwesomeIcons
                                                                  .basketShopping,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
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
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Food You May Like",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 10),
                                FaIcon(FontAwesomeIcons.pizzaSlice),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MenuPage(),
                                  ),
                                );
                              },
                              child: Text("See More"),
                            ),
                          ],
                        ),
                      ),

                      StreamBuilder<QuerySnapshot>(
                        stream: _getAllMenuItems(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text("No menu items available"),
                              ),
                            );
                          }

                          final allItems = snapshot.data!.docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name =
                                data['name']?.toString().toLowerCase() ?? '';
                            final category =
                                data['category']?.toString().toLowerCase() ??
                                '';
                            final matchesSearch =
                                name.contains(_searchQuery) ||
                                _searchQuery.isEmpty;
                            final matchesCategory =
                                _selectedCategory == null ||
                                category == _selectedCategory!.toLowerCase();
                            return matchesSearch && matchesCategory;
                          }).toList();

                          if (allItems.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text("No matching items found"),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: allItems.length,
                            itemBuilder: (context, index) {
                              final data =
                                  allItems[index].data()
                                      as Map<String, dynamic>;
                              final menuId = allItems[index].id;

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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading:
                                        (data['imageUrl'] != null &&
                                            data['imageUrl']
                                                .toString()
                                                .isNotEmpty)
                                        ? Image.network(
                                            data['imageUrl'],
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.fastfood),
                                    title: Text(
                                      "${data['name']} \nRs. ${data['price']}",
                                    ),
                                    subtitle: Text(
                                      data['category'] ?? 'Uncategorized',
                                      style: const TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          188,
                                          153,
                                          140,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: SizedBox(
                                      width: 130,
                                      height: double.infinity,
                                      child: Consumer<CartProvider>(
                                        builder: (_, cart, __) {
                                          final isAdded = cart.isInCart(menuId);
                                          return ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.brown.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: isAdded
                                                ? null
                                                : () => _addToCart(
                                                    context,
                                                    data,
                                                    menuId,
                                                  ),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      isAdded
                                                          ? "Added"
                                                          : "To Basket",
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6),
                                                    FaIcon(
                                                      isAdded
                                                          ? FontAwesomeIcons
                                                                .checkToSlot
                                                          : FontAwesomeIcons
                                                                .basketShopping,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
