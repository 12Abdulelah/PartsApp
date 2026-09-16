import 'package:flutter/material.dart';
import '../../api_service.dart';

class CheckoutChannel extends StatefulWidget {
  final List<dynamic> cartItems;
  final double subtotal;

  const CheckoutChannel({super.key, required this.cartItems, required this.subtotal});

  @override
  State<CheckoutChannel> createState() => _CheckoutChannelState();
}

class _CheckoutChannelState extends State<CheckoutChannel> {
  final TextEditingController _addressController = TextEditingController();
  final double deliveryFee = 15.00;
  bool _isLoading = false;
  bool _saveAddress = false; // 🟢 New: State for saving address

  @override
  Widget build(BuildContext context) {
    double total = widget.subtotal + deliveryFee;
    const Color skyBlue = Color(0xFF00BFFF);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 SECTION 1: Product Summary
            const Text("Order Items",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: widget.cartItems.map((item) {
                  final storeProd = item['store_product'] ?? {};
                  final product = storeProd['product'] ?? {};
                  return ListTile(
                    title: Text(product['part_name'] ?? "Unknown Part",
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text("Qty: ${item['quantity']}"),
                    trailing: Text("${(double.parse(
                        storeProd['price'].toString()) * item['quantity'])
                        .toStringAsFixed(2)} SAR"),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 30),

            // 🟢 SECTION 2: Shipping Address
            const Text("Shipping Address",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              maxLength: 150, // 🟢 Limits input to 150 characters
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter your full address...",
                counterText: "",
                // 🟢 Keeps it clean by hiding the character count
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            // 🟢 NEW: Save Address Toggle
            SwitchListTile(
              title: const Text("Save as default address",
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              value: _saveAddress,
              activeColor: skyBlue,
              onChanged: (bool value) => setState(() => _saveAddress = value),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 20),
            const Text("Order Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            _summaryRow(
                "Subtotal", "${widget.subtotal.toStringAsFixed(2)} SAR"),
            _summaryRow(
                "Delivery Fee", "${deliveryFee.toStringAsFixed(2)} SAR"),
            _summaryRow("Payment Method", "Cash on Delivery", isBlue: true),
            const Divider(),
            _summaryRow("Total Amount", "${total.toStringAsFixed(2)} SAR",
                isBold: true),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: skyBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: _isLoading ? null : () => _handlePlaceOrder(total),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM ORDER", style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Helpers ---
  Widget _summaryRow(String label, String value,
      {bool isBold = false, bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontSize: 16, color: isBold ? Colors.black : Colors.black54)),
          Text(value, style: TextStyle(fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBlue ? const Color(0xFF00BFFF) : Colors.black)),
        ],
      ),
    );
  }

  void _handlePlaceOrder(double totalAmount) async {
    FocusScope.of(context).unfocus();

    if (_addressController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your address")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_saveAddress) {
        await ApiService().updateUserAddress(_addressController.text.trim());
      }

      // 🟢 We pass the raw widget.cartItems list.
      // The ApiService will handle the mapping to store_product_id, etc.
      bool success = await ApiService().placeOrder(
        address: _addressController.text.trim(),
        cartItems: widget.cartItems,
        total: totalAmount,
      );

      if (success) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/order_success', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(
              "Order failed. Please check your database or connection.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}