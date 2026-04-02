import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';

class ClientWorkoutPage extends ConsumerStatefulWidget {
  const ClientWorkoutPage({super.key});

  @override
  ConsumerState<ClientWorkoutPage> createState() => _ClientWorkoutPageState();
}

class _ClientWorkoutPageState extends ConsumerState<ClientWorkoutPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _program;
  List<ClientWorkoutExercise> _exercises = [];
  Map<int, Map<int, List<ClientWorkoutExercise>>> _groupedExercises = {};
  List<int> _sortedDays = [];
  int _selectedWeek = 1;
  int _currentDayIndex = 0;
  late PageController _pageController;
  int? _expandedExerciseIndex;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadWorkout();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkout() async {
    setState(() => _isLoading = true);

    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final programResponse = await Supabase.instance.client
          .from('client_programs')
          .select('''
            *,
            program:program_id (id, title, description, duration_weeks, difficulty)
          ''')
          .eq('client_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (programResponse != null && programResponse['program'] != null) {
        final programData = programResponse['program'];
        setState(() {
          _program = {
            'id': programResponse['id'],
            'title': programData['title'],
            'description': programData['description'],
            'duration_weeks': programData['duration_weeks'],
            'difficulty': programData['difficulty'],
          };
        });

        final exercisesResponse = await Supabase.instance.client
            .from('client_program_exercises')
            .select('*')
            .eq('client_program_id', programResponse['id'])
            .order('week_number', ascending: true)
            .order('day_of_week', ascending: true)
            .order('order_index', ascending: true);

        _exercises = (exercisesResponse as List)
            .map((e) => ClientWorkoutExercise.fromJson(e))
            .toList();

        final Set<int> days = {};
        for (var exercise in _exercises) {
          if (!_groupedExercises.containsKey(exercise.weekNumber)) {
            _groupedExercises[exercise.weekNumber] = {};
          }
          if (!_groupedExercises[exercise.weekNumber]!.containsKey(exercise.dayOfWeek)) {
            _groupedExercises[exercise.weekNumber]![exercise.dayOfWeek] = [];
            days.add(exercise.dayOfWeek);
          }
          _groupedExercises[exercise.weekNumber]![exercise.dayOfWeek]!.add(exercise);
        }
        _sortedDays = days.toList()..sort();

        for (var week in _groupedExercises.keys) {
          for (var day in _sortedDays) {
            if (_groupedExercises[week]!.containsKey(day)) {
              _groupedExercises[week]![day]!.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
            }
          }
        }
      }
    } catch (e) {
      print('Error loading workout: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'beginner': return 'Начинающий';
      case 'intermediate': return 'Средний';
      case 'advanced': return 'Продвинутый';
      default: return difficulty;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDayNameShort(int day) {
    switch (day) {
      case 1: return 'ПН';
      case 2: return 'ВТ';
      case 3: return 'СР';
      case 4: return 'ЧТ';
      case 5: return 'ПТ';
      case 6: return 'СБ';
      case 7: return 'ВС';
      default: return '';
    }
  }

  Widget _buildWeekSelector() {
    final maxWeeks = _program?['duration_weeks'] ?? 4;

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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
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
                  Text(
                    '$_selectedWeek',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.green, size: 20),
                ],
              ),
            ),
            onSelected: (week) {
              setState(() {
                _selectedWeek = week;
                _currentDayIndex = 0;
                _pageController.jumpToPage(0);
                _expandedExerciseIndex = null;
              });
            },
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
                        color: _selectedWeek == week
                            ? Colors.green.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        week.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedWeek == week ? FontWeight.bold : null,
                          color: _selectedWeek == week ? Colors.green : Colors.white,
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

  // ✅ Табы дней с белой линией и бегающей зеленой полоской
  Widget _buildDayTabs() {
    final weekExercises = _groupedExercises[_selectedWeek] ?? {};
    final daysWithExercises = _sortedDays.where((day) => weekExercises.containsKey(day)).toList();

    if (daysWithExercises.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(daysWithExercises.length, (index) {
              final day = daysWithExercises[index];
              final isActive = _currentDayIndex == index;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentDayIndex = index;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      _expandedExerciseIndex = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _getDayNameShort(day),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Белая линия с зеленой полоской
        Stack(
          children: [
            // Белая линия (фон)
            Container(
              height: 2,
              color: Colors.white.withOpacity(0.1),
            ),
            // Зеленая полоска (бегает)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width / daysWithExercises.length,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
              transform: Matrix4.translationValues(
                _currentDayIndex * (MediaQuery.of(context).size.width / daysWithExercises.length),
                0,
                0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCarousel() {
    final weekExercises = _groupedExercises[_selectedWeek] ?? {};
    final daysWithExercises = _sortedDays.where((day) => weekExercises.containsKey(day)).toList();

    if (daysWithExercises.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'В этой неделе нет тренировок',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentDayIndex = index;
            _expandedExerciseIndex = null;
          });
        },
        itemCount: daysWithExercises.length,
        itemBuilder: (context, index) {
          final day = daysWithExercises[index];
          final exercises = weekExercises[day] ?? [];

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: exercises.length,
            itemBuilder: (context, exerciseIndex) {
              final isFirst = exerciseIndex == 0;
              final isLast = exerciseIndex == exercises.length - 1;
              return _buildExerciseCard(
                exercises[exerciseIndex],
                exerciseIndex,
                exercises.length,
                isFirst,
                isLast,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    ClientWorkoutExercise exercise,
    int index,
    int exercisesLength,
    bool isFirst,
    bool isLast,
  ) {
    final isExpanded = _expandedExerciseIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(12) : Radius.zero,
          topRight: isFirst ? const Radius.circular(12) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_expandedExerciseIndex == index) {
                  _expandedExerciseIndex = null;
                } else {
                  _expandedExerciseIndex = index;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
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
                  bottomLeft: isLast ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      const Text('Вес', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          exercise.weight != null && exercise.weight! > 0
                              ? '${exercise.weight!.toInt()} кг'
                              : 'собственный вес',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      const Text('Повторы', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${exercise.reps}',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 40),
                      const Text('Подходы', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${exercise.sets}',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  if (exercise.restSeconds != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 40),
                        const Text('Отдых', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '${exercise.restSeconds} сек',
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (_program == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Моя тренировка',
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
                Icon(
                  Icons.fitness_center,
                  size: 80,
                  color: Colors.grey.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Нет активной тренировки',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Тренер назначит программу',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Моя тренировка',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Название программы
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _program!['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Сложность и недели
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(_program!['difficulty']).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: _getDifficultyColor(_program!['difficulty']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDifficultyText(_program!['difficulty']),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getDifficultyColor(_program!['difficulty']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${_program!['duration_weeks']} недель',
                          style: const TextStyle(fontSize: 11, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Выбор недели
            _buildWeekSelector(),
            
            // Табы дней с белой линией и бегающей зеленой полоской
            _buildDayTabs(),
            
            const SizedBox(height: 16),
            
            // Список упражнений без отступов
            Expanded(
              child: _buildDayCarousel(),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Класс для упражнений клиента
class ClientWorkoutExercise {
  final String id;
  final String clientProgramId;
  final String templateExerciseId;
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final int orderIndex;
  final int dayOfWeek;
  final int weekNumber;
  final int? restSeconds;
  final String? notes;
  final DateTime? completedAt;
  final bool isCompleted;

  const ClientWorkoutExercise({
    required this.id,
    required this.clientProgramId,
    required this.templateExerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight,
    required this.orderIndex,
    required this.dayOfWeek,
    required this.weekNumber,
    this.restSeconds,
    this.notes,
    this.completedAt,
    this.isCompleted = false,
  });

  factory ClientWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return ClientWorkoutExercise(
      id: json['id'],
      clientProgramId: json['client_program_id'],
      templateExerciseId: json['template_exercise_id'],
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      orderIndex: json['order_index'],
      dayOfWeek: json['day_of_week'],
      weekNumber: json['week_number'],
      restSeconds: json['rest_seconds'],
      notes: json['notes'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}