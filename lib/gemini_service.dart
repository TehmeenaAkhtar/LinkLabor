import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = "AIzaSyDt4yySxy2qEC1JCrGH3zgnnG47l3x2G1s";

  static const _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey";
  static const _serverUrl = "http://192.168.10.2:3000";

  static List<Map<String, dynamic>> _history = [];
  static String _currentRole = "guest";
  static String _currentName = "Guest";

  static void initSession({required String role, required String name}) {
    _currentRole = role;
    _currentName = name;
    _history = [];
  }

  static void clearHistory() => _history = [];

  // ── Detect skill ──
  static String? _extractSkill(String message) {
    final msg = message.toLowerCase();
    final skills = {
      'electrician': 'electrician',
      'electric': 'electrician',
      'bijli': 'electrician',
      'plumber': 'plumber',
      'plumbing': 'plumber',
      'paani': 'plumber',
      'carpenter': 'carpenter',
      'wood': 'carpenter',
      'lakri': 'carpenter',
      'painter': 'painter',
      'paint': 'painter',
      'rang': 'painter',
      'ac technician': 'ac technician',
      'ac': 'ac technician',
      'air condition': 'ac technician',
      'mechanic': 'mechanic',
      'welder': 'welder',
      'mason': 'mason',
      'cleaner': 'cleaner',
      'driver': 'driver',
      'cook': 'cook',
      'gardener': 'gardener',
    };
    for (final entry in skills.entries) {
      if (msg.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static bool _isAskingForWorker(String message) {
    final msg = message.toLowerCase();
    return msg.contains('need') || msg.contains('chahiye') ||
        msg.contains('find') || msg.contains('dhundo') ||
        msg.contains('want') || msg.contains('hire') ||
        msg.contains('book') || msg.contains('available') ||
        msg.contains('worker') || msg.contains('karigar') ||
        msg.contains('technician') || msg.contains('who can') ||
        msg.contains('looking') || msg.contains('send');
  }

  static bool _isAskingForJobs(String message) {
    final msg = message.toLowerCase();
    return msg.contains('job') || msg.contains('kaam') ||
        msg.contains('work') || msg.contains('open') ||
        msg.contains('available job') || msg.contains('any job') ||
        msg.contains('show job') || msg.contains('near') ||
        msg.contains('earning') || msg.contains('apply');
  }

  static bool _isAskingAboutRating(String message) {
    final msg = message.toLowerCase();
    return msg.contains('rating') || msg.contains('review') ||
        msg.contains('star') || msg.contains('feedback') ||
        msg.contains('rate');
  }

  static bool _isAskingAboutEarnings(String message) {
    final msg = message.toLowerCase();
    return msg.contains('earn') || msg.contains('income') ||
        msg.contains('money') || msg.contains('payment') ||
        msg.contains('paise') || msg.contains('wages') ||
        msg.contains('salary') || msg.contains('kamai');
  }

  // ── Fetch workers ──
  static Future<List<Map<String, dynamic>>> _fetchWorkers({
    String? skill,
    String? city,
  }) async {
    try {
      String url = "$_serverUrl/api/workers/search?";
      if (skill != null) url += "skill=${Uri.encodeComponent(skill)}&";
      if (city != null) url += "city=${Uri.encodeComponent(city)}";
      final response =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Worker fetch error: $e");
    }
    return [];
  }

  // ── Fetch open jobs ──
  static Future<List<Map<String, dynamic>>> _fetchOpenJobs() async {
    try {
      final response = await http
          .get(Uri.parse("$_serverUrl/api/jobs/open"))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Jobs fetch error: $e");
    }
    return [];
  }

  // ── Format workers ──
  static String _formatWorkers(
      List<Map<String, dynamic>> workers, String skill) {
    if (workers.isEmpty) {
      return "No workers found for '$skill' in the database right now. "
          "Tell the user no verified workers are available for this skill currently "
          "and suggest they check back later or try a different skill.";
    }

    final buffer = StringBuffer();
    buffer.writeln("=== LIVE WORKER DATA FROM DATABASE ===");
    buffer.writeln("Found ${workers.length} worker(s) for skill: $skill");
    buffer.writeln();

    for (int i = 0; i < workers.length; i++) {
      final w = workers[i];
      buffer.writeln("WORKER ${i + 1}:");
      buffer.writeln("  Name: ${w['fullName'] ?? 'N/A'}");
      buffer.writeln("  Skill: ${w['skill'] ?? 'N/A'}");
      buffer.writeln("  City: ${w['city'] ?? 'N/A'}");
      buffer.writeln("  Phone: ${w['phone'] ?? 'N/A'}");
      buffer.writeln("  Available Hours: ${w['availableHours'] ?? 'N/A'}");
      if (w['avg_rating'] != null && w['avg_rating'] != 0) {
        buffer.writeln(
            "  Rating: ${w['avg_rating']} ⭐ (${w['total_ratings']} reviews)");
      }
      if (w['about'] != null && w['about'].toString().isNotEmpty) {
        buffer.writeln("  About: ${w['about']}");
      }
      buffer.writeln();
    }
    buffer.writeln("=== END OF WORKER DATA ===");
    return buffer.toString();
  }

  // ── Format jobs ──
  static String _formatJobs(List<Map<String, dynamic>> jobs) {
    if (jobs.isEmpty) {
      return "No open jobs found in the database right now. "
          "Tell the worker to check back later or set up job alerts.";
    }

    final buffer = StringBuffer();
    buffer.writeln("=== LIVE OPEN JOBS FROM DATABASE ===");
    buffer.writeln("Found ${jobs.length} open job(s):");
    buffer.writeln();

    for (int i = 0; i < jobs.length; i++) {
      final j = jobs[i];
      buffer.writeln("JOB ${i + 1}:");
      buffer.writeln("  Title: ${j['title'] ?? 'N/A'}");
      buffer.writeln("  Description: ${j['description'] ?? 'N/A'}");
      buffer.writeln("  Budget: PKR ${j['budget'] ?? 'N/A'}");
      buffer.writeln("  Location: ${j['location'] ?? 'N/A'}");
      buffer.writeln("  Posted by: ${j['customerName'] ?? 'N/A'}");
      buffer.writeln("  Customer Phone: ${j['customerPhone'] ?? 'N/A'}");
      buffer.writeln();
    }
    buffer.writeln("=== END OF JOBS DATA ===");
    return buffer.toString();
  }

  // ── System prompts ──
  static String _buildSystemPrompt() {
    if (_currentRole == "worker") {
      return """
You are LinkLabour AI Assistant — a helpful assistant for WORKER named "$_currentName" in Pakistan.

YOUR JOB:
- Help workers find jobs, apply for work, understand their earnings
- Give advice on improving their profile and getting more jobs
- Answer questions about the app features
- Respond in the SAME language the user writes in (Urdu or English)

WHEN YOU SEE "LIVE OPEN JOBS FROM DATABASE":
- Show EXACT job details: title, budget, location, customer name, phone
- Format each job clearly with bullet points or numbered list
- Tell worker how to apply — go to Jobs tab → tap the job → tap Apply
- Highlight the best matching jobs for the worker

WHEN YOU SEE "No open jobs found":
- Be encouraging, say market is currently slow
- Suggest tips to get more jobs (complete profile, add photo, get verified)

OTHER HELPFUL TIPS TO GIVE:
- Complete your profile with photo and documents to get verified
- Verified workers get 3x more job requests
- Respond quickly to customer messages to build good reputation
- After completing jobs, encourage customers to rate you

RULES:
- Keep replies SHORT (max 5-6 lines) unless showing job list
- Be friendly and encouraging
- Never say "I cannot help" — always give useful advice
- If asked about app features, explain clearly
""";
    } else if (_currentRole == "customer") {
      return """
You are LinkLabour AI Assistant — a helpful assistant for CUSTOMER named "$_currentName" in Pakistan.

YOUR JOB:
- Help customers find the right worker for their needs
- Give information about worker availability, pricing, verification
- Help customers post jobs and manage applications
- Respond in the SAME language the user writes in (Urdu or English)

WHEN YOU SEE "LIVE WORKER DATA FROM DATABASE":
- Show EACH worker with this EXACT format:
  👷 [Name] — [Skill]
  📍 City: [City]
  🕐 Available: [Hours]
  📞 Phone: [Phone Number]
  ⭐ Rating: [Rating] (if available)
- Tell customer they can contact directly by phone OR post a job in the app
- Recommend the highest rated worker first

WHEN YOU SEE "No workers found":
- Be helpful, suggest posting a job so workers can apply
- Suggest trying a different skill name

PRICING GUIDANCE (approximate rates in Pakistan):
- Electrician: PKR 500-2000 per visit
- Plumber: PKR 500-1500 per visit  
- Carpenter: PKR 800-3000 per day
- Painter: PKR 1000-2500 per day
- AC Technician: PKR 500-2000 per service

HOW TO POST A JOB:
- Go to Home tab → tap blue "Post a Job" button
- Fill title, location, budget, description
- Workers will apply and you can accept/reject

RULES:
- Keep replies SHORT unless showing worker list
- Be professional and helpful
- Reassure customers about worker safety — all workers are verified with CNIC
- Respond in same language as user (Urdu or English)
""";
    } else {
      return """
You are LinkLabour AI Assistant for a guest visitor in Pakistan.

LinkLabour is a platform that connects:
- Customers who need skilled workers (electricians, plumbers, carpenters, painters, AC technicians, etc.)
- Workers who want to find jobs and earn money

WHAT YOU CAN HELP WITH:
- Explain how the app works
- Show available workers if asked
- Show open jobs if asked  
- Help them decide whether to register as Worker or Customer

WHEN YOU SEE LIVE DATA:
- Use it to show real workers or jobs
- This shows the app is real and active

HOW TO REGISTER:
- Tap "Get Started" → choose Worker or Customer
- Workers: fill profile, upload CNIC and documents
- Customers: fill basic info, start posting jobs immediately

RULES:
- Be welcoming and helpful
- Keep responses short and clear
- Encourage them to register
- Respond in same language as user (Urdu or English)
""";
    }
  }

  // ── Main send message ──
  static Future<String> sendMessage(String userMessage) async {
    String liveData = "";

    final detectedSkill = _extractSkill(userMessage);
    final wantsWorker = _isAskingForWorker(userMessage);
    final wantsJobs = _isAskingForJobs(userMessage);

    // Fetch relevant live data
    if ((wantsWorker || detectedSkill != null) &&
        (_currentRole == "customer" || _currentRole == "guest")) {
      final workers = await _fetchWorkers(skill: detectedSkill);
      liveData = _formatWorkers(workers, detectedSkill ?? "any");
    } else if (wantsJobs && _currentRole == "worker") {
      final jobs = await _fetchOpenJobs();
      liveData = _formatJobs(jobs);
    } else if (detectedSkill != null && _currentRole == "worker") {
      // Worker asking about a skill type — show matching jobs
      final jobs = await _fetchOpenJobs();
      final filtered = jobs
          .where((j) =>
      (j['title'] ?? '')
          .toLowerCase()
          .contains(detectedSkill.toLowerCase()) ||
          (j['description'] ?? '')
              .toLowerCase()
              .contains(detectedSkill.toLowerCase()))
          .toList();
      liveData = _formatJobs(filtered.isNotEmpty ? filtered : jobs);
    }

    final enrichedMessage = liveData.isNotEmpty
        ? "$userMessage\n\n[REAL-TIME DATA FROM LINKLABOUR DATABASE — USE THIS TO ANSWER]:\n$liveData"
        : userMessage;

    _history.add({
      "role": "user",
      "parts": [
        {"text": enrichedMessage}
      ]
    });

    // Keep history to last 10 messages to avoid token limit
    if (_history.length > 20) {
      _history = _history.sublist(_history.length - 20);
    }

    final requestBody = {
      "system_instruction": {
        "parts": [
          {"text": _buildSystemPrompt()}
        ]
      },
      "contents": _history,
      "generationConfig": {
        "temperature": 0.3,
        "maxOutputTokens": 1024,
        "topP": 0.8,
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print("Gemini Error ${response.statusCode}: ${response.body}");
        return "Sorry, something went wrong. Please try again.";
      }

      final data = jsonDecode(response.body);
      final botText =
      data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      if (botText is String) {
        _history.add({
          "role": "model",
          "parts": [
            {"text": botText}
          ]
        });
        return botText;
      }

      return "No response received. Please try again.";
    } catch (e) {
      print("Gemini error: $e");
      return "Network error. Please check your connection.";
    }
  }
}