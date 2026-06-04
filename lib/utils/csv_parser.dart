import 'package:csv/csv.dart';

class ParsedCsvRow {
  final DateTime? date;
  final String rawDate;
  final String category;
  final String transactionType; // 'expense' or 'income'
  final int amount;
  final String rawAmount;
  final String description;
  final String? vendor;
  final String? warning;

  ParsedCsvRow({
    this.date,
    required this.rawDate,
    required this.category,
    required this.transactionType,
    required this.amount,
    required this.rawAmount,
    required this.description,
    this.vendor,
    this.warning,
  });

  ParsedCsvRow copyWith({
    DateTime? date,
    String? rawDate,
    String? category,
    String? transactionType,
    int? amount,
    String? rawAmount,
    String? description,
    String? vendor,
    String? warning,
  }) {
    return ParsedCsvRow(
      date: date ?? this.date,
      rawDate: rawDate ?? this.rawDate,
      category: category ?? this.category,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      rawAmount: rawAmount ?? this.rawAmount,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      warning: warning ?? this.warning,
    );
  }
}

class CsvParser {
  /// Detects whether the delimiter in the CSV content is a comma, semicolon, or tab.
  static String detectDelimiter(String content) {
    if (content.isEmpty) return ',';
    final lines = content.split('\n');
    if (lines.isEmpty) return ',';
    final firstLine = lines.first;
    
    int commaCount = 0;
    int semicolonCount = 0;
    int tabCount = 0;
    
    for (int i = 0; i < firstLine.length; i++) {
      final char = firstLine[i];
      if (char == ',') commaCount++;
      else if (char == ';') semicolonCount++;
      else if (char == '\t') tabCount++;
    }
    
    if (semicolonCount > commaCount && semicolonCount > tabCount) return ';';
    if (tabCount > commaCount && tabCount > semicolonCount) return '\t';
    return ',';
  }

  /// Parses the CSV string into a 2D list of Strings.
  static List<List<String>> parseToRows(String csvString) {
    if (csvString.trim().isEmpty) return [];
    final delimiter = detectDelimiter(csvString);
    // Normalize all line endings to \n
    final normalizedCsv = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final converter = CsvToListConverter(
      fieldDelimiter: delimiter,
      shouldParseNumbers: false,
      eol: '\n',
    );
    final list = converter.convert(normalizedCsv);
    return list.map((row) => row.map((cell) => cell.toString().trim()).toList()).toList();
  }

  /// Auto-detect column headers.
  /// Returns a map of field names ('date', 'category', 'description', 'income_amount', 'expense_amount', 'amount', 'type') to their column indices.
  static Map<String, int> autoDetectHeaders(List<String> headers) {
    final Map<String, int> mapping = {};
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase();
      
      // Date detection
      if (header.contains('tgl') || header.contains('tanggal') || header.contains('date') || header.contains('waktu')) {
        mapping['date'] = i;
      }
      // Category detection
      else if (header.contains('kategori') || header.contains('category') || header.contains('jenis')) {
        mapping['category'] = i;
      }
      // Description detection
      else if (header.contains('keterangan') || header.contains('deskripsi') || header.contains('description') || header.contains('catatan') || header.contains('note')) {
        mapping['description'] = i;
      }
      // Vendor/Merchant detection
      else if (header.contains('vendor') || header.contains('toko') || header.contains('merchant') || header.contains('penerima') || header.contains('payee')) {
        mapping['vendor'] = i;
      }
      // Income column detection
      else if (header.contains('pemasukan') || header.contains('income') || header.contains('kredit') || header.contains('masuk')) {
        mapping['income_amount'] = i;
      }
      // Expense column detection
      else if (header.contains('pengeluaran') || header.contains('expense') || header.contains('debit') || header.contains('keluar')) {
        mapping['expense_amount'] = i;
      }
      // General Amount detection
      else if (header.contains('jumlah') || header.contains('nominal') || header.contains('amount') || header.contains('nilai') || header.contains('total') || header.contains('harga')) {
        if (!mapping.containsKey('amount')) {
          mapping['amount'] = i;
        }
      }
      // Transaction Type column detection
      else if (header.contains('tipe') || header.contains('type') || header.contains('jenis transaksi') || header.contains('status')) {
        mapping['type'] = i;
      }
    }
    
    return mapping;
  }

  /// Parses date string with multiple formats:
  /// YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY, YYYY/MM/DD, etc.
  static DateTime? parseDate(String dateStr) {
    final clean = dateStr.trim();
    if (clean.isEmpty) return null;

    // Try standard DateTime parse first
    final stdParse = DateTime.tryParse(clean);
    if (stdParse != null) return stdParse;

    // Try regex for DD/MM/YYYY or DD-MM-YYYY
    final matchDMY = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(clean);
    if (matchDMY != null) {
      final day = int.parse(matchDMY.group(1)!);
      final month = int.parse(matchDMY.group(2)!);
      final year = int.parse(matchDMY.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // Try regex for DD/MM/YY or DD-MM-YY (e.g. 12/05/26)
    final matchDMYShort = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{2})$').firstMatch(clean);
    if (matchDMYShort != null) {
      final day = int.parse(matchDMYShort.group(1)!);
      final month = int.parse(matchDMYShort.group(2)!);
      var year = int.parse(matchDMYShort.group(3)!);
      year += (year < 50 ? 2000 : 1900);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    // Try regex for YYYY/MM/DD
    final matchYMD = RegExp(r'^(\d{4})[/\-](\d{1,2})[/\-](\d{1,2})$').firstMatch(clean);
    if (matchYMD != null) {
      final year = int.parse(matchYMD.group(1)!);
      final month = int.parse(matchYMD.group(2)!);
      final day = int.parse(matchYMD.group(3)!);
      if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// Parses monetary amount from string, cleaning currency symbols, dots, commas.
  /// Handles formats like "Rp 15.000", "15,000.00", "15000", "-Rp 5.000", "15.000,50"
  static int parseAmount(String amountStr) {
    if (amountStr.trim().isEmpty) return 0;
    
    // Clean currency symbols, spaces, keep only digits, dots, commas, minus
    var s = amountStr.replaceAll(RegExp(r'[^\d.,-]'), '');
    if (s.isEmpty) return 0;
    
    // Check if both dots and commas are present
    final hasDot = s.contains('.');
    final hasComma = s.contains(',');
    
    double? parsedVal;
    
    if (hasDot && hasComma) {
      final dotIndex = s.indexOf('.');
      final commaIndex = s.indexOf(',');
      if (dotIndex < commaIndex) {
        // Dot is thousands, comma is decimal (Indonesian style: 1.234,56)
        final clean = s.replaceAll('.', '').replaceAll(',', '.');
        parsedVal = double.tryParse(clean);
      } else {
        // Comma is thousands, dot is decimal (US style: 1,234.56)
        final clean = s.replaceAll(',', '');
        parsedVal = double.tryParse(clean);
      }
    } else if (hasDot) {
      // Only dot. Check if it's thousands or decimal.
      final parts = s.split('.');
      if (parts.length > 2) {
        // Multiple dots, must be thousands separator
        parsedVal = double.tryParse(s.replaceAll('.', ''));
      } else {
        // Single dot
        final decimalPart = parts[1];
        if (decimalPart.length == 3) {
          // E.g. 150.000 -> thousands
          parsedVal = double.tryParse(s.replaceAll('.', ''));
        } else {
          // E.g. 150.5 -> decimal
          parsedVal = double.tryParse(s);
        }
      }
    } else if (hasComma) {
      // Only comma.
      final parts = s.split(',');
      if (parts.length > 2) {
        // Multiple commas, thousands
        parsedVal = double.tryParse(s.replaceAll(',', ''));
      } else {
        // Single comma
        final decimalPart = parts[1];
        if (decimalPart.length == 3) {
          // E.g. 15,000 -> thousands
          parsedVal = double.tryParse(s.replaceAll(',', ''));
        } else {
          // E.g. 15,5 -> decimal (Indonesian style decimal)
          parsedVal = double.tryParse(s.replaceAll(',', '.'));
        }
      }
    } else {
      // No dots or commas
      parsedVal = double.tryParse(s);
    }
    
    if (parsedVal == null) return 0;
    return parsedVal.round().abs();
  }

  /// Process the parsed rows using the given mapping.
  static List<ParsedCsvRow> processRows({
    required List<List<String>> rows,
    required Map<String, int> mapping,
    required bool hasHeader,
  }) {
    final List<ParsedCsvRow> results = [];
    final startIndex = hasHeader ? 1 : 0;
    
    for (int i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      // Skip empty rows
      if (row.isEmpty || (row.length == 1 && row.first.isEmpty)) continue;
      
      // Pad row to ensure we don't index out of bounds
      final maxLength = mapping.values.isEmpty ? 0 : mapping.values.reduce((a, b) => a > b ? a : b);
      while (row.length <= maxLength) {
        row.add('');
      }
      
      // Get raw values
      final rawDate = mapping.containsKey('date') ? row[mapping['date']!] : '';
      final rawCategory = mapping.containsKey('category') ? row[mapping['category']!] : '';
      final rawDescription = mapping.containsKey('description') ? row[mapping['description']!] : '';
      final rawVendor = mapping.containsKey('vendor') ? row[mapping['vendor']!] : '';
      
      final rawAmount = mapping.containsKey('amount') ? row[mapping['amount']!] : '';
      final rawIncome = mapping.containsKey('income_amount') ? row[mapping['income_amount']!] : '';
      final rawExpense = mapping.containsKey('expense_amount') ? row[mapping['expense_amount']!] : '';
      final rawType = mapping.containsKey('type') ? row[mapping['type']!] : '';
      
      // Parse Date
      final parsedDate = parseDate(rawDate);
      String? warning;
      if (rawDate.isNotEmpty && parsedDate == null) {
        warning = 'Format tanggal tidak dikenali. Digunakan tanggal hari ini.';
      }
      
      // Parse Amount & Type
      int amount = 0;
      String type = 'expense';
      
      // Check if separate income and expense columns are used
      final bool hasIncomeCol = mapping.containsKey('income_amount') && rawIncome.isNotEmpty && parseAmount(rawIncome) > 0;
      final bool hasExpenseCol = mapping.containsKey('expense_amount') && rawExpense.isNotEmpty && parseAmount(rawExpense) > 0;
      
      if (hasIncomeCol && hasExpenseCol) {
        final incVal = parseAmount(rawIncome);
        final expVal = parseAmount(rawExpense);
        if (incVal > expVal) {
          amount = incVal;
          type = 'income';
        } else {
          amount = expVal;
          type = 'expense';
        }
      } else if (hasIncomeCol) {
        amount = parseAmount(rawIncome);
        type = 'income';
      } else if (hasExpenseCol) {
        amount = parseAmount(rawExpense);
        type = 'expense';
      } else if (rawAmount.isNotEmpty) {
        amount = parseAmount(rawAmount);
        
        // Determine type based on type column
        if (rawType.isNotEmpty) {
          final t = rawType.toLowerCase();
          if (t.contains('in') || t.contains('masuk') || t.contains('pemasukan') || t.contains('credit') || t.contains('gaji') || t == 'cr' || t == '1') {
            type = 'income';
          } else {
            type = 'expense';
          }
        } else {
          // If no type column, check if amount is negative
          final isNegative = rawAmount.trim().startsWith('-');
          if (isNegative) {
            type = 'expense';
          }
        }
      }
      
      if (amount == 0) {
        warning = (warning == null) ? 'Nominal transaksi Rp0' : '$warning; Nominal transaksi Rp0';
      }
      
      results.add(ParsedCsvRow(
        date: parsedDate ?? DateTime.now(),
        rawDate: rawDate,
        category: rawCategory,
        transactionType: type,
        amount: amount,
        rawAmount: rawIncome.isNotEmpty ? rawIncome : (rawExpense.isNotEmpty ? rawExpense : rawAmount),
        description: rawDescription.isNotEmpty ? rawDescription : rawCategory,
        vendor: rawVendor.isNotEmpty ? rawVendor : null,
        warning: warning,
      ));
    }
    
    return results;
  }
}
