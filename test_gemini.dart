import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/openai/chat/completions');
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer YOUR_API_KEY_HERE',
    },
    body: jsonEncode({
      'model': 'gemini-2.0-flash',
      'messages': [{'role': 'user', 'content': 'Hello, test!'}],
    })
  );
  print(response.statusCode);
  print(response.body);
}
