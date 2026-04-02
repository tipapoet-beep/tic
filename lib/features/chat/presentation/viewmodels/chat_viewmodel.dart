import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trainapp/features/chat/domain/repositories/chat_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../../../config/di/providers.dart';
import '../../../profile/domain/entities/profile.dart';

// Провайдеры
final chatRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChatRemoteDataSource(client);
});

// В отдельном файле или в chat_viewmodel.dart
final unreadMessagesProvider = StateNotifierProvider<UnreadMessagesNotifier, int>((ref) {
  return UnreadMessagesNotifier();
});

class UnreadMessagesNotifier extends StateNotifier<int> {
  UnreadMessagesNotifier() : super(0);

  void setCount(int count) {
    state = count;
  }

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }
}

final chatRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(dataSource);
});

// Состояние чата
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final Profile? otherUser;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.otherUser,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    Profile? otherUser,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      otherUser: otherUser ?? this.otherUser,
    );
  }
}

// ViewModel
class ChatViewModel extends StateNotifier<ChatState> {
  final ChatRepository _repository;

  ChatViewModel(this._repository) : super(ChatState());

  Future<void> loadChatHistory(String userId1, String userId2) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _repository.getChatHistory(userId1, userId2);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      final newMessage = await _repository.sendMessage(message);
      state = state.copyWith(
        messages: [...state.messages, newMessage],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void subscribeToMessages(String userId1, String userId2) {
    _repository.getMessagesStream(userId1, userId2).listen((message) {
      // Добавляем только если это новое сообщение (не дублируем)
      if (!state.messages.any((m) => m.id == message.id)) {
        state = state.copyWith(messages: [...state.messages, message]);
      }
      
      // Если сообщение от другого пользователя - отмечаем как прочитанное
      if (message.receiverId == userId1 && !message.isRead) {
        _repository.markAsRead(message.id);
      }
    });
  }

  void setOtherUser(Profile user) {
    state = state.copyWith(otherUser: user);
  }

  void updateMessages(List<Message> updatedMessages) {}
}

// Провайдер ViewModel
final chatViewModelProvider = StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatViewModel(repository);
});