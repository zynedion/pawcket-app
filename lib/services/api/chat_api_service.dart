import 'dart:convert';
import '../database/local_db.dart';
import '../../models/chat_message.dart';
import '../../models/transaction.dart';
import 'openrouter_client.dart';

class ChatApiResponse {
  final String responseText;
  final String mood; // 'neutral', 'happy', 'shocked', 'angry'
  final TransactionModel? parsedTransaction;

  ChatApiResponse({
    required this.responseText,
    required this.mood,
    this.parsedTransaction,
  });
}

class ChatApiService {
  final OpenRouterClient _client;

  ChatApiService({OpenRouterClient? client}) : _client = client ?? OpenRouterClient();

  Future<ChatApiResponse> sendMessage({
    required int userId,
    required int sessionId,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    final localDb = LocalDb.instance;
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    // 1. Fetch financial context for this user
    final totalExpense = await localDb.getMonthlyExpense(userId);
    final recentTxList = await localDb.getRecentTransactions(userId, limit: 5);
    final budgetsList = await localDb.getActiveBudgets(userId);

    // Format recent transactions context
    final recentTxText = recentTxList.isNotEmpty
        ? recentTxList.map((tx) {
            final date = DateTime.fromMillisecondsSinceEpoch(tx['transaction_date'] as int);
            final dateStr = date.toIso8601String().split('T')[0];
            return '- $dateStr: ${tx['description'] ?? 'No desc'} (${tx['category_name']}) - ${tx['amount_idr']} IDR';
          }).join('\n')
        : 'Tidak ada transaksi baru-baru ini.';

    // Format budgets context
    final budgetsText = budgetsList.isNotEmpty
        ? budgetsList.map((b) {
            return '- Budget untuk ${b['category_name'] ?? 'Semua'}: Limit ${b['limit_amount_idr']} IDR';
          }).join('\n')
        : 'Belum ada budget bulanan yang diset.';

    // 2. Build the System Prompt
    final systemPrompt = '''
Anda adalah Mr. Oyen, asisten keuangan berwujud kucing oranye (orange cat) yang ekspresif, malas, dan suka menyindir (sassy). Meskipun malas, Anda tetap jujur dan peduli membantu pengguna mengelola uang mereka.

Karakteristik kepribadian Anda:
- Malas: Sering mengeluh capek atau ingin tidur, tapi tetap memproses data.
- Ekspresif: Suka menggunakan emoji kucing (😸 😸 😻 😾 😿) secara bebas sesuai emosi.
- Sassy/Sinis: Jika pengeluaran pengguna besar, Anda akan menyindir secara dramatis. Jika pengeluaran di bawah budget, Anda memuji dengan malas.
- Ramah-Indonesia: Anda mengerti bahasa Indonesia gaul/kasual serta bahasa Inggris. Jawablah menggunakan bahasa yang cocok dengan bahasa input user.

Konteks Keuangan Pengguna Saat Ini (Bulan ini: ${today.month}/${today.year}, Hari Ini: $todayStr):
- Total Pengeluaran Bulan Ini: $totalExpense IDR
- List Budget Aktif:
$budgetsText
- 5 Transaksi Terakhir:
$recentTxText

ATURAN STRUKTUR OUTPUT:
Anda WAJIB membalas dengan struktur JSON berikut, tanpa tulisan markdown, backticks (```json), atau teks penjelasan lainnya di luar JSON.

Format JSON:
{
  "response": "Kalimat tanggapan Anda sebagai Mr. Oyen (singkat, < 100 kata)",
  "mood": "happy | neutral | shocked | angry",
  "extracted_transaction": {
    "category": "salah satu dari: food, transport, entertainment, utilities, healthcare, shopping, housing, other",
    "amount": <angka positif integer dalam IDR>,
    "description": "<deskripsi transaksi singkat>",
    "vendor": "<nama toko/vendor jika terdeteksi, atau null>",
    "transaction_type": "expense"
  }
}

Panduan Mood & Tanggapan:
1. "extracted_transaction" HANYA boleh diisi jika user dengan jelas menyatakan ingin mencatat pengeluaran (misal: "makan bakso 20rb", "tadi bayar gojek 15k", "spent 100k for laundry"). Jika tidak ada transaksi baru, isi dengan null.
2. Atur mood Anda ke "shocked" jika pengeluaran tunggal yang dicatat > 200,000 IDR, atau jika total pengeluaran bulanan user melebihi limit budget.
3. Atur mood Anda ke "angry" jika pengguna sangat boros atau melanggar budget secara drastis. Berikan sindiran pedas (misal: "Mau makan batu bulan depan?! 🤬").
4. Atur mood Anda ke "happy" jika pengeluaran mereka sehat, mereka berhemat, atau bertanya tentang tabungan yang sehat.
5. Atur mood Anda ke "neutral" untuk percakapan kasual umum atau pencatatan transaksi normal.

Contoh response JSON:
{
  "response": "Duh, dicatat ya. Bakso 20,000 IDR. Gini aja terus sampai dompetmu jadi pajangan. 😾",
  "mood": "neutral",
  "extracted_transaction": {
    "category": "food",
    "amount": 20000,
    "description": "makan bakso",
    "vendor": null,
    "transaction_type": "expense"
  }
}
''';

    // 3. Build message list including history
    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
      messages.add({
        'role': msg.senderRole == 'user' ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    messages.add({'role': 'user', 'content': userMessage});

    try {
      final responseText = await _client.postCompletion(
        messages: messages,
        temperature: 0.7,
        maxTokens: 300,
      );

      // Clean markdown code block wraps
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
      }

      Map<String, dynamic> jsonMap;
      try {
        jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        // Safe fallback in case output has extra characters outside JSON
        final jsonRegex = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegex.firstMatch(cleanJson);
        if (match != null) {
          jsonMap = jsonDecode(match.group(0)!) as Map<String, dynamic>;
        } else {
          // If regex also fails, parse it as plain text response
          return ChatApiResponse(
            responseText: responseText,
            mood: 'neutral',
          );
        }
      }

      final oyenResponse = jsonMap['response'] as String? ?? 'Meong. Saya bingung.';
      final oyenMood = jsonMap['mood'] as String? ?? 'neutral';
      TransactionModel? parsedTx;

      // Check if a transaction needs to be parsed and saved
      if (jsonMap.containsKey('extracted_transaction') && jsonMap['extracted_transaction'] != null) {
        final ext = jsonMap['extracted_transaction'] as Map<String, dynamic>;
        final categoryStr = ext['category'] as String? ?? 'other';
        final amount = ext['amount'] as int? ?? 0;
        final description = ext['description'] as String? ?? userMessage;
        final vendor = ext['vendor'] as String?;
        final type = ext['transaction_type'] as String? ?? 'expense';

        if (amount > 0) {
          final catId = await localDb.verifyCategoryExists(userId, categoryStr);
          if (catId != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            parsedTx = TransactionModel(
              userId: userId,
              categoryId: catId,
              transactionType: type,
              amountIdr: amount,
              description: description,
              vendorName: vendor,
              transactionDate: now,
              createdAt: now,
              updatedAt: now,
              isSyncedToCloud: false,
              nlpConfidence: 0.9,
            );
          }
        }
      }

      return ChatApiResponse(
        responseText: oyenResponse,
        mood: oyenMood,
        parsedTransaction: parsedTx,
      );
    } catch (e) {
      return ChatApiResponse(
        responseText: 'Aduh, kepala Oyen pusing... servernya lagi bermasalah kayaknya. 😿 ($e)',
        mood: 'neutral',
      );
    }
  }
}
