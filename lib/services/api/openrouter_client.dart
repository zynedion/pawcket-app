import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterClient {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  String get _model => dotenv.env['OPENROUTER_MODEL'] ?? 'openai/gpt-oss-120b';

  static const List<String> _fallbackModels = [
    'openai/gpt-oss-120b',
    'google/gemma-4-26b-a4b-it:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'qwen/qwen3-coder:free',
  ];

  Future<String> postCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.3,
    int maxTokens = 200,
    String? model,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenRouter API key is missing. Please check your .env file.');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/zynedion/pawcket-app',
      'X-Title': 'Pawcket App',
    };

    final primaryModel = model ?? _model;

    // Build list of models to try, starting with the primary model
    final List<String> modelsToTry = [primaryModel];
    for (final fallback in _fallbackModels) {
      if (fallback != primaryModel) {
        modelsToTry.add(fallback);
      }
    }

    dynamic lastError;

    for (final currentModel in modelsToTry) {
      final body = jsonEncode({
        'model': currentModel,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: headers,
          body: body,
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded['choices'] != null && decoded['choices'].isNotEmpty) {
            return decoded['choices'][0]['message']['content'] as String;
          }
          throw Exception('Invalid response format from OpenRouter');
        } else {
          final errorMsg = _parseError(response.body);
          lastError = 'OpenRouter API Error (${response.statusCode}) with model $currentModel: $errorMsg';
          print('OpenRouter client warning: $lastError. Trying next fallback...');
        }
      } catch (e) {
        lastError = 'Failed to communicate with OpenRouter API using model $currentModel: $e';
        print('OpenRouter client warning: $lastError. Trying next fallback...');
      }
    }

    throw Exception('All models failed. Last error: $lastError');
  }

  String _parseError(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      if (json['error'] != null) {
        if (json['error'] is Map) {
          return json['error']['message'] ?? 'Unknown error';
        }
        return json['error'].toString();
      }
    } catch (_) {}
    return 'Server returned an error';
  }
}
