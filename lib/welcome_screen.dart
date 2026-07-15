import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'language_state.dart';
import 'role_selection_screen.dart';
import 'chat_bubble.dart';
import 'chat_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language') ?? 'English';
    setState(() {
      selectedLanguage = saved;
      isUrdu = saved == 'Urdu';
    });
  }

  Future<void> _saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    isUrdu = language == 'Urdu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ✅ Logo added above the main image
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Image.asset(
                          'assets/images/image1.jpeg',
                          height: 250,
                          fit: BoxFit.contain,
                          cacheWidth: 800,
                          cacheHeight: 800,
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 170,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  isUrdu
                      ? const Text(
                    "لنک لیبر میں خوش آمدید",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                      : RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(text: "Welcome to ",style: TextStyle(color: Colors.black87)),
                        TextSpan(text: "Link", style: TextStyle(color: Colors.green)),
                        TextSpan(text: "Labor", style: TextStyle(color: Colors.black87)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isUrdu
                        ? "اپنی روزمرہ کی ضروریات کے لیے ہنرمند کارکنوں سے جڑیں۔ صحیح شخص جلدی اور آسانی سے تلاش کریں۔"
                        : "Connect with skilled workers for your daily needs. Find the right person for the job, quickly and easily.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isUrdu ? "زبان منتخب کریں" : "Select Language",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedLanguage = 'English');
                              _saveLanguage('English');
                            },
                            child: _buildLanguageButton('English'),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedLanguage = 'Urdu');
                              _saveLanguage('Urdu');
                            },
                            child: _buildLanguageButton('Urdu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) =>
                            const LoginScreen(),
                            transitionDuration:
                            const Duration(milliseconds: 150),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isUrdu ? "شروع کریں" : "Get Started",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ChatBubble(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, _, _) => const ChatScreen(
                    role: "guest",
                    name: "Guest",
                  ),
                  transitionDuration: const Duration(milliseconds: 150),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String language) {
    final bool isSelected = selectedLanguage == language;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
            : [],
      ),
      child: Center(
        child: Text(
          language,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black),
        ),
      ),
    );
  }
}