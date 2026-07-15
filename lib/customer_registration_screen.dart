import 'dart:convert';
import 'language_state.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'screens/customer/dashboard.dart';
import 'speaker_button.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() =>
      _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState
    extends State<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCity;

  XFile? _cnicFront;
  XFile? _cnicBack;
  XFile? _profilePic;

  static const String _baseUrl = "http://192.168.10.2:3000";
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  final List<String> _cities = [
    'Abbottabad', 'Ahmadpur East', 'Arifwala', 'Attock',
    'Badin', 'Bahawalnagar', 'Bahawalpur', 'Bannu', 'Batkhela',
    'Bhakkar', 'Bhalwal', 'Bhimber', 'Burewala', 'Chakwal', 'Chaman',
    'Charsadda', 'Chichawatni', 'Chiniot', 'Chishtian', 'Dadu', 'Daska',
    'Dera Ghazi Khan', 'Dera Ismail Khan', 'Faisalabad', 'Ghotki',
    'Gilgit', 'Gojra', 'Gujranwala', 'Gujrat', 'Gwadar', 'Hafizabad',
    'Haripur', 'Hyderabad', 'Islamabad', 'Jacobabad', 'Jaranwala',
    'Jhang', 'Jhelum', 'Kamalia', 'Kamoke', 'Karachi', 'Kasur',
    'Khairpur', 'Khanewal', 'Khanpur', 'Khushab', 'Kohat', 'Kot Addu',
    'Lahore', 'Larkana', 'Layyah', 'Lodhran', 'Mandi Bahauddin',
    'Mansehra', 'Mardan', 'Mianwali', 'Mingora', 'Mirpur',
    'Mirpur Khas', 'Multan', 'Muzaffarabad', 'Murree', 'Nankana Sahib',
    'Narowal', 'Nawabshah', 'Nowshera', 'Okara', 'Pakpattan',
    'Peshawar', 'Quetta', 'Rahim Yar Khan', 'Rawalpindi', 'Sadiqabad',
    'Sahiwal', 'Sargodha', 'Sheikhupura', 'Shikarpur', 'Sialkot',
    'Sibi', 'Skardu', 'Sukkur', 'Swabi', 'Taxila', 'Toba Tek Singh',
    'Turbat', 'Vehari', 'Wah Cantonment', 'Zhob'
  ];

  final Map<String, String> cityUrdu = {
    "Abbottabad": "ایبٹ آباد",
    "Ahmadpur East": "احمد پور ایسٹ",
    "Arifwala": "عارف والا",
    "Attock": "اٹک",
    "Badin": "بدین",
    "Bahawalnagar": "بہاول نگر",
    "Bahawalpur": "بہاولپور",
    "Bannu": "بنوں",
    "Batkhela": "بٹ خیلہ",
    "Bhakkar": "بھکر",
    "Bhalwal": "بھلوال",
    "Bhimber": "بھمبر",
    "Burewala": "بورے والا",
    "Chakwal": "چکوال",
    "Chaman": "چمن",
    "Charsadda": "چارسدہ",
    "Chichawatni": "چیچہ وطنی",
    "Chiniot": "چنیوٹ",
    "Chishtian": "چشتیاں",
    "Dadu": "دادو",
    "Daska": "ڈسکہ",
    "Dera Ghazi Khan": "ڈیرہ غازی خان",
    "Dera Ismail Khan": "ڈیرہ اسماعیل خان",
    "Faisalabad": "فیصل آباد",
    "Ghotki": "گھوٹکی",
    "Gilgit": "گلگت",
    "Gojra": "گوجرہ",
    "Gujranwala": "گوجرانوالہ",
    "Gujrat": "گجرات",
    "Gwadar": "گوادر",
    "Hafizabad": "حافظ آباد",
    "Haripur": "ہری پور",
    "Hyderabad": "حیدر آباد",
    "Islamabad": "اسلام آباد",
    "Jacobabad": "جیکب آباد",
    "Jaranwala": "جڑانوالہ",
    "Jhang": "جھنگ",
    "Jhelum": "جہلم",
    "Kamalia": "کمالیہ",
    "Kamoke": "کامونکی",
    "Karachi": "کراچی",
    "Kasur": "قصور",
    "Khairpur": "خیرپور",
    "Khanewal": "خانیوال",
    "Khanpur": "خانپور",
    "Khushab": "خوشاب",
    "Kohat": "کوہاٹ",
    "Kot Addu": "کوٹ ادو",
    "Lahore": "لاہور",
    "Larkana": "لاڑکانہ",
    "Layyah": "لیہ",
    "Lodhran": "لودھراں",
    "Mandi Bahauddin": "منڈی بہاؤالدین",
    "Mansehra": "مانسہرہ",
    "Mardan": "مردان",
    "Mianwali": "میانوالی",
    "Mingora": "مینگورہ",
    "Mirpur": "میرپور",
    "Mirpur Khas": "میرپور خاص",
    "Multan": "ملتان",
    "Muzaffarabad": "مظفر آباد",
    "Murree": "مری",
    "Nankana Sahib": "ننکانہ صاحب",
    "Narowal": "نارووال",
    "Nawabshah": "نواب شاہ",
    "Nowshera": "نوشہرہ",
    "Okara": "اوکاڑہ",
    "Pakpattan": "پاکپتن",
    "Peshawar": "پشاور",
    "Quetta": "کوئٹہ",
    "Rahim Yar Khan": "رحیم یار خان",
    "Rawalpindi": "راولپنڈی",
    "Sadiqabad": "صادق آباد",
    "Sahiwal": "ساہیوال",
    "Sargodha": "سرگودھا",
    "Sheikhupura": "شیخوپورہ",
    "Shikarpur": "شکارپور",
    "Sialkot": "سیالکوٹ",
    "Sibi": "سبی",
    "Skardu": "سکردو",
    "Sukkur": "سکھر",
    "Swabi": "صوابی",
    "Taxila": "ٹیکسلا",
    "Toba Tek Singh": "ٹوبہ ٹیک سنگھ",
    "Turbat": "تربت",
    "Vehari": "وہاڑی",
    "Wah Cantonment": "واہ کینٹ",
    "Zhob": "ژوب"
  };

  static const Map<String, String> _uploadUrdu = {
    "Upload CNIC Front": "شناختی کارڈ کا اگلا حصہ اپلوڈ کریں",
    "Upload CNIC Back": "شناختی کارڈ کا پچھلا حصہ اپلوڈ کریں",
    "Upload Profile Picture": "اپنی تصویر اپلوڈ کریں",
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(
      ImageSource source, Function(XFile) onSelect) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() => onSelect(picked));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? "تصویر منتخب نہیں ہو سکی: $e"
                : "Failed to pick image: $e",
          ),
        ),
      );
    }
  }

  Future<void> _addFile(
      http.MultipartRequest request, String field, XFile? file) async {
    if (file == null) return;
    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        field, bytes,
        filename: file.name.isNotEmpty ? file.name : '$field.jpg',
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cnicFront == null || _cnicBack == null || _profilePic == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isUrdu
              ? "پروفائل تصویر اور شناختی کارڈ کے دونوں حصے ضروری ہیں۔"
              : "Profile picture, CNIC front & back are required.",
        ),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _isUploading = true);
    int? newCustomerId;

    try {
      final request = http.MultipartRequest(
          "POST", Uri.parse("$_baseUrl/api/customer"));
      request.fields['fullName'] = _fullNameController.text;
      request.fields['cnic'] = _cnicController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['city'] = _selectedCity!;
      await _addFile(request, "cnicFront", _cnicFront);
      await _addFile(request, "cnicBack", _cnicBack);
      await _addFile(request, "profilePic", _profilePic);

      final response =
      await http.Response.fromStream(await request.send());

      if (mounted) {
        if (response.statusCode == 201) {
          final responseBody = jsonDecode(response.body);
          newCustomerId =
              int.parse(responseBody['customerId'].toString());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              isUrdu
                  ? "رجسٹریشن کامیابی سے مکمل ہوگئی۔"
                  : "Customer registered successfully",
            ),
            backgroundColor: Colors.green,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              isUrdu
                  ? "سرور خرابی: ${response.body}"
                  : "Server error: ${response.body}",
            ),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isUrdu
                    ? "خرابی پیش آگئی: $e"
                    : "An error occurred: $e",
              ),
            ),
            );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }

    if (newCustomerId != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              CustomerDashboard(customerId: newCustomerId!),
        ),
            (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isUrdu
              ? "تصدیق شدہ صارف بنیں"
              : "Become a Verified User",
        ),
        backgroundColor: const Color(0xFF1E8449),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                _fullNameController,
                "Enter your full name",
                "e.g. Ali Abbas",
                "اپنا پورا نام درج کریں",
              ),
              _buildTextField(
                _cnicController,
                "Enter CNIC",
                "e.g. 37201-5267698-8",
                "اپنا شناختی کارڈ نمبر درج کریں",
                isNumeric: true,
              ),
              _buildTextField(
                _phoneController,
                "Enter Phone no.",
                "e.g. 03316634986",
                "اپنا فون نمبر درج کریں",
                isNumeric: true,
              ),
              _buildCityDropdown(),
              const SizedBox(height: 20),
              _buildUploadRow(
                "Upload CNIC Front",
                _cnicFront,
                    (f) => setState(() => _cnicFront = f),
              ),
              _buildUploadRow(
                "Upload CNIC Back",
                _cnicBack,
                    (f) => setState(() => _cnicBack = f),
              ),
              _buildUploadRow(
                "Upload Profile Picture",
                _profilePic,
                    (f) => setState(() => _profilePic = f),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8449),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    isUrdu ? "جمع کریں" : "Submit",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Text field with speaker next to label ──
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      String hint,
      String urduText, {
        bool isNumeric = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  isUrdu ? urduText : label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              SpeakerButton(urduText: urduText),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType:
            isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: isUrdu ? "" : hint,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? (isUrdu
                ? "یہ خانہ لازمی ہے"
                : "$label is required")
                : null,
          ),
        ],
      ),
    );
  }

  // ── City dropdown with speaker next to label ──
  Widget _buildCityDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isUrdu
                    ? "شہر منتخب کریں"
                    : "Select City",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              SpeakerButton(
                urduText: "اپنا شہر منتخب کریں جہاں آپ رہتے ہیں",
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            hint: Text(
              isUrdu
                  ? "شہر منتخب کریں"
                  : "Select City",
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
            ),
            items: _cities
                .map((city) => DropdownMenuItem<String>(
                value: city, child: Text(
              isUrdu
                  ? (cityUrdu[city] ?? city)
                  : city,
            ),))
                .toList(),
            onChanged: (v) => setState(() => _selectedCity = v),
            validator: (v) =>
            v == null ? isUrdu
                ? "براہ کرم شہر منتخب کریں"
                : "Please select a city" : null,
          ),
        ],
      ),
    );
  }

  // ── Upload row with speaker next to label ──
  Widget _buildUploadRow(
      String title, XFile? file, Function(XFile) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  isUrdu
                      ? (_uploadUrdu[title] ?? title)
                      : title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              SpeakerButton(
                urduText: _uploadUrdu[title] ?? title,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: Text(
                    file == null
                        ? (isUrdu ? "اپلوڈ" : "Upload")
                        : (isUrdu ? "تبدیل کریں" : "Change"),
                  ),
                  onPressed: () =>
                      _pickImage(ImageSource.gallery, onSelect),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E8449),
                    side: const BorderSide(color: Color(0xFF1E8449)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: Text(
                    file == null
                        ? (isUrdu ? "اسکین" : "Scan")
                        : (isUrdu ? "دوبارہ اسکین" : "Re-Scan"),
                  ),
                  onPressed: () =>
                      _pickImage(ImageSource.camera, onSelect),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (file != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    file.name.isNotEmpty
                        ? file.name
                        : (isUrdu
                        ? "تصویر منتخب ہوگئی ✓"
                        : "Image selected ✓"),
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