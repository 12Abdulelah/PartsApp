import 'dart:convert';
import '../../api_service.dart';
import 'package:flutter/material.dart';
import 'select_account_type_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🟢 CLEANUP: We deleted the 'selectedRole' variable because the DB handles it now.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  // Theme Colors
  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 80),

            Column(
              children: [
                // 🖼️ LOGO PLACEHOLDER
                Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.car_repair,
                      size: 50,
                      color: skyBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "Parts",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.5,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Locate , Compare and Buy Auto Spare Parts",
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // INPUT FIELDS
            _buildInputField("Username", controller: _usernameController, icon: Icons.person_outline),
            const SizedBox(height: 15),
            _buildInputField("Password", isPassword: true, controller: _passwordController, icon: Icons.lock_outline),

            const SizedBox(height: 30),

            // THE SMART LOGIN BUTTON
          _buildMainButton("Login", onTap: () async {
            if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please enter username and password")),
              );
              return;
            }

            try {
              // 🟢 This will now either succeed (200) or JUMP to 'catch' if blocked (403)
              final response = await apiService.login(
                  _usernameController.text.trim(),
                  _passwordController.text.trim()
              );

              // If it reaches here, the status was 200 OK
              final Map<String, dynamic> responseData = jsonDecode(response.body);
              final String serverRole = responseData['user']['role'];

              if (serverRole == 'admin') {
                Navigator.pushReplacementNamed(context, '/admin_dashboard');
              } else if (serverRole == 'vendor') {
                final prefs = await SharedPreferences.getInstance();
                if (responseData['details'] != null && responseData['details']['id'] != null) {
                  await prefs.setInt('my_store_id', responseData['details']['id']);
                }
                Navigator.pushReplacementNamed(context, '/store_dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/customer_dashboard');
              }

            } catch (e) {
              // 🟢 THE FIX IS HERE:
              // We check if 'e' is a SocketException (No internet) or a String (Your Blocked message)
              String errorText = e.toString();

              // If it's a real connection error (server down)
              if (errorText.contains("SocketException") || errorText.contains("Connection refused")) {
                errorText = "Cannot reach server. Is your Node.js running?";
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorText), // 👈 This will now show the REAL message!
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            }),
            const SizedBox(height: 25),

            // REGISTRATION LINK
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/select_account'),
                  child: Text("Register Now", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildInputField(String hint, {bool isPassword = false, TextEditingController? controller, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          prefixIcon: Icon(icon, color: skyBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildMainButton(String label, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}