import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'complaints_channel.dart';
import 'store_feedback_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreProfileChannel extends StatelessWidget {
  const StoreProfileChannel({super.key});

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFFF5F7FA);
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Store Profile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: ApiService().getProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: skyBlue));
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error loading profile", style: TextStyle(color: Colors.grey)));
          } else {
            final profile = snapshot.data!;
            final details = profile['details'] ?? {};
            final int? id = details['id'];

            return ListView(
              padding: const EdgeInsets.all(25),
              children: [
                const SizedBox(height: 20),
                Center(
                    child: CircleAvatar(
                        radius: 50,
                        backgroundColor: skyBlue.withOpacity(0.1),
                        child: const Icon(Icons.storefront, size: 50, color: skyBlue)
                    )
                ),
                const SizedBox(height: 30),

                _buildInfoItem("Store Name", details['store_name'] ?? "No Store Name", skyBlue, textColor),
                _buildInfoItem("Email Address", profile['email'] ?? "No email", skyBlue, textColor),
                _buildInfoItem("CR Number", details['commercial_registration'] ?? "N/A", skyBlue, textColor),
                _buildInfoItem("City ID", details['city_id']?.toString() ?? "Not set", skyBlue, textColor),

                const SizedBox(height: 10),

                // 🟡 REVIEWS BUTTON
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                    title: const Text("Customer Reviews", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("See your ratings and feedback", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoreFeedbackScreen(storeId: id),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // 🔵 SUPPORT REQUESTS BUTTON
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: skyBlue.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.support_agent, color: skyBlue),
                    title: const Text("Support Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("View customer complaints", style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintsChannel(storeId: id),
                        ),
                      );
                    },
                  ),
                ),

                Divider(color: Colors.black.withOpacity(0.05), height: 40),

                const SizedBox(height: 20),
                TextButton(
                    onPressed: () => _showLogoutDialog(context),
                    child: const Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)
                    )
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // --- HELPER METHODS ---

  Widget _buildInfoItem(String title, String content, Color skyBlue, Color textColor) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: skyBlue, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(content, style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.8))),
        ]
    ),
  );

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure? This will clear your store session."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('my_store_id');

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