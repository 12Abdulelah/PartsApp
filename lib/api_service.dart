import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';


class ApiService {
  // 1. الرابط الأساسي
  final String baseUrl = "http://10.0.2.2:3000";

  // 2. دالة جلب القوائم للقنوات
  Future<List<dynamic>> getData(String endpoint) async {
    try {
      final safeUrl = Uri.encodeFull('$baseUrl/$endpoint');


      final response = await http.get(
        Uri.parse(safeUrl),
        headers: {"Content-Type": "application/json"},
      );

      print("SERVER RESPONDED WITH: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          print("DATA RECEIVED: ${data[0]}");
        }
        return data;
      }
      return [];
    } catch (e) {
      print("CONNECTION ERROR: $e");
      return [];
    }
  }

  Future<bool> addToCart({required int storeProductId, int quantity = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      // 🕵️‍♂️ Debug Check 1: Did we find the user ID?
      if (userId == null) {

        return false;
      }


      final response = await http.post(
        Uri.parse('$baseUrl/api/sales/cart/add'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customer_id": userId,
          "store_product_id": storeProductId,
          "quantity": quantity,
        }),
      );



      return response.statusCode == 200;
    } catch (e) {
      print(" CONNECTION ERROR: $e");
      return false;
    }
  }


  // : Generic POST helper that handles errors professionally
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded;
    } else {
      // 🟢 THIS IS THE KEY: We throw the error message sent by your Node.js
      // It will be "Your store has been blocked..." or "Your account is under review..."
      throw Exception(decoded['error'] ?? "Something went wrong");
    }
  }


  // Inside your ApiService class
  Future<Map<String, dynamic>?> getDataMap(String endpoint) async {
    try {
      // Replace 'baseUrl' with your actual server variable name
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print("Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("ApiService Error: $e");
      return null;
    }
  }
  // 3. دالة جلب بيانات المستخدم
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUuid = prefs.getString('user_id');

      if (savedUuid == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/profile'),
        headers: {
          "Content-Type": "application/json",
          "x-user-role": "admin",
          "user-id": savedUuid, // We send the UUID to find the account
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);


        // We save the Numeric ID
        if (data['admin_id'] != null) {
          await prefs.setInt('admin_numeric_id', data['admin_id']);
          print(" Saved Numeric Admin ID: ${data['admin_id']}");
        }

        return data;
      }
      return null;
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  Future<File?> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery,
        imageQuality: 50);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
// 4. دالة اللوجن
  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "identity": email.trim(),
        "password": password.trim(),
      }),
    );


    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // Wipe Remnants
      await prefs.remove('user_id');
      await prefs.remove('my_store_id');
      print("MEMORY CLEARED: Starting fresh for new user.");


      final String? userId = responseData['user']?['id']?.toString();
      if (userId != null) {
        await prefs.setString('user_id', userId);
        print("SUCCESS: User UUID $userId saved.");
      }


      final String serverRole = responseData['user']?['role'] ?? 'user';

      // vendor login function
      if (serverRole == 'vendor') {

        int? storeId;

        if (responseData['user']?['store_id'] != null) {
          storeId = responseData['user']['store_id'];
        } else if (responseData['details']?['id'] != null) {
          storeId = responseData['details']['id'];
        } else if (responseData['store_id'] != null) {
          storeId = responseData['store_id'];
        }

        if (storeId != null) {
          await prefs.setInt('my_store_id', storeId);
          print("SUCCESS: Saved Store ID $storeId to memory.");
        } else {
          print(" WARNING: User is a vendor but NO Store ID was found in the response!");

        }
      }

      return response;
    }


    else {

      final Map<String, dynamic> errorData = json.decode(response.body);


      throw errorData['error'] ?? "Login failed";
    }
  }
  Future<List<dynamic>> fetchStoreReviews(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reviews/store/$storeId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching store feedback: $e");
      return [];
    }
  }
  Future<bool> submitComplaint({
    required int customerId,
    required int storeId,
    required int orderId,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/customer/complaints'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customer_id": customerId,
          "store_id": storeId,
          "order_id": orderId,
          "subject": subject,
          "description": description,
        }),
      );

      // 🟢 ADD THIS PRINT STATEMENT
      print(" SERVER STATUS CODE: ${response.statusCode}");
      print(" SERVER RESPONSE: ${response.body}");

      return response.statusCode == 201;
    } catch (e) {
      print("Complaint Error: $e");
      return false;
    }
  }
  Future<List<dynamic>> getPendingStores() async {
    final url = Uri.parse(
        '$baseUrl/api/admin/stores/pending'); // The exact Node.js route

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-user-role": "admin",
      },
    );

    if (response.statusCode == 200) {
      return json.decode(
          response.body); // Hands the list of stores to your screen
    } else {
      throw Exception('Failed to load pending stores: ${response.statusCode}');
    }
  }
// 🟢 NEW: Fetch the user's cart items from the database
  Future<List<dynamic>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id'); // UUID saved at login

      if (userId == null) {
        print("🔎 DEBUG: No user_id found in memory.");
        return [];
      }

      // We use the '/api/sales' prefix because that's what is in your index.js
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales/cart/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("$data");
        return data; // This returns the list of cart_items
      } else {
        print("Server Error fetching cart: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Connection Error in getCartItems: $e");
      return [];
    }
  }
  Future<bool> updateCartQuantity(int cartItemId, int newQuantity) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/sales/cart/item/$cartItemId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"quantity": newQuantity}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Error: $e");
      return false;
    }
  }
  Future<Map<String, dynamic>> getFullAccountData() async {
    try {
      final String? userId = await getUserId();

      // 🕵️‍♂️ DEBUG 1: Is the ID correct?
      print("🕵️‍♂️ DEBUG: App is searching for orders for User UUID: '$userId'");

      final profileResponse = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      final ordersResponse = await http.get(
        Uri.parse('$baseUrl/api/transactions/customer/$userId/orders'),
        headers: {"Content-Type": "application/json"},
      );

      // 🕵️‍♂️ DEBUG 2: What is the RAW server response?
      print("📡 PROFILE STATUS: ${profileResponse.statusCode}");
      print("📡 ORDERS STATUS: ${ordersResponse.statusCode}");
      print("📦 RAW ORDERS BODY: ${ordersResponse.body}");

      final profileData = profileResponse.statusCode == 200 ? jsonDecode(profileResponse.body) : {};
      final ordersData = ordersResponse.statusCode == 200 ? jsonDecode(ordersResponse.body) : [];

      return {
        "profile": profileData,
        "orders": ordersData,
      };
    } catch (e) {
      print("❌ FATAL ERROR: $e");
      return {"profile": {}, "orders": []};
    }
  }
  Future<List<dynamic>> getVendorOrders() async {

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? storeId = prefs.getInt('my_store_id');


      print("🔎 DEBUG: Vendor is logged in with Store ID: $storeId");

      if (storeId == null) {
        print("🕵️‍♂️ DEBUG: No store_id found in memory for this vendor.");
        return [];
      }

      // We use the transactions alias from your Node.js
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/vendor/$storeId/orders'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ Vendor API Error: $e");
      return [];
    }
  }
// 1. SEND the review to your Node.js server
  Future<bool> postReview(Review review) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(review.toJson()), // This calls the mapping we made in the model
    );
    print("📡 REVIEW STATUS: ${response.statusCode}");
    return response.statusCode == 201;
  }

// 2. GET reviews for a specific product
  Future<List<dynamic>> fetchProductReviews(int productId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/reviews/product/$productId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // FUNCTION: Approve a Store
  Future<bool> approveStore(int storeId) async {
    final url = Uri.parse('$baseUrl/api/admin/stores/$storeId/approve');

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-user-role": "admin", // The VIP Badge
      },

      body: jsonEncode({}),
    );

    return response.statusCode == 200;
  }

  // FUNCTION: Reject (Block) a Store
  Future<bool> rejectStore(int storeId) async {
    final url = Uri.parse('$baseUrl/api/admin/stores/$storeId/block');

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-user-role": "admin", // The VIP Badge
      },

      body: jsonEncode({}),
    );

    return response.statusCode == 200;
  }

  // 🟢 HELPER: Gets the logged-in User's UUID from SharedPreferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<bool> placeOrder({
    required String address,
    required List<dynamic> cartItems,
    required double total,
  }) async {
    try {
      final String? customerId = await getUserId();

      // 🟢 Map the items here to match exactly what transaction.js expects
      final formattedItems = cartItems.map((item) {
        final storeProd = item['store_product'] ?? {};
        return {
          "store_id": storeProd['store_id'],
          "store_product_id": storeProd['id'],
          "price": double.tryParse(storeProd['price']?.toString() ?? "0") ?? 0.0,
          "quantity": item['quantity'],
        };
      }).toList();

      // 🟢 Get the cart_id so the backend can clear the cart
      final int? cartId = cartItems.isNotEmpty ? cartItems[0]['cart_id'] : null;

      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions/checkout'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customer_id": customerId,
          "shipping_address": address,
          "items": formattedItems,
          "cart_id": cartId,
        }),
      );

      print("📡 CHECKOUT STATUS: ${response.statusCode}");
      return response.statusCode == 201;
    } catch (e) {
      print("❌ CHECKOUT ERROR: $e");
      return false;
    }
  }
  // 🟢 NEW: Update the user's address in the database/profile
  Future<bool> updateUserAddress(String newAddress) async {
    try {
      final String? userId = await getUserId();
      if (userId == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile/update-address'), // Ensure this route exists in your Node.js
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "address": newAddress,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Error updating address: $e");
      return false;
    }
  }

  Future<bool> removeFromCart(int cartItemId) async {
    try {
      final response = await http.delete(
        // 🟢 The path must be exactly /api/cart/item/
        Uri.parse('$baseUrl/api/cart/item/$cartItemId'),
        headers: {"Content-Type": "application/json"},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ API Error: $e");
      return false;
    }
  }
  Future<List<dynamic>> getCustomerOrders() async {
    try {
      final String? userId = await getUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/customer/$userId/orders'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ API ERROR (Orders): $e");
      return [];
    }
  }
  Future<List<dynamic>> getMyOrders() async {
    try {
      final String? userId = await getUserId();
      // Using our new /api/transactions alias!
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/customer/$userId/orders'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("❌ History Error: $e");
      return [];
    }
  }

  Future<List<dynamic>> getInventory(int storeId, {String search = ""}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/inventory/$storeId/products?search=$search'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }


  Future<List<dynamic>> getApprovedStores() async {
    final url = Uri.parse('$baseUrl/api/admin/stores/approved');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-user-role": "admin", // The VIP Badge
      },
    );

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return List<dynamic>.from(list);
    } else {
      throw Exception('Failed to load approved stores: ${response.statusCode}');
    }
  }

// 🟢 VIP FUNCTION: Get all Open Complaints
  Future<List<dynamic>> getOpenComplaints() async {
    final url = Uri.parse('$baseUrl/api/admin/complaints/open');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-user-role": "admin",
      },
    );

    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return List<dynamic>.from(list);
    } else {
      throw Exception('Failed to load complaints');
    }
  }

  Future<bool> resolveComplaint(int complaintId, String responseText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedId = prefs.getString('user_id');

      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/complaints/$complaintId/resolve'),
        headers: {
          "Content-Type": "application/json",
          "x-user-role": "admin",
          "user-id": savedId ?? "",
        },
        body: jsonEncode({
          "admin_response": responseText,
        }),
      );

      if (response.statusCode == 200) {
        print("Complaint resolved successfully!");
        return true;
      } else {
        print("Failed to resolve: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error in resolveComplaint: $e");
      return false;
    }
  }


  Future<bool> resolveComplaintWithNote(int complaintId, int storeId,
      String note, {String role = "vendor"}) async {
    final url = Uri.parse('$baseUrl/api/auth/vendor/complaints/resolve');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "complaint_id": complaintId,
          "store_id": storeId,
          "resolution_note": note, // 🟢 This is the new "precise" data
          "role": role,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("API Error: $e");
      return false;
    }
  }


  Future<List<dynamic>> getStoreComplaints(int storeId) async {
    // Note: We use the /api/auth path because that's where we put the vendor route
    final url = Uri.parse('$baseUrl/api/auth/vendor/complaints/$storeId');

    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Vendor Complaints Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Connection error fetching vendor complaints: $e");
      return [];
    }
  }

  // Allow store to resolve a complaint locally
  Future<bool> resolveComplaintByStore(int complaintId, int storeId) async {
    final url = Uri.parse(
        '$baseUrl/api/auth/vendor/complaints/$complaintId/resolve');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"store_id": storeId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error resolving vendor complaint: $e");
      return false;
    }
  }
  Future<bool> deepUpdateProduct({
    required int storeProductId,
    required String name,
    required String description,
    String? category, // 🟢 Added this line
    required double price,
    required int qty,
    int? modelId,
    String? image_url,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/inventory/deep-update/$storeProductId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "part_name": name,
          "description": description,
          "category": category, // 🟢 Added this to the JSON body
          "price": price,
          "quantity": qty,
          "model_id": modelId,
          "image_url": image_url,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating product: $e");
      return false;
    }
  }

  Future<String?> uploadProductImage(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;

      // 🟢 Create a unique filename
      final String fileName = '${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';
      final String path = 'products/$fileName'; // This creates a 'products' folder automatically

      // 🚀 Upload to the 'pic' bucket
      await supabase.storage.from('pic').upload(path, imageFile);

      // 🔗 Get the Public URL
      final String publicUrl = supabase.storage.from('pic').getPublicUrl(path);

      print("Upload Success! URL: $publicUrl");
      return publicUrl;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
  Future<List<dynamic>?> getVehicleModels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/auth/vehicle-models'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print("Error fetching vehicle models: $e");
      return null;
    }
  }

  // 2. Add a new product (Updated to include modelId)
  Future<bool> addProduct({
    required String name,
    required String description,
    String? category, // 🟢 Added this line
    required double price,
    required int qty,
    required int storeId,
    int? modelId,
    String? image_url,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/inventory/add-new'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "part_name": name,
          "description": description,
          "category": category, // 🟢 Added this to the JSON body
          "price": price,
          "quantity": qty,
          "store_id": storeId,
          "model_id": modelId,
          "image_url": image_url,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error adding product: $e");
      return false;
    }

  }
  Future<Map<String, dynamic>?> matchVin(String vin) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vehicle/vin-match/$vin'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("VIN Search Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Connection Error: $e");
      return null;
    }
  }

  // A generic profile fetcher for EVERYONE
  Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedUuid = prefs.getString('user_id');

      if (savedUuid == null) return null;

      // Use the generic auth route we found in your Node.js code
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/profile/$savedUuid'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Profile Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  // 1. Fetching inbound requests for the Vendor
  Future<List<dynamic>> getStoreOrders(int storeId) async {
    final url = Uri.parse('$baseUrl/api/transactions/vendor/$storeId/orders');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }
  Future<bool> updateOrderStatus(int orderId, int newStatusId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? storeId = prefs.getInt('my_store_id');

      final response = await http.put(
        Uri.parse('$baseUrl/api/transactions/vendor/orders/$orderId/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "status_id": newStatusId, // 🟢 1=Pending, 2=Shipped, 3=Completed
          "store_id": storeId
        }),
      );

      print("📡 STATUS UPDATE: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("❌ Update Error: $e");
      return false;
    }
  }
  // 🟢 5. THE NEW MASTER REGISTER FUNCTION!
  Future<http.Response> registerUser({
    required String username,
    required String email,
    required String password,
    required String role, // Must be exactly 'customer' or 'vendor'

    // Optional Customer Fields
    String? firstName,
    String? lastName,
    String? phone,

    // Optional Vendor Fields
    String? storeName,
    String? commercialRegistration,

    // Shared Field
    int? cityId,

    String? crDocumentUrl,
  }) async {

    final url = Uri.parse('$baseUrl/api/auth/register');

    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username.trim(),
        "email": email.trim(),
        "password": password.trim(),
        "role": role.toLowerCase(),

        // Profile Data (Flutter sends null for blanks, Node.js safely ignores them!)
        "first_name": firstName?.trim(),
        "last_name": lastName?.trim(),
        "phone": phone?.trim(),
        "store_name": storeName?.trim(),
        "commercial_registration": commercialRegistration?.trim(),
        "city_id": cityId,
        "cr_document_url": crDocumentUrl,
      }),
    );
  }
}