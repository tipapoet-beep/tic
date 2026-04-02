import '../entities/message.dart';

abstract class ChatRepository {
  Future<Message> sendMessage(Message message);
  Future<List<Message>> getChatHistory(String userId1, String userId2);
  Stream<Message> getMessagesStream(String userId1, String userId2);
  Future<void> markAsRead(String messageId);
}