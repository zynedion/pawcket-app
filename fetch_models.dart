import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://openrouter.ai/api/v1/models');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final models = json['data'] as List;
      for (final model in models) {
        final id = model['id'] as String;
        if (id.contains('tencent/')) {
          final pricing = model['pricing'];
          print('- $id');
          if (pricing != null) {
            print('  Prompt: ${pricing['prompt']}');
            print('  Completion: ${pricing['completion']}');
          }
        }
      }
    } else {
      print('Failed to load models: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
