import 'package:flutter/material.dart';
import 'store_registration_part2.dart';

class StoreRegistrationPart1 extends StatefulWidget {
  const StoreRegistrationPart1({super.key});

  @override
  State<StoreRegistrationPart1> createState() => _StoreRegistrationPart1State();
}

class _StoreRegistrationPart1State extends State<StoreRegistrationPart1> {
  // 🟢 1. THE CONTROLLERS
  final TextEditingController _storeNameCtrl = TextEditingController();
  final TextEditingController _crNumberCtrl = TextEditingController();

  // 🟢 2. THE MULTI-SELECT LIST (Added this, removed the single String)
  List<String> selectedCategories = [];

  // 🟢 3. THE NAVIGATION LOGIC
  void _goToNextStep() {
    if (_storeNameCtrl.text.isEmpty || _crNumberCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one category"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Handing the data over to Part 2!
    // NOTE: Make sure StoreRegistrationPart2 accepts List<String> for categories!
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => StoreRegistrationPart2(
              storeName: _storeNameCtrl.text.trim(),
              crNumber: _crNumberCtrl.text.trim(),
              categories: selectedCategories, // 🟢 Sending the list now
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 70),
            const Text("Store Registration",
                style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Join our platform as a vendor", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 30),

            _buildStepIndicator(true, skyBlue),
            const SizedBox(height: 40),

            _buildInputField("Store Name", Icons.store_outlined, skyBlue, _storeNameCtrl),
            const SizedBox(height: 15),
            _buildInputField("Commercial Register (CR) Number", Icons.description_outlined, skyBlue, _crNumberCtrl),

            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft,
                child: Text("Specialization Categories",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),

            // 🟢 MULTI-SELECT CHIPS
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ["Engines", "Body", "Suspension", "Electrical", "Brakes", "Interior"].map((category) {
                bool isSelected = selectedCategories.contains(category);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedCategories.remove(category);
                      } else {
                        selectedCategories.add(category);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? skyBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: skyBlue, width: 1.5),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : skyBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 50),
            _buildMainButton("Next Step", skyBlue, _goToNextStep),

            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text("Back to Login", style: TextStyle(color: skyBlue))),
          ],
        ),
      ),
    );
  }

  // Helper methods below remain the same...
  Widget _buildStepIndicator(bool isStepOne, Color skyBlue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(radius: 15, backgroundColor: isStepOne ? skyBlue : Colors.grey[300],
            child: const Text("1", style: TextStyle(color: Colors.white))),
        Container(width: 40, height: 2, color: Colors.grey[300]),
        CircleAvatar(radius: 15, backgroundColor: isStepOne ? Colors.grey[300] : skyBlue,
            child: const Text("2", style: TextStyle(color: Colors.white))),
      ],
    );
  }

  Widget _buildInputField(String hint, IconData icon, Color skyBlue, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: skyBlue),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildMainButton(String label, Color skyBlue, VoidCallback onTap) {
    return SizedBox(width: double.infinity, height: 55,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: skyBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: onTap,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))));
  }
}