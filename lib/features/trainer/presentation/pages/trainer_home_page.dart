import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/config/di/providers.dart';
import '../../../../config/di/providers.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../../../core/theme/premium_theme.dart';

class TrainerHomePage extends ConsumerStatefulWidget {
  const TrainerHomePage({super.key});

  @override
  ConsumerState<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends ConsumerState<TrainerHomePage> {
  bool _isLoading = true;
  String? _trainerName;
  Map<String, Map<String, dynamic>> _clientPrograms = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTrainerName();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null) {
      await ref.read(clientsViewModelProvider.notifier).loadClients(userId);
      await ref.read(templatesViewModelProvider.notifier).loadTemplates(userId);
      await ref.read(subscriptionsViewModelProvider.notifier).loadSubscriptions(userId);
      await _loadClientPrograms();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadClientPrograms() async {
    try {
      final clients = ref.read(clientsViewModelProvider).clients;
      for (var client in clients) {
        final response = await Supabase.instance.client
            .from('client_programs')
            .select('''
              id,
              program:program_id (title),
              status
            ''')
            .eq('client_id', client.id)
            .eq('status', 'active')
            .maybeSingle();
        
        if (response != null && mounted) {
          _clientPrograms[client.id] = {
            'title': response['program']['title'],
            'id': response['id'],
          };
        }
      }
      setState(() {});
    } catch (e) {
      print('Error loading client programs: $e');
    }
  }

  Future<void> _loadTrainerName() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          _trainerName = response['full_name']?.split(' ').first ?? 'Тренер';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsViewModelProvider);
    final templatesState = ref.watch(templatesViewModelProvider);
    final subscriptionsState = ref.watch(subscriptionsViewModelProvider);

    final clients = clientsState.clients;
    final templates = templatesState.templates;
    final subscriptions = subscriptionsState.subscriptions;

    final activeSubs = subscriptions.where((s) => s.isActive).toList();
    final income = activeSubs.fold(0.0, (sum, s) => sum + s.price);

    if (_isLoading && clients.isEmpty && templates.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: PremiumBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.green,
          backgroundColor: const Color(0xFF1A1D24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 👋 Приветствие
                Text(
                  _trainerName != null ? 'Привет, $_trainerName 👋' : 'Привет 👋',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                /// 💰 KPI карточка
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Доход за месяц',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₽ ${income.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// ⚡ Быстрые действия
                Column(
                  children: [
                    _actionTile(
                      icon: Icons.people,
                      title: 'Клиенты',
                      onTap: () => context.push('/clients'),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.zero,
                        bottomRight: Radius.zero,
                      ),
                    ),
                    _actionTile(
                      icon: Icons.fitness_center,
                      title: 'Программы',
                      onTap: () => context.push('/programs-list'),
                      borderRadius: BorderRadius.zero,
                    ),
                    _actionTile(
                      icon: Icons.payments,
                      title: 'Абонементы',
                      onTap: () => context.push('/subscriptions'),
                      borderRadius: BorderRadius.zero,
                    ),
                    _actionTile(
                      icon: Icons.message,
                      title: 'Сообщения',
                      onTap: () => context.push('/chat-list'),
                      borderRadius: BorderRadius.zero,
                    ),
                    _actionTile(
                      icon: Icons.calendar_today,
                      title: 'Расписание',
                      onTap: () => context.push('/schedule'),
                      borderRadius: BorderRadius.zero,
                    ),
                    _actionTile(
                      icon: Icons.history,
                      title: 'История',
                      onTap: () => context.push('/history'),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.zero,
                        topRight: Radius.zero,
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                /// 📊 Мини-статистика
                Row(
                  children: [
                    Expanded(child: _statCard('Клиенты', clients.length.toString())),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Программы', templates.length.toString())),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard('Активные', activeSubs.length.toString())),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard('Доход', '₽ ${income.toStringAsFixed(0)}')),
                  ],
                ),

                const SizedBox(height: 24),

                /// 👥 Последние клиенты
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Последние клиенты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/clients'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('Все'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (clients.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Нет клиентов',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Column(
                    children: clients.take(3).map((client) {
                      return _clientCard(client);
                    }).toList(),
                  ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1D24),
            Color(0xFF22262F),
          ],
        ),
        borderRadius: borderRadius,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.green, size: 22),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clientCard(client) {
    final activeProgram = _clientPrograms[client.id];
    
    return PremiumCard(
      onTap: () => context.push('/client/${client.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: Text(
                client.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (client.email.isNotEmpty)
                    Text(
                      client.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  /// Отображаем активную программу если есть
                  if (activeProgram != null)
                    GestureDetector(
                      onTap: () {
                        _showProgramDialog(client, activeProgram);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fitness_center, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              activeProgram['title'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (client.hasActiveSubscription)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Активен',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramDialog(client, Map<String, dynamic> activeProgram) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.green, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeProgram['title'],
                            style: const TextStyle(fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ],
                ),
              ),
              
              // Кнопки действий
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/client-program/${client.id}');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3), width: 0.5),
                        ),
                        child: const Text(
                          'Просмотреть программу',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/assign-program/${client.id}');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: const Text(
                          'Заменить программу',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                        ),
                        child: const Text(
                          'Закрыть',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}