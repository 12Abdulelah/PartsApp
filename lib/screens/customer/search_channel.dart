import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🟢 Added for InputFormatters
import '../../api_service.dart';
import 'part_detail_channel.dart';

class SearchChannel extends StatefulWidget {
  const SearchChannel({super.key});

  @override
  State<SearchChannel> createState() => _SearchChannelState();
}
class _SearchChannelState extends State<SearchChannel> {
  bool isVinMode = false;
  String? selectedPartType;

  // 1. PROFESSIONAL RENAMING
  //
  final List<String> partTypes = [
    "Engine & Drivetrain",
    "Braking System",
    "Suspension & Steering",
    "Body & Exterior",
    "Cooling System",
    "Electrical & Lighting",
    "Maintenance & Filters"
  ];

  final TextEditingController _searchController = TextEditingController();

  Future<List> _fetchResults() async {
    String query = _searchController.text.trim();

    if (!isVinMode) {
      if (query.isEmpty) return [];
      return await ApiService().getData('api/catalog/products?search=$query');
    } else {
      if (query.length != 17) return [];

      // 🟢 STEP 1: Make the call
      // Note: Pass the category in the URL so the backend filters it for you
      String url = 'api/catalog/vin-match/$query';
      if (selectedPartType != null) {
        url += '?category=${Uri.encodeComponent(selectedPartType!)}';
      }
      print("🚀 CALLING URL: $url");

      final Map<String, dynamic>? vinResponse = await ApiService().getDataMap(url);

      // 🟢 STEP 2: Use the 'products' list already inside the response
      if (vinResponse != null && vinResponse['success'] == true) {
        // 🟢 We access the 'products' key inside the Map
        // This matches your Node.js code: res.json({ success: true, vehicle, products });
        return vinResponse['products'] ?? [];
      }


      return [];
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildHeader(textColor),
            const SizedBox(height: 20),

            // --- SEARCH BAR ---
            Row(
              children: [
                Expanded(
                  child: _buildVinSafeTextField(skyBlue),
                ),
                const SizedBox(width: 10),
                _buildVinToggleButton(skyBlue),
              ],
            ),

            // --- CATEGORIES (VIN MODE) ---
            if (isVinMode) _buildCategoryChips(skyBlue, textColor),

            const SizedBox(height: 25),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Results", style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            // --- RESULTS LIST ---
            Expanded(
              child: _buildResultsList(skyBlue, textColor),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 Custom TextField with "Exact" enforcement
  Widget _buildVinSafeTextField(Color skyBlue) {
    return TextField(
      controller: _searchController,
      maxLength: isVinMode ? 17 : null, // Enforces 17 in VIN mode
      inputFormatters: isVinMode ? [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // No symbols
        UpperCaseTextFormatter(), // Force Uppercase
      ] : [],
      onChanged: (val) {
        // Only refresh UI if it's a normal search or a complete 17-char VIN
        if (!isVinMode || val.length == 17 || val.isEmpty) {
          setState(() {});
        }
      },
      decoration: InputDecoration(
        hintText: isVinMode ? "Enter 17-digit VIN" : "Search Parts...",
        prefixIcon: Icon(isVinMode ? Icons.directions_car : Icons.search, color: skyBlue),
        counterText: "", // Hide character counter
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildResultsList(Color skyBlue, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: FutureBuilder<List>(
        future: _fetchResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF)));
          }

          if (isVinMode && _searchController.text.length < 17) {
            return const Center(child: Text("Please enter all 17 characters", style: TextStyle(color: Colors.grey)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No compatible parts found", style: TextStyle(color: Colors.grey)));
          }

          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(15),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = items[index];

              // 1. DATA EXTRACTION (Matches your 18-table joins)
              final product = item['product'] ?? {};
              final store = item['store'] ?? {};
              final car = product['vehicle_models']; // From the fk_product_vehicle_model join

              // 2. DEFINE MISSING VARIABLES LOCALLY
              String carText = (car != null)
                  ? "${car['make']} ${car['model']} (${car['year_start']})"
                  : "Fits your vehicle";

              return ListTile(
                title: Text(
                    product['part_name'] ?? "Part",
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                    carText, // 🟢 Now defined for every item!
                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)
                ),
                trailing: Text(
                    "${item['price'] ?? '0'} SAR",
                    style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold)
                ),
                onTap: () {
                  // 3. FORMATTED NAVIGATION (Fixes "Official Store" and "Spare Part" text)
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartDetailChannel(
                          part: {
                            ...item,
                            'display_name': (product['part_name'] ?? "Unknown Part").toString(),
                            'display_store': (store['store_name'] ?? "Local Store").toString(),
                            'display_desc': (product['description'] ?? "No description available.").toString(),
                            'display_car': carText,
                            'image_url': item['image_url'] ?? "",
                          },
                        ),
                      )
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  // --- UI HELPER WIDGETS ---
  Widget _buildHeader(Color textColor) => Text("Search Channel", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor));

  Widget _buildVinToggleButton(Color skyBlue) => GestureDetector(
    onTap: () => setState(() {
      isVinMode = !isVinMode;
      _searchController.clear();
    }),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: isVinMode ? skyBlue : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: skyBlue.withOpacity(0.3)),
      ),
      child: Text("VIN", style: TextStyle(color: isVinMode ? Colors.white : skyBlue, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _buildCategoryChips(Color skyBlue, Color textColor) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 15),
      const Text("Vehicle Systems", // 🟢 Renamed for clarity
          style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      SizedBox(
        height: 45, // Slightly taller for better touch area
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: partTypes.map((part) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(part),
              selected: selectedPartType == part,
              // 🟢 This setState triggers _fetchResults automatically
              onSelected: (sel) => setState(() => selectedPartType = sel ? part : null),
              selectedColor: skyBlue,
              labelStyle: TextStyle(
                color: selectedPartType == part ? Colors.white : textColor,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )).toList(),
        ),
      ),
    ],
  );
}

// 🟢 Helper to force Uppercase in the VIN field
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldV, TextEditingValue newV) {
    return newV.copyWith(text: newV.text.toUpperCase());
  }
}