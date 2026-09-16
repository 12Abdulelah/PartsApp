import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final double rating;
  final String partNum;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.rating,
    required this.partNum,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // اللون الداكن من فيقما
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // القسم العلوي: أيقونة القطعة مع خلفية زرقاء خفيفة
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFFF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.settings_input_component, color: Color(0xFF00BFFF), size: 40),
            ),
          ),
          const SizedBox(height: 12),
          
          // اسم القطعة ورقمها التسلسلي
          Text(name, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          Text(partNum, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          
          const Spacer(),
          
          // التقييم (النجوم)
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text("$rating", style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 8),
          
          // السعر وزر الإضافة للسلة الأزرق
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$price SAR", 
                style: const TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.bold, fontSize: 15)
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }
}