import 'chat_message.dart';

class ChatSession {
  final int? sessionId;
  final int userId;
  final String? sessionTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? lastMood; // 'happy', 'neutral', 'shocked', 'angry'
  final List<ChatMessage> messages;

  ChatSession({
    this.sessionId,
    required this.userId,
    this.sessionTitle,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.lastMood = 'neutral',
    this.messages = const [],
  });

  factory ChatSession.fromMap(Map<String, dynamic> map, {List<ChatMessage> messages = const []}) {
    return ChatSession(
      sessionId: map['session_id'] as int?,
      userId: map['user_id'] as int,
      sessionTitle: map['session_title'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      deletedAt: map['deleted_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int) : null,
      lastMood: map['last_mood'] as String? ?? 'neutral',
      messages: messages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (sessionId != null) 'session_id': sessionId,
      'user_id': userId,
      'session_title': sessionTitle,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
      'last_mood': lastMood,
    };
  }

  ChatSession copyWith({
    int? sessionId,
    int? userId,
    String? sessionTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? lastMood,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastMood: lastMood ?? this.lastMood,
      messages: messages ?? this.messages,
    );
  }
}
