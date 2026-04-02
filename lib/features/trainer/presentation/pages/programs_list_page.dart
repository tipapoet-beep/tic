import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../domain/entities/workout_template.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/premium_theme.dart';

class ProgramsListPage extends ConsumerStatefulWidget {
  const ProgramsListPage({super.key});

  @override
  ConsumerState<ProgramsListPage> createState() => _ProgramsListPageState();
}

class _ProgramsListPageState extends ConsumerState<ProgramsListPage> {
  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final userId = await _getCurrentUserId();
    if (userId != null) {
      ref.read(templatesViewModelProvider.notifier).loadTemplates(userId);
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

  void _viewProgram(WorkoutTemplate program) {
    context.push('/view-template/${program.id}');
  }

  void _editProgram(WorkoutTemplate program) {
    context.push('/edit-template/${program.id}');
  }

  Future<void> _deleteProgram(WorkoutTemplate program) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text(
          'Удалить программу',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить программу "${program.title}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('template_exercises')
            .delete()
            .eq('template_id', program.id);
        
        await Supabase.instance.client
            .from('workout_templates')
            .delete()
            .eq('id', program.id);
        
        final userId = await _getCurrentUserId();
        if (userId != null) {
          await ref.read(templatesViewModelProvider.notifier).loadTemplates(userId);
        }
        
        if (mounted) {
          Helpers.showSnackBar(context, 'Программа удалена');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Ошибка удаления: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesState = ref.watch(templatesViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Мои программы',
          style: TextStyle(
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
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () {
              context.push('/create-template');
            },
            tooltip: 'Создать программу',
          ),
        ],
      ),
      body: PremiumBackground(
        child: templatesState.isLoading && templatesState.templates.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : templatesState.error != null
                ? ErrorView(
                    message: templatesState.error!,
                    onRetry: _loadPrograms,
                  )
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
                              'Нет программ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Создайте первую программу тренировок',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: () {
                                context.push('/create-template');
                              },
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
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          final program = templatesState.templates[index];
                          final isFirst = index == 0;
                          final isLast = index == templatesState.templates.length - 1;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1A1D24),
                                  Color(0xFF22262F),
                                ],
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                              ),
                              border: Border(
                                bottom: !isLast
                                    ? BorderSide(
                                        color: Colors.white.withOpacity(0.05),
                                        width: 0.5,
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.only(
                                topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                              ),
                              child: InkWell(
                                onTap: () => _viewProgram(program),
                                borderRadius: BorderRadius.only(
                                  topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                  topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                  bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
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
                                            color: Colors.green.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          color: Colors.green,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              program.title,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getDifficultyColor(program.difficulty).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _getDifficultyColor(program.difficulty).withOpacity(0.3),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _getDifficultyText(program.difficulty),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: _getDifficultyColor(program.difficulty),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.green.withOpacity(0.3),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 10,
                                                        color: Colors.green,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${program.durationWeeks} нед',
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        color: const Color(0xFF1A1D24),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editProgram(program);
                                          } else if (value == 'delete') {
                                            _deleteProgram(program);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                  color: Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Редактировать',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Удалить',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner': return Colors.green;
      case 'intermediate': return Colors.orange;
      case 'advanced': return Colors.red;
      default: return Colors.grey;
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
}