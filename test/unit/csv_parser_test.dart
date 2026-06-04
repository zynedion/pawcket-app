import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/utils/csv_parser.dart';

void main() {
  group('CsvParser Delimiter Detection', () {
    test('should detect comma', () {
      final csv = 'date,category,amount\n2026-06-01,Food,15000';
      expect(CsvParser.detectDelimiter(csv), equals(','));
    });

    test('should detect semicolon', () {
      final csv = 'date;category;amount\n2026-06-01;Food;15000';
      expect(CsvParser.detectDelimiter(csv), equals(';'));
    });

    test('should detect tab', () {
      final csv = 'date\tcategory\tamount\n2026-06-01\tFood\t15000';
      expect(CsvParser.detectDelimiter(csv), equals('\t'));
    });
  });

  group('CsvParser Header Auto-Detection', () {
    test('should auto detect basic headers', () {
      final headers = ['Tanggal', 'Kategori', 'Keterangan', 'Nominal', 'Tipe'];
      final mapping = CsvParser.autoDetectHeaders(headers);
      
      expect(mapping['date'], equals(0));
      expect(mapping['category'], equals(1));
      expect(mapping['description'], equals(2));
      expect(mapping['amount'], equals(3));
      expect(mapping['type'], equals(4));
    });

    test('should auto detect separate income and expense columns', () {
      final headers = ['Date', 'Category', 'Pemasukan', 'Pengeluaran', 'Keterangan'];
      final mapping = CsvParser.autoDetectHeaders(headers);
      
      expect(mapping['date'], equals(0));
      expect(mapping['category'], equals(1));
      expect(mapping['income_amount'], equals(2));
      expect(mapping['expense_amount'], equals(3));
      expect(mapping['description'], equals(4));
    });
  });

  group('CsvParser Date Parsing', () {
    test('should parse YYYY-MM-DD', () {
      final date = CsvParser.parseDate('2026-06-04');
      expect(date, isNotNull);
      expect(date!.year, equals(2026));
      expect(date.month, equals(6));
      expect(date.day, equals(4));
    });

    test('should parse DD/MM/YYYY', () {
      final date = CsvParser.parseDate('15/12/2025');
      expect(date, isNotNull);
      expect(date!.year, equals(2025));
      expect(date.month, equals(12));
      expect(date.day, equals(15));
    });

    test('should parse DD-MM-YYYY', () {
      final date = CsvParser.parseDate('01-03-2026');
      expect(date, isNotNull);
      expect(date!.year, equals(2026));
      expect(date.month, equals(3));
      expect(date.day, equals(1));
    });

    test('should return null for invalid date', () {
      expect(CsvParser.parseDate('invalid date'), isNull);
    });
  });

  group('CsvParser Amount Parsing', () {
    test('should parse plain numbers', () {
      expect(CsvParser.parseAmount('15000'), equals(15000));
    });

    test('should parse Indonesian format with dots', () {
      expect(CsvParser.parseAmount('Rp 150.000'), equals(150000));
      expect(CsvParser.parseAmount('Rp. 150.000'), equals(150000));
      expect(CsvParser.parseAmount('1.500.000'), equals(1500000));
    });

    test('should parse standard thousands with commas', () {
      expect(CsvParser.parseAmount('1,500.50'), equals(1501)); // Rounded to nearest int
      expect(CsvParser.parseAmount('15,000'), equals(15000));
    });

    test('should parse negative numbers as absolute values', () {
      expect(CsvParser.parseAmount('-15000'), equals(15000));
      expect(CsvParser.parseAmount('-Rp 5.000'), equals(5000));
    });
  });

  group('CsvParser Process Rows', () {
    test('should process row with separate columns correctly', () {
      final csv = 'Tanggal;Kategori;Pemasukan;Pengeluaran;Keterangan\n'
          '01/05/2026;Gaji;Rp 5.000.000;;Gaji Bulanan\n'
          '02/05/2026;Makanan;;Rp 75.000;Makan Bakso\n';
      
      final rows = CsvParser.parseToRows(csv);
      final headers = rows.first;
      final mapping = CsvParser.autoDetectHeaders(headers);
      
      final parsed = CsvParser.processRows(
        rows: rows,
        mapping: mapping,
        hasHeader: true,
      );
      
      expect(parsed.length, equals(2));
      
      // First row: income
      expect(parsed[0].transactionType, equals('income'));
      expect(parsed[0].amount, equals(5000000));
      expect(parsed[0].category, equals('Gaji'));
      expect(parsed[0].description, equals('Gaji Bulanan'));
      expect(parsed[0].date!.month, equals(5));
      expect(parsed[0].date!.day, equals(1));
      
      // Second row: expense
      expect(parsed[1].transactionType, equals('expense'));
      expect(parsed[1].amount, equals(75000));
      expect(parsed[1].category, equals('Makanan'));
      expect(parsed[1].description, equals('Makan Bakso'));
    });
  });
}
