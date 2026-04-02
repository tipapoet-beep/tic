import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/template_exercise.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/premium_theme.dart';

class AssignProgramPage extends ConsumerStatefulWidget {
  final String clientId;
  
  const AssignProgramPage({super.key, required this.clientId});

  @override
  ConsumerState<AssignProgramPage> createState() => _AssignProgramPageState();
}

class _AssignProgramPageState extends ConsumerState<AssignProgramPage> {
  WorkoutTemplate? _selectedTemplate;
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;
  bool _isSaving = false;
  
  final Map<String, Map<String, dynamic>> _exerciseSettings = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }
  
  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    final userId = await _getCurrentUserId();
    if (userId != null) {
      await ref.read(templatesViewModelProvider.notifier).loadTemplates(userId);
    }
    setState(() => _isLoading = false);
  }
  
  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1D24),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _selectTemplate(WorkoutTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _exerciseSettings.clear();
      for (var exercise in template.exercises) {
        _exerciseSettings[exercise.id] = {
          'weight': 0.0,
          'reps': exercise.reps,
          'sets': exercise.sets,
        };
      }
    });
  }

  Future<void> _assignProgram() async {
    if (_selectedTemplate == null) {
      Helpers.showSnackBar(context, 'Выберите программу', isError: true);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final existingPrograms = await Supabase.instance.client
          .from('client_programs')
          .select('id')
          .eq('client_id', widget.clientId);
      
      if (existingPrograms != null && existingPrograms.isNotEmpty) {
        for (var program in existingPrograms) {
          await Supabase.instance.client
              .from('client_program_exercises')
              .delete()
              .eq('client_program_id', program['id']);
          
          await Supabase.instance.client
              .from('client_programs')
              .delete()
              .eq('id', program['id']);
        }
        print('✅ Удалено программ: ${existingPrograms.length}');
      }

      final clientProgramId = const Uuid().v4();
      final programData = {
        'id': clientProgramId,
        'client_id': widget.clientId,
        'program_id': _selectedTemplate!.id,
        'start_date': _startDate.toIso8601String(),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('client_programs')
          .insert(programData);

      print('✅ Новая программа создана: $clientProgramId');

      for (var exercise in _selectedTemplate!.exercises) {
        final settings = _exerciseSettings[exercise.id]!;
        
        await Supabase.instance.client
            .from('client_program_exercises')
            .insert({
              'id': const Uuid().v4(),
              'client_program_id': clientProgramId,
              'template_exercise_id': exercise.id,
              'name': exercise.name,
              'sets': settings['sets'],
              'reps': settings['reps'],
              'weight': settings['weight'] > 0 ? settings['weight'] : null,
              'order_index': exercise.orderIndex,
              'day_of_week': exercise.dayOfWeek,
              'week_number': exercise.weekNumber,
              'rest_seconds': exercise.restSeconds,
              'is_completed': false,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      print('✅ Упражнения добавлены: ${_selectedTemplate!.exercises.length}');

      if (mounted) {
        Helpers.showSnackBar(context, 'Программа назначена');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Ошибка назначения программы: $e');
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showExerciseSettingsDialog(TemplateExercise exercise) {
    final settings = _exerciseSettings[exercise.id]!;
    final weightController = TextEditingController(text: settings['weight'].toString());
    final repsController = TextEditingController(text: settings['reps'].toString());
    final setsController = TextEditingController(text: settings['sets'].toString());
    
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
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
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
                      _buildSettingField(
                        controller: weightController,
                        label: 'Вес',
                        unit: 'кг',
                        hint: '0',
                      ),
                      const SizedBox(height: 16),
                      _buildSettingField(
                        controller: repsController,
                        label: 'Повторы',
                        unit: 'раз',
                        hint: exercise.reps.toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildSettingField(
                        controller: setsController,
                        label: 'Подходы',
                        unit: '',
                        hint: exercise.sets.toString(),
                      ),
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _exerciseSettings[exercise.id] = {
                        'weight': double.tryParse(weightController.text) ?? 0,
                        'reps': int.tryParse(repsController.text) ?? exercise.reps,
                        'sets': int.tryParse(setsController.text) ?? exercise.sets,
                      };
                    });
                    Navigator.pop(context);
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingField({
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
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 0.5,
            ),
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
    final templatesState = ref.watch(templatesViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Назначить программу',
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
            : Column(
                children: [
                  Expanded(
                    child: templatesState.isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.green))
                        : templatesState.templates.isEmpty
                            ? Center(
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
                                      'Нет доступных программ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Создайте программу в конструкторе',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 24),
                                    GestureDetector(
                                      onTap: () => context.push('/create-template'),
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
                                          'Создать программу',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: templatesState.templates.length,
                                itemBuilder: (context, index) {
                                  final template = templatesState.templates[index];
                                  final isSelected = _selectedTemplate?.id == template.id;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? Colors.green : Colors.white.withOpacity(0.05),
                                        width: isSelected ? 1.5 : 0.5,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        onTap: () => _selectTemplate(template),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      template.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 24,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${template.durationWeeks} недель • ${_getDifficultyText(template.difficulty)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              
                                              if (isSelected && template.exercises.isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                const Divider(color: Colors.white12, height: 1),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  'Настройка упражнений',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ...template.exercises.map((exercise) {
                                                  final settings = _exerciseSettings[exercise.id];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 8),
                                                    child: GestureDetector(
                                                      onTap: () => _showExerciseSettingsDialog(exercise),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF0F1115),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                exercise.name,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              settings != null
                                                                  ? '${settings['sets']}×${settings['reps']} ${settings['weight'] > 0 ? '${settings['weight']}кг' : ''}'
                                                                  : 'настроить',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: settings != null ? Colors.green : Colors.grey,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            const Icon(
                                                              Icons.edit,
                                                              color: Colors.grey,
                                                              size: 16,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF0F1115), Color(0xFF1A1D24)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 0.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Дата начала',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Helpers.formatDate(_startDate),
                                            style: const TextStyle(fontSize: 14, color: Colors.white),
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
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _assignProgram,
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
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.green,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Назначить программу',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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