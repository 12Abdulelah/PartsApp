import 'package:flutter/material.dart';
import 'dart:convert';
import '../../api_service.dart'; // 🟢 MAKE SURE THIS PATH IS CORRECT!

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  // 🟢 1. THE BUCKETS (Controllers to catch the text)
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;

  // 🟢 2. THE HANDSHAKE (Sending the data to Node.js)
  Future<void> _handleRegistration() async {
    // Check if passwords match first
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Node.js wants first and last name, so we split the Full Name string!
    List<String> nameParts = _fullNameCtrl.text.trim().split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Call our Master Register Function
    final response = await ApiService().registerUser(
      username: _usernameCtrl.text,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      role: 'customer', // Hardcoded safely!
      firstName: firstName,
      lastName: lastName,
      phone: _phoneCtrl.text,
      cityId: int.tryParse(_cityCtrl.text) ?? 1, // Tries to send a number, defaults to 1
    );

    setState(() => _isLoading = false);

    // 🟢 3. THE RESULT
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful! Please log in."), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Teleports them back to the Login screen!
    } else {
      // If Node.js rejects it, show the exact error on the screen
      final errorData = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorData['error'] ?? "Registration failed"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFFF5F7FA);
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 70),
            const Text("Customer Registration",
                style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Create your account to start shopping",
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 40),

            // 🟢 ADDED: Passed the specific controllers into the text fields
            _buildInputField("Username", Icons.alternate_email, _usernameCtrl),
            const SizedBox(height: 15),
            _buildInputField("Full Name", Icons.person_outline, _fullNameCtrl),
            const SizedBox(height: 15),
            _buildInputField("Email", Icons.email_outlined, _emailCtrl),
            const SizedBox(height: 15),
            _buildInputField("Phone Number", Icons.phone_android_outlined, _phoneCtrl),
            const SizedBox(height: 15),
            _buildInputField("City ID (Type a number)", Icons.location_on_outlined, _cityCtrl),
            const SizedBox(height: 15),
            _buildInputField("Password", Icons.lock_outline, _passwordCtrl, isPassword: true),
            const SizedBox(height: 15),
            _buildInputField("Confirm Password", Icons.lock_outline, _confirmPasswordCtrl, isPassword: true),

            const SizedBox(height: 30),

            // 🟢 ADDED: Loading spinner logic
            _isLoading
                ? const CircularProgressIndicator(color: skyBlue)
                : _buildMainButton(context, "Sign Up", skyBlue),

            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Login", style: TextStyle(color: skyBlue))),
          ],
        ),
      ),
    );
  }

  // 🟢 UPDATED: Now requires a TextEditingController
  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: TextField(
        controller: controller, // Puts the bucket under the field
        obscureText: isPassword,
        style: const TextStyle(color: Color(0xFF454545)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          prefixIcon: Icon(icon, color: const Color(0xFF00BFFF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, String label, Color color) {
    return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            // 🟢 TRIGGER THE HANDSHAKE
            onPressed: _handleRegistration,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
        )
    );
  }
}