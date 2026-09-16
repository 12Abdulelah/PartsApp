import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  // دالة لتغيير التبويب المختار (Marketplace, Orders, Account)
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners(); // لتحديث الواجهة فوراً
  }
}