import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreOrdersChannel extends StatefulWidget {
  const StoreOrdersChannel({super.key});

  @override
  State<StoreOrdersChannel> createState() => _StoreOrdersChannelState();
}

class _StoreOrdersChannelState extends State<StoreOrdersChannel> {
  Key _refreshKey = UniqueKey();

  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);
  final Color scaffoldBg = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Inbound Requests",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: FutureBuilder<List>(
        key: _refreshKey,
        // 🟢 CHANGE 1: Use the dynamic fetcher we wrote in ApiService
        // This automatically gets the logged-in vendor's ID
        future: ApiService().getVendorOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: skyBlue));
          }
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text("No incoming requests", style: TextStyle(color: Colors.grey)));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              // Inside your ListView.builder mapping
              final order = orders[index];

// 1. Safe ID and Status
              final String orderId = order['id']?.toString() ?? "0";
              final statusData = order['status'] as Map<String, dynamic>?;
              final String statusName = statusData?['status_name'] ?? "Pending";

// 2. Safe Customer Name (Using the email as a fallback)
              final userMap = order['customer_user'] as Map<String, dynamic>?;
              final String customerLabel = userMap?['email'] ?? "Unknown Customer";

// 3. Safe Items Loop
              String items = "Multiple Items";
              try {
                final detailsList = order['order_details'] as List?;
                if (detailsList != null && detailsList.isNotEmpty) {
                  items = detailsList.map((d) {
                    final sp = d['store_product'] as Map<String, dynamic>?;
                    final p = sp?['product'] as Map<String, dynamic>?;
                    return p?['part_name'] ?? "Part";
                  }).join(", ");
                }
              } catch (e) {
                items = "Item list unavailable";
              }

              return _buildOrderCard(orderId, "ORD-$orderId", statusName, customerLabel, items);


            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String rawId, String id, String status, String customer, String item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(id, style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
                _statusChip(status),
              ]
          ),
          const Divider(color: Colors.black12, height: 25),
          _infoRow(Icons.person, customer),
          const SizedBox(height: 10),
          _infoRow(Icons.build, item),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: skyBlue,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => _showStatusPicker(rawId),
            child: const Text("Update Status", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(String orderId) {
    // 🟢 CHANGE 4: Map the words to the actual Database IDs
    final List<Map<String, dynamic>> statusOptions = [
      {'name': 'Processing', 'id': 1},
      {'name': 'Shipped', 'id': 2},
      {'name': 'Delivered', 'id': 3},
      {'name': 'Cancelled', 'id': 4},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Update Order Status", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...statusOptions.map((option) => ListTile(
            title: Text(option['name']),
            leading: Icon(Icons.circle, size: 12, color: option['id'] == 2 ? Colors.green : Colors.orange),
            onTap: () async {
              Navigator.pop(context);

              // 🟢 Sends the numeric ID to the database
              bool success = await ApiService().updateOrderStatus(
                  int.parse(orderId),
                  option['id']
              );

              if (success) {
                setState(() { _refreshKey = UniqueKey(); });
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Order updated to ${option['name']}"))
                );
              }
            },
          )).toList(),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, size: 16, color: skyBlue.withOpacity(0.7)),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))
  ]);

  Widget _statusChip(String label) {
    Color color = (label == 'Shipped' || label == 'Delivered') ? Colors.green : Colors.orange;
    if (label == 'Cancelled') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}