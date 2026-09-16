import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'checkout_channel.dart';

class CartChannel extends StatefulWidget {
  const CartChannel({super.key});

  @override
  State<CartChannel> createState() => _CartChannelState();
}

class _CartChannelState extends State<CartChannel> {
  double totalAmount = 0.0;
  List<dynamic> _currentItems = [];

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color(0xFFF5F7FA);
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        color: skyBlue,
        onRefresh: () async { setState(() {}); },
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ApiService().getCartItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: skyBlue));
                  }

                  if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && (_currentItems.isNotEmpty || totalAmount != 0.0)) {
                        setState(() {
                          totalAmount = 0.0;
                          _currentItems = [];
                        });
                      }
                    });

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text("Your cart is empty", style: TextStyle(color: Colors.grey, fontSize: 16))),
                      ],
                    );
                  }

                  final items = snapshot.data!;

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    double currentTotal = 0;
                    for (var item in items) {
                      final storeProd = item['store_product'] ?? {};
                      double price = double.tryParse(storeProd['price']?.toString() ?? "0") ?? 0.0;
                      int qty = item['quantity'] ?? 1;
                      currentTotal += (price * qty);
                    }
                    if (mounted && ((totalAmount - currentTotal).abs() > 0.01 || _currentItems.length != items.length)) {
                      setState(() {
                        totalAmount = currentTotal;
                        _currentItems = items;
                      });
                    }
                  });

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final storeProduct = item['store_product'] ?? {};
                      final productInfo = storeProduct['product'] ?? {};
                      final List imageList = productInfo['images'] ?? [];

                      String imageUrl = "";
                      if (imageList.isNotEmpty) {
                        final mainImg = imageList.firstWhere((img) => img['is_main'] == true, orElse: () => imageList[0]);
                        imageUrl = (mainImg['image_path'] ?? "").toString().trim();
                      }


                      return _buildCartItem(
                        item['id'],
                        productInfo['part_name'] ?? "Unknown Part",
                        storeProduct['price']?.toString() ?? "0.00",
                        item['quantity'] ?? 1,
                        imageUrl,
                        skyBlue,
                        textColor,
                        onIncrement: () async {
                          bool success = await ApiService().updateCartQuantity(item['id'], (item['quantity'] ?? 1) + 1);
                          if (success) setState(() {});
                        },
                        onDecrement: () async {
                          int currentQty = item['quantity'] ?? 1;

                          bool success = await ApiService().updateCartQuantity(item['id'], currentQty - 1);
                          if (success) setState(() {});
                        },

                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount", style: TextStyle(color: Colors.black54, fontSize: 16)),
                      Text("${totalAmount.toStringAsFixed(2)} SAR",
                          style: const TextStyle(color: skyBlue, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skyBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        if (_currentItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Your cart is empty!")));
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutChannel(
                              cartItems: _currentItems,
                              subtotal: totalAmount,
                            ),
                          ),
                        );
                      },
                      child: const Text("PROCEED TO CHECKOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 FIX 2: Cleaned up the closing braces and structure here
  Widget _buildCartItem(
      int cartId, // 🟢 This is the variable name we must use below
      String name, String price, int qty, String imageUrl,
      Color skyBlue, Color textColor,
      {required VoidCallback onIncrement, required VoidCallback onDecrement}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: skyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 25))
                  : Icon(Icons.settings_suggest, color: skyBlue, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const SizedBox(height: 5),
                Text("$price SAR", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // 🟢 FIXED BUTTON LOGIC
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            onPressed: () async {
              // We use 'cartId' here because it is defined in the function parameters above
              bool success = await ApiService().updateCartQuantity(cartId, 0);
              if (success) setState(() {});
            },
          ),

          Row(
            children: [
              _buildQtyBtn(Icons.remove, textColor, onDecrement),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(qty.toString(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
              _buildQtyBtn(Icons.add, textColor, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, Color textColor, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: textColor)));
  }
}