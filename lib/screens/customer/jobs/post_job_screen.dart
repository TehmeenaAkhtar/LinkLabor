import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../language_state.dart';

class PostJobScreen extends StatefulWidget {
  final int customerId;

  const PostJobScreen({super.key, required this.customerId});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
// 1. Start Loading
    setState(() => _isLoading = true);

    try {
      // Replace with your Laptop IP
      final url = Uri.parse('http://192.168.10.2:3000/api/jobs');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "customerId": widget.customerId,
          "title": _titleController.text,
          "description": _descController.text,
          "budget": _budgetController.text,
          "location": _locationController.text,
        }),
      );

      if (!mounted) return; // Safety check if user left screen

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 2. Show Success Popup
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap OK
          builder: (ctx) => AlertDialog(
            title: Text(isUrdu ? "کامیابی" : "Success"),
            content: Text(isUrdu
                ? "کام کامیابی سے پوسٹ ہو گیا! کارکن اب اسے دیکھ سکتے ہیں۔"
                : "Job Posted Successfully! Workers can now view it."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close Dialog
                  Navigator.of(context).pop(true); // 3. Go Back to Dashboard (pass 'true' to refresh)
                },
                child: Text(isUrdu ? "ٹھیک ہے" : "OK",
                    style: const TextStyle(color: Color(0xFF1E8449))),
              ),
            ],
          ),
        );
      } else {
        _showErrorSnackBar(isUrdu
            ? "کام پوسٹ کرنے میں ناکامی: ${response.body}"
            : "Failed to post job: ${response.body}");
      }
    } catch (e) {
      _showErrorSnackBar(isUrdu ? "نیٹ ورک میں خرابی: $e" : "Network Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Helper for error messages
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? "نیا کام پوسٹ کریں" : "Post a New Job"),
        backgroundColor: const Color(0xFF1E8449),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                isUrdu ? "کام کا عنوان" : "Job Title",
                isUrdu ? "مثلاً نل کی مرمت" : "e.g. Fix Leaking Tap",
                _titleController,
              ),
              _buildTextField(
                isUrdu ? "مقام" : "Location",
                isUrdu ? "مثلاً واپڈا ٹاؤن، لاہور" : "e.g. Wapda Town, Lahore",
                _locationController,
              ),
              _buildTextField(
                isUrdu ? "بجٹ (روپے)" : "Budget (PKR)",
                isUrdu ? "مثلاً 2000" : "e.g. 2000",
                _budgetController,
                isNumber: true,
              ),
              _buildTextField(
                isUrdu ? "تفصیل" : "Description",
                isUrdu ? "مسئلے کی وضاحت کریں..." : "Describe the issue...",
                _descController,
                maxLines: 4,
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8449),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isUrdu ? "کام پوسٹ کریں" : "Post Job",
                    style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (val) => val!.isEmpty ? (isUrdu ? "درکار ہے" : "Required") : null,
      ),
    );
  }
}