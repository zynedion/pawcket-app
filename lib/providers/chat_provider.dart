import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/api/chat_api_service.dart';
import '../services/database/chat_service.dart';
import '../services/database/local_db.dart';
import 'dashboard_provider.dart';

class ChatState {
  final ChatSession? currentSession;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final String currentMood;

  ChatState({
    this.currentSession,
    required this.isLoading,
    required this.isSending,
    this.errorMessage,
    required this.currentMood,
  });

  factory ChatState.initial() {
    return ChatState(
      isLoading: false,
      isSending: false,
      currentMood: 'neutral',
    );
  }

  ChatState copyWith({
    ChatSession? currentSession,
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    String? currentMood,
  }) {
    return ChatState(
      currentSession: currentSession ?? this.currentSession,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      currentMood: currentMood ?? this.currentMood,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  final ChatService _chatService = ChatService();
  final ChatApiService _chatApiService = ChatApiService();
  final LocalDb _db = LocalDb.instance;

  ChatNotifier(this.ref) : super(ChatState.initial()) {
    initChat();
  }

  Future<void> initChat() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _db.getUser();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not found. Please complete onboarding first.',
        );
        return;
      }

      var session = await _chatService.getLatestSession(user.userId!);
      if (session == null) {
        session = await _chatService.createChatSession(user.userId!);
        // Add a welcoming message from Mr. Oyen to seed the chat
        final welcomeMsg = await _chatService.saveChatMessage(
          sessionId: session.sessionId!,
          senderRole: 'assistant',
          content: 'Meong. Saya Mr. Oyen, asisten keuangan pribadimu. Ada transaksi yang mau dicatat? Atau mau nanya pengeluaran bulananmu yang menyeramkan itu? 😼',
        );
        session = session.copyWith(messages: [welcomeMsg]);
      }

      state = state.copyWith(
        currentSession: session,
        currentMood: session.lastMood ?? 'neutral',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menginisialisasi chat: $e',
      );
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || state.isSending || state.currentSession == null) {
      return;
    }

    final session = state.currentSession!;
    final user = await _db.getUser();
    if (user == null) return;

    state = state.copyWith(isSending: true);

    try {
      // 1. Save user message to database
      final userMsg = await _chatService.saveChatMessage(
        sessionId: session.sessionId!,
        senderRole: 'user',
        content: content,
      );

      // Update state with the user message immediately for responsiveness
      final updatedMessagesWithUser = [...session.messages, userMsg];
      state = state.copyWith(
        currentSession: session.copyWith(messages: updatedMessagesWithUser),
      );

      // 2. Call OpenAI / OpenRouter client
      final response = await _chatApiService.sendMessage(
        userId: user.userId!,
        sessionId: session.sessionId!,
        history: session.messages, // pass current history (excluding the new user msg if api only takes previous context, but standard is to pass user msg too)
        userMessage: content,
      );

      int? transactionId;
      // 3. If LLM extracted a transaction, save it
      if (response.parsedTransaction != null) {
        try {
          transactionId = await _db.insertTransaction(response.parsedTransaction!);
          // Refresh Dashboard
          ref.invalidate(dashboardProvider);
        } catch (e) {
          print('Gagal menyimpan transaksi otomatis dari chat: $e');
        }
      }

      // 4. Save Mr. Oyen response to database
      final assistantMsg = await _chatService.saveChatMessage(
        sessionId: session.sessionId!,
        senderRole: 'assistant',
        content: response.responseText,
        transactionId: transactionId,
      );

      // 5. Update session mood in database
      await _chatService.updateSessionMood(session.sessionId!, response.mood);

      // 6. Update local state
      state = state.copyWith(
        currentSession: session.copyWith(
          messages: [...updatedMessagesWithUser, assistantMsg],
          lastMood: response.mood,
        ),
        currentMood: response.mood,
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Gagal mengirim pesan: $e',
      );
    }
  }

  Future<void> startNewSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _db.getUser();
      if (user == null) return;

      final session = await _chatService.createChatSession(user.userId!);
      final welcomeMsg = await _chatService.saveChatMessage(
        sessionId: session.sessionId!,
        senderRole: 'assistant',
        content: 'Meong. Sesi baru dimulai. Laporkan pengeluaranmu sebelum kubakar uangmu! 😾',
      );

      state = state.copyWith(
        currentSession: session.copyWith(messages: [welcomeMsg]),
        currentMood: 'neutral',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat sesi baru: $e',
      );
    }
  }

  Future<void> clearHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _db.getUser();
      if (user == null) return;

      await _chatService.clearAllChatHistory(user.userId!);
      await initChat();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menghapus riwayat chat: $e',
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
