import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey =
      'e882dfabbbc84db692d570bc4bfa1fe9.ODOjIQBmkIatsGKb';
  static const String _baseUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful assistant in a jewelry sharing community app. Please respond in English only.',
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        } else {
          return 'Sorry, I couldn\'t process your message right now.';
        }
      } else {
        print('API Error: ${response.statusCode}, ${response.body}');
        return 'Sorry, there was an error connecting to the AI service.';
      }
    } catch (e) {
      print('Error sending message: $e');
      return 'Sorry, I\'m having trouble responding right now. Please try again later.';
    }
  }

  static Future<String> getJewelryExpertResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'glm-4-flash',
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are an expert AI Jewelry Consultant with extensive knowledge in:
- Gemstone identification and properties
- Jewelry design and craftsmanship
- Diamond grading and certification
- Precious metals and alloys
- Jewelry care and maintenance
- Market values and appraisal
- Fashion trends and styling advice
- Historical and cultural significance
- Ethical sourcing and sustainability

Please provide professional, accurate, and helpful advice about jewelry-related questions. Always respond in English and be detailed yet easy to understand.''',
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        } else {
          return 'Sorry, I couldn\'t process your jewelry question right now.';
        }
      } else {
        print('API Error: ${response.statusCode}, ${response.body}');
        return 'Sorry, there was an error connecting to the jewelry expert service.';
      }
    } catch (e) {
      print('Error getting jewelry expert response: $e');
      return 'Sorry, I\'m having trouble responding right now. Please try again later.';
    }
  }
}
