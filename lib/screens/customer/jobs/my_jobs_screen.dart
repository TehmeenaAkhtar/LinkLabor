import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../screens/customer/jobs/post_job_screen.dart';
import '../../../screens/customer/profile/profile_screen.dart';
import '../../../screens/chat_screen.dart';
import '../../../language_state.dart';

class CustomerMyJobsScreen extends StatefulWidget {
  final int customerId;
  const CustomerMyJobsScreen({super.key, required this.customerId});

  @override
  State<CustomerMyJobsScreen> createState() => _CustomerMyJobsScreenState();
}

class _CustomerMyJobsScreenState extends State<CustomerMyJobsScreen> {
  List<dynamic> _myJobs = [];
  bool _isLoading = true;
  Map<String, dynamic>? _customerProfile;

  final String _baseUrl = "http://192.168.10.2:3000";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!_isLoading) setState(() => _isLoading = true);
    await Future.wait([
      _fetchMyJobs(),
      _fetchCustomerProfile(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMyJobs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/jobs/customer/${widget.customerId}'),
      );
      if (mounted && response.statusCode == 200) {
        setState(() => _myJobs = jsonDecode(response.body));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isUrdu
                  ? "کام حاصل کرنے میں ناکامی۔"
                  : "Failed to fetch jobs.")),
        );
      }
    }
  }

  Future<void> _fetchCustomerProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/customer/${widget.customerId}'),
      );
      if (mounted && response.statusCode == 200) {
        setState(() => _customerProfile = jsonDecode(response.body));
      }
    } catch (_) {}
  }

  void _navigateToPostJob() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostJobScreen(customerId: widget.customerId),
      ),
    );
    if (result == true) _fetchMyJobs();
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerProfileScreen(customerId: widget.customerId),
      ),
    ).then((_) => _fetchCustomerProfile());
  }

  // ── Show applicants bottom sheet when job card tapped ──
  void _showApplicants(dynamic job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicantsSheet(
        job: job,
        customerId: widget.customerId,
        baseUrl: _baseUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToPostJob,
        backgroundColor: const Color(0xFF0EA5E9),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isUrdu ? "کام پوسٹ کریں" : "Post a Job",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _navigateToProfile,
                    child: _buildProfileAvatar(),
                  ),
                  Text(
                    isUrdu ? "ہوم" : "Home",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: isUrdu ? "کارکن تلاش کریں" : "Search for workers",
                  prefixIcon:
                  const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isUrdu ? "آپ کے کام" : "Your Jobs",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Job List ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _myJobs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadAllData,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: _myJobs.length,
                  itemBuilder: (context, index) {
                    return _buildJobCard(_myJobs[index]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final profilePicBase64 = _customerProfile?['profilePic'];
    ImageProvider? backgroundImage;
    if (profilePicBase64 != null) {
      backgroundImage = MemoryImage(base64Decode(profilePicBase64));
    } else {
      backgroundImage =
      const AssetImage('assets/images/avatar_placeholder.png');
    }
    return CircleAvatar(
      backgroundImage: backgroundImage,
      radius: 20,
      backgroundColor: Colors.grey[200],
    );
  }

  // ── Job card — tap to see applicants ──
  Widget _buildJobCard(dynamic job) {
    bool isActive = job['status'] == 'open';
    return GestureDetector(
      onTap: () => _showApplicants(job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.handyman_outlined,
                  color: Colors.blue),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title'] ?? (isUrdu ? "نامعلوم کام" : "Unknown Job"),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? (isUrdu
                        ? "فعال — درخواست دہندگان دیکھنے کے لیے ٹیپ کریں"
                        : "Active — tap to see applicants")
                        : (isUrdu ? "مکمل" : "Completed"),
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            isUrdu ? "ابھی تک کوئی کام پوسٹ نہیں کیا گیا" : "No jobs posted yet",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(
            isUrdu
                ? "شروع کرنے کے لیے + کام پوسٹ کریں پر ٹیپ کریں"
                : "Tap + Post a Job to get started",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════
// APPLICANTS BOTTOM SHEET
// ════════════════════════════════════════
class _ApplicantsSheet extends StatefulWidget {
  final dynamic job;
  final int customerId;
  final String baseUrl;

  const _ApplicantsSheet({
    required this.job,
    required this.customerId,
    required this.baseUrl,
  });

  @override
  State<_ApplicantsSheet> createState() => _ApplicantsSheetState();
}

class _ApplicantsSheetState extends State<_ApplicantsSheet> {
  List<dynamic> _applicants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final r = await http.get(Uri.parse(
        '${widget.baseUrl}/api/jobs/${widget.job['id']}/applications',
      ));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _applicants = jsonDecode(r.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int applicationId, String status) async {
    try {
      await http.put(
        Uri.parse('${widget.baseUrl}/api/applications/$applicationId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      await _fetchApplicants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                status == 'accepted'
                    ? (isUrdu ? '✓ کارکن منظور کر لیا گیا!' : '✓ Worker accepted!')
                    : (isUrdu ? 'کارکن مسترد کر دیا گیا' : 'Worker rejected')),
            backgroundColor:
            status == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (_) {}
  }

  void _openChat(dynamic applicant) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobChatScreen(
          jobId: widget.job['id'] as int,
          jobTitle: widget.job['title'] ?? '',
          workerId: applicant['worker_id'] as int,
          customerId: widget.customerId,
          senderType: 'customer',
          otherPersonName: applicant['fullName'] ?? (isUrdu ? 'کارکن' : 'Worker'),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    if (status == 'accepted') return isUrdu ? '✓ منظور شدہ' : '✓ Accepted';
    if (status == 'rejected') return isUrdu ? '✗ مسترد' : '✗ Rejected';
    return isUrdu ? '⏳ زیر التوا' : '⏳ Pending';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle ──
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job['title'] ?? (isUrdu ? 'کام' : 'Job'),
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isUrdu
                              ? '${widget.job['budget']} روپے • ${widget.job['location'] ?? ''}'
                              : 'PKR ${widget.job['budget']} • ${widget.job['location'] ?? ''}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUrdu
                          ? '${_applicants.length} درخواست دہندگان'
                          : '${_applicants.length} applicant(s)',
                      style: const TextStyle(
                        color: Color(0xFF1A6B4A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ── Applicants List ──
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _applicants.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      isUrdu
                          ? "ابھی تک کوئی درخواست دہندہ نہیں ہے\nکارکن جلد درخواست دیں گے!"
                          : "No applicants yet\nWorkers will apply soon!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: _applicants.length,
                itemBuilder: (context, index) {
                  final app = _applicants[index];
                  final status = app['status'] ?? 'pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // ── Worker Info ──
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                const Color(0xFF1A6B4A),
                                child: Text(
                                  (app['fullName'] ??
                                      'W')[0]
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app['fullName'] ??
                                          (isUrdu ? 'کارکن' : 'Worker'),
                                      style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${app['skill'] ?? ''} • ${app['city'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (app['availableHours'] !=
                                        null)
                                      Text(
                                        '🕐 ${app['availableHours']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // ── Status Badge ──
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'accepted'
                                      ? const Color(0xFFE8F5EE)
                                      : status == 'rejected'
                                      ? const Color(
                                      0xFFFEE2E2)
                                      : const Color(
                                      0xFFFEF3C7),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'accepted'
                                        ? const Color(0xFF1A6B4A)
                                        : status == 'rejected'
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── About ──
                          if (app['about'] != null &&
                              app['about']
                                  .toString()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              app['about'],
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],

                          // ── Phone ──
                          if (app['phone'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    size: 14,
                                    color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  app['phone'],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),

                          // ── Action Buttons ──
                          if (status == 'pending') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _updateStatus(
                                            app['id'],
                                            'rejected'),
                                    style:
                                    OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(
                                          color: Colors.red),
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    child: Text(
                                        isUrdu ? "✗ مسترد کریں" : "✗ Reject"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _updateStatus(
                                            app['id'],
                                            'accepted'),
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      const Color(0xFF1A6B4A),
                                      foregroundColor:
                                      Colors.white,
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                    child: Text(
                                        isUrdu ? "✓ منظور کریں" : "✓ Accept"),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (status == 'accepted') ...[
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openChat(app),
                                icon: const Icon(
                                    Icons.chat_rounded,
                                    size: 18),
                                label: Text(
                                    isUrdu ? "کارکن کو پیغام بھیجیں" : "Message Worker"),
                                style:
                                ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF1A6B4A),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ] else if (status == 'rejected') ...[
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(
                                    app['id'], 'accepted'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  const Color(0xFF1A6B4A),
                                  side: const BorderSide(
                                      color: Color(0xFF1A6B4A)),
                                ),
                                child: Text(
                                    isUrdu
                                        ? "واپس لیں — منظور کریں"
                                        : "Undo — Accept Instead"),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}