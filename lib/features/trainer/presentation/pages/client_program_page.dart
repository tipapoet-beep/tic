import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/client_workout_exercise.dart';
import '../../../../core/theme/premium_theme.dart';

class ClientProgramPage extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  
  const ClientProgramPage({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<ClientProgramPage> createState() => _ClientProgramPageState();
}

class _ClientProgramPageState extends ConsumerState<ClientProgramPage> {
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
    _loadClientProgram();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadClientProgram() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .from('client_programs')
          .select('''
            *,
            program:program_id (
              id, title, description, duration_weeks, difficulty
            )
          ''')
          .eq('client_id', widget.clientId)
          .eq('status', 'active')
          .maybeSingle();

      if (response != null && response['program'] != null) {
        final programData = response['program'];
        setState(() {
          _program = {
            'id': response['id'],
            'title': programData['title'],
            'description': programData['description'],
            'duration_weeks': programData['duration_weeks'],
            'difficulty': programData['difficulty'],
          };
        });

        final exercisesResponse = await Supabase.instance.client
            .from('client_program_exercises')
            .select('*')
            .eq('client_program_id', response['id'])
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
      print('❌ Ошибка загрузки программы: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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

  // ✅ Табы дней с белой линией и бегающей зеленой полоской (как у клиента)
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
                  // Кнопка редактирования для тренера
                  GestureDetector(
                    onTap: () => _editExercise(exercise),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(Icons.edit, color: Colors.grey, size: 18),
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

  void _editExercise(ClientWorkoutExercise exercise) async {
    final weightController = TextEditingController(text: exercise.weight?.toString() ?? '0');
    final repsController = TextEditingController(text: exercise.reps.toString());
    final setsController = TextEditingController(text: exercise.sets.toString());
    
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
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
                          .eq('id', exercise.id);
                      
                      Navigator.pop(context);
                      _loadClientProgram();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Упражнение обновлено'), backgroundColor: Colors.green),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                        );
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
          title: Text(
            widget.clientName,
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
                  'У клиента нет активной программы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Назначьте программу в карточке клиента',
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
                      'Закрыть',
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
        title: Text(
          widget.clientName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
            
            // Список упражнений без отступов с каруселью
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