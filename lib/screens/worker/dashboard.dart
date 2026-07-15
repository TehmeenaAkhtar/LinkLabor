import 'package:flutter/material.dart';
import 'package:linklabor/screens/worker/profile/profile_screen.dart';
import 'package:linklabor/screens/worker/jobs/jobs_screen.dart';
import 'package:linklabor/screens/worker/wages/wages_screen.dart';
import 'package:linklabor/screens/worker/chats/chats_screen.dart';
import 'package:linklabor/screens/widgets/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class WorkerDashboard extends StatefulWidget {
  final int workerId;
  const WorkerDashboard({super.key, required this.workerId});

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  late final List<Widget> _screens;
  Timer? _unreadTimer;
  static const String _baseUrl = "http://192.168.10.2:3000";

  @override
  void initState() {
    super.initState();
    _screens = [
      WorkerProfile(workerId: widget.workerId),
      WorkerJobsScreen(workerId: widget.workerId),
      WorkerWagesScreen(workerId: widget.workerId),
      WorkerChatsScreen(workerId: widget.workerId),
    ];
    _fetchUnreadCount();
    // Check for new messages every 5 seconds
    _unreadTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _fetchUnreadCount(),
    );
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final r = await http.get(Uri.parse(
          '$_baseUrl/api/worker/${widget.workerId}/conversations'));
      if (r.statusCode == 200 && mounted) {
        final convs = jsonDecode(r.body) as List;
        int total = convs.fold(
            0, (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0));
        setState(() => _unreadCount = total);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: WorkerBottomNavBar(
        currentIndex: _currentIndex,
        unreadCount: _unreadCount,
        onTabChange: (index) {
          setState(() => _currentIndex = index);
          if (index == 3) {
            // Cleared when entering chats
            setState(() => _unreadCount = 0);
          }
        },
      ),
    );
  }
}