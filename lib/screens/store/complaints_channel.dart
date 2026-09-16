import 'package:flutter/material.dart';
import '../../api_service.dart';

class ComplaintsChannel extends StatefulWidget {
  // 🟢 Changed to optional (int?) and removed 'required' to stop red lines elsewhere
  final int? storeId;
  const ComplaintsChannel({super.key, this.storeId});

  @override
  State<ComplaintsChannel> createState() => _ComplaintsChannelState();
}

class _ComplaintsChannelState extends State<ComplaintsChannel> {
  List<dynamic>? _complaints;
  bool _isLoading = true;

  // 🟢 Updated to accept a 'note'
  Future<void> _handleResolve(int complaintId, String note) async {
    int? id = widget.storeId;

    if (id == null) {
      final profile = await ApiService().getProfileData();
      id = profile?['details']?['id'];
    }

    if (id == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saving resolution..."))
    );

    // 🟢 We pass the note to the API service
    bool success = await ApiService().resolveComplaintWithNote(
        complaintId, id, note, role: "vendor");

    if (success && mounted) {
      setState(() {
        final index = _complaints!.indexWhere((c) => c['id'] == complaintId);
        if (index != -1) {
          _complaints![index]['status'] = 'resolved';
          _complaints![index]['resolution_note'] = note; // Save it locally too
        }
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _showResolveDialog(int complaintId) {
    TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Resolve Complaint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How was this issue resolved?", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "e.g., Replacement part shipped via Aramex...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.isNotEmpty) {
                _handleResolve(complaintId, noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    int? id = widget.storeId;

    // 1. If we don't have an ID, we go find it in the profile
    if (id == null) {
      final profile = await ApiService().getProfileData();
      id = profile?['details']?['id'];
    }

    print("Found Store ID: $id");

    if (id != null) {
      // 2. Fetch the actual data
      final data = await ApiService().getStoreComplaints(id);

      print("checker for complaints viewing : Raw Data from Server: $data");
      // 3. Update the UI
      if (mounted) {
        setState(() {
          _complaints = data;
          _isLoading = false;
        });
      }
    } else {
      // 4. Handle the case where the user isn't linked to a store yet
      print(
          "No Store ID linked to this account!");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _complaints = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 FORCING THE LIGHT THEME COLORS
    const Color scaffoldBg = Color(0xFFF5F7FA); // Light Gray/Blue
    const Color cardWhite = Colors.white;
    const Color skyBlue = Color(0xFF00BFFF);
    const Color textColor = Color(0xFF454545);

    return Scaffold(
      backgroundColor: scaffoldBg, // 🟢 Forces the background to stay light
      appBar: AppBar(
        title: const Text("Support Requests",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardWhite,
        elevation: 0.5,
        iconTheme: const IconThemeData(
            color: textColor), // Ensures back button is visible
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: skyBlue))
          : _complaints == null || _complaints!.isEmpty
          ? const Center(child: Text(
          "No support requests found", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _complaints!.length,
        itemBuilder: (context, index) {
          final item = _complaints![index];
          // Pass 'cardWhite' and 'textColor' to your Tile widget
          return _buildComplaintTile(item, skyBlue, textColor, cardWhite);
        },
      ),
    );
  }

  // 🟢 This builds each individual complaint "card"
  Widget _buildComplaintTile(Map<String, dynamic> item, Color skyBlue, Color textColor, Color cardColor) {
    bool isResolved = item['status'] == 'resolved';

    // Format the date (Assuming Supabase provides created_at)
    String dateStr = item['created_at'] != null
        ? item['created_at'].toString().split('T')[0]
        : "Recent";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20), // Softer corners
        border: Border.all(
            color: isResolved ? Colors.green.withOpacity(0.3) : skyBlue.withOpacity(0.1),
            width: 1.5
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon + Subject + Status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isResolved ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Icon(
                  isResolved ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 20,
                  color: isResolved ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['subject'] ?? "General Issue",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
              ),
              _buildStatusBadge(item['status'] ?? "open"),
            ],
          ),

          const SizedBox(height: 15),

          // 2. Body: Description
          Text(
            item['description'] ?? "No details provided.",
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.7), height: 1.4),
          ),

          const SizedBox(height: 15),

          // 3. Metadata: Order ID & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Order: #${item['order_id'] ?? 'N/A'}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.black26)),
            ],
          ),

          // Inside  Column in _buildComplaintTile, after the Order ID text:

          if (isResolved && item['resolution_note'] != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Resolution: ${item['resolution_note']}",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green),
              ),
            ),
          ],

          const Divider(height: 30, thickness: 0.5),

          // 4. Action Bar: The "Precision" Interaction
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isResolved) ...[
                TextButton.icon(
                  onPressed: () => _showResolveDialog(item['id']), // 🟢 Calls the logic
                  icon: const Icon(Icons.done_all, size: 18, color: Colors.green),
                  label: const Text("Mark Resolved", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ] else
                const Text("Resolution Complete", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

// Helper for the Status Badge
  Widget _buildStatusBadge(String status) {
    bool isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isResolved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.green : Colors.orange),
      ),
    );
  }
}