import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/config/di/providers.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../profile/domain/entities/profile.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      // Получаем текущую роль пользователя
      final currentUserRole = await _getUserRole(userId);
      
      List<Map<String, dynamic>> chats = [];
      
      if (currentUserRole == 'trainer') {
        // Тренер видит всех своих клиентов
        final response = await Supabase.instance.client
            .from('trainer_clients')
            .select('''
              client_id,
              profiles:client_id (
                id, full_name, avatar_url, email
              )
            ''')
            .eq('trainer_id', userId);
        
        for (final item in response) {
          final profile = item['profiles'];
          if (profile != null) {
            final lastMessage = await Supabase.instance.client
                .from('messages')
                .select()
                .or('sender_id.eq.$userId,sender_id.eq.${profile['id']}')
                .or('receiver_id.eq.$userId,receiver_id.eq.${profile['id']}')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            chats.add({
              'user': profile,
              'lastMessage': lastMessage,
              'unreadCount': 0,
            });
          }
        }
      } else {
        // Клиент видит только своего тренера
        final response = await Supabase.instance.client
            .from('trainer_clients')
            .select('''
              trainer_id,
              trainer:trainer_id (
                id, full_name, avatar_url, email
              )
            ''')
            .eq('client_id', userId);
        
        for (final item in response) {
          final profile = item['trainer'];
          if (profile != null) {
            final lastMessage = await Supabase.instance.client
                .from('messages')
                .select()
                .or('sender_id.eq.$userId,sender_id.eq.${profile['id']}')
                .or('receiver_id.eq.$userId,receiver_id.eq.${profile['id']}')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            chats.add({
              'user': profile,
              'lastMessage': lastMessage,
              'unreadCount': 0,
            });
          }
        }
      }

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }
  
  Future<String> _getUserRole(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Сообщения',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: PremiumBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : _chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 80,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет чатов',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Здесь будут появляться чаты с тренером',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      final user = chat['user'];
                      final lastMessage = chat['lastMessage'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1A1D24),
                              Color(0xFF22262F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              final profile = Profile(
                                id: user['id'],
                                email: user['email'] ?? '',
                                fullName: user['full_name'],
                                role: 'trainer', // для клиента собеседник - тренер
                                avatarUrl: user['avatar_url'], experienceYears: null,
                              );
                              context.push('/chat/${user['id']}', extra: profile);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Аватар
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.green.withOpacity(0.15),
                                    backgroundImage: user['avatar_url'] != null
                                        ? NetworkImage(user['avatar_url'])
                                        : null,
                                    child: user['avatar_url'] == null
                                        ? Text(
                                            user['full_name'][0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Информация
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['full_name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lastMessage != null
                                              ? lastMessage['content']
                                              : 'Нет сообщений',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Счетчик непрочитанных
                                  if (chat['unreadCount'] > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${chat['unreadCount']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}