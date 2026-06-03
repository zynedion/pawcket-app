import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import 'local_db.dart';

class ChatService {
  final LocalDb _localDb;

  ChatService({LocalDb? localDb}) : _localDb = localDb ?? LocalDb.instance;

  Future<ChatSession> createChatSession(int userId, {String? title}) async {
    final db = await _localDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final sessionId = await db.insert('chat_sessions', {
      'user_id': userId,
      'session_title': title ?? 'Chat dengan Mr. Oyen',
      'created_at': now,
      'updated_at': now,
      'last_mood': 'neutral',
    });

    return ChatSession(
      sessionId: sessionId,
      userId: userId,
      sessionTitle: title ?? 'Chat dengan Mr. Oyen',
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      lastMood: 'neutral',
      messages: [],
    );
  }

  Future<List<ChatSession>> getChatSessions(int userId) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final List<ChatSession> sessions = [];
    for (final map in maps) {
      final sessionId = map['session_id'] as int;
      final messages = await getChatMessages(sessionId);
      sessions.add(ChatSession.fromMap(map, messages: messages));
    }
    return sessions;
  }

  Future<ChatSession?> getLatestSession(int userId) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final map = maps.first;
    final sessionId = map['session_id'] as int;
    final messages = await getChatMessages(sessionId);
    return ChatSession.fromMap(map, messages: messages);
  }

  Future<List<ChatMessage>> getChatMessages(int sessionId) async {
    final db = await _localDb.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
      limit: 100,
    );

    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<ChatMessage> saveChatMessage({
    required int sessionId,
    required String senderRole,
    required String content,
    int? transactionId,
  }) async {
    final db = await _localDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final messageId = await db.insert('chat_messages', {
      'session_id': sessionId,
      'sender_role': senderRole,
      'content': content,
      'transaction_id': transactionId,
      'created_at': now,
    });

    // Also update session's updated_at
    await db.update(
      'chat_sessions',
      {'updated_at': now},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    return ChatMessage(
      messageId: messageId,
      sessionId: sessionId,
      senderRole: senderRole,
      content: content,
      transactionId: transactionId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  Future<void> updateSessionMood(int sessionId, String mood) async {
    final db = await _localDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'chat_sessions',
      {
        'last_mood': mood,
        'updated_at': now,
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteChatSession(int sessionId) async {
    final db = await _localDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'chat_sessions',
      {'deleted_at': now},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> clearAllChatHistory(int userId) async {
    final db = await _localDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'chat_sessions',
      {'deleted_at': now},
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
    );
  }
}
