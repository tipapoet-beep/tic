import 'package:trainapp/features/chat/data/datasources/chat_remote_datasource.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';


class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<Message> sendMessage(Message message) async {
    return await _remoteDataSource.sendMessage(message);
  }

  @override
  Future<List<Message>> getChatHistory(String userId1, String userId2) async {
    return await _remoteDataSource.getChatHistory(userId1, userId2);
  }

  @override
  Stream<Message> getMessagesStream(String userId1, String userId2) {
    return _remoteDataSource.getMessagesStream(userId1, userId2);
  }

  @override
  Future<void> markAsRead(String messageId) async {
    await _remoteDataSource.markAsRead(messageId);
  }
}