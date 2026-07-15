import 'dart:convert';
import '../../../language_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../welcome_screen.dart';

class WorkerProfile extends StatefulWidget {
  final int workerId;
  const WorkerProfile({super.key, required this.workerId});

  @override
  State<WorkerProfile> createState() => _WorkerProfileState();
}

class _WorkerProfileState extends State<WorkerProfile> {
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
    if (mounted && !_isLoading) setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/worker/${widget.workerId}'));
      if (mounted) {
        if (response.statusCode == 200) {
          setState(() => _profile = jsonDecode(response.body));
        } else {
          _showError(
            isUrdu
                ? "پروفائل لوڈ نہیں ہو سکا۔"
                : "Failed to load profile.",
          );
        }
      }
    } catch (e) {
      _showError(
        isUrdu
            ? "کنکشن میں خرابی: $e"
            : "Connection Error: $e",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Update document using XFile bytes (no dart:io) ──
  Future<void> _updateDocument(String field) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;

      _showLoadingDialog();

      final bytes = await picked.readAsBytes();
      final uri = Uri.parse(
          '$_baseUrl/api/worker/${widget.workerId}/documents?field=$field');
      final request = http.MultipartRequest('PUT', uri);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: picked.name.isNotEmpty ? picked.name : '$field.jpg',
        ),
      );

      final response = await request.send();
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        _showSuccess(
          isUrdu
              ? "دستاویز کامیابی سے اپ ڈیٹ ہوگئی۔"
              : "Document updated successfully",
        );
        await _fetchProfile();
      } else {
        _showError(
          isUrdu
              ? "اپ ڈیٹ ناکام ہوگئی۔"
              : "Update failed",
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError("Error: $e");
    }
  }

  Future<void> _deleteDocument(String field) async {
    final confirm = await _showConfirmDialog(
      isUrdu
          ? "کیا آپ یہ دستاویز حذف کرنا چاہتے ہیں؟"
          : "Delete this document?",
    );
    if (!confirm) return;

    try {
      final response = await http.delete(
        Uri.parse(
            '$_baseUrl/api/worker/${widget.workerId}/documents?field=$field'),
      );
      if (response.statusCode == 200) {
        setState(() => _profile![field] = null);
        _showSuccess(
          isUrdu
              ? "دستاویز حذف ہوگئی۔"
              : "Document deleted",
        );
      } else {
        _showError(
          isUrdu
              ? "حذف نہیں ہو سکی۔"
              : "Failed to delete",
        );
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _handleSignOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
          (route) => false, // removes ALL previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(
          isUrdu ? "میرا پروفائل" : "My Profile",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
    ? const Center(
    child: CircularProgressIndicator(),
    )
        : _profile == null
    ? Center(
    child: Text(
    isUrdu
    ? "کارکن نہیں ملا۔"
        : "Worker not found.",
    ),
    )
        : SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    _buildHeaderCard(),
    const SizedBox(height: 16),

    _buildInfoCard(
    isUrdu ? "تعارف" : "About",
    _profile!['about'] ??
    (isUrdu
    ? "کوئی معلومات فراہم نہیں کی گئی۔"
        : "No description provided."),
    ),

    const SizedBox(height: 16),
    _buildSkillsCard(),
    const SizedBox(height: 16),
    _buildDocumentsSection(),
    const SizedBox(height: 24),

    ElevatedButton(
    onPressed: _handleSignOut,
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red[50],
    foregroundColor: Colors.red,
    padding: const EdgeInsets.symmetric(vertical: 15),
    elevation: 0,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: Colors.red),
    ),
    ),
    child: Text(
    isUrdu ? "سائن آؤٹ" : "Sign Out",
    style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),

    const SizedBox(height: 30),
    ],
    ),
    ),
    );
  }

  Widget _buildHeaderCard() {
    final profilePicBase64 = _profile!['profilePic'];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // ── Profile picture with edit button ──
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    image: profilePicBase64 != null
                        ? DecorationImage(
                      image: MemoryImage(
                          base64Decode(profilePicBase64)),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: profilePicBase64 == null
                      ? const Icon(Icons.person,
                      size: 40, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _updateDocument('profilePic'),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A6B4A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile!['fullName'] ?? "Worker",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text("📞 ${_profile!['phone'] ?? 'N/A'}",
                      style: TextStyle(color: Colors.grey[700])),
                  Text(
                      "📍 ${_profile!['city'] ?? 'N/A'}",
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  if (_profile!['worker_form_completed'] == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border:
                        Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        isUrdu
                            ? "✔ تصدیق شدہ"
                            : "✔ Verified",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Text(content,
                style: const TextStyle(
                    color: Colors.black87, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    final skills = (_profile!['skill'] ?? '')
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? "مہارتیں" : "Skills",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            skills.isEmpty
                ? Text(
              isUrdu
                  ? "کوئی مہارت شامل نہیں کی گئی"
                  : "No skills added",
              style: const TextStyle(color: Colors.grey),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Chip(
                  label: Text(skill),
                  backgroundColor: const Color(0xFFE8F5E9),
                  labelStyle: const TextStyle(
                    color: Color(0xFF1A6B4A),
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docs = [
      {
        'field': 'cnicFront',
        'label': isUrdu ? 'شناختی کارڈ (سامنے)' : 'CNIC Front'
      },
      {
        'field': 'cnicBack',
        'label': isUrdu ? 'شناختی کارڈ (پیچھے)' : 'CNIC Back'
      },
      {
        'field': 'workCert',
        'label': isUrdu ? 'کام کا سرٹیفکیٹ' : 'Work Certificate'
      },
      {
        'field': 'license',
        'label': isUrdu ? 'ڈرائیونگ لائسنس' : 'Driver License'
      },
    ];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu ? "دستاویزات" : "Documents",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            ...docs.map(
                  (doc) => _buildDocumentRow(
                doc['field']!,
                doc['label']!,
              ),
            ),
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                isUrdu ? "بند کریں" : "Close",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String msg) async {
    return await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isUrdu ? "تصدیق" : "Confirm",
        ),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isUrdu ? "منسوخ کریں" : "Cancel",
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
                isUrdu ? "حذف کریں" : "Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}