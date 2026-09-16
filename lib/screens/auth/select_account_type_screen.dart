import 'package:flutter/material.dart';
import 'customer_registration_screen.dart';
import 'store_registration_part1.dart';

class SelectAccountTypeScreen extends StatefulWidget {
  const SelectAccountTypeScreen({super.key});

  @override
  State<SelectAccountTypeScreen> createState() => _SelectAccountTypeScreenState();
}

class _SelectAccountTypeScreenState extends State<SelectAccountTypeScreen> {
  int selectedRole = 0; 

  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  @override
  Widget build(BuildContext context) {
    bool isEnabled = selectedRole != 0;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Choose Account Type", 
              style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Select how you want to use the platform", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 60),

            Row(
              children: [
                Expanded(child: _buildRoleCard("Customer", Icons.person_outline, 1)),
                const SizedBox(width: 15),
                Expanded(child: _buildRoleCard("Store", Icons.storefront_outlined, 2)),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled ? skyBlue : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: isEnabled ? () {
                  if (selectedRole == 1) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerRegistrationScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreRegistrationPart1()));
                  }
                } : null,
                child: Text("Continue", 
                  style: TextStyle(color: isEnabled ? Colors.white : Colors.black26, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 15),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to Login", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(String title, IconData icon, int roleId) {
    bool isSelected = selectedRole == roleId;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = roleId),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? skyBlue : Colors.black.withOpacity(0.05), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 45, color: isSelected ? skyBlue : Colors.grey[400]),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: isSelected ? textColor : Colors.grey[600], fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

