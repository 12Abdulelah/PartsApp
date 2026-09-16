import 'package:flutter/material.dart';
import 'package:partflow_app/api_service.dart';
import 'customer_complaint.dart'; // 🟢 Import the new screen

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color skyBlue = Color(0xFF00BFFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getCustomerOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: skyBlue));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You haven't placed any orders yet."));
          }

          final orders = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusName = order['status']?['status_name'] ?? "Pending";

              // 🟢 Extracting the IDs for the complaint
              final int orderId = order['id'];
              final int storeId = order['store_id'] ?? (order['store']?['id'] ?? 0);
              // Since an order might have many parts, we'll just use a generic name or the first part found
              final String displayName = "Order #$orderId Parts";

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Column( // 🟢 Changed to Column to add buttons at the bottom
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      title: Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text("Store: ${order['store']?['store_name'] ?? 'N/A'}"),
                          Text(
                              "${order['total_price']} SAR",
                              style: const TextStyle(color: skyBlue, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(statusName).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusName,
                          style: TextStyle(color: _getStatusColor(statusName), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const Divider(height: 1, indent: 15, endIndent: 15),

                    // 🟢 ACTION BAR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // 🚀 Navigate to the complaint screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerComplaintScreen(
                                    orderId: orderId,
                                    storeId: storeId,
                                    partName: displayName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.report_problem_outlined, size: 18, color: Colors.orange),
                            label: const Text(
                                "Report Problem",
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'shipped': return Colors.blue;
      case 'processing': return Colors.orange;
      default: return Colors.grey;
    }
  }
}