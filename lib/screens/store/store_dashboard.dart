import 'package:flutter/material.dart';
import 'inventory_channel.dart';
import 'store_orders_channel.dart';
import 'store_profile_channel.dart';
// 🟢 IMPORT YOUR NEW FEEDBACK SCREEN
import 'store_feedback_screen.dart';

class StoreDashboard extends StatefulWidget {
  // 🟢 REQUIRE storeId: The dashboard needs to know WHICH store it is
  final int storeId;
  const StoreDashboard({super.key, required this.storeId});

  @override
  State<StoreDashboard> createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  int _currentIndex = 0;

  // 🟢 We use 'late' because we need to wait for 'widget.storeId' to exist
  late List<Widget> _channels;

  @override
  void initState() {
    super.initState();
    // 🟢 PASS the storeId to the feedback screen
    _channels = [
      const InventoryChannel(),
      const StoreOrdersChannel(),
      StoreFeedbackScreen(storeId: widget.storeId),
      const StoreProfileChannel(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _channels,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF00BFFF),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Orders',
          ),
          // 🟢 UPDATED: Change 'Complaints' to 'Feedback'
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}