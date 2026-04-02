import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;
      
      final response = await Supabase.instance.client
          .from('trainer_requests')
          .select('''
            *,
            trainer:trainer_id (id, full_name, avatar_url)
          ''')
          .eq('client_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading requests: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }
  
  Future<void> _respondToRequest(String requestId, String status) async {
  try {
    // Получаем данные запроса перед удалением
    final request = _requests.firstWhere((r) => r['id'] == requestId);
    final trainerId = request['trainer_id'];
    final clientId = await _getCurrentUserId();
    
    // Проверяем, что clientId не null
    if (clientId == null) {
      throw Exception('Пользователь не авторизован');
    }
    
    // Обновляем статус запроса
    await Supabase.instance.client
        .from('trainer_requests')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
    
    if (status == 'accepted') {
      // Проверяем, нет ли уже связи
      final existing = await Supabase.instance.client
          .from('trainer_clients')
          .select()
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId)
          .maybeSingle();
      
      if (existing == null) {
        // Создаём связь тренер-клиент
        await Supabase.instance.client
            .from('trainer_clients')
            .insert({
              'trainer_id': trainerId,
              'client_id': clientId,
              'status': 'active',
              'start_date': DateTime.now().toIso8601String(),
            });
      }
      
      // Синхронизируем данные клиента с тренером
      final clientData = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', clientId)
          .single();
      
      final existingUnreg = await Supabase.instance.client
          .from('unregistered_clients')
          .select()
          .eq('trainer_id', trainerId)
          .eq('id', clientId)
          .maybeSingle();
      
      if (existingUnreg != null) {
        await Supabase.instance.client
            .from('unregistered_clients')
            .update({
              'full_name': clientData['full_name'],
              'email': clientData['email'],
              'phone': clientData['phone'],
            })
            .eq('id', clientId);
      } else {
        await Supabase.instance.client
            .from('unregistered_clients')
            .insert({
              'id': clientId,
              'trainer_id': trainerId,
              'full_name': clientData['full_name'],
              'email': clientData['email'],
              'phone': clientData['phone'],
            });
      }
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Тренер добавлен');
      }
    } else {
      if (mounted) {
        Helpers.showSnackBar(context, 'Запрос отклонён');
      }
    }
    
    // Обновляем список
    _loadRequests();
  } catch (e) {
    if (mounted) {
      Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Запросы от тренеров',
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
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет запросов',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Когда тренер отправит запрос,\nон появится здесь',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      final trainer = request['trainer'];
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.green.withOpacity(0.15),
                                  backgroundImage: trainer['avatar_url'] != null
                                      ? NetworkImage(trainer['avatar_url'])
                                      : null,
                                  child: trainer['avatar_url'] == null
                                      ? Text(
                                          trainer['full_name'][0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trainer['full_name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Хочет добавить вас в список клиентов',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _respondToRequest(request['id'], 'accepted'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: const Text(
                                        'Принять',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _respondToRequest(request['id'], 'rejected'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: const Text(
                                        'Отклонить',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}