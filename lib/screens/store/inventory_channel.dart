import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../api_service.dart';
import 'dart:io';

class InventoryChannel extends StatefulWidget {
  const InventoryChannel({super.key});

  @override
  State<InventoryChannel> createState() => _InventoryChannelState();
}

class _InventoryChannelState extends State<InventoryChannel> {
  bool _isSearching = false;
  String _searchQuery = "";
  File? _selectedImage;
  String? _selectedCategory;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  Key _refreshKey = UniqueKey();

  static const Color scaffoldBg = Color(0xFFF5F7FA);
  static const Color skyBlue = Color(0xFF00BFFF);
  static const Color textColor = Color(0xFF454545);

  int? _currentStoreId;

  // 🟢 NEW: State variables to hold the cars from the database
  List<dynamic> _allModels = [];
  int? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _getSavedStoreId();
    _loadVehicleModels(); // 🟢 NEW: Fetch models when screen loads
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // 🟢 NEW: Function to load models from your ApiService
  Future<void> _loadVehicleModels() async {
    final models = await ApiService().getVehicleModels();

    if (models != null && models.isNotEmpty) {
      setState(() {
        _allModels = models;
        print("DEBUG: Loaded ${_allModels.length} models successfully.");
      });
    } else {
      print("DEBUG: No models found or API error.");
    }
  }
  Future<void> _getSavedStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedId = prefs.getInt('my_store_id');

    if (savedId == null) {
      final profileData = await ApiService().getProfileData();
      if (profileData != null && profileData['details'] != null) {
        savedId = int.tryParse(profileData['details']['id'].toString());
        if (savedId != null) {
          await prefs.setInt('my_store_id', savedId);
        }
      }
    }

    setState(() { _currentStoreId = savedId; });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStoreId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: skyBlue)));
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: skyBlue,
        onPressed: () => _showAddPartSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: !_isSearching
            ? const Text("Store Inventory", style: TextStyle(fontWeight: FontWeight.bold, color: textColor))
            : TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Search parts...", border: InputBorder.none),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _refreshKey = UniqueKey();
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: skyBlue),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = "";
                  _searchController.clear();
                  _refreshKey = UniqueKey();
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<List>(
          key: _refreshKey,
          future: ApiService().getInventory(_currentStoreId!, search: _searchQuery),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: skyBlue));
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No items found"));

            final items = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard("Total Items", items.length.toString(), skyBlue, textColor),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildInventoryTile(items[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryTile(Map<String, dynamic> item) {
    final product = item['product'];
    final String name = product?['part_name'] ?? "Unknown";
    final int qty = int.tryParse(item['quantity'].toString()) ?? 0;
    final String price = item['price']?.toString() ?? "0";

    // 🟢 Extract the model text if it exists to show on the tile
    String carModelText = "";
    if (product != null && product['vehicle_models'] != null) {
      final v = product['vehicle_models'];
      carModelText = " • Fits: ${v['make']} ${v['model']}";
    }

    String? imageUrl;
    if (product != null && product['images'] != null && product['images'] is List) {
      List imagesList = product['images'];
      if (imagesList.isNotEmpty) imageUrl = imagesList[0]['image_path'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            width: 55, height: 55,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: skyBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                : const Icon(Icons.inventory_2_outlined, color: skyBlue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                // 🟢 Added the carModelText to the subtext
                Text("Stock: $qty | $price SAR$carModelText", style: TextStyle(color: qty < 5 ? Colors.red : Colors.black38, fontSize: 12)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_note, color: skyBlue), onPressed: () => _showEditProductSheet(item)),
        ],
      ),
    );
  }

  void _showEditProductSheet(Map<String, dynamic> item) {
    final product = item['product'];
    final List? images = product?['images'];
    final String? imageUrl = (images != null && images.isNotEmpty) ? images[0]['image_path'] : null;

    _nameController.text = product?['part_name'] ?? "";
    _descController.text = product?['description'] ?? "";
    _priceController.text = item['price'].toString();
    _stockController.text = item['quantity'].toString();
    _selectedImage = null;

    // 🟢 NEW: Set the dropdown to the currently assigned model
    _selectedModelId = product?['model_id'];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Product Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final image = await ApiService().pickImageFromGallery();
                    if (image != null) setSheetState(() { _selectedImage = image; });
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: scaffoldBg, borderRadius: BorderRadius.circular(15),
                      image: _selectedImage != null
                          ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                          : (imageUrl != null) ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                    ),
                    child: (_selectedImage == null && imageUrl == null) ? const Icon(Icons.add_a_photo, color: skyBlue) : null,
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 NEW: The Dropdown for Edit Mode
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedModelId,
                  decoration: InputDecoration(
                    hintText: "Select Compatible Vehicle",
                    filled: true, fillColor: const Color(0xFFE4E4E4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _allModels.map((m) {
                    return DropdownMenuItem<int>(
                      value: m['id'],
                      child: Text("${m['make']} ${m['model']} (${m['year_start']}-${m['year_end']})"),
                    );
                  }).toList(),
                  onChanged: (val) => setSheetState(() => _selectedModelId = val),
                ),
                const SizedBox(height: 10),

                _buildInput("Part Name", scaffoldBg, _nameController),
                _buildInput("Description", scaffoldBg, _descController),
                Row(
                  children: [
                    Expanded(child: _buildInput("Price", scaffoldBg, _priceController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput("Stock", scaffoldBg, _stockController)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: skyBlue, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () async {
                    final double? parsedPrice = double.tryParse(_priceController.text);
                    final int? parsedStock = int.tryParse(_stockController.text);

                    if (parsedPrice == null || parsedStock == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numbers only for Price & Stock!"), backgroundColor: Colors.red));
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating...")));

                    String? newUrl;
                    if (_selectedImage != null) newUrl = await ApiService().uploadProductImage(_selectedImage!);

                    final success = await ApiService().deepUpdateProduct(
                      storeProductId: item['id'],
                      name: _nameController.text,
                      description: _descController.text,
                      price: parsedPrice,
                      qty: parsedStock,
                      image_url: newUrl,
                      modelId: _selectedModelId, // 🟢 NEW: Send updated model to backend
                    );

                    if (success) {
                      Navigator.pop(context);
                      setState(() { _refreshKey = UniqueKey(); });
                    }
                  },
                  child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showAddPartSheet(BuildContext context) {
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _stockController.clear();
    _selectedImage = null;
    _selectedModelId = null;
    _selectedCategory = null; // Clear category for new items

    String? sheetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add New Part", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () async {
                    final image = await ApiService().pickImageFromGallery();
                    if (image != null) setSheetState(() { _selectedImage = image; });
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(15),
                      image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                    ),
                    child: _selectedImage == null ? const Icon(Icons.add_a_photo, color: skyBlue) : null,
                  ),
                ),
                const SizedBox(height: 20),

                // 🟢 Vehicle Model Dropdown
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedModelId,
                  decoration: InputDecoration(
                    hintText: "Select Compatible Vehicle",
                    filled: true, fillColor: const Color(0xFFE4E4E4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _allModels.map((m) {
                    return DropdownMenuItem<int>(
                      value: m['id'],
                      child: Text("${m['make']} ${m['model']} (${m['year_start']}-${m['year_end']})"),
                    );
                  }).toList(),
                  onChanged: (val) => setSheetState(() => _selectedModelId = val),
                ),

                const SizedBox(height: 10),

                // 🟢 NEW: Category Dropdown (Fixed setSheetState and Comma)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    hintText: "Select Category",
                    filled: true, fillColor: const Color(0xFFE4E4E4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: ['Engine', 'Brakes', 'Body', 'Suspension', 'Other']
                      .map((label) => DropdownMenuItem(
                    child: Text(label),
                    value: label,
                  )).toList(),
                  onChanged: (value) {
                    setSheetState(() { // Use setSheetState so the modal updates immediately
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 10), // Added missing comma/spacing here

                _buildInput("Item Name", scaffoldBg, _nameController),
                _buildInput("Description", scaffoldBg, _descController),
                Row(
                  children: [
                    Expanded(child: _buildInput("Price (SAR)", scaffoldBg, _priceController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput("Stock Qty", scaffoldBg, _stockController)),
                  ],
                ),

                const SizedBox(height: 10),

                if (sheetError != null)
                  Text(
                    sheetError!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  ),

                const SizedBox(height: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: skyBlue, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () async {
                    if (_nameController.text.isEmpty) {
                      setSheetState(() => sheetError = "Item Name is required!");
                      return;
                    }
                    if (_selectedModelId == null) {
                      setSheetState(() => sheetError = "Please select a compatible vehicle!");
                      return;
                    }
                    if (_selectedCategory == null) {
                      setSheetState(() => sheetError = "Please select a category!");
                      return;
                    }

                    final double? parsedPrice = double.tryParse(_priceController.text);
                    final int? parsedStock = int.tryParse(_stockController.text);

                    if (parsedPrice == null || parsedStock == null) {
                      setSheetState(() => sheetError = "Price and Stock must be numbers!");
                      return;
                    }

                    setSheetState(() => sheetError = null);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Creating...")));

                    String? url;
                    if (_selectedImage != null) url = await ApiService().uploadProductImage(_selectedImage!);

                    final success = await ApiService().addProduct(
                      name: _nameController.text,
                      description: _descController.text,
                      category: _selectedCategory, // 🟢 Send Category to API
                      price: parsedPrice,
                      qty: parsedStock,
                      storeId: _currentStoreId!,
                      image_url: url,
                      modelId: _selectedModelId,
                    );

                    if (success) {
                      Navigator.pop(context);
                      setState(() { _refreshKey = UniqueKey(); });
                    } else {
                      setSheetState(() => sheetError = "Server error. Try again.");
                    }
                  },
                  child: const Text("UPLOAD & SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildInput(String hint, Color bg, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint, filled: true, fillColor: const Color(0xFFE4E4E4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        )
    ),
  );

  Widget _buildStatCard(String label, String val, Color skyBlue, Color textColor) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: skyBlue.withOpacity(0.2)), borderRadius: BorderRadius.circular(15)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor)),
        Text(val, style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold))
      ],
    ),
  );
}