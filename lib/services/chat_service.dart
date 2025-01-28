import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String apiUrl = "https://api.openai.com/v1/chat/completions";

  // Fetch API Key from environment variables
  static Future<String> askChatGptWithPdf(String pdfContent, String userQuery) async {
    final apiKey = dotenv.env['OPENAI_CHATGPT_TOKEN'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("OpenAI API key is not configured.");
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {"role": "system", "content": "You are a helpful assistant."},
          {"role": "user", "content": "Here is the PDF content: $pdfContent"},
          {"role": "user", "content": userQuery},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to fetch response: ${response.body}');
    }
  }
}