// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:final_app/screens/all_orders.dart';
import 'package:final_app/utils/provider/discount_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class AdminMenuPage extends StatefulWidget {
  const AdminMenuPage({super.key});

  @override
  State<AdminMenuPage> createState() => _AdminMenuPageState();
}

class _AdminMenuPageState extends State<AdminMenuPage> {
  final CollectionReference menuCollection =
      FirebaseFirestore.instance.collection('menu');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'All';
  String sortOrder = 'A-Z';
  bool isSpecial = false;
  bool _isProcessing = false; 

  Set<String> categories = {'All'};
  bool categoriesLoaded = false;

  void _showMenuDialog({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descController.text = data['description'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _imageController.text = data['imageUrl'] ?? '';
      _categoryController.text = data['category'] ?? '';
      isSpecial = data['special'] ?? false;
    } else {
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _imageController.clear();
      _categoryController.clear();
      isSpecial = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                doc == null ? 'Add Menu Item' : 'Edit Menu Item',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Name'),
              _buildTextField(_descController, 'Description'),
              _buildTextField(_priceController, 'Price',
                  keyboard: TextInputType.number),
              _buildTextField(_imageController, 'Image URL'),
              _buildTextField(_categoryController, 'Category'),
              SwitchListTile(
                title: const Text("Mark as Today's Special"),
                value: isSpecial,
                onChanged: (val) => setState(() => isSpecial = val),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isProcessing ? 'Saving...' : 'Save'),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        final name = _nameController.text.trim();
                        final price =
                            double.tryParse(_priceController.text.trim()) ?? 0;
                        if (name.isEmpty || price <= 0) {
                          ElegantNotification.error(
                            title: const Text('Invalid Data'),
                            description: const Text(
                                'Please enter a valid name and price.'),
                            background: const Color.fromARGB(255, 112, 60, 22),
                          ).show(context);
                          return;
                        }

                        setState(() => _isProcessing = true);
                        final menuData = {
                          'name': name,
                          'description': _descController.text.trim(),
                          'price': price,
                          'imageUrl': _imageController.text.trim(),
                          'category': _categoryController.text.trim().isEmpty
                              ? 'Uncategorized'
                              : _categoryController.text.trim(),
                          'special': isSpecial,
                        };

                        try {
                          if (doc == null) {
                            await menuCollection.add(menuData);
                          } else {
                            await menuCollection.doc(doc.id).update(menuData);
                          }

                          ElegantNotification.success(
                            title: const Text('Success'),
                            description: Text(doc == null
                                ? 'Item added successfully'
                                : 'Item updated successfully'),
                            background: Colors.black,
                          ).show(context);
                          Navigator.pop(context);
                        } catch (e) {
                          ElegantNotification.error(
                            title: const Text('Error'),
                            description: Text('Failed: $e'),
                            background: Colors.black,
                          ).show(context);
                        } finally {
                          setState(() => _isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(width: 2)),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            floatingLabelStyle: const TextStyle(
                backgroundColor: Colors.black, letterSpacing: 1.2, fontSize: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'))
        ],
      ),
    );

    if (confirm == true) {
      await menuCollection.doc(id).delete();
      ElegantNotification.success(
        title: const Text('Deleted'),
        description: const Text('Item deleted successfully'),
        background: Colors.black,
      ).show(context);
    }
  }

  Query _buildQuery() {
    Query q = menuCollection;

   
    if (selectedCategory != 'All') {
      q = q.where('category', isEqualTo: selectedCategory);
    }

    if (sortOrder == 'A-Z') {
      q = q.orderBy('name');
    } else if (sortOrder == 'Z-A') {
      q = q.orderBy('name', descending: true);
    } else if (sortOrder == 'Price ↑') {
      q = q.orderBy('price');
    } else if (sortOrder == 'Price ↓') {
      q = q.orderBy('price', descending: true);
    }

    return q;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍴 Admin Menu Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(FontAwesomeIcons.basketShopping, size: 18),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminOrdersPage()))),
        ],
      ),
      floatingActionButton: Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    FloatingActionButton(
      onPressed: () {
        TextEditingController discountController = TextEditingController(text: "0.");

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Set Discount"),
              content: TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                maxLength: 3,
                decoration: const InputDecoration(
                  hintText: "Enter discount %",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final discount = double.tryParse(discountController.text) ?? 0;
                    Provider.of<DiscountProvider>(context, listen: false)
                        .setDiscount(discount.toDouble());

                    Navigator.of(context).pop(); 
                  },
                  child: const Text("Set"),
                ),
              ],
            );
          },
        );
      },
      child: const Text("Disc"),
    ),
    const SizedBox(width: 20),
    FloatingActionButton(
      onPressed: () => _showMenuDialog(),
      child: const Icon(Icons.add),
    ),
  ],
),

      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search menu...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color.fromARGB(67, 245, 245, 245),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort),
                    onSelected: (v) => setState(() => sortOrder = v),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'A-Z', child: Text('A-Z')),
                      PopupMenuItem(value: 'Z-A', child: Text('Z-A')),
                      PopupMenuItem(
                          value: 'Price ↑', child: Text('Price Low→High')),
                      PopupMenuItem(
                          value: 'Price ↓', child: Text('Price High→Low')),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: StreamBuilder<QuerySnapshot>(
                stream: menuCollection.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && !categoriesLoaded) {
                    categories = {'All'};
                    for (var doc in snapshot.data!.docs) {
                      final cat =
                          (doc['category'] ?? 'Uncategorized').toString();
                      categories.add(cat);
                    }
                    categoriesLoaded = true;
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedCategory,
                    onChanged: (val) =>
                        setState(() => selectedCategory = val!),
                    decoration: InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildQuery().snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['name']
                        .toString()
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase());
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('No menu items found.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: data['imageUrl'] != null &&
                                    data['imageUrl'].toString().isNotEmpty
                                ? Image.network(data['imageUrl'],
                                    width: 55, height: 55, fit: BoxFit.cover)
                                : const Icon(Icons.fastfood, size: 40),
                          ),
                          title: Text(data['name'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Rs. ${data['price']}"),
                              Text(data['category'] ?? 'Uncategorized',
                                  style: const TextStyle(fontSize: 12)),
                              if (data['special'] == true)
                                const Text("🌟 Special",
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'Edit') {
                                _showMenuDialog(doc: docs[index]);
                              } else if (value == 'Delete') {
                                _deleteMenuItem(docs[index].id);
                              } else if (value == 'Toggle Special') {
                                menuCollection.doc(docs[index].id).update({
                                  'special': !(data['special'] ?? false)
                                });
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'Edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'Toggle Special',
                                  child: Text('Toggle Special')),
                              PopupMenuItem(
                                  value: 'Delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
