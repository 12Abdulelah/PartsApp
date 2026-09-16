class Review {
  final int? id;
  final int rating;
  final String comment;
  final String customerId;
  final String? customerName;
  final int? storeId;    // 🟢 Changed to optional
  final int? productId;  // 🟢 Changed to optional
  final DateTime? createdAt;

  Review({
    this.id,
    required this.rating,
    required this.comment,
    required this.customerId,
    this.customerName,
    this.storeId,    // 🟢 Removed 'required'
    this.productId,  // 🟢 Removed 'required'
    this.createdAt,
  });

  // Convert Flutter object to JSON for the API (Sending to backend)
  Map<String, dynamic> toJson() => {
    "rating": rating,
    "comment": comment,
    "customer_id": customerId,
    "store_id": storeId,
    "product_id": productId,
  };

  // Convert JSON from API to Flutter object (Reading from backend)
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? "",
      customerId: json['customer_id']?.toString() ?? "",
      // 🟢 FIX 1: Capture the IDs so the constructor is happy
      storeId: json['store_id'] is int ? json['store_id'] : int.tryParse(json['store_id']?.toString() ?? ""),
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? ""),

      // 🟢 FIX 2: Parse the date safely
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,

      // 🟢 FIX 3: Map the flattened name we built in the Node.js backend
      customerName: json['customer']?['full_name'] ?? "Guest User",
    );
  }
}