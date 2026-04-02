import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../progress/presentation/pages/progress_page.dart';
import '../../../client/presentation/pages/client_subscription_page.dart';
import '../../../chat/presentation/pages/chat_list_page.dart';
import '../../../client/presentation/pages/client_schedule_page.dart';
import '../../../client/presentation/pages/client_workout_page.dart';

class ClientHomePage extends ConsumerStatefulWidget {
  const ClientHomePage({super.key});

  @override
  ConsumerState<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends ConsumerState<ClientHomePage> {
  bool _isLoading = true;
  String? _clientName;
  Map<String, dynamic>? _activeProgram;
  
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadClientName();
    _loadActiveWorkout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isFirstLoad) {
      _loadActiveWorkout();
    }
    _isFirstLoad = false;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    setState(() => _isLoading = false);
  }

  Future<void> _loadClientName() async {
    final userId = await _getCurrentUserId();
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          _clientName = response['full_name']?.split(' ').first ?? 'Клиент';
        });
      }
    }
  }

  Future<void> _loadActiveWorkout() async {
    final userId = await _getCurrentUserId();
    print('=== LOAD ACTIVE WORKOUT ===');
    print('Client ID: $userId');
    
    if (userId != null) {
      final clientProgram = await Supabase.instance.client
          .from('client_programs')
          .select('''
            *,
            program:program_id (
              id, title, description, duration_weeks, difficulty
            )
          ''')
          .eq('client_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      
      print('Client program: $clientProgram');
      
      if (clientProgram != null && clientProgram['program'] != null) {
        final program = clientProgram['program'];
        print('Program title: ${program['title']}');
        if (mounted) {
          setState(() {
            _activeProgram = {
              'title': program['title'],
              'id': clientProgram['id'],
              'program_id': program['id'],
              'description': program['description'],
              'duration_weeks': program['duration_weeks'],
              'difficulty': program['difficulty'],
            };
          });
        }
      } else {
        print('No active program found');
        if (mounted) {
          setState(() {
            _activeProgram = null;
          });
        }
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD: _activeProgram = $_activeProgram');
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1115),
              Color(0xFF1A1D24),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      
                      Text(
                        _clientName != null ? 'Привет, $_clientName 👋' : 'Привет 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _actionTile(
                        icon: Icons.fitness_center,
                        title: 'Моя тренировка',
                        subtitle: _activeProgram != null 
                            ? _activeProgram!['title'] 
                            : 'Нет активной программы',
                        onTap: () async {
                          if (_activeProgram != null) {
                            print('Navigating to client-workout, program: ${_activeProgram!['title']}');
                            await context.push('/client-workout');
                            _loadActiveWorkout();
                          } else {
                            print('No program, showing snackbar');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Тренировка не назначена'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.zero,
                          bottomRight: Radius.zero,
                        ),
                        showChevron: _activeProgram != null,
                      ),

                      _actionTile(
                        icon: Icons.show_chart,
                        title: 'Прогресс и замеры',
                        subtitle: 'Отслеживайте свой прогресс',
                        onTap: () => context.push('/progress'),
                        borderRadius: BorderRadius.zero,
                      ),

                      _actionTile(
                        icon: Icons.payment,
                        title: 'Абонемент',
                        subtitle: 'Информация о вашем абонементе',
                        onTap: () => context.push('/client-subscription'),
                        borderRadius: BorderRadius.zero,
                      ),

                      _actionTile(
                        icon: Icons.message,
                        title: 'Сообщения',
                        subtitle: 'Чат с тренером',
                        onTap: () => context.push('/chat-list'),
                        borderRadius: BorderRadius.zero,
                      ),

                      _actionTile(
                        icon: Icons.calendar_today,
                        title: 'Расписание',
                        subtitle: 'Ваши тренировки',
                        onTap: () => context.push('/client-schedule'),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.zero,
                          topRight: Radius.zero,
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
    bool showChevron = true,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showChevron)
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
}