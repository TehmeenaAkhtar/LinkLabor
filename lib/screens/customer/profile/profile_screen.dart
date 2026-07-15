import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../language_state.dart';

class CustomerProfileScreen extends StatefulWidget {
  final int customerId;
  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  final String _baseUrl = "http://192.168.10.2:3000";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/api/customer/${widget.customerId}'));
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() => _profile = jsonDecode(response.body));
        } else {
          _showError(
              isUrdu ? "پروفائل لوڈ نہیں ہو سکی۔" : "Failed to load profile.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(isUrdu ? "کنکشن میں خرابی: $e" : "Connection Error: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Update document using XFile bytes (no dart:io) ──
  Future<void> _updateDocument(String field) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    _showLoadingDialog();

    try {
      final bytes = await picked.readAsBytes();
      final uri = Uri.parse(
          '$_baseUrl/api/customer/${widget.customerId}/documents?field=$field');
      final request = http.MultipartRequest('PUT', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename:
          picked.name.isNotEmpty ? picked.name : '$field.jpg',
        ),
      );

      final response = await request.send();
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSuccess(
            isUrdu ? "دستاویز کامیابی سے اپڈیٹ ہو گئی!" : "Document updated successfully!");
        await _fetchProfile();
      } else {
        _showError(isUrdu ? "اپڈیٹ ناکام ہو گیا" : "Update failed");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError(isUrdu ? "خرابی: $e" : "Error: $e");
    }
  }

  Future<void> _deleteDocument(String field) async {
    final confirm = await _showConfirmDialog(
        isUrdu ? "اس دستاویز کو حذف کریں؟" : "Delete this document?");
    if (!confirm) return;

    try {
      final response = await http.delete(
        Uri.parse(
            '$_baseUrl/api/customer/${widget.customerId}/documents?field=$field'),
      );
      if (response.statusCode == 200) {
        setState(() => _profile![field] = null);
        _showSuccess(
            isUrdu ? "دستاویز کامیابی سے حذف کر دی گئی" : "Document deleted successfully");
      } else {
        _showError(isUrdu ? "حذف کرنے میں ناکامی" : "Failed to delete");
      }
    } catch (e) {
      _showError(isUrdu ? "خرابی: $e" : "Error: $e");
    }
  }

  void _viewImage(String base64String) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(base64Decode(base64String),
                fit: BoxFit.contain),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isUrdu ? "بند کریں" : "Close"),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSignOut() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? "میری پروفائل" : "My Profile"),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? Center(
          child: Text(isUrdu
              ? "پروفائل لوڈ نہیں ہو سکی۔"
              : "Profile could not be loaded."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildDocumentsCard(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSignOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side:
                    const BorderSide(color: Colors.red),
                  ),
                ),
                child: Text(isUrdu ? "سائن آؤٹ" : "Sign Out",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final profilePicBase64 = _profile!['profilePic'];
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: profilePicBase64 != null
                  ? MemoryImage(base64Decode(profilePicBase64))
                  : null,
              child: profilePicBase64 == null
                  ? const Icon(Icons.person,
                  size: 50, color: Colors.grey)
                  : null,
            ),
            GestureDetector(
              onTap: () => _updateDocument('profilePic'),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A6B4A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _profile!['fullName'] ?? (isUrdu ? 'دستیاب نہیں' : 'N/A'),
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          _profile!['city'] ?? '',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.badge_outlined,
                isUrdu ? "شناختی کارڈ" : "CNIC", _profile!['cnic']),
            _buildInfoRow(Icons.phone_outlined,
                isUrdu ? "فون" : "Phone", _profile!['phone']),
            _buildInfoRow(Icons.location_city_outlined,
                isUrdu ? "شہر" : "City", _profile!['city']),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isUrdu ? "دستاویزات" : "Documents",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildDocumentRow(
                'cnicFront', isUrdu ? 'شناختی کارڈ کا اگلا حصہ' : 'CNIC Front'),
            _buildDocumentRow(
                'cnicBack', isUrdu ? 'شناختی کارڈ کا پچھلا حصہ' : 'CNIC Back'),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentRow(String field, String label) {
    final hasFile = _profile![field] != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.check_circle : Icons.error_outline,
            color: hasFile ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style:
                const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (hasFile)
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: () => _viewImage(_profile![field]),
            ),
          IconButton(
            icon: const Icon(Icons.cloud_upload,
                color: Color(0xFF1A6B4A)),
            onPressed: () => _updateDocument(field),
          ),
          if (hasFile)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteDocument(field),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value ?? (isUrdu ? 'دستیاب نہیں' : 'N/A'),
              style: TextStyle(color: Colors.grey[800])),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Colors.red));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Colors.green));
  }

  void _showLoadingDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator()),
    );
  }

  Future<bool> _showConfirmDialog(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(isUrdu
            ? "یہ عمل واپس نہیں کیا جا سکتا۔"
            : "This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isUrdu ? "منسوخ کریں" : "Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isUrdu ? "تصدیق کریں" : "Confirm",
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}