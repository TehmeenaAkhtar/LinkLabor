import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../screens/chat_screen.dart';
import '../../../language_state.dart';

class CustomerChatsScreen extends StatefulWidget {
  final int customerId;
  const CustomerChatsScreen({super.key, required this.customerId});

  @override
  State<CustomerChatsScreen> createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends State<CustomerChatsScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  static const String _baseUrl = "http://192.168.10.2:3000";

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final r = await http.get(Uri.parse(
          '$_baseUrl/api/customer/${widget.customerId}/conversations'));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _conversations = jsonDecode(r.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? "بات چیت" : "Chats"),
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? Center(
        child: Text(
          isUrdu
              ? "ابھی تک کوئی بات چیت نہیں ہے۔\nدرخواست دینے کے بعد کارکن آپ کو پیغام بھیجیں گے!"
              : "No chats yet.\nWorkers will message you after applying!",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchConversations,
        child: ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final conv = _conversations[index];
            final unread =
                (conv['unreadCount'] as int?) ?? 0;

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobChatScreen(
                      jobId: conv['job_id'] as int,
                      jobTitle: conv['jobTitle'] ?? '',
                      workerId: conv['workerId'] as int,
                      customerId: widget.customerId,
                      senderType: 'customer',
                      otherPersonName:
                      conv['workerName'] ?? (isUrdu ? 'کارکن' : 'Worker'),
                    ),
                  ),
                ).then((_) => _fetchConversations());
              },
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1565C0),
                child: Text(
                  (conv['workerName'] ?? 'W')[0]
                      .toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                conv['workerName'] ?? (isUrdu ? 'کارکن' : 'Worker'),
                style: TextStyle(
                  fontWeight: unread > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv['jobTitle'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1A6B4A)),
                  ),
                  Text(
                    conv['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: unread > 0
                          ? Colors.black87
                          : Colors.grey,
                      fontWeight: unread > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              trailing: unread > 0
                  ? Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A6B4A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              )
                  : Text(
                _formatTime(conv['lastTime']),
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}