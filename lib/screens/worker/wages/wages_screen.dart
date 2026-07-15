import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../language_state.dart';

class WorkerWagesScreen extends StatefulWidget {
  final int workerId;
  const WorkerWagesScreen({super.key, required this.workerId});

  @override
  State<WorkerWagesScreen> createState() => _WorkerWagesScreenState();
}

class _WorkerWagesScreenState extends State<WorkerWagesScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  static const String _baseUrl = "http://192.168.10.2:3000";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(
        Uri.parse('$_baseUrl/api/worker/${widget.workerId}/applications'),
      );
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _applications = jsonDecode(r.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _accepted =>
      _applications.where((j) => j['status'] == 'accepted').toList();

  double get _totalEarnings {
    return _accepted.fold(0, (sum, job) {
      final budget = double.tryParse(job['budget'].toString()) ?? 0;
      return sum + budget;
    });
  }

  double get _activeEarnings {
    return _accepted
        .where((j) => j['jobStatus'] == 'open' || j['jobStatus'] == 'assigned')
        .fold(0, (sum, job) {
      final budget = double.tryParse(job['budget'].toString()) ?? 0;
      return sum + budget;
    });
  }

  String _pkr(num amount) {
    final formatted = amount is double ? amount.toStringAsFixed(0) : amount.toString();
    return isUrdu ? "$formatted روپے" : "PKR $formatted";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text(isUrdu ? "میری کمائی" : "My Earnings"),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Total Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A6B4A), Color(0xFF2D9E6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6B4A).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrdu ? "کل کمائی" : "Total Earnings",
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pkr(_totalEarnings),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.work_outline,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isUrdu
                              ? "${_accepted.length} منظور شدہ کام"
                              : "${_accepted.length} accepted jobs",
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Summary Cards ──
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      isUrdu ? "جاری کام" : "Active Jobs",
                      _pkr(_activeEarnings),
                      Icons.pending_actions_rounded,
                      Colors.orange,
                      const Color(0xFFFEF3C7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      isUrdu ? "کل درخواستیں" : "Total Applications",
                      "${_applications.length}",
                      Icons.send_rounded,
                      Colors.blue,
                      const Color(0xFFDBEAFE),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                isUrdu ? "کمائی کی تفصیل" : "Earnings Breakdown",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (_accepted.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.money_off,
                          size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        isUrdu
                            ? "ابھی تک کوئی کمائی نہیں ہے\nکام کے لیے درخواست دیں اور منظوری حاصل کریں!"
                            : "No earnings yet\nApply and get accepted for jobs!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ..._accepted.map((job) => _buildEarningCard(job)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String label,
      String value,
      IconData icon,
      Color color,
      Color bgColor,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEarningCard(dynamic job) {
    final isPending = job['jobStatus'] == 'open';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPending
                  ? Icons.pending_outlined
                  : Icons.check_circle_outline,
              color: isPending ? Colors.orange : const Color(0xFF1A6B4A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job['title'] ?? (isUrdu ? 'کام' : 'Job'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(job['customerName'] ?? '',
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _pkr(num.tryParse(job['budget'].toString()) ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isPending ? Colors.orange : const Color(0xFF1A6B4A),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPending
                      ? (isUrdu ? 'جاری ہے' : 'In Progress')
                      : (isUrdu ? 'مکمل' : 'Completed'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? Colors.orange
                        : const Color(0xFF1A6B4A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}