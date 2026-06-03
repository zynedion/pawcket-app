import 'package:flutter_test/flutter_test.dart';
import 'package:pawcket/models/chat_message.dart';

void main() {
  group('Chat Message Model Tests', () {
    test('ChatMessage mapping test', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        messageId: 1,
        sessionId: 5,
        senderRole: 'user',
        content: 'Halo Oyen',
        createdAt: now,
      );

      final map = msg.toMap();
      expect(map['message_id'], equals(1));
      expect(map['session_id'], equals(5));
      expect(map['sender_role'], equals('user'));
      expect(map['content'], equals('Halo Oyen'));
      expect(map['created_at'], equals(now.millisecondsSinceEpoch));

      final mappedMsg = ChatMessage.fromMap(map);
      expect(mappedMsg.messageId, equals(1));
      expect(mappedMsg.sessionId, equals(5));
      expect(mappedMsg.senderRole, equals('user'));
      expect(mappedMsg.content, equals('Halo Oyen'));
      expect(mappedMsg.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
    });
  });
}
