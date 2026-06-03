class ChatMessage {
  final int? messageId;
  final int sessionId;
  final String senderRole; // 'user' or 'assistant'
  final String content;
  final int? transactionId;
  final DateTime createdAt;

  ChatMessage({
    this.messageId,
    required this.sessionId,
    required this.senderRole,
    required this.content,
    this.transactionId,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map['message_id'] as int?,
      sessionId: map['session_id'] as int,
      senderRole: map['sender_role'] as String,
      content: map['content'] as String,
      transactionId: map['transaction_id'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (messageId != null) 'message_id': messageId,
      'session_id': sessionId,
      'sender_role': senderRole,
      'content': content,
      'transaction_id': transactionId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
