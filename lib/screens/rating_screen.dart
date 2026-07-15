import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../language_state.dart';

class RatingScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  final int raterId;
  final int ratedId;
  final String ratedBy; // 'worker' or 'customer'
  final String ratedName;

  const RatingScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.raterId,
    required this.ratedId,
    required this.ratedBy,
    required this.ratedName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _selectedRating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  static const String _baseUrl = "http://192.168.10.2:3000";
  static const Color kGreen = Color(0xFF1A6B4A);

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu ? "براہ کرم ریٹنگ منتخب کریں" : "Please select a rating",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/api/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': widget.jobId,
          'rated_by': widget.ratedBy,
          'rater_id': widget.raterId,
          'rated_id': widget.ratedId,
          'rating': _selectedRating,
          'feedback': _feedbackController.text.trim(),
        }),
      );

      if (!mounted) return;

      if (r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu ? "ریٹنگ جمع ہو گئی! شکریہ" : "Rating submitted! Thank you",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(r.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Failed to submit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isUrdu ? "ریٹنگ دیں" : "Rate & Review"),
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ── Job title ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.jobTitle,
                style: const TextStyle(
                  color: kGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Avatar ──
            CircleAvatar(
              radius: 40,
              backgroundColor: kGreen,
              child: Text(
                widget.ratedName.isNotEmpty
                    ? widget.ratedName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.ratedName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              isUrdu
                  ? "آپ کے ساتھ کام کرنا کیسا تجربہ تھا؟"
                  : "How was your experience working together?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 32),

            // ── Star rating ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = star),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      star <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 48,
                      color: star <= _selectedRating
                          ? Colors.amber
                          : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // ── Rating label ──
            Text(
              _ratingLabel(),
              style: TextStyle(
                color: _selectedRating > 0 ? Colors.amber[700] : Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // ── Feedback field ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isUrdu
                    ? "رائے (اختیاری)"
                    : "Feedback (Optional)",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: isUrdu
                    ? "اپنا تجربہ بیان کریں..."
                    : "Describe your experience...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: kGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 32),

            // ── Submit button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isUrdu ? "جمع کروائیں" : "Submit Rating",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Skip button ──
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isUrdu ? "ابھی نہیں" : "Skip for now",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel() {
    switch (_selectedRating) {
      case 1:
        return isUrdu ? "بہت برا" : "Very Poor";
      case 2:
        return isUrdu ? "برا" : "Poor";
      case 3:
        return isUrdu ? "ٹھیک ہے" : "Average";
      case 4:
        return isUrdu ? "اچھا" : "Good";
      case 5:
        return isUrdu ? "بہترین!" : "Excellent!";
      default:
        return isUrdu ? "ستارہ منتخب کریں" : "Select a star";
    }
  }
}