import 'dart:convert';
import 'package:pawcket/models/parsed_transaction.dart';
import 'package:pawcket/services/api/openrouter_client.dart';

class NLPParser {
  final OpenRouterClient _client;

  NLPParser({OpenRouterClient? client}) : _client = client ?? OpenRouterClient();

  Future<ParsedTransaction> parseExpenseFromText(String rawInput) async {
    if (rawInput.trim().isEmpty) {
      throw Exception('Input text cannot be empty');
    }

    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];
    
    final systemPrompt = '''
You are a transaction parser. User input is in Indonesian or English. Parse it strictly into JSON format:
{
  "category": "one of: food, transport, entertainment, utilities, healthcare, shopping, housing, other",
  "amount": <positive integer in IDR>,
  "vendor": "<vendor name or empty string>",
  "description": "<raw user input>",
  "date": "YYYY-MM-DD",
  "day": "<Monday, Tuesday, etc>"
}
If parsing is impossible or no amount/price is specified, return {"error": "Could not find a valid expense amount or category."}.
Today's date is $todayStr.
Never return markdown, backticks (```json), or any explanations. Return only the raw JSON.
''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': rawInput},
    ];

    try {
      final responseText = await _client.postCompletion(
        messages: messages,
        temperature: 0.1,
        maxTokens: 150,
      );

      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
      }

      final Map<String, dynamic> jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
      
      if (!jsonMap.containsKey('description') || jsonMap['description'] == null || jsonMap['description'].toString().isEmpty) {
        jsonMap['description'] = rawInput;
      }
      
      return ParsedTransaction.fromJson(jsonMap);
    } catch (e) {
      return ParsedTransaction(
        category: 'other',
        amount: 0,
        description: rawInput,
        transactionDate: DateTime.now(),
        error: e.toString(),
      );
    }
  }
}
