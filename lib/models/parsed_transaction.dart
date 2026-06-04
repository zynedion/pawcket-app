class ParsedTransaction {
  final String category;              // e.g., 'food' or 'salary'
  final int amount;                   // e.g., 15000 IDR
  final String? vendor;               // e.g., 'gado-gado stand' (nullable)
  final String description;           // Raw user input
  final DateTime transactionDate;     // When transaction occurred
  final String transactionType;       // 'expense' or 'income'
  final String? error;                // If parsing failed
  
  const ParsedTransaction({
    required this.category,
    required this.amount,
    this.vendor,
    required this.description,
    required this.transactionDate,
    this.transactionType = 'expense',
    this.error,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error') && json['error'] != null) {
      return ParsedTransaction(
        category: 'other',
        amount: 0,
        description: json['description'] ?? '',
        transactionDate: DateTime.now(),
        transactionType: 'expense',
        error: json['error'] as String?,
      );
    }

    DateTime parsedDate;
    try {
      if (json['date'] != null) {
        parsedDate = DateTime.parse(json['date'] as String);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // Clean dynamic inputs from LLM to ensure type safety
    final amountVal = json['amount'];
    int parsedAmount = 0;
    if (amountVal is num) {
      parsedAmount = amountVal.toInt();
    } else if (amountVal is String) {
      parsedAmount = int.tryParse(amountVal) ?? 0;
    }

    return ParsedTransaction(
      category: (json['category'] as String? ?? 'other').toLowerCase(),
      amount: parsedAmount,
      vendor: json['vendor'] as String?,
      description: json['description'] as String? ?? '',
      transactionDate: parsedDate,
      transactionType: (json['transaction_type'] as String? ?? 'expense').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'vendor': vendor,
      'description': description,
      'date': transactionDate.toIso8601String().split('T')[0],
      'transaction_type': transactionType,
      'error': error,
    };
  }
}
