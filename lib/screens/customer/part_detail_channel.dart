import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:partflow_app/models/review.dart';

// 1. THE WIDGET (The Configuration)
class PartDetailChannel extends StatefulWidget {
  final Map<String, dynamic> part;

  const PartDetailChannel({super.key, required this.part});

  @override
  State<PartDetailChannel> createState() => _PartDetailChannelState();
}

// 2. THE STATE (The "Brain" where logic happens)
class _PartDetailChannelState extends State<PartDetailChannel> {
  // Variables to hold the data
  List<Review> reviewsList = [];
  bool isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    // This runs the moment the page opens
    _loadReviews();
  }
  Future<void> _loadReviews() async {
    try {
      // 🟢 FIX: Use the nested ID path that matches your database joins
      final int productId = widget.part['product']?['id'] ?? widget.part['product_id'] ?? 0;

      print("🔎 CUSTOMER FETCH: Requesting reviews for Product ID: $productId");

      if (productId == 0) {
        print("⚠️ Warning: Product ID is 0. Check how data is passed to this screen.");
        setState(() => isLoadingReviews = false);
        return;
      }

      final List<dynamic> data = await ApiService().fetchProductReviews(productId);

      setState(() {
        reviewsList = data.map((json) => Review.fromJson(json)).toList();
        isLoadingReviews = false;
      });
    } catch (e) {
      print("Review Fetch Error: $e");
      setState(() => isLoadingReviews = false);
    }
  }

  void _showReviewDialog(BuildContext context) {
    int selectedRating = 5;
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder lets the stars change inside the popup
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Write a Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () => setDialogState(() => selectedRating = index + 1),
                )),
              ),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(hintText: "Share your thoughts..."),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final String? userId = await ApiService().getUserId();

                // 🟢 CORRECT NESTED PATHS
                // Based on your log: store is a map, product is a map
                final int storeId = widget.part['store']['id'] ?? 0;
                final int productId = widget.part['product']['id'] ?? 0;

                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please login first!")),
                  );
                  return;
                }

                // Double check we have the IDs from the nested maps
                if (storeId == 0 || productId == 0) {
                  print("Error: Could not find IDs in ${widget.part}");
                  return;
                }

                final newReview = Review(
                  rating: selectedRating,
                  comment: commentController.text,
                  customerId: userId,
                  storeId: storeId,
                  productId: productId,
                );

                bool success = await ApiService().postReview(newReview);

                if (success) {
                  Navigator.pop(context);
                  _loadReviews(); // This will refresh the list!
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(" Review posted!"), backgroundColor: Colors.green),
                  );
                }
              },              child: const Text("Post"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Part Details",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Container(
              width: double.infinity,
              height: 250,
              color: skyBlue.withOpacity(0.05),
              child: Builder(
                builder: (context) {
                  final String imageUrl = (widget.part['image_url'] ?? "").toString().trim();
                  if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, color: Colors.grey, size: 80),
                    );
                  }
                  return const Icon(Icons.settings_suggest, color: skyBlue, size: 80);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.part['display_store'] ?? "Official Store",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      Text(
                        "${widget.part['price']} SAR",
                        style: const TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.part['display_name'] ?? "Spare Part",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text("Description",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const SizedBox(height: 8),
                  Text(
                    widget.part['display_desc'] ?? "Detailed description is not available for this item.",
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),

                  // 🟢 THE REVIEWS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Reviews",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF454545))),
                      TextButton.icon(
                        onPressed: () => _showReviewDialog(context),
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00BFFF)),
                        label: const Text("Write a Review", style: TextStyle(color: Color(0xFF00BFFF))),
                      ),
                    ],
                  ),

                  _buildReviewsList(),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront, color: skyBlue),
                        const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Sold by", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          widget.part['display_store'] ?? "Official Store",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: textColor)
                        )
                          ],

                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, skyBlue),
    );
  }


  // 🟢 Helper to build the review list
  Widget _buildReviewsList() {
    if (isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reviewsList.isEmpty) {
      return const Text("No reviews yet. Be the first to rate this part!",
          style: TextStyle(color: Colors.grey, fontSize: 14));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviewsList.length,
      itemBuilder: (context, index) {
        final review = reviewsList[index];

        // 🟢 Get the name from the review model (or raw json if not in model yet)
        // If your Review model doesn't have customerName, we'll need to add it!
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Customer Review",
            // Replace with review.customerName if model is updated
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (star) =>
                    Icon(
                      star < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    )),
              ),
              const SizedBox(height: 4),
              Text(review.comment ?? "No comment provided.",
                  style: const TextStyle(color: Colors.black87)),
              const Divider(),
            ],
          ),
        );
      },
    );
  }
  Widget _buildBottomBar(BuildContext context, Color skyBlue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12))
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          bool success = await ApiService().addToCart(
            storeProductId: widget.part['id'],
            quantity: 1,
          );

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Added to Cart!"), backgroundColor: Colors.green),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("❌ Failed to add."), backgroundColor: Colors.red),
            );
          }
        },
        child: const Text("Add to Cart",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}