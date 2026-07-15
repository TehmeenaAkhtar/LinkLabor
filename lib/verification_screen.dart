import 'dart:convert';
import 'dart:typed_data';
import 'language_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'screens/worker/dashboard.dart';
import 'speaker_button.dart';

class VerificationScreen extends StatefulWidget {
  final Map<String, String> workerData;
  const VerificationScreen({super.key, required this.workerData});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // Store bytes directly instead of XFile — bytes stay in memory forever
  Map<String, Uint8List> _fileBytes = {};
  Map<String, String> _fileNames = {};

  static const String _baseUrl = "http://192.168.10.2:3000";
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  static const Map<String, String> _urduMap = {
    "CNIC Front *": "شناختی کارڈ کا اگلا حصہ اپلوڈ کریں",
    "CNIC Back *": "شناختی کارڈ کا پچھلا حصہ اپلوڈ کریں",
    "Profile Picture *": "اپنی تصویر اپلوڈ کریں",
    "Work Certificate (Optional)": "کام کا سرٹیفکیٹ اپلوڈ کریں",
    "License Front (Optional)": "لائسنس کا اگلا حصہ اپلوڈ کریں",
    "License Back (Optional)": "لائسنس کا پچھلا حصہ اپلوڈ کریں",
  };

  // Field keys
  static const String kCnicFront = "cnicFront";
  static const String kCnicBack = "cnicBack";
  static const String kProfilePic = "profilePic";
  static const String kWorkCert = "workCert";
  static const String kLicense = "license";
  static const String kLicenseBack = "licenseBack";

  // ── Pick image and immediately read bytes ──
  Future<void> _pickImage(
      ImageSource source, String fieldKey) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      // Read bytes IMMEDIATELY — before Android clears the cache
      final Uint8List bytes = await picked.readAsBytes();
      final String name = picked.name.isNotEmpty
          ? picked.name
          : '$fieldKey.jpg';

      if (!mounted) return;
      setState(() {
        _fileBytes[fieldKey] = bytes;
        _fileNames[fieldKey] = name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? "تصویر منتخب نہیں کی جا سکی۔"
                : "Failed to pick image: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Submit ──
  Future<void> _submitFullRegistration() async {
    if (!_fileBytes.containsKey(kCnicFront) ||
        !_fileBytes.containsKey(kCnicBack) ||
        !_fileBytes.containsKey(kProfilePic)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? "تصویر، شناختی کارڈ کا اگلا اور پچھلا حصہ لازمی ہیں۔"
                : "Profile picture, CNIC front & back are required.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    int? newWorkerId;

    try {
      final request = http.MultipartRequest(
          "POST", Uri.parse("$_baseUrl/api/worker"));

      request.fields.addAll(widget.workerData);

      // Add all files from stored bytes
      _fileBytes.forEach((field, bytes) {
        request.files.add(
          http.MultipartFile.fromBytes(
            field,
            bytes,
            filename: _fileNames[field] ?? '$field.jpg',
          ),
        );
      });

      final response =
      await http.Response.fromStream(await request.send());

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = jsonDecode(response.body);
        newWorkerId = int.parse(responseBody['workerId'].toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? "رجسٹریشن کامیابی سے مکمل ہوگئی!"
                  : "Registered successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? "سرور کی خرابی۔"
                  : "Server error: ${response.body}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUrdu ? "خرابی: $e" : "Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

    if (newWorkerId != null && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => WorkerDashboard(workerId: newWorkerId!),
        ),
            (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? "دستاویزات کی تصدیق" : "Verify Documents"),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                _buildUploadRow("CNIC Front *", kCnicFront),
                _buildUploadRow("CNIC Back *", kCnicBack),
                _buildUploadRow("Profile Picture *", kProfilePic),
                _buildUploadRow("Work Certificate (Optional)", kWorkCert),
                _buildUploadRow("License Front (Optional)", kLicense),
                _buildUploadRow("License Back (Optional)", kLicenseBack),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isUrdu ? "* لازمی فیلڈز" : "* Required fields",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    _isUploading ? null : _submitFullRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : Text(
                      isUrdu
                          ? "درخواست جمع کروائیں"
                          : "Submit Application",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadRow(String title, String fieldKey) {
    final bool hasFile = _fileBytes.containsKey(fieldKey);
    final String? fileName = _fileNames[fieldKey];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label with speaker ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUrdu ? (_urduMap[title] ?? title) : title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 6),
              SpeakerButton(urduText: _urduMap[title] ?? title),
            ],
          ),
          const SizedBox(height: 8),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: Text(
                    hasFile
                        ? (isUrdu ? "تبدیل کریں" : "Change")
                        : (isUrdu ? "اپلوڈ کریں" : "Upload"),
                  ),
                  onPressed: () =>
                      _pickImage(ImageSource.gallery, fieldKey),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A6B4A),
                    side: const BorderSide(color: Color(0xFF1A6B4A)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text(
                    hasFile
                        ? (isUrdu ? "دوبارہ لیں" : "Retake")
                        : (isUrdu ? "اسکین کریں" : "Scan"),
                  ),
                  onPressed: () =>
                      _pickImage(ImageSource.camera, fieldKey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B4A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // ── File name ──
          if (hasFile) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fileName ?? (isUrdu ? "تصویر منتخب ✓" : "Image selected ✓"),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}