import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'part_detail_channel.dart';

class GeneralChannel extends StatefulWidget {
  const GeneralChannel({super.key});

  @override
  State<GeneralChannel> createState() => _GeneralChannelState();
}

class _GeneralChannelState extends State<GeneralChannel> {
  // Brand Colors
  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  int? selectedCityId; // 🟢 Null = Show everything, Number = Filtered
  List productList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text("Local Parts Marketplace",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CITY FILTER SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text("Select Your City",
                style: TextStyle(fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16)),
          ),
          _buildCitySquares(),

          // 2. PRODUCT LIST SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCityId == null
                      ? "Global Market"
                      : "Parts in Selected City",
                  style: TextStyle(fontSize: 14,
                      color: skyBlue,
                      fontWeight: FontWeight.w600),
                ),
                if (selectedCityId != null)
                  Icon(Icons.location_on, color: skyBlue, size: 16),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List>(
              // 🟢 Double-check this string: 'city_id='
              future: ApiService().getData(
                  selectedCityId == null
                      ? 'api/catalog/products'
                      : 'api/catalog/products?city_id=$selectedCityId'
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: skyBlue));
                }
                if (snapshot.hasError || snapshot.data == null ||
                    snapshot.data!.isEmpty) {
                  return const Center(child: Text("No parts found here.",
                      style: TextStyle(color: Colors.grey)));
                }
                if (snapshot.hasData) {
                  debugPrint("Loaded ${snapshot.data!
                      .length} items for City: $selectedCityId");
                }

                final items = snapshot.data!;
                return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];

                      // 1. DATA EXTRACTION
                      final product = item['product'] ?? {};
                      final store = item['store'] ?? {};

                      // 2. CAR EXTRACTION (Extract the join from your 18-table system)
                      final car = product['vehicle_models'];
                      String carText = (car != null)
                          ? "${car['make']} ${car['model']} (${car['year_start']})"
                          : "Compatible Part";

                      // 3. IMAGE LOGIC (Preserving your existing path logic)
                      final List imagesList = product['listing_images'] ?? [];
                      String? rawPath;
                      if (imagesList.isNotEmpty && imagesList[0]['image_path'] != null) {
                        rawPath = imagesList[0]['image_path'].toString();
                      } else if (item['image_url'] != null) {
                        rawPath = item['image_url'].toString();
                      }
                      // 1. YOUR CONNECTION SETTINGS
                      const String projectId = "czabrqvpolkdwuwjffsc";
                      const String bucketName = "pic";
                      const String folderName = "products";
                      const String baseUrl = "https://$projectId.supabase.co/storage/v1/object/public/$bucketName/$folderName/";

// 3. Selection Logic
                      if (imagesList.isNotEmpty && imagesList[0]['image_path'] != null) {
                        rawPath = imagesList[0]['image_path'].toString();
                      } else if (item['image_url'] != null && item['image_url'].toString().isNotEmpty) {
                        rawPath = item['image_url'];
                      }

// 3. URL Construction (The part that prevents th
// e crash)
                      String? finalImageUrl;
                      if (rawPath != null && rawPath.trim().isNotEmpty) {
                        finalImageUrl = rawPath.startsWith('http')
                            ? rawPath
                            : "$baseUrl$rawPath";

                        // Clean double slashes
                        finalImageUrl = finalImageUrl.replaceAll(RegExp(r'(?<!https?:)/{2,}'), '/');
                      }
                      // Add this temporarily to "see" what is happening in the terminal

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartDetailChannel(
                                part: {
                                  ...item,
                                  'display_name': (product['part_name'] ?? "Unknown Part").toString(),
                                  'display_store': (store['store_name'] ?? "Local Store").toString(),
                                  'display_desc': (product['description'] ?? "No description available.").toString(),
                                  'image_url': finalImageUrl,
                                  // 🟢 PASSING CAR INFO TO DETAILS SCREEN
                                  'display_car': carText,
                                },
                              ),
                            ),
                          );
                        },
                        child: _buildProductCard(
                          name: (product['part_name'] ?? "Unknown Part").toString(),
                          price: "${item['price'] ?? '0.00'} SAR",
                          imageUrl: finalImageUrl,
                          storeName: (store['store_name'] ?? "Local Store").toString(),

                          carInfo: carText,
                        ),
                      );
                    }                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- CITY SQUARES UI ---
  Widget _buildCitySquares() {
    return SizedBox(
      height: 100, // Height for the square boxes
      child: FutureBuilder<List>(
        future: ApiService().getData('api/auth/cities'),
        // Ensure this route exists
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final cities = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: cities.length,


            itemBuilder: (context, index) {
              final city = cities[index];
              bool isSelected = selectedCityId == city['id'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    // 🟢 TOGGLE LOGIC: If already selected, turn off (null). Otherwise, select.
                    selectedCityId = isSelected ? null : city['id'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected ? skyBlue : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05),
                          blurRadius: 5)
                    ],
                    border: Border.all(
                        color: isSelected ? skyBlue : Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          Icons.location_city,
                          color: isSelected ? Colors.white : skyBlue,
                          size: 24
                      ),
                      const SizedBox(height: 5),
                      Text(
                        city['name'],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textColor
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🟢 Add curly braces {} around the parameters to make them "Named"
  Widget _buildProductCard({
    required String name,
    required String price,
    required String storeName, // Changed 'store' to 'storeName' to match your call
    required String? imageUrl,
    required String carInfo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF).withOpacity(0.05),
                // Using a hex for skyBlue if not defined
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              // 🟢 Inside _buildProductCard
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: (imageUrl != null &&
                    imageUrl.trim().length > 10 && // 🟢 Must be long enough to be a URL
                    imageUrl.startsWith('http') && // 🟢 Must start with http
                    !imageUrl.contains(' '))       // 🟢 Must NOT have spaces
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.grey, size: 35),
                )
                    : const Icon(Icons.settings_suggest, color: Color(0xFF00BFFF), size: 35),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Use storeName here
                Text(storeName.toUpperCase(), style: const TextStyle(
                    color: Color(0xFF00BFFF),
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                Text(carInfo,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                const SizedBox(height: 5),
                // We removed the hardcoded "SAR" here because we add it in the itemBuilder
                Text(
                    price, style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}