import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../language_state.dart';
import 'rating_screen.dart';

class JobChatScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  final int workerId;
  final int customerId;
  final String senderType;
  final String otherPersonName;

  const JobChatScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.workerId,
    required this.customerId,
    required this.senderType,
    required this.otherPersonName,
  });

  @override
  State<JobChatScreen> createState() => _JobChatScreenState();
}

class _JobChatScreenState extends State<JobChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isCompleted = false;
  bool _hasRated = false;
  Timer? _timer;

  static const String _baseUrl = "http://192.168.10.2:3000";

  int get _myId => widget.senderType == 'worker'
      ? widget.workerId
      : widget.customerId;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _fetchJobStatus();
    _markAsRead();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        _fetchMessages(silent: true);
        _fetchJobStatus(silent: true);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobStatus({bool silent = false}) async {
    try {
      final r = await http.get(
          Uri.parse('$_baseUrl/api/jobs/${widget.jobId}/status'));
      if (r.statusCode == 200 && mounted) {
        final data = jsonDecode(r.body);
        final completed = data['status'] == 'completed';

        // Check if already rated
        if (completed) {
          final ratingCheck = await http.get(Uri.parse(
            '$_baseUrl/api/ratings/check?job_id=${widget.jobId}&rated_by=${widget.senderType}&rater_id=$_myId',
          ));
          if (ratingCheck.statusCode == 200 && mounted) {
            final ratingData = jsonDecode(ratingCheck.body);
            setState(() {
              _isCompleted = completed;
              _hasRated = ratingData['hasRated'] ?? false;
            });
          }
        } else {
          if (mounted) setState(() => _isCompleted = completed);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    try {
      final r = await http.get(Uri.parse(
        '$_baseUrl/api/messages/${widget.jobId}/${widget.workerId}/${widget.customerId}',
      ));
      if (r.statusCode == 200 && mounted) {
        setState(() {
          _messages = jsonDecode(r.body);
          if (!silent) _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!silent && mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/api/messages/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'job_id': widget.jobId, 'receiver_id': _myId}),
      );
    } catch (_) {}
  }

  Future<void> _markJobComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isUrdu ? "کام مکمل؟" : "Mark as Complete?"),
        content: Text(
          isUrdu
              ? "کیا آپ واقعی یہ کام مکمل کرنا چاہتے ہیں؟"
              : "Are you sure you want to mark this job as completed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isUrdu ? "نہیں" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6B4A)),
            child: Text(
              isUrdu ? "ہاں، مکمل کریں" : "Yes, Complete",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final r = await http.put(
        Uri.parse('$_baseUrl/api/jobs/${widget.jobId}/complete'),
        headers: {'Content-Type': 'application/json'},
      );

      if (r.statusCode == 200 && mounted) {
        setState(() => _isCompleted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu ? "کام مکمل ہو گیا!" : "Job marked as completed!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Open rating screen
        _openRatingScreen();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _openRatingScreen() {
    final ratedId = widget.senderType == 'worker'
        ? widget.customerId
        : widget.workerId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RatingScreen(
          jobId: widget.jobId,
          jobTitle: widget.jobTitle,
          raterId: _myId,
          ratedId: ratedId,
          ratedBy: widget.senderType,
          ratedName: widget.otherPersonName,
        ),
      ),
    ).then((rated) {
      if (rated == true) setState(() => _hasRated = true);
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    final receiverId = widget.senderType == 'worker'
        ? widget.customerId
        : widget.workerId;

    setState(() {
      _messages.add({
        'sender_type': widget.senderType,
        'sender_id': _myId,
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': 0,
      });
    });
    _scrollToBottom();

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_id': widget.jobId,
          'sender_type': widget.senderType,
          'sender_id': _myId,
          'receiver_id': receiverId,
          'message': text,
        }),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send message")),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isMyMessage(dynamic msg) {
    return msg['sender_type'] == widget.senderType &&
        msg['sender_id'].toString() == _myId.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A6B4A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPersonName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.jobTitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Only customer can mark complete, or worker if assigned
          if (!_isCompleted)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: isUrdu ? "کام مکمل کریں" : "Mark Complete",
              onPressed: _markJobComplete,
            ),
          if (_isCompleted && !_hasRated)
            IconButton(
              icon: const Icon(Icons.star_outline, color: Colors.amber),
              tooltip: isUrdu ? "ریٹنگ دیں" : "Rate",
              onPressed: _openRatingScreen,
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Job completed banner ──
          if (_isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: const Color(0xFFE8F5EE),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF1A6B4A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUrdu
                          ? "یہ کام مکمل ہو چکا ہے"
                          : "This job has been completed",
                      style: const TextStyle(
                        color: Color(0xFF1A6B4A),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (!_hasRated)
                    TextButton(
                      onPressed: _openRatingScreen,
                      child: Text(
                        isUrdu ? "ریٹنگ دیں" : "Rate now",
                        style: const TextStyle(
                          color: Color(0xFF1A6B4A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (_hasRated)
                    const Text(
                      "⭐ Rated",
                      style: TextStyle(
                        color: Color(0xFF1A6B4A),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    isUrdu
                        ? "ابھی تک کوئی پیغام نہیں\nہیلو کہیں! 👋"
                        : "No messages yet\nSay hello! 👋",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 15),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = _isMyMessage(msg);
                return _buildBubble(msg, isMe);
              },
            ),
          ),

          // Hide input if job is completed
          if (!_isCompleted) _buildInputBar(),

          if (_isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Text(
                isUrdu
                    ? "کام مکمل ہو گیا — مزید پیغامات نہیں بھیجے جا سکتے"
                    : "Job completed — messaging is now closed",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF1A6B4A),
              child: Text(
                widget.otherPersonName.isNotEmpty
                    ? widget.otherPersonName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          if (!isMe) const SizedBox(width: 6),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:
                isMe ? const Color(0xFF1A6B4A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg['message'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(msg['created_at']),
                    style: TextStyle(
                      color: isMe ? Colors.white60 : Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 6),
          if (isMe)
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person,
                  size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText:
                isUrdu ? "پیغام لکھیں..." : "Type a message...",
                hintStyle: TextStyle(
                    color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF4F7F5),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                      color: Color(0xFF1A6B4A), width: 1.5),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B4A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
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