import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../api_service.dart';
import 'dart:io';

class StoreRegistrationPart2 extends StatefulWidget {
  final String storeName;
  final String crNumber;
  final List<String> categories;

  const StoreRegistrationPart2({
    super.key,
    required this.storeName,
    required this.crNumber,
    required this.categories,
  });

  @override
  State<StoreRegistrationPart2> createState() => _StoreRegistrationPart2State();
}

class _StoreRegistrationPart2State extends State<StoreRegistrationPart2> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isLoading = false;

  final Color scaffoldBg = const Color(0xFFF5F7FA);
  final Color skyBlue = const Color(0xFF00BFFF);
  final Color textColor = const Color(0xFF454545);

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _handleVendorRegistration() async {
    if (_usernameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in your account credentials!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_pickedFile == null || _pickedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your Commercial Register document!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? publicUrl;
      final String extension = _pickedFile!.extension ?? 'pdf';
      final fileName = 'cr_${DateTime.now().millisecondsSinceEpoch}.$extension';

      // Use File from dart:io to read from the path
      final File fileToUpload = File(_pickedFile!.path!);

      // Use .upload() instead of .uploadBinary() for mobile files
      await Supabase.instance.client.storage
          .from('store-docs')
          .upload(fileName, fileToUpload);

      publicUrl = Supabase.instance.client.storage
          .from('store-docs')
          .getPublicUrl(fileName);

      final response = await ApiService().registerUser(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'vendor',
        storeName: widget.storeName,
        commercialRegistration: widget.crNumber,
        cityId: int.tryParse(_cityCtrl.text) ?? 1,
        crDocumentUrl: publicUrl,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Store Registered! Pending Admin Approval."), backgroundColor: Colors.green),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception("Registration failed on server");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text("Account Details", style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Create your login credentials", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 30),
            _buildStepIndicator(),
            const SizedBox(height: 40),

            _buildInputField("Username", Icons.person_outline, _usernameCtrl),
            const SizedBox(height: 15),
            _buildInputField("Email Address", Icons.email_outlined, _emailCtrl),
            const SizedBox(height: 15),
            _buildInputField("Password", Icons.lock_outline, _passwordCtrl, isPassword: true),
            const SizedBox(height: 15),
            _buildInputField("City ID", Icons.location_city_outlined, _cityCtrl),

            const SizedBox(height: 30),
            Align(alignment: Alignment.centerLeft, child: Text("Commercial License Document", style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: _pickDocument,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: _pickedFile == null ? skyBlue.withOpacity(0.5) : Colors.green, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        _pickedFile == null ? Icons.upload_file_rounded : Icons.check_circle_outline,
                        color: _pickedFile == null ? skyBlue : Colors.green,
                        size: 40
                    ),
                    const SizedBox(height: 5),
                    Text(
                        _pickedFile == null ? "Upload CR Document" : "File: ${_pickedFile!.name}",
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600)
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: _buildOutlineButton("Back", null, onTap: () => Navigator.pop(context))),
                const SizedBox(width: 15),
                Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMainButton("Register", _handleVendorRegistration)),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            CircleAvatar(radius: 15, backgroundColor: skyBlue, child: const Icon(Icons.check, size: 15, color: Colors.white)),
            const SizedBox(height: 4),
            const Text("Step 1", style: TextStyle(color: Colors.black45, fontSize: 10)),
          ],
        ),
        Container(width: 40, height: 2, color: skyBlue, margin: const EdgeInsets.only(bottom: 15)),
        Column(
          children: [
            CircleAvatar(radius: 15, backgroundColor: skyBlue, child: const Text("2", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 4),
            Text("Step 2", style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black26),
              prefixIcon: Icon(icon, color: skyBlue),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
          )
      ),
    );
  }

  Widget _buildOutlineButton(String label, IconData? icon, {VoidCallback? onTap}) {
    return SizedBox(height: 55, width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(side: BorderSide(color: skyBlue, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), backgroundColor: Colors.white),
        onPressed: onTap,
        icon: icon != null ? Icon(icon, color: skyBlue) : const SizedBox.shrink(),
        label: Text(label, style: TextStyle(color: skyBlue, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMainButton(String label, VoidCallback onTap) {
    return SizedBox(height: 55, child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: skyBlue, elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));
  }
}