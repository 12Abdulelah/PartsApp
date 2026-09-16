import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:partflow_app/screens/store/inventory_channel.dart';
import 'package:partflow_app/screens/auth/login_screen.dart';
import 'package:partflow_app/screens/auth/select_account_type_screen.dart';
import 'package:partflow_app/screens/customer/customer_dashboard.dart';
import 'package:partflow_app/screens/store/store_dashboard.dart';
import 'package:partflow_app/screens/admin/admin_dashboard.dart';
import 'package:partflow_app/screens/store/store_feedback_screen.dart';
// 🟢 NEW IMPORTS
import 'package:partflow_app/screens/customer/checkout_channel.dart';
import 'package:partflow_app/screens/customer/order_success_screen.dart';
import 'package:partflow_app/screens/customer/order_tracking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("Environment variables loaded");
  } catch (e) {
    debugPrint("Could not load .env file: $e");
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parts',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
        primaryColor: const Color(0xFF00BFFF),
        hintColor: const Color(0xFF00BFFF),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/customer_dashboard': (context) => const CustomerDashboard(),

        // 🟢 FIXED ROUTE: This handles the dynamic storeId
        '/store_dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          // If no ID is passed (for safety), we default to 1, otherwise use the passed ID
          final int storeId = (args is int) ? args : 1;
          return StoreDashboard(storeId: storeId);
        },

        '/admin_dashboard': (context) => const AdminDashboard(),
        '/select_account': (context) => const SelectAccountTypeScreen(),
        '/inventory': (context) => const InventoryChannel(),


        '/order_success': (context) => const OrderSuccessScreen(),
        '/order_tracking': (context) => const OrderTrackingScreen(),
      },
    );
  }
}