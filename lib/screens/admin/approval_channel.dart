import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ApprovalChannel extends StatefulWidget {
  const ApprovalChannel({super.key});

  @override
  State<ApprovalChannel> createState() => _ApprovalChannelState();
}

class _ApprovalChannelState extends State<ApprovalChannel> {
  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  // 🟢 1. THE FIX: Removed "late" and added "?" to make it safely nullable!
  Future<List<dynamic>>? _pendingStoresFuture;

  @override
  void initState() {
    super.initState();
    // 🟢 2. THE FIX: Directly assigned the future here without using setState
    _pendingStoresFuture = ApiService().getPendingStores();
  }

  void _refreshStores() {
    setState(() {
      _pendingStoresFuture = ApiService().getPendingStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text("Store Approvals",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(

        future: _pendingStoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: skyBlue));
          } else if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text("No pending approval requests", style: TextStyle(color: Colors.grey))
            );
          } else {
            final stores = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];

                final int safeId = int.tryParse(store['id']?.toString() ?? '0') ?? 0;
                final String safeName = store['store_name']?.toString() ?? "New Store";
                final String safeCR = store['commercial_registration']?.toString() ?? "CR: Unknown";

                // 🟢 Extract the document URL
                final String? docUrl = store['cr_document_url'];

                return _buildApprovalCard(
                  safeId,
                  safeName,
                  safeCR,
                  docUrl, // 🟢 Pass the URL here
                  skyBlue,
                  textColor,
                );
              },
            );

          }
        },
      ),
    );
  }

  Widget _buildApprovalCard(
      int id, //
      String name,
      String cr,
      String? docUrl,
      Color skyBlue,
      Color textColor
      ) {
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
                backgroundColor: skyBlue.withOpacity(0.1),
                child: Icon(Icons.store, color: skyBlue)
            ),
            title: Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text("CR: $cr", style: const TextStyle(color: Colors.black38, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.description_outlined, color: Colors.blueGrey),
              onPressed: () async {
                if (docUrl != null && docUrl.isNotEmpty) {
                  final Uri url = Uri.parse(docUrl);
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    debugPrint("Could not launch $docUrl");
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No document uploaded for this store.")),
                  );
                }
              },
            ),
          ),

          Divider(color: Colors.black.withOpacity(0.05)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // 🟢 FIXED: Changed 'storeId' to 'id'
                    bool success = await ApiService().rejectStore(id);
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Store Rejected"), backgroundColor: Colors.red),
                        );
                        _refreshStores();
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Reject", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 🟢 FIXED: Changed 'storeId' to 'id'
                    bool success = await ApiService().approveStore(id);
                    if (success) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Store Approved!"), backgroundColor: Colors.green),
                        );
                        _refreshStores();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skyBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  }
