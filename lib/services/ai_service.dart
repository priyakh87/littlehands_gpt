
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Simple client for interacting with OpenAI's Chat Completion API.
///
/// The API key must be provided via an `.env` file with the key
/// `OPENAI_API_KEY`. All requests specify a short system prompt that
/// instructs the model to produce safe, child‑friendly responses. If
/// the key is missing or an error occurs, the service falls back to
/// returning a static message.
class AiService {
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Sends a single‑prompt chat completion request and returns the
  /// assistant's reply. The [prompt] should be concise and suited to
  /// generating a response appropriate for toddlers.
  static Future<String> sendMessage(String prompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('OpenAI API key missing or empty.');
      return 'I\'m sorry, I don\'t have access to my brain right now.';
    }
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a friendly and educational assistant for toddlers. Respond in a short, simple and engaging manner suitable for children aged 2–5. Never include adult or unsafe content.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 100,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final message = json['choices'][0]['message']['content'] as String?;
        return message?.trim() ?? '';
      } else {
        debugPrint('OpenAI API error: Status ${response.statusCode}, Body: ${response.body}');
        return 'Oops! Something went wrong with the AI.';
      }
    } catch (e) {
      debugPrint('OpenAI API exception: $e');
      return 'I\'m having trouble thinking right now.';
    }
  }
}