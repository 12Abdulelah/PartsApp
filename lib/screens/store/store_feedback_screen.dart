import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:partflow_app/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';


class StoreFeedbackScreen extends StatefulWidget {
  final int storeId; // Passed when the store owner logs in
  const StoreFeedbackScreen({super.key, required this.storeId});

  @override
  State<StoreFeedbackScreen> createState() => _StoreFeedbackScreenState();
}
class _StoreFeedbackScreenState extends State<StoreFeedbackScreen> {
  List<dynamic> storeReviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }
  void _loadFeedback() async {
    try {
      // 1. Get the REAL ID from memory
      final prefs = await SharedPreferences.getInstance();
      final int? savedStoreId = prefs.getInt('my_store_id');

      // 2. If memory is empty
      final idToUse = savedStoreId ?? widget.storeId;

      print(" ID CHECK: Dashboard sent ${widget.storeId}, Memory says $savedStoreId. Using: $idToUse");

      final data = await ApiService().fetchStoreReviews(idToUse);

      setState(() {
        storeReviews = data;
        isLoading = false;
      });
    } catch (e) {
      print("Frontend Error: $e");
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Feedback")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeReviews.isEmpty
          ? const Center(child: Text("No feedback received yet."))
          : ListView.builder(
        itemCount: storeReviews.length,
          itemBuilder: (context, index) {
            final review = storeReviews[index];

            // Since we flattened it in the backend, these keys are now direct!
            final productName = review['product']?['part_name'] ?? "Unknown Part";
            final customerName = review['customer']?['full_name'] ?? "Guest User";

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text("${review['rating']}⭐", style: const TextStyle(fontSize: 12)),
                ),
                title: Text(customerName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bought: $productName", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("${review['comment'] ?? ''}"),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }
}