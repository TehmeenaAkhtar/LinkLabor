import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static Future<String> translateToUrdu(String text) async {
    final response = await http.post(
      Uri.parse('https://libretranslate.com/translate'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "q": text,
        "source": "en",
        "target": "ur",
        "format": "text",
        "api_key": "YOUR_API_KEY"
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['translatedText'];
    } else {
      throw Exception('Translation failed');
    }
  }
}