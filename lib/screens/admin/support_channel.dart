import 'package:flutter/material.dart';
import '../../api_service.dart';

class SupportChannel extends StatefulWidget {
  const SupportChannel({super.key});

  @override
  State<SupportChannel> createState() => _SupportChannelState();
}

class _SupportChannelState extends State<SupportChannel> {
  final Color skyBlue = const Color(0xFF00BFFF);
  Future<List<dynamic>>? _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _refreshComplaints();
  }

  void _refreshComplaints() {
    setState(() {
      _complaintsFuture = ApiService().getOpenComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Complaints", style: TextStyle(color: Color(0xFF454545), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: skyBlue));
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No open complaints!", style: TextStyle(color: Colors.grey)));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final complaint = snapshot.data![index];
                return _ComplaintCard(
                  complaint: complaint,
                  onResolved: _refreshComplaints,
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Sub-widget for the card
class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onResolved;

  const _ComplaintCard({required this.complaint, required this.onResolved});

  // 🟢 NEW: Function to show the text box dialog
  void _showResolveDialog(BuildContext context) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Complaint", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subject: ${complaint['subject'] ?? 'No Subject'}",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text("Write your response:"),
            const SizedBox(height: 10),
            TextField(
              controller: responseController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter the resolution details...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              String adminText = responseController.text.trim();
              if (adminText.isEmpty) return; // Don't allow empty response

              // 🟢 Call your API with the text you just wrote!
              bool success = await ApiService().resolveComplaint(
                  complaint['id'],
                  adminText
              );

              if (success) {
                if (context.mounted) Navigator.pop(context);
                onResolved(); // Refresh the list
              }
            },
            child: const Text("Resolve & Send", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String customerName = complaint['customer']?['username'] ?? "User";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("From: $customerName", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(complaint['subject'] ?? "General",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(complaint['description'] ?? "No description",
              style: const TextStyle(color: Colors.black54)),
          const Divider(height: 30),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              // 🟢 Trigger the dialog instead of calling API directly
              onPressed: () => _showResolveDialog(context),
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: const Text("Write Response & Resolve",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}