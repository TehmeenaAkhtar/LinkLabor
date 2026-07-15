import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../../screens/chat_screen.dart';
import '../../../language_state.dart';

class WorkerJobsScreen extends StatefulWidget {
  final int workerId;
  const WorkerJobsScreen({super.key, required this.workerId});

  @override
  State<WorkerJobsScreen> createState() => _WorkerJobsScreenState();
}

class _WorkerJobsScreenState extends State<WorkerJobsScreen> {
  List<dynamic> _jobs = [];
  List<dynamic> _filteredJobs = [];
  List<dynamic> _myApplications = [];
  bool _isLoading = true;
  int _tab = 0;

  // Filter state
  String _searchQuery = '';
  String? _selectedSkill;
  bool _nearbyOnly = false;
  Position? _currentPosition;

  static const String _baseUrl = "http://192.168.10.2:3000";

  final List<String> _skills = [
    'Electrician', 'Plumber', 'Carpenter',
    'Painter', 'AC Technician', 'Mechanic',
    'Welder', 'Mason', 'Cleaner', 'Driver',
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = pos);

      // Update worker location on server
      await http.put(
        Uri.parse('$_baseUrl/api/worker/${widget.workerId}/location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        }),
      );
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchJobs(), _fetchMyApplications()]);
  }

  Future<void> _fetchJobs() async {
    try {
      setState(() => _isLoading = true);
      final r = await http.get(Uri.parse('$_baseUrl/api/jobs/open'));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _jobs = jsonDecode(r.body);
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchNearbyJobs() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUrdu
                ? "مقام حاصل کیا جا رہا ہے، براہ کرم انتظار کریں"
                : "Getting location, please wait...",
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final r = await http.get(Uri.parse(
        '$_baseUrl/api/jobs/nearby?latitude=${_currentPosition!.latitude}&longitude=${_currentPosition!.longitude}&radius=50',
      ));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _jobs = jsonDecode(r.body);
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMyApplications() async {
    try {
      final r = await http.get(
          Uri.parse('$_baseUrl/api/worker/${widget.workerId}/applications'));
      if (r.statusCode == 200 && mounted) {
        setState(() => _myApplications = jsonDecode(r.body));
      }
    } catch (_) {}
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _jobs.where((job) {
        final matchesSearch = _searchQuery.isEmpty ||
            (job['title'] ?? '').toLowerCase().contains(_searchQuery) ||
            (job['location'] ?? '').toLowerCase().contains(_searchQuery) ||
            (job['description'] ?? '').toLowerCase().contains(_searchQuery);

        final matchesSkill = _selectedSkill == null ||
            (job['title'] ?? '')
                .toLowerCase()
                .contains(_selectedSkill!.toLowerCase()) ||
            (job['description'] ?? '')
                .toLowerCase()
                .contains(_selectedSkill!.toLowerCase());

        return matchesSearch && matchesSkill;
      }).toList();
    });
  }

  Future<void> _applyJob(int jobId, String jobTitle, int customerId) async {
    try {
      final r = await http.post(
        Uri.parse('$_baseUrl/api/jobs/$jobId/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'workerId': widget.workerId}),
      );

      if (!mounted) return;

      if (r.statusCode == 201) {
        await _loadAll();
        _openChat(
          jobId: jobId,
          jobTitle: jobTitle,
          customerId: customerId,
        );
      } else {
        final body = jsonDecode(r.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['error'] ??
                (isUrdu ? "درخواست نہیں دی جا سکی" : "Could not apply")),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isUrdu ? "کنکشن میں خرابی" : "Connection error")),
        );
      }
    }
  }

  void _openChat({
    required int jobId,
    required String jobTitle,
    required int customerId,
    String? customerName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobChatScreen(
          jobId: jobId,
          jobTitle: jobTitle,
          workerId: widget.workerId,
          customerId: customerId,
          senderType: 'worker',
          otherPersonName:
          customerName ?? (isUrdu ? "کسٹمر" : "Customer"),
        ),
      ),
    );
  }

  void _showJobDetails(dynamic job) {
    final jobId = job['id'] as int;
    final applied = _hasApplied(jobId);
    final status = _applicationStatus(jobId);
    final customerId = job['customer_id'] as int? ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title + Budget
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      job['title'] ?? '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUrdu
                          ? "${job['budget']} روپے"
                          : "PKR ${job['budget']}",
                      style: const TextStyle(
                        color: Color(0xFF1A6B4A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer
              _detailRow(Icons.person_outline, job['customerName'] ?? ''),
              const SizedBox(height: 8),

              // Location
              _detailRow(Icons.location_on_outlined, job['location'] ?? ''),
              const SizedBox(height: 8),

              // Distance
              if (job['distance'] != null)
                _detailRow(
                  Icons.near_me_outlined,
                  '${(job['distance'] as double).toStringAsFixed(1)} km away',
                ),

              const Divider(height: 32),

              // Description
              Text(
                isUrdu ? "تفصیل" : "Description",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                job['description'] ?? '',
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.black87),
              ),

              const SizedBox(height: 32),

              // Action button
              if (!applied)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _applyJob(jobId, job['title'] ?? '', customerId);
                    },
                    icon: const Icon(Icons.send),
                    label: Text(isUrdu ? "درخواست دیں" : "Apply for this Job"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else if (status == 'accepted')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openChat(
                        jobId: jobId,
                        jobTitle: job['title'] ?? '',
                        customerId: customerId,
                        customerName: job['customerName'],
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: Text(isUrdu ? "پیغام بھیجیں" : "Message Customer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6B4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  bool _hasApplied(int jobId) => _myApplications
      .any((a) => a['job_id'].toString() == jobId.toString());

  String _applicationStatus(int jobId) {
    final app = _myApplications.firstWhere(
          (a) => a['job_id'].toString() == jobId.toString(),
      orElse: () => null,
    );
    return app?['status'] ?? '';
  }

  String _statusLabel(String status) {
    if (status == 'accepted') return isUrdu ? '✓ منظور شدہ' : '✓ Accepted';
    if (status == 'rejected') return isUrdu ? '✗ مسترد' : '✗ Rejected';
    return isUrdu ? '⏳ زیر التوا' : '⏳ Applied — Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? "کام" : "Jobs"),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: const Color(0xFF1A6B4A),
            child: Row(
              children: [
                _tabBtn(isUrdu ? "دستیاب کام" : "Open Jobs", 0),
                _tabBtn(isUrdu ? "میری درخواستیں" : "My Applications", 1),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tab == 0
          ? Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _nearbyOnly
                    ? await _fetchNearbyJobs()
                    : await _fetchJobs();
              },
              child: _buildOpenJobs(),
            ),
          ),
        ],
      )
          : RefreshIndicator(
        onRefresh: _loadAll,
        child: _buildMyApplications(),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          // Search box
          TextField(
            onChanged: (v) {
              _searchQuery = v.toLowerCase();
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: isUrdu
                  ? "کام تلاش کریں..."
                  : "Search jobs...",
              prefixIcon:
              const Icon(Icons.search, color: Colors.grey, size: 20),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),

          // Filter chips row
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Nearby toggle
                _filterChip(
                  label: isUrdu ? "📍 قریبی" : "📍 Nearby",
                  selected: _nearbyOnly,
                  onSelected: (val) {
                    setState(() => _nearbyOnly = val);
                    val ? _fetchNearbyJobs() : _fetchJobs();
                  },
                ),
                const SizedBox(width: 6),

                // All skills chip
                _filterChip(
                  label: isUrdu ? "تمام" : "All Skills",
                  selected: _selectedSkill == null,
                  onSelected: (_) {
                    setState(() => _selectedSkill = null);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 6),

                // Skill chips
                ..._skills.map((skill) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _filterChip(
                    label: skill,
                    selected: _selectedSkill == skill,
                    onSelected: (val) {
                      setState(() =>
                      _selectedSkill = val ? skill : null);
                      _applyFilters();
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? Colors.white : const Color(0xFF1A6B4A),
            fontWeight:
            selected ? FontWeight.w600 : FontWeight.normal,
          )),
      selected: selected,
      onSelected: onSelected,
      selectedColor: const Color(0xFF1A6B4A),
      backgroundColor: const Color(0xFFE8F5EE),
      checkmarkColor: Colors.white,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontWeight:
              active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenJobs() {
    if (_filteredJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined,
                size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              isUrdu
                  ? "کوئی کام نہیں ملا"
                  : "No jobs found",
              style: const TextStyle(color: Colors.grey),
            ),
            if (_selectedSkill != null || _searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSkill = null;
                    _searchQuery = '';
                  });
                  _applyFilters();
                },
                child: Text(
                  isUrdu ? "فلٹر ہٹائیں" : "Clear filters",
                  style:
                  const TextStyle(color: Color(0xFF1A6B4A)),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _filteredJobs.length,
      itemBuilder: (context, index) {
        final job = _filteredJobs[index];
        final jobId = job['id'] as int;
        final applied = _hasApplied(jobId);
        final status = _applicationStatus(jobId);
        final customerId = job['customer_id'] as int? ?? 0;

        return GestureDetector(
          onTap: () => _showJobDetails(job),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          job['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                              ? "${job['budget']} روپے"
                              : "PKR ${job['budget']}",
                          style: const TextStyle(
                            color: Color(0xFF1A6B4A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.person,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                        job['customerName'] ??
                            (isUrdu ? 'کسٹمر' : 'Customer'),
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(job['location'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ),
                    if (job['distance'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(job['distance'] as double).toStringAsFixed(1)} km',
                          style: TextStyle(
                              fontSize: 10, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ]),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Text(
                        isUrdu
                            ? "تفصیل دیکھنے کے لیے ٹیپ کریں"
                            : "Tap to view details",
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[400]),
                      ),
                      const Spacer(),
                      if (applied) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: status == 'accepted'
                                ? const Color(0xFFE8F5EE)
                                : status == 'rejected'
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: status == 'accepted'
                                  ? const Color(0xFF1A6B4A)
                                  : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (status == 'accepted') ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _openChat(
                              jobId: jobId,
                              jobTitle: job['title'] ?? '',
                              customerId: customerId,
                              customerName: job['customerName'],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A6B4A),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chat,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: () => _applyJob(
                              jobId, job['title'] ?? '', customerId),
                          icon: const Icon(Icons.send, size: 14),
                          label: Text(
                              isUrdu ? "درخواست دیں" : "Apply"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            const Color(0xFF1A6B4A),
                            side: const BorderSide(
                                color: Color(0xFF1A6B4A)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            textStyle:
                            const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyApplications() {
    if (_myApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
                isUrdu
                    ? "آپ نے ابھی تک کسی کام کے لیے درخواست نہیں دی"
                    : "You haven't applied to any jobs yet",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _myApplications.length,
      itemBuilder: (context, index) {
        final app = _myApplications[index];
        final status = app['status'] ?? 'pending';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        app['title'] ?? '',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'accepted'
                            ? const Color(0xFFE8F5EE)
                            : status == 'rejected'
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: status == 'accepted'
                              ? const Color(0xFF1A6B4A)
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                    isUrdu
                        ? "${app['budget']} روپے"
                        : "PKR ${app['budget']}",
                    style: const TextStyle(
                        color: Color(0xFF1A6B4A),
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                      app['customerName'] ??
                          (isUrdu ? 'کسٹمر' : 'Customer'),
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(app['location'] ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ]),
                if (status == 'accepted') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openChat(
                        jobId: app['job_id'] as int,
                        jobTitle: app['title'] ?? '',
                        customerId:
                        app['customer_id'] as int? ?? 0,
                        customerName: app['customerName'],
                      ),
                      icon: const Icon(Icons.chat),
                      label: Text(
                          isUrdu
                              ? "کسٹمر کو پیغام بھیجیں"
                              : "Message Customer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6B4A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}