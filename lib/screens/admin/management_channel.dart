import 'package:flutter/material.dart';
import '../../api_service.dart';

class ManagementChannel extends StatefulWidget {
  const ManagementChannel({super.key});

  @override
  State<ManagementChannel> createState() => _ManagementChannelState();
}

class _ManagementChannelState extends State<ManagementChannel> {
  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  // 🟢 Safely nullable variable to hold our active stores
  Future<List<dynamic>>? _activeStoresFuture;

  @override
  void initState() {
    super.initState();
    _refreshStores();
  }
  void _refreshStores() {
    setState(() {
      _activeStoresFuture = ApiService().getApprovedStores();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text("Active Stores Control",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _activeStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: skyBlue));
          } else if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No active stores right now.", style: TextStyle(color: Colors.grey))
            );
          } else {
            final stores = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];

                // 🛡️ Bulletproof data extraction
                final int safeId = int.tryParse(store['id']?.toString() ?? '0') ?? 0;
                final String safeName = store['store_name']?.toString() ?? "Unknown Store";
                final String safeCR = store['commercial_registration']?.toString() ?? "CR: Unknown";

                return _buildStoreCard(safeId, safeName, safeCR, skyBlue, textColor);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildStoreCard(int storeId, String name, String cr, Color skyBlue, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
                backgroundColor: Colors.green.withOpacity(0.1), // Green for active!
                child: const Icon(Icons.storefront, color: Colors.green)
            ),
            title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text("CR: $cr\nStatus: Active", style: const TextStyle(color: Colors.black38, fontSize: 12)),
            isThreeLine: true,
          ),
          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () async {

                  bool success = await ApiService().rejectStore(storeId);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Store Access Revoked!"), backgroundColor: Colors.red),
                    );
                    _refreshStores(); // Instantly removes them from the screen
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.block, color: Colors.redAccent, size: 18),
                label: const Text("Block Store", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}