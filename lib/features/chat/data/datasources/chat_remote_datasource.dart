import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/message.dart';
import '../../../../core/base/base_datasource.dart';

class ChatRemoteDataSource extends BaseDataSource {
  ChatRemoteDataSource(super.client);

  // Отправка сообщения
  Future<Message> sendMessage(Message message) async {
    try {
      log('Sending message to: ${message.receiverId}');
      
      final supabase = await client;
      final response = await supabase
          .from('messages')
          .insert(message.toJson())
          .select()
          .single();

      logSuccess('Message sent');
      return Message.fromJson(response);
    } catch (e) {
      logError('Failed to send message', error: e);
      throw Exception('Failed to send message: $e');
    }
  }

  // Получение истории чата между двумя пользователями
  Future<List<Message>> getChatHistory(String userId1, String userId2) async {
    try {
      log('Fetching chat history between $userId1 and $userId2');

      final supabase = await client;
      final response = await supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$userId1,sender_id.eq.$userId2')
          .or('receiver_id.eq.$userId1,receiver_id.eq.$userId2')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      logError('Failed to fetch chat history', error: e);
      throw Exception('Failed to fetch chat history: $e');
    }
  }

  // Стрим новых сообщений (упрощенная версия)
  Stream<Message> getMessagesStream(String userId1, String userId2) {
    try {
      log('Subscribing to messages stream between $userId1 and $userId2');
      
      // Простой стрим с фильтрацией на клиенте
      return rawClient
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at')
          .map((response) {
            // Получаем список всех сообщений
            final messages = (response as List)
                .map((json) => Message.fromJson(json))
                .where((msg) =>
                    (msg.senderId == userId1 && msg.receiverId == userId2) ||
                    (msg.senderId == userId2 && msg.receiverId == userId1))
                .toList();
            
            // Возвращаем последнее сообщение для реального времени
            return messages.isNotEmpty ? messages.last : null;
          })
          .where((message) => message != null)
          .map((message) => message!);
    } catch (e) {
      logError('Failed to create messages stream', error: e);
      return const Stream.empty();
    }
  }

  // Отметить сообщения как прочитанные
  Future<void> markAsRead(String messageId) async {
    try {
      final supabase = await client;
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
    } catch (e) {
      logError('Failed to mark as read', error: e);
    }
  }

  // Отметить все сообщения от пользователя как прочитанные
  Future<void> markAllAsRead(String userId, String otherUserId) async {
    try {
      final supabase = await client;
      await supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      logError('Failed to mark all as read', error: e);
    }
  }
}