import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/config/di/providers.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/subscription.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/logger.dart' hide Logger;
import '../../../../config/di/providers.dart';
import '../../../profile/domain/entities/profile.dart' as profile_entity;
import '../../../../core/theme/premium_theme.dart';

class ClientDetailPage extends ConsumerStatefulWidget {
  final String clientId;
  
  const ClientDetailPage({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends ConsumerState<ClientDetailPage> {
  List<Subscription> _subscriptions = [];
  bool _loadingSubscriptions = true;
  Map<String, dynamic>? _activeProgram;
  bool _isInfoExpanded = false;
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _goalsController;
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _goalsController = TextEditingController();
    
    _loadData();
    _loadSubscriptions();
    _loadActiveProgram();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalsController.dispose();
    super.dispose();
  }
  
  void _initControllers(Client client) {
    _nameController.text = client.fullName;
    _phoneController.text = client.phone ?? '';
    _emailController.text = client.email;
    _ageController.text = client.age?.toString() ?? '';
    _heightController.text = client.height?.toString() ?? '';
    _weightController.text = client.weight?.toString() ?? '';
    _goalsController.text = client.goals?.join(', ') ?? '';
  }
  
  Future<void> _loadData() async {
    // TODO: Загрузить детальную информацию о клиенте
  }
  
  Future<void> _loadSubscriptions() async {
    setState(() => _loadingSubscriptions = true);
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('client_id', widget.clientId)
          .order('created_at', ascending: false);
      
      setState(() {
        _subscriptions = (response as List).map((json) => Subscription.fromJson(json)).toList();
        _loadingSubscriptions = false;
      });
    } catch (e) {
      Logger.error('Error loading subscriptions', error: e);
      setState(() => _loadingSubscriptions = false);
    }
  }
  
  Future<void> _loadActiveProgram() async {
    try {
      final response = await Supabase.instance.client
          .from('client_programs')
          .select('''
            *,
            program:program_id (title, description, duration_weeks, difficulty)
          ''')
          .eq('client_id', widget.clientId)
          .eq('status', 'active')
          .maybeSingle();
      
      if (response != null) {
        setState(() {
          _activeProgram = {
            'id': response['id'],
            'title': response['program']['title'],
            'description': response['program']['description'],
            'duration_weeks': response['program']['duration_weeks'],
            'difficulty': response['program']['difficulty'],
          };
        });
      }
    } catch (e) {
      print('Error loading active program: $e');
    }
  }
  
  Future<void> _deleteActiveProgram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text('Удалить программу', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Вы уверены, что хотите удалить назначенную программу?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      try {
        await Supabase.instance.client
            .from('client_program_exercises')
            .delete()
            .eq('client_program_id', _activeProgram!['id']);
        
        await Supabase.instance.client
            .from('client_programs')
            .delete()
            .eq('id', _activeProgram!['id']);
        
        setState(() {
          _activeProgram = null;
        });
        
        await _refreshHomePage();
        
        if (mounted) {
          Helpers.showSnackBar(context, 'Программа удалена');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
        }
      }
    }
  }
  
  Future<void> _refreshHomePage() async {
    final userId = await _getCurrentUserId();
    if (userId != null) {
      await ref.read(clientsViewModelProvider.notifier).loadClients(userId);
    }
  }
  
  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  Future<void> _saveClientInfo(Client client) async {
    try {
      final updatedClient = Client(
        id: client.id,
        fullName: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text,
        age: _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        height: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
        weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        goals: _goalsController.text.isNotEmpty ? _goalsController.text.split(',').map((e) => e.trim()).toList() : null,
        avatarUrl: client.avatarUrl,
        startDate: client.startDate,
        lastActive: client.lastActive,
        workoutsCompleted: client.workoutsCompleted,
        currentStreak: client.currentStreak,
        hasActiveSubscription: client.hasActiveSubscription,
      );
      
      ref.read(clientsViewModelProvider.notifier).updateClient(updatedClient);
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Информация сохранена'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      Logger.error('Error saving client info', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsState = ref.watch(clientsViewModelProvider);
    
    Client? client;
    for (final c in clientsState.clients) {
      if (c.id == widget.clientId) {
        client = c;
        break;
      }
    }

    if (clientsState.isLoading && client == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (client == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Клиент не найден',
            style: TextStyle(color: Colors.white),
          ),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Клиент не найден',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: const Text(
                      'Назад',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (client != null && _nameController.text.isEmpty) {
      _initControllers(client);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          client!.fullName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Основная информация (аккордеон)
                      PremiumCard(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isInfoExpanded = !_isInfoExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Colors.green, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        client!.fullName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _isInfoExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_isInfoExpanded)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildEditableField(
                                      label: 'Телефон',
                                      controller: _phoneController,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.phone,
                                      hint: 'Не указан',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField(
                                      label: 'Email',
                                      controller: _emailController,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField(
                                      label: 'Возраст',
                                      controller: _ageController,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.number,
                                      hint: 'Не указан',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField(
                                      label: 'Рост',
                                      controller: _heightController,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.number,
                                      hint: 'Не указан',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField(
                                      label: 'Вес',
                                      controller: _weightController,
                                      enabled: _isEditing,
                                      keyboardType: TextInputType.number,
                                      hint: 'Не указан',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField(
                                      label: 'Цели',
                                      controller: _goalsController,
                                      enabled: _isEditing,
                                      hint: 'Не указаны (через запятую)',
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      /// Действия
                      PremiumCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildProgramActionTile(client),
                              
                              _actionTile(
                                icon: Icons.show_chart,
                                title: 'Прогресс клиента',
                                subtitle: 'Графики и замеры',
                                onTap: () {
                                  context.push('/client-progress/${client!.id}', extra: client!.fullName);
                                },
                              ),
                              _actionTile(
                                icon: Icons.message,
                                title: 'Написать сообщение',
                                subtitle: 'Чат с клиентом',
                                onTap: () {
                                  final profile = _createProfileFromClient(client!);
                                  context.push('/chat/${client.id}', extra: profile);
                                },
                              ),
                              _actionTile(
                                icon: Icons.payment,
                                title: 'Управление абонементом',
                                subtitle: 'Продлить, изменить тариф',
                                onTap: () => context.push('/subscriptions?client=${client!.id}'),
                              ),
                              _actionTile(
                                icon: Icons.calendar_today,
                                title: 'Календарь клиента',
                                subtitle: 'Посмотреть расписание',
                                onTap: () => context.push('/calendar?client=${client!.id}'),
                                isLast: true,
                              ),
                            ],
                          ),
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
  
  profile_entity.Profile _createProfileFromClient(Client client) {
    return profile_entity.Profile(
      id: client.id,
      email: client.email,
      fullName: client.fullName,
      role: 'client',
      avatarUrl: client.avatarUrl,
      age: client.age,
      height: client.height,
      weight: client.weight,
      goals: client.goals,
      experienceYears: null,
    );
  }
  
  Widget _buildProgramActionTile(Client client) {
    if (_activeProgram != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 0.5,
            ),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showProgramDialog(client);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.green, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeProgram!['title'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Текущая программа',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
    } else {
      return GestureDetector(
        onTap: () async {
          final result = await context.push('/assign-program/${client.id}');
          if (result == true && mounted) {
            await _loadActiveProgram();
            final userId = await _getCurrentUserId();
            if (userId != null) {
              await ref.read(clientsViewModelProvider.notifier).loadClients(userId);
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.05),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.green, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Назначить программу',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Выбрать программу тренировок',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
      );
    }
  }
  
  void _showProgramDialog(Client client) {
  // Просто переходим на страницу программы клиента
  context.push('/client-program/${client.id}', extra: client.fullName);
}
  Widget _buildWeekSelector(int selectedWeek, int maxWeeks, Function(int) onWeekSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Неделя',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          PopupMenuButton<int>(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.green.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$selectedWeek', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.green, size: 20),
                ],
              ),
            ),
            onSelected: (week) => onWeekSelected(week),
            itemBuilder: (context) {
              return List.generate(maxWeeks, (index) {
                final week = index + 1;
                return PopupMenuItem<int>(
                  value: week,
                  child: Center(
                    child: Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedWeek == week ? Colors.green.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        week.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: selectedWeek == week ? FontWeight.bold : null,
                          color: selectedWeek == week ? Colors.green : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditableExerciseCard(
    Map<String, dynamic> exercise,
    int index,
    int exercisesLength,
    int? expandedIndex,
    Function(int) onTap,
    VoidCallback onEdit,
  ) {
    final isExpanded = expandedIndex == index;
    final isFirst = index == 0;
    final isLast = index == exercisesLength - 1;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          topRight: isFirst && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLast && !isExpanded ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('${index + 1}.', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 14))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(exercise['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white))),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(Icons.edit, color: Colors.grey, size: 18),
                    ),
                  ),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F1115), Color(0xFF1A1D24)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Column(
                children: [
                  Row(children: [
                    const SizedBox(width: 40),
                    const Text('Вес', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        exercise['weight'] != null && exercise['weight'] > 0
                            ? '${exercise['weight']} кг'
                            : 'собственный вес',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const SizedBox(width: 40),
                    const Text('Повторы', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Expanded(child: Text('${exercise['reps']}', style: const TextStyle(fontSize: 14, color: Colors.white))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const SizedBox(width: 40),
                    const Text('Подходы', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Expanded(child: Text('${exercise['sets']}', style: const TextStyle(fontSize: 14, color: Colors.white))),
                  ]),
                  if (exercise['rest_seconds'] != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const SizedBox(width: 40),
                      const Text('Отдых', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Expanded(child: Text('${exercise['rest_seconds']} сек', style: const TextStyle(fontSize: 14, color: Colors.white))),
                    ]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  void _editExercise(Client client, Map<String, dynamic> exercise, StateSetter setStateDialog) async {
    final weightController = TextEditingController(text: exercise['weight']?.toString() ?? '0');
    final repsController = TextEditingController(text: exercise['reps'].toString());
    final setsController = TextEditingController(text: exercise['sets'].toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D24),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 24),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildEditField(controller: weightController, label: 'Вес', unit: 'кг', hint: '0'),
                      const SizedBox(height: 16),
                      _buildEditField(controller: repsController, label: 'Повторы', unit: 'раз', hint: '10'),
                      const SizedBox(height: 16),
                      _buildEditField(controller: setsController, label: 'Подходы', unit: '', hint: '3'),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await Supabase.instance.client
                          .from('client_program_exercises')
                          .update({
                            'weight': double.tryParse(weightController.text) ?? 0,
                            'reps': int.tryParse(repsController.text) ?? 10,
                            'sets': int.tryParse(setsController.text) ?? 3,
                          })
                          .eq('id', exercise['id']);
                      
                      setStateDialog(() {
                        exercise['weight'] = double.tryParse(weightController.text) ?? 0;
                        exercise['reps'] = int.tryParse(repsController.text) ?? 10;
                        exercise['sets'] = int.tryParse(setsController.text) ?? 3;
                      });
                      Navigator.pop(context);
                      if (mounted) {
                        Helpers.showSnackBar(context, 'Упражнение обновлено');
                      }
                    } catch (e) {
                      if (mounted) {
                        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
                      }
                    }
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
                      'Сохранить',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
          ),
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              suffixText: unit.isEmpty ? null : unit,
              suffixStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        enabled
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                ),
                child: TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.text.isEmpty ? (hint ?? '—') : controller.text,
                        style: TextStyle(
                          color: controller.text.isEmpty ? Colors.grey.withOpacity(0.5) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
  
  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.green, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'beginner': return 'Начинающий';
      case 'intermediate': return 'Средний';
      case 'advanced': return 'Продвинутый';
      default: return difficulty;
    }
  }
}