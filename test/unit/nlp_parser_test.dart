import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/models/parsed_transaction.dart';
import 'package:pawcket/services/api/nlp_parser.dart';
import 'package:pawcket/services/api/openrouter_client.dart';

class MockOpenRouterClient implements OpenRouterClient {
  final String responseToReturn;
  final bool shouldThrow;

  MockOpenRouterClient({required this.responseToReturn, this.shouldThrow = false});

  @override
  Future<String> postCompletion({
    required List<Map<String, String>> messages,
    double temperature = 0.3,
    int maxTokens = 200,
    String? model,
  }) async {
    if (shouldThrow) {
      throw Exception('API Connection Failure');
    }
    return responseToReturn;
  }
}

void main() {
  group('NLPParser Tests', () {
    test('Successful parsing from clean JSON', () async {
      final jsonResponse = '{"category": "food", "amount": 15000, "vendor": "Gado-gado stand", "description": "Makan gado-gado 15k", "date": "2025-01-15", "day": "Wednesday"}';
      final mockClient = MockOpenRouterClient(responseToReturn: jsonResponse);
      final parser = NLPParser(client: mockClient);

      final result = await parser.parseExpenseFromText('Makan gado-gado 15k');

      expect(result.error, isNull);
      expect(result.amount, equals(15000));
      expect(result.category, equals('food'));
      expect(result.vendor, equals('Gado-gado stand'));
    });

    test('Successful parsing from JSON wrapped in markdown backticks', () async {
      final jsonResponse = '```json\n{"category": "transport", "amount": 20000, "vendor": "Gojek", "description": "Ojek 20k", "date": "2025-01-15", "day": "Wednesday"}\n```';
      final mockClient = MockOpenRouterClient(responseToReturn: jsonResponse);
      final parser = NLPParser(client: mockClient);

      final result = await parser.parseExpenseFromText('Ojek 20k');

      expect(result.error, isNull);
      expect(result.amount, equals(20000));
      expect(result.category, equals('transport'));
    });

    test('Handling API throws gracefully', () async {
      final mockClient = MockOpenRouterClient(responseToReturn: '', shouldThrow: true);
      final parser = NLPParser(client: mockClient);

      final result = await parser.parseExpenseFromText('Makan gado-gado 15k');

      expect(result.error, contains('API Connection Failure'));
      expect(result.amount, equals(0));
      expect(result.category, equals('other'));
    });

    test('Handling unparseable JSON error', () async {
      final jsonResponse = 'Invalid JSON String';
      final mockClient = MockOpenRouterClient(responseToReturn: jsonResponse);
      final parser = NLPParser(client: mockClient);

      final result = await parser.parseExpenseFromText('Makan gado-gado 15k');

      expect(result.error, isNotNull);
      expect(result.amount, equals(0));
      expect(result.category, equals('other'));
    });
  });
}
