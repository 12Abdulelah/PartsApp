import 'package:flutter/material.dart';
import '../../api_service.dart'; // Make sure this path is correct for your project
import 'package:shared_preferences/shared_preferences.dart';

class CustomerComplaintScreen extends StatefulWidget {
  final int orderId;
  final int storeId;
  final String partName;

  const CustomerComplaintScreen({
    super.key,
    required this.orderId,
    required this.storeId,
    required this.partName,
  });

  @override
  State<CustomerComplaintScreen> createState() => _CustomerComplaintScreenState();
}

class _CustomerComplaintScreenState extends State<CustomerComplaintScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isSending = false;

  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);
  Future<void> _submit() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 🟢 1. Use your EXISTING api_service to fetch the profile on the fly!
      final profileData = await _api.getProfileData();

      // Extract the numeric ID from the details map
      int? customerNumericId = profileData?['details']?['id'];

      if (customerNumericId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Could not load your customer profile.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
        );
        setState(() => _isSending = false);
        return;
      }

      print("📤 SENDING COMPLAINT: Order ${widget.orderId}, Store ${widget.storeId}, Customer $customerNumericId");

      // 🟢 2. Send the complaint using the fetched ID
      bool success = await _api.submitComplaint(
        customerId: customerNumericId,
        storeId: widget.storeId, // If this is still 0, see Fix 2 below!
        orderId: widget.orderId,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Complaint submitted successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Server rejected it. Check Terminal."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      print("❌ ERROR: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text("Report an Issue", style: TextStyle(color: Color(0xFF454545), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order #${widget.orderId}", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
            Text("Product: ${widget.partName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            const Text("Subject", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: "e.g., Wrong part, Damaged item...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe the problem in detail...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Complaint", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}