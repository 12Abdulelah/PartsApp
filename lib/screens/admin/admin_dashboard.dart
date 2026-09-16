import 'package:flutter/material.dart';
import 'approval_channel.dart';
import 'support_channel.dart';
import 'management_channel.dart';
// 🟢 1. Make sure this filename matches your actual file in the folder!
import 'admin_account_channel.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  //  2. No 'const' before the list.
  // Individual 'const' only for ApprovalChannel if it allows it.
  final List<Widget> _channels = [
    const ApprovalChannel(),
    SupportChannel(),
    ManagementChannel(),
    AdminAccountChannel(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101012),
      body: IndexedStack(
        index: _currentIndex,
        children: _channels,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1C1C1E),
        selectedItemColor: const Color(0xFF00BFFF),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), label: 'Approvals'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Control'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
        ],
      ),
    );
  }
}