import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🟢 CLASS NAME FIXED: Must match what the Dashboard is looking for
class AdminAccountChannel extends StatelessWidget {
  const AdminAccountChannel({super.key});

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFFF5F7FA);
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("My Account", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: ApiService().getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: skyBlue));
          }

          final user = snapshot.data ?? {};
          final String username = user['username'] ?? "Admin";
          final String email = user['email'] ?? "admin@system.com";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: skyBlue.withOpacity(0.1),
                    child: const Icon(Icons.admin_panel_settings, size: 50, color: skyBlue),
                  ),
                ),
                const SizedBox(height: 15),
                Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                const Text("System Administrator", style: TextStyle(color: Colors.black38, fontSize: 14)),
                const SizedBox(height: 40),

                // Info Section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: skyBlue),
                        title: const Text("Username", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email_outlined, color: skyBlue),
                        title: const Text("Email", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(email, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // 🟢 2. Change to 'async' so we can wait for the memory to clear
                    onPressed: () async {

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('user_id');

                      // 🟢 4. Now move to the login screen
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                        "Sign Out",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}