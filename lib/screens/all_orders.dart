// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final CollectionReference ordersCollection = FirebaseFirestore.instance
      .collection('orders');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  String searchQuery = '';
  String selectedStatus = 'All';
  String selectedDateFilter = 'All';

  Future<Map<String, String>> _getUserData(String userId) async {
    try {
      final doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {'name': data['name'] ?? userId, 'phone': data['phone'] ?? ''};
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
    return {'name': userId, 'phone': ''};
  }

  Color _statusColor(String status) {
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

  Future<void> _updateOrderStatus(String docId, String status) async {
    try {
      await ordersCollection.doc(docId).update({'status': status});
      ElegantNotification.success(
        title: const Text('Success'),
        description: Text('Order status updated to $status'),
        toastDuration: const Duration(seconds: 1),
        background: const Color.fromARGB(255, 131, 80, 13),
      ).show(context);
    } catch (e) {
      ElegantNotification.error(
        title: const Text('Error'),
        description: Text('Failed to update status: $e'),
        toastDuration: const Duration(seconds: 1),
        background: const Color.fromARGB(255, 131, 80, 13),
      ).show(context);
    }
  }

  Future<void> _deleteOrder(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ordersCollection.doc(docId).delete();
      ElegantNotification.success(
        title: const Text('Deleted'),
        description: const Text('Order deleted successfully'),
        toastDuration: const Duration(seconds: 1),
        background: const Color.fromARGB(255, 131, 80, 13),
      ).show(context);
    } catch (e) {
      ElegantNotification.error(
        title: const Text('Error'),
        description: Text('Failed to delete order: $e'),
        toastDuration: const Duration(seconds: 1),
        background: const Color.fromARGB(255, 131, 80, 13),
      ).show(context);
    }
  }

  bool _filterOrder(Map<String, dynamic> data, Map<String, String> userData) {
    final orderId = (data['orderId'] ?? '').toString().toLowerCase();
    final status = (data['status'] ?? '').toString().toLowerCase();
    final userName = (userData['name'] ?? '').toLowerCase();
    final userPhone = (userData['phone'] ?? '').toLowerCase();

    bool matchesSearch =
        searchQuery.isEmpty ||
        orderId.contains(searchQuery.toLowerCase()) ||
        userName.contains(searchQuery.toLowerCase()) ||
        userPhone.contains(searchQuery.toLowerCase());

    bool matchesStatus =
        selectedStatus == 'All' || status == selectedStatus.toLowerCase();

    bool matchesDate = true;
    if (selectedDateFilter != 'All' && data['timestamp'] != null) {
      final ts = (data['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();

      if (selectedDateFilter == 'Today') {
        matchesDate =
            ts.year == now.year && ts.month == now.month && ts.day == now.day;
      } else if (selectedDateFilter == 'This Week') {
        final diff = now.difference(ts).inDays;
        matchesDate = diff <= 7;
      } else if (selectedDateFilter == 'This Month') {
        matchesDate = ts.year == now.year && ts.month == now.month;
      }
    }

    return matchesSearch && matchesStatus && matchesDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders Panel'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => selectedDateFilter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All Time')),
              PopupMenuItem(value: 'Today', child: Text('Today')),
              PopupMenuItem(value: 'This Week', child: Text('This Week')),
              PopupMenuItem(value: 'This Month', child: Text('This Month')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.brown
                  )
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or order ID...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color.fromARGB(59, 238, 238, 238),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Filter by Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(
                    value: 'Processing',
                    child: Text('Processing'),
                  ),
                  DropdownMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'Cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: (val) => setState(() => selectedStatus = val!),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ordersCollection
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final data = orders[index].data() as Map<String, dynamic>;

                      return FutureBuilder<Map<String, String>>(
                        future: _getUserData(data['userId']),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) {
                            return const SizedBox();
                          }

                          final userData = userSnap.data!;
                          if (!_filterOrder(data, userData)) {
                            return const SizedBox();
                          }

                          final location = data['location'] ?? 'Not provided';
                          final notes = data['notes'] ?? 'No notes';
                          final timestamp = (data['timestamp'] as Timestamp?)
                              ?.toDate();
                          final dateStr = timestamp != null
                              ? DateFormat(
                                  'MMM d, y • h:mm a',
                                ).format(timestamp)
                              : 'Unknown date';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Order: ${data['orderId']}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(data['status']),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          data['status'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text("👤 User: ${userData['name']}"),
                                  if (userData['phone']!.isNotEmpty)
                                    Text("📞 Phone: ${userData['phone']}"),
                                  const SizedBox(height: 6),
                                  Text("📍 Location: $location"),
                                  Text("📝 Notes: $notes"),
                                  const SizedBox(height: 6),
                                  Text("🛒 Orders:"),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (var item in (data['items'] as List))
                                        Text(
                                          "- ${item['name']} x${item['quantity']}",
                                        ),
                                    ],
                                  ),
                                  Text(
                                    "💰 Total: Rs. ${data['totalPrice']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "📅 $dateStr",
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'Delete') {
                                          _deleteOrder(orders[index].id);
                                        } else {
                                          _updateOrderStatus(
                                            orders[index].id,
                                            value,
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'Processing',
                                          child: Text('Processing'),
                                        ),
                                        PopupMenuItem(
                                          value: 'Completed',
                                          child: Text('Completed'),
                                        ),
                                        PopupMenuItem(
                                          value: 'Cancelled',
                                          child: Text('Cancelled'),
                                        ),
                                        PopupMenuItem(
                                          value: 'Delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
