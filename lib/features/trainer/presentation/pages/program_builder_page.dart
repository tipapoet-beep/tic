// lib/features/trainer/presentation/pages/program_builder_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/template_exercise.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/keyboard_utils.dart';
import '../../../../core/theme/premium_theme.dart';

class ProgramBuilderPage extends ConsumerStatefulWidget {
  final String? templateId;
  final bool readOnly;
  
  const ProgramBuilderPage({
    super.key, 
    this.templateId,
    this.readOnly = false,
  });

  @override
  ConsumerState<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends ConsumerState<ProgramBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _difficulty = 'intermediate';
  int _durationWeeks = 4;
  bool _isPublic = false;
  bool _isLoading = false;
  bool _isEditing = false;
  int _currentStep = 0;
  int _selectedWeek = 1;
  int? _expandedExerciseIndex;
  List<int> _selectedDays = [1, 3, 5];
  
  final Map<int, Map<int, List<TemplateExercise>>> _exercises = {};
  final List<String> _difficultyLevels = const ['beginner', 'intermediate', 'advanced'];
  
  // Контроллер для нового упражнения
  final TextEditingController _newExerciseController = TextEditingController();
  String? _newExerciseName;
  int? _newExerciseWeek;
  int? _newExerciseDay;
  bool _showNewExerciseInput = false;
  
  final FocusNode _newExerciseFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.templateId != null;
    
    if (_isEditing) {
      _loadTemplate();
    } else {
      _initEmptyStructure();
    }
    
    // Добавляем слушатель для скролла при открытии клавиатуры
    _newExerciseFocusNode.addListener(() {
      if (_newExerciseFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _initEmptyStructure() {
    for (var week = 1; week <= _durationWeeks; week++) {
      _exercises[week] = {};
      for (var day in _selectedDays) {
        _exercises[week]![day] = [];
      }
    }
  }
  
  Future<void> _loadTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.templateId == null) return;

      final response = await Supabase.instance.client
          .from('workout_templates')
          .select('*, template_exercises(*)')
          .eq('id', widget.templateId!)
          .single();

      final template = WorkoutTemplate.fromJson(response);
      final exercises = (response['template_exercises'] as List)
          .map((e) => TemplateExercise.fromJson(e))
          .toList();

      _titleController.text = template.title;
      _descriptionController.text = template.description ?? '';
      _difficulty = template.difficulty;
      _durationWeeks = template.durationWeeks;
      _isPublic = template.isPublic;
      
      final Set<int> days = {};
      for (var exercise in exercises) {
        days.add(exercise.dayOfWeek);
      }
      _selectedDays = days.toList()..sort();

      for (var week = 1; week <= _durationWeeks; week++) {
        _exercises[week] = {};
        for (var day in _selectedDays) {
          _exercises[week]![day] = exercises
              .where((e) => e.weekNumber == week && e.dayOfWeek == day)
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        }
      }
      
      _selectedWeek = 1;
      setState(() {});
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка загрузки программы', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newExerciseController.dispose();
    _newExerciseFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  

  void _startAddExercise(int week, int day) {
  print('🔵 [ADD EXERCISE] ========== START ==========');
  print('🔵 [ADD EXERCISE] Called with week: $week, day: $day');
  print('🔵 [ADD EXERCISE] Current _showNewExerciseInput: $_showNewExerciseInput');
  print('🔵 [ADD EXERCISE] Current _newExerciseWeek: $_newExerciseWeek');
  print('🔵 [ADD EXERCISE] Current _newExerciseDay: $_newExerciseDay');
  
  setState(() {
    print('🔵 [ADD EXERCISE] Inside setState');
    _newExerciseWeek = week;
    _newExerciseDay = day;
    _showNewExerciseInput = true;
    _newExerciseController.clear();
    print('🔵 [ADD EXERCISE] After assignment - week: $_newExerciseWeek, day: $_newExerciseDay, show: $_showNewExerciseInput');
  });
  
  print('🔵 [ADD EXERCISE] After setState');
  
  Future.delayed(const Duration(milliseconds: 100), () {
    print('🔵 [ADD EXERCISE] Requesting focus');
    _newExerciseFocusNode.requestFocus();
    _scrollToBottom();
  });
  
  print('🔵 [ADD EXERCISE] ========== END ==========');
}

void _confirmAddExercise() {
  print('🟢 [CONFIRM ADD] ========== START ==========');
  print('🟢 [CONFIRM ADD] Called');
  final name = _newExerciseController.text.trim();
  print('🟢 [CONFIRM ADD] Exercise name: "$name"');
  
  if (name.isEmpty) {
    print('🟢 [CONFIRM ADD] Name is empty - showing error');
    Helpers.showSnackBar(context, 'Введите название упражнения', isError: true);
    return;
  }
  
  if (_newExerciseWeek == null || _newExerciseDay == null) {
    print('🟢 [CONFIRM ADD] Invalid week or day - week: $_newExerciseWeek, day: $_newExerciseDay');
    return;
  }
  
  print('🟢 [CONFIRM ADD] Adding exercise to week: $_newExerciseWeek, day: $_newExerciseDay');
  final currentCount = _exercises[_newExerciseWeek]?[_newExerciseDay]?.length ?? 0;
  print('🟢 [CONFIRM ADD] Current exercises count: $currentCount');
  
  setState(() {
    print('🟢 [CONFIRM ADD] Inside setState');
    final exercise = TemplateExercise(
      id: const Uuid().v4(),
      templateId: widget.templateId ?? '',
      name: name,
      orderIndex: currentCount,
      dayOfWeek: _newExerciseDay!,
      weekNumber: _newExerciseWeek!,
      restSeconds: 60,
    );
    _exercises[_newExerciseWeek]![_newExerciseDay]!.add(exercise);
    
    print('🟢 [CONFIRM ADD] Exercise added, new count: ${_exercises[_newExerciseWeek]![_newExerciseDay]!.length}');
    
    _showNewExerciseInput = false;
    _newExerciseWeek = null;
    _newExerciseDay = null;
    _newExerciseController.clear();
    print('🟢 [CONFIRM ADD] State cleared');
  });
  
  print('🟢 [CONFIRM ADD] ========== END ==========');
}

void _cancelAddExercise() {
  print('🔴 [CANCEL ADD] ========== START ==========');
  print('🔴 [CANCEL ADD] Called');
  setState(() {
    _showNewExerciseInput = false;
    _newExerciseWeek = null;
    _newExerciseDay = null;
    _newExerciseController.clear();
  });
  _newExerciseFocusNode.unfocus();
  print('🔴 [CANCEL ADD] State cleared');
  print('🔴 [CANCEL ADD] ========== END ==========');
}
  
  void _removeExercise(int week, int day, int index) {
    if (widget.readOnly) return;
    
    setState(() {
      _exercises[week]![day]!.removeAt(index);
      for (var i = 0; i < _exercises[week]![day]!.length; i++) {
        _exercises[week]![day]![i] = _exercises[week]![day]![i].copyWith(orderIndex: i);
      }
      if (_expandedExerciseIndex == index) {
        _expandedExerciseIndex = null;
      } else if (_expandedExerciseIndex != null && _expandedExerciseIndex! > index) {
        _expandedExerciseIndex = _expandedExerciseIndex! - 1;
      }
    });
  }
  
  void _updateExercise(int week, int day, int index, TemplateExercise exercise) {
    if (widget.readOnly) return;
    
    setState(() {
      _exercises[week]![day]![index] = exercise;
    });
  }
  
  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) {
      Helpers.showSnackBar(context, 'Введите название программы', isError: true);
      return false;
    }
    if (_durationWeeks < 1) {
      Helpers.showSnackBar(context, 'Количество недель должно быть больше 0', isError: true);
      return false;
    }
    if (_selectedDays.isEmpty) {
      Helpers.showSnackBar(context, 'Выберите хотя бы один день тренировок', isError: true);
      return false;
    }
    return true;
  }
  
  bool _validateStep2() {
    bool hasExercises = false;
    for (final week in _exercises.values) {
      for (final day in week.values) {
        if (day.isNotEmpty) {
          hasExercises = true;
          break;
        }
      }
    }
    
    if (!hasExercises) {
      Helpers.showSnackBar(context, 'Добавьте хотя бы одно упражнение', isError: true);
      return false;
    }
    return true;
  }
  
  Future<void> _saveTemplate() async {
    if (!_validateStep2()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Ошибка авторизации', isError: true);
        }
        return;
      }
      
      final allExercises = <TemplateExercise>[];
      for (var week = 1; week <= _durationWeeks; week++) {
        for (var day in _selectedDays) {
          final dayExercises = _exercises[week]?[day];
          if (dayExercises != null) {
            allExercises.addAll(dayExercises);
          }
        }
      }
      
      final template = WorkoutTemplate(
        id: _isEditing ? widget.templateId! : const Uuid().v4(),
        trainerId: userId,
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        difficulty: _difficulty,
        durationWeeks: _durationWeeks,
        isPublic: _isPublic,
        exercises: allExercises,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      if (_isEditing) {
        await Supabase.instance.client
            .from('workout_templates')
            .update(template.toJson())
            .eq('id', template.id);

        await Supabase.instance.client
            .from('template_exercises')
            .delete()
            .eq('template_id', template.id);

        for (final exercise in allExercises) {
          await Supabase.instance.client
              .from('template_exercises')
              .insert(exercise.toJson());
        }

        if (mounted) {
          Helpers.showSnackBar(context, 'Программа обновлена');
        }
      } else {
        final templateResponse = await Supabase.instance.client
            .from('workout_templates')
            .insert(template.toJson())
            .select()
            .single();

        for (final exercise in allExercises) {
          await Supabase.instance.client
              .from('template_exercises')
              .insert({
                ...exercise.toJson(),
                'template_id': templateResponse['id'],
              });
        }

        if (mounted) {
          Helpers.showSnackBar(context, 'Программа создана');
        }
      }
      
      await ref.read(templatesViewModelProvider.notifier).loadTemplates(userId);
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session?.user.id;
    } catch (e) {
      return null;
    }
  }
  
  String _getDayNameShort(int day) {
    switch (day) {
      case 1: return 'Пн';
      case 2: return 'Вт';
      case 3: return 'Ср';
      case 4: return 'Чт';
      case 5: return 'Пт';
      case 6: return 'Сб';
      case 7: return 'Вс';
      default: return '';
    }
  }
  
  Widget _buildWeekSelector() {
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
                  colors: [
                    Color(0xFF1A1D24),
                    Color(0xFF22262F),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 0.5,
                ),
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
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.green,
                    size: 20,
                  ),
                ],
              ),
            ),
            onSelected: (int week) {
              setState(() {
                _selectedWeek = week;
                _expandedExerciseIndex = null;
              });
            },
            itemBuilder: (context) {
              return List.generate(_durationWeeks, (index) {
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
  
  Widget _buildAddExerciseRow(int week, int day) {
    if (_showNewExerciseInput && _newExerciseWeek == week && _newExerciseDay == day) {
      return Container(
        margin: const EdgeInsets.only(left: 16, top: 12, bottom: 16, right: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: _newExerciseController,
                  focusNode: _newExerciseFocusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Название упражнения...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _confirmAddExercise(),
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _scrollToBottom();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _cancelAddExercise,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _confirmAddExercise,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 16),
      child: GestureDetector(
        onTap: () => _startAddExercise(week, day),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            const Text('Добавить упражнение', style: TextStyle(fontSize: 13, color: Colors.green)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEditWeek() {
  final weekExercises = _exercises[_selectedWeek] ?? {};
  final daysWithExercises = _selectedDays.where((day) => weekExercises.containsKey(day)).toList();
  
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
  
  int currentDayIndex = 0;
  PageController pageController = PageController(initialPage: 0);
  
  return StatefulBuilder(
    builder: (context, setStateLocal) {
      return Column(
        children: [
          // Табы дней
          _buildEditDayTabs(
            daysWithExercises: daysWithExercises,
            currentDayIndex: currentDayIndex,
            onDaySelected: (index) {
              setStateLocal(() {
                currentDayIndex = index;
                pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Карусель дней
          SizedBox(
            height: MediaQuery.of(context).size.height - 350,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setStateLocal(() {
                  currentDayIndex = index;
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
                      _selectedWeek, 
                      day, 
                      exerciseIndex, 
                      exercises[exerciseIndex],
                      isFirst,
                      isLast,
                    );
                  },
                );
              },
            ),
          ),
          
          // Кнопка "Добавить упражнение"
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => _startAddExercise(_selectedWeek, daysWithExercises[currentDayIndex]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Добавить упражнение',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildEditDayTabs({
  required List<int> daysWithExercises,
  required int currentDayIndex,
  required Function(int) onDaySelected,
}) {
  final dayNames = {
    1: 'ПН', 2: 'ВТ', 3: 'СР', 4: 'ЧТ', 5: 'ПТ', 6: 'СБ', 7: 'ВС',
  };
  
  return Column(
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(daysWithExercises.length, (index) {
            final day = daysWithExercises[index];
            final isActive = currentDayIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onDaySelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dayNames[day]!,
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
      Stack(
        children: [
          Container(
            height: 2,
            color: Colors.white.withOpacity(0.1),
          ),
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
              currentDayIndex * (MediaQuery.of(context).size.width / daysWithExercises.length),
              0,
              0,
            ),
          ),
        ],
      ),
    ],
  );
}
  
  Widget _buildExerciseCard(
  int week, 
  int day, 
  int index, 
  TemplateExercise exercise,
  bool isFirst,
  bool isLast,
) {
  final TextEditingController _editController = TextEditingController(text: exercise.name);
  final FocusNode _editFocusNode = FocusNode();
  bool _isEditing = false;
  
  return StatefulBuilder(
    builder: (context, setStateCard) {
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
                child: _isEditing
                    ? TextFormField(
                        controller: _editController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Название упражнения',
                          hintStyle: TextStyle(color: Colors.grey),
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onFieldSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _updateExercise(
                              week, day, index,
                              exercise.copyWith(name: value.trim()),
                            );
                          }
                          setStateCard(() => _isEditing = false);
                        },
                      )
                    : Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isEditing) {
                    // Сохраняем изменения
                    final newName = _editController.text.trim();
                    if (newName.isNotEmpty) {
                      _updateExercise(
                        week, day, index,
                        exercise.copyWith(name: newName),
                      );
                    }
                    setStateCard(() => _isEditing = false);
                  } else {
                    // Редактируем
                    _editController.text = exercise.name;
                    setStateCard(() => _isEditing = true);
                    _editFocusNode.requestFocus();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(left: 8),
                  child: Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: _isEditing ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeExercise(week, day, index),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  
  Widget _buildStep1() {
  return KeyboardUtils.wrapWithDismissGesture(
    child: PremiumBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Название программы
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Название',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                    child: TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Например: Программа на массу',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Введите название';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Описание
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Описание',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Необязательно',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Сложность
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Сложность',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      dropdownColor: const Color(0xFF1A1D24),
                      items: _difficultyLevels.map((level) {
                        return DropdownMenuItem(
                          value: level,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(level),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getDifficultyText(level)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _difficulty = value!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Количество недель
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Количество недель',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                    child: TextFormField(
                      initialValue: _durationWeeks.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '4',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _durationWeeks = int.tryParse(value) ?? 4;
                          _initEmptyStructure();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Дни тренировок
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дни тренировок',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final isSelected = _selectedDays.contains(day);
                      final dayNames = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                              _selectedDays.sort();
                            }
                            _initEmptyStructure();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            dayNames[index],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.green : Colors.grey,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Информационное сообщение
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.green, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: const Text(
                        'Вес, повторы и подходы можно будет настроить при назначении программы клиенту',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Публичная программа
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 0.5,
                  ),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Публичная программа',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Доступна всем тренерам',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: _isPublic,
                  activeColor: Colors.green,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Кнопка "Далее"
              GestureDetector(
                onTap: () {
                  if (_validateStep1()) setState(() => _currentStep = 1);
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
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Text(
                    'Далее →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}
  
  Widget _buildStep2() {
  return KeyboardUtils.wrapWithDismissGesture(
    child: PremiumBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Название программы (по центру, без иконки)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                _titleController.text.isNotEmpty
                    ? _titleController.text
                    : 'Новая программа',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Сложность и недели (под названием)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(_difficulty).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 12,
                        color: _getDifficultyColor(_difficulty),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getDifficultyText(_difficulty),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getDifficultyColor(_difficulty),
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
                        '$_durationWeeks недель',
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
          
          // Карусель дней и список упражнений
          Expanded(
            child: _buildEditWeekWithAddButton(),
          ),
          
          const SizedBox(height: 20),
          
          // Кнопки "Назад" и "Сохранить"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentStep = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: const Text(
                        '← Назад',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _saveTemplate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Сохранить',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _buildEditWeekWithAddButton() {
  print('🏗️ [BUILD] Building edit week with add button');
  final weekExercises = _exercises[_selectedWeek] ?? {};
  final daysWithExercises = _selectedDays.where((day) => weekExercises.containsKey(day)).toList();
  
  print('🏗️ [BUILD] Selected week: $_selectedWeek');
  print('🏗️ [BUILD] Days with exercises: $daysWithExercises');
  
  if (daysWithExercises.isEmpty) {
    print('🏗️ [BUILD] No exercises - showing empty state');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'В этой неделе нет тренировок',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              print('👆 [TAP] Empty state add button clicked');
              final day = _selectedDays.isNotEmpty ? _selectedDays.first : 1;
              _startAddExercise(_selectedWeek, day);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Добавить упражнение',
                    style: TextStyle(fontSize: 13, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int currentDayIndex = 0;
  PageController pageController = PageController(initialPage: 0);
  
  print('🏗️ [BUILD] Building with ${daysWithExercises.length} days');
  
  return StatefulBuilder(
    builder: (context, setStateLocal) {
      return Column(
        children: [
          // Табы дней
          _buildEditDayTabs(
            daysWithExercises: daysWithExercises,
            currentDayIndex: currentDayIndex,
            onDaySelected: (index) {
              print('👆 [TAP] Day tab clicked: index $index');
              setStateLocal(() {
                currentDayIndex = index;
                pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Карусель дней
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                print('📄 [PAGE] Page changed to: $index');
                setStateLocal(() {
                  currentDayIndex = index;
                });
              },
              itemCount: daysWithExercises.length,
              itemBuilder: (context, index) {
                final day = daysWithExercises[index];
                final exercises = weekExercises[day] ?? [];
                final showInput = _showNewExerciseInput && 
                    _newExerciseWeek == _selectedWeek && 
                    _newExerciseDay == day;
                
                print('📄 [PAGE] Building day $day with ${exercises.length} exercises, showInput: $showInput');
                
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: exercises.length + 1,
                  itemBuilder: (context, exerciseIndex) {
                    // Если показываем поле ввода
                    if (exerciseIndex == exercises.length && showInput) {
                      print('📝 [INPUT] Rendering input field for day $day');
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _newExerciseController,
                                focusNode: _newExerciseFocusNode,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Название упражнения...',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onSubmitted: (_) => _confirmAddExercise(),
                              ),
                            ),
                            GestureDetector(
                              onTap: _cancelAddExercise,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.close, color: Colors.red, size: 20),
                              ),
                            ),
                            GestureDetector(
                              onTap: _confirmAddExercise,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: const Icon(Icons.check, color: Colors.green, size: 20),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    // Если это последний элемент — показываем кнопку добавления
                    if (exerciseIndex == exercises.length && !showInput) {
                      print('🔘 [BUTTON] Rendering add button for day $day');
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: GestureDetector(
                            onTap: () {
                              print('👆 [TAP] Add button clicked for week $_selectedWeek, day $day');
                              _startAddExercise(_selectedWeek, day);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Добавить упражнение',
                                    style: TextStyle(fontSize: 14, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final exercise = exercises[exerciseIndex];
                    final isFirst = exerciseIndex == 0;
                    final isLast = exerciseIndex == exercises.length - 1;
                    return _buildExerciseCard(
                      _selectedWeek, 
                      day, 
                      exerciseIndex, 
                      exercise,
                      isFirst,
                      isLast,
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          widget.readOnly 
              ? _titleController.text.isNotEmpty ? _titleController.text : 'Просмотр программы'
              : (_isEditing ? 'Редактировать программу' : 'Создать программу'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.readOnly)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => context.push('/edit-template/${widget.templateId}'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : widget.readOnly
              ? _buildReadOnlyView()
              : _currentStep == 0
                  ? _buildStep1()
                  : PremiumBackground(child: _buildStep2()),
    );
  }
  
  Widget _buildReadOnlyView() {
  // Группируем упражнения по неделям и дням
  final grouped = <int, Map<int, List<TemplateExercise>>>{};
  final days = <int>{};
  
  for (var exercise in _exercises.values.expand((week) => week.values.expand((day) => day))) {
    if (!grouped.containsKey(exercise.weekNumber)) {
      grouped[exercise.weekNumber] = {};
    }
    if (!grouped[exercise.weekNumber]!.containsKey(exercise.dayOfWeek)) {
      grouped[exercise.weekNumber]![exercise.dayOfWeek] = [];
      days.add(exercise.dayOfWeek);
    }
    grouped[exercise.weekNumber]![exercise.dayOfWeek]!.add(exercise);
  }
  
  final sortedDays = days.toList()..sort();
  
  for (var week in grouped.keys) {
    for (var day in sortedDays) {
      if (grouped[week]!.containsKey(day)) {
        grouped[week]![day]!.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }
    }
  }
  
  int selectedWeek = 1;
  int currentDayIndex = 0;
  PageController pageController = PageController(initialPage: 0);
  int? expandedIndex;
  
  return StatefulBuilder(
    builder: (context, setStateReadOnly) {
      final weekExercises = grouped[selectedWeek] ?? {};
      final daysWithExercises = sortedDays.where((day) => weekExercises.containsKey(day)).toList();
      
      return Container(
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
                _titleController.text,
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
                      color: _getDifficultyColor(_difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 12,
                          color: _getDifficultyColor(_difficulty),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getDifficultyText(_difficulty),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getDifficultyColor(_difficulty),
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
                          '$_durationWeeks недель',
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
            _buildReadOnlyWeekSelector(selectedWeek, _durationWeeks, (week) {
              setStateReadOnly(() {
                selectedWeek = week;
                currentDayIndex = 0;
                pageController.jumpToPage(0);
                expandedIndex = null;
              });
            }),
            
            // Табы дней
            _buildReadOnlyDayTabs(
              daysWithExercises: daysWithExercises,
              currentDayIndex: currentDayIndex,
              onDaySelected: (index) {
                setStateReadOnly(() {
                  currentDayIndex = index;
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  expandedIndex = null;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Карусель дней
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  setStateReadOnly(() {
                    currentDayIndex = index;
                    expandedIndex = null;
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
                      return _buildReadOnlyExerciseCard(
                        exercises[exerciseIndex],
                        exerciseIndex,
                        exercises.length,
                        expandedIndex,
                        (idx) {
                          setStateReadOnly(() {
                            if (expandedIndex == idx) {
                              expandedIndex = null;
                            } else {
                              expandedIndex = idx;
                            }
                          });
                        },
                        isFirst,
                        isLast,
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildReadOnlyWeekSelector(int selectedWeek, int maxWeeks, Function(int) onWeekSelected) {
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
                  '$selectedWeek',
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
                      color: selectedWeek == week
                          ? Colors.green.withOpacity(0.15)
                          : Colors.transparent,
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

Widget _buildReadOnlyDayTabs({
  required List<int> daysWithExercises,
  required int currentDayIndex,
  required Function(int) onDaySelected,
}) {
  if (daysWithExercises.isEmpty) return const SizedBox.shrink();
  
  final dayNames = {
    1: 'ПН', 2: 'ВТ', 3: 'СР', 4: 'ЧТ', 5: 'ПТ', 6: 'СБ', 7: 'ВС',
  };
  
  return Column(
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(daysWithExercises.length, (index) {
            final day = daysWithExercises[index];
            final isActive = currentDayIndex == index;
            
            return Expanded(
              child: GestureDetector(
                onTap: () => onDaySelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    dayNames[day]!,
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
      Stack(
        children: [
          Container(
            height: 2,
            color: Colors.white.withOpacity(0.1),
          ),
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
              currentDayIndex * (MediaQuery.of(context).size.width / daysWithExercises.length),
              0,
              0,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildReadOnlyExerciseCard(
  TemplateExercise exercise,
  int index,
  int exercisesLength,
  int? expandedIndex,
  Function(int) onTap,
  bool isFirst,
  bool isLast,
) {
  final isExpanded = expandedIndex == index;

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
          onTap: () => onTap(index),
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
                    const Text('Отдых', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${exercise.restSeconds ?? 60} сек',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
  

  String _getDifficultyText(String level) {
    switch (level) {
      case 'beginner': return 'Начинающий';
      case 'intermediate': return 'Средний';
      case 'advanced': return 'Продвинутый';
      default: return level;
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

  String _getDayName(int day) {
    switch (day) {
      case 1: return 'Понедельник';
      case 2: return 'Вторник';
      case 3: return 'Среда';
      case 4: return 'Четверг';
      case 5: return 'Пятница';
      case 6: return 'Суббота';
      case 7: return 'Воскресенье';
      default: return 'День $day';
    }
  }
}

// Класс для премиум текстового поля (если нет в общих виджетах)
class PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? initialValue;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;
  
  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.initialValue,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final textController = controller ?? TextEditingController(text: initialValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1D24),
                Color(0xFF22262F),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: TextFormField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.green, size: 20)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}