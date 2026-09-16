import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 Added for session cleanup

class AccountChannel extends StatefulWidget {
  const AccountChannel({super.key});

  @override
  State<AccountChannel> createState() => _AccountChannelState();
}

class _AccountChannelState extends State<AccountChannel> {
  String? selectedRegion;
  String? selectedCity;

  // Unified Brand Colors
  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);
  final Color cardColor = Colors.white;

  final Map<String, List<String>> locations = {
    "Riyadh": ["Riyadh City", "Al-Kharj", "Al-Majma'ah"],
    "Eastern Province": ["Dammam", "Al-Khobar", "Hafar Al-Batin"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text("Profile & Orders",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
          future: ApiService().getFullAccountData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: skyBlue));
            }

            // 🟢 Extract the combined results
            final combinedData = snapshot.data ?? {};
            final userData = combinedData['profile'] ?? {};
            final details = userData['details'] ?? {};
            final orders = combinedData['orders'] ?? [];

            return SingleChildScrollView(

              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                      child: CircleAvatar(
                          radius: 45,
                          backgroundColor: skyBlue.withOpacity(0.1),
                          child: Icon(Icons.person, size: 40, color: skyBlue)
                      )
                  ),
                  const SizedBox(height: 30),

                  _buildSectionTitle("Profile Info"),

                  _buildInfoCard(
                      Icons.person_outline,
                      "Name",
                      "${details['first_name'] ?? 'User'} ${details['last_name'] ?? ''}"
                  ),
                  _buildInfoCard(
                      Icons.phone_android,
                      "Phone",
                      details['phone'] ?? "No phone added"
                  ),

                  const SizedBox(height: 25),

// 🟢 FIXED: Only ONE "Order Tracking" header with the "VIEW ALL" button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Order Tracking"),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/order_tracking'),
                        child: Text("VIEW ALL", style: TextStyle(color: skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  if (orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text("No active orders", style: TextStyle(color: Colors.black38, fontSize: 13)),
                    )
                  else
                    ...orders.take(3).map((order) {
                      // 🟢 1. Get the Order ID (e.g., #3)
                      final String orderId = order['id']?.toString() ?? "?";

                      // 🟢 2. Get the Store Name safely (but we won't use it as the main title)
                      final storeData = order['store'] as Map<String, dynamic>?;
                      final String storeName = storeData?['store_name'] ?? "Store";

                      // 🟢 3. Get the Status
                      final statusData = order['status'] as Map<String, dynamic>?;
                      final String statusText = statusData?['status_name'] ?? "Pending";

                      // 🟢 4. Get the Price
                      final String price = order['total_price']?.toString() ?? "0";

                      Color statusColor = statusText == 'Pending' ? Colors.orange : Colors.green;

                      return _buildOrderTile(
                          "Order #$orderId",      // ⬅️ This puts "Order #3" back as the main text
                          statusText,             // ⬅️ Status on the right
                          statusColor,
                          subtitle: storeName,     // ⬅️ Optional: Pass store name as a small subtitle
                          price: price            // ⬅️ Optional: Pass price
                      );
                    }).toList(),

                  const SizedBox(height: 25),

                  _buildSectionTitle("Delivery Location"),

                  _buildDropdown(
                      "Select Region", locations.keys.toList(), (val) {
                    setState(() {
                      selectedRegion = val;
                      selectedCity = null;
                    });
                  }),
                  if (selectedRegion != null) ...[
                    const SizedBox(height: 10),
                    _buildDropdown(
                        "Select City", locations[selectedRegion]!, (val) {
                      setState(() => selectedCity = val);
                    }, value: selectedCity),
                  ],

                  const SizedBox(height: 40),

                  Center(
                    child: TextButton(
                      onPressed: () => _showLogoutDialog(context),
                      child: const Text(
                          "Sign Out",
                          style: TextStyle(color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
      ),

    );
  }

  // --- UI Helpers ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Icon(icon, color: skyBlue.withOpacity(0.5), size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black38, fontSize: 11)),
              Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Icon(Icons.edit, size: 16, color: skyBlue.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(String title, String status, Color statusColor, {String? subtitle, String? price}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: Colors.black38, fontSize: 11)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (price != null)
                Padding(
                  // 🟢 FIXED LINE BELOW:
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text("$price SAR", style: const TextStyle(fontSize: 10, color: Colors.black45)),
                ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildDropdown(String hint, List<String> items, Function(String?) onChanged, {String? value}) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.white,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  // 🟢 NEW: Secure Logout Dialog (Same as Vendor side for consistency)
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Wipes the customer session
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}