import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../../domain/entities/body_measurement.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';

class AddMeasurementPage extends ConsumerStatefulWidget {
  final BodyMeasurement? measurement;
  
  const AddMeasurementPage({super.key, this.measurement});

  @override
  ConsumerState<AddMeasurementPage> createState() => _AddMeasurementPageState();
}

class _AddMeasurementPageState extends ConsumerState<AddMeasurementPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isEditing = false;
  
  final _weightController = TextEditingController();
  final _neckController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _bicepsLeftController = TextEditingController();
  final _bicepsRightController = TextEditingController();
  final _thighsLeftController = TextEditingController();
  final _thighsRightController = TextEditingController();
  final _calvesController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.measurement != null;
    _selectedDate = widget.measurement?.date ?? DateTime.now();
    
    if (_isEditing) {
      _fillControllers();
    }
  }
  
  void _fillControllers() {
    final m = widget.measurement!;
    _weightController.text = m.weight?.toString() ?? '';
    _neckController.text = m.neck?.toString() ?? '';
    _chestController.text = m.chest?.toString() ?? '';
    _waistController.text = m.waist?.toString() ?? '';
    _hipsController.text = m.hips?.toString() ?? '';
    _bicepsLeftController.text = m.bicepsLeft?.toString() ?? '';
    _bicepsRightController.text = m.bicepsRight?.toString() ?? '';
    _thighsLeftController.text = m.thighsLeft?.toString() ?? '';
    _thighsRightController.text = m.thighsRight?.toString() ?? '';
    _calvesController.text = m.calves?.toString() ?? '';
    _shouldersController.text = m.shoulders?.toString() ?? '';
    _bodyFatController.text = m.bodyFat?.toString() ?? '';
    _notesController.text = m.notes ?? '';
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _neckController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _bicepsLeftController.dispose();
    _bicepsRightController.dispose();
    _thighsLeftController.dispose();
    _thighsRightController.dispose();
    _calvesController.dispose();
    _shouldersController.dispose();
    _bodyFatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await ref.read(currentUserIdProvider.future);
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }

      final measurement = BodyMeasurement(
        id: _isEditing ? widget.measurement!.id : const Uuid().v4(),
        userId: userId,
        date: _selectedDate,
        weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        neck: _neckController.text.isNotEmpty ? double.tryParse(_neckController.text) : null,
        chest: _chestController.text.isNotEmpty ? double.tryParse(_chestController.text) : null,
        waist: _waistController.text.isNotEmpty ? double.tryParse(_waistController.text) : null,
        hips: _hipsController.text.isNotEmpty ? double.tryParse(_hipsController.text) : null,
        bicepsLeft: _bicepsLeftController.text.isNotEmpty ? double.tryParse(_bicepsLeftController.text) : null,
        bicepsRight: _bicepsRightController.text.isNotEmpty ? double.tryParse(_bicepsRightController.text) : null,
        thighsLeft: _thighsLeftController.text.isNotEmpty ? double.tryParse(_thighsLeftController.text) : null,
        thighsRight: _thighsRightController.text.isNotEmpty ? double.tryParse(_thighsRightController.text) : null,
        calves: _calvesController.text.isNotEmpty ? double.tryParse(_calvesController.text) : null,
        shoulders: _shouldersController.text.isNotEmpty ? double.tryParse(_shouldersController.text) : null,
        bodyFat: _bodyFatController.text.isNotEmpty ? double.tryParse(_bodyFatController.text) : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: _isEditing ? widget.measurement!.createdAt : DateTime.now(),
      );

      if (_isEditing) {
        await ref.read(measurementsViewModelProvider.notifier).updateMeasurement(measurement);
        if (mounted) {
          Helpers.showSnackBar(context, 'Замер обновлён');
        }
      } else {
        await ref.read(measurementsViewModelProvider.notifier).addMeasurement(measurement);
        if (mounted) {
          Helpers.showSnackBar(context, 'Замер добавлен');
        }
      }
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать замер' : 'Новый замер',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : PremiumBackground(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Дата
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Дата замера',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Helpers.formatDate(_selectedDate),
                                        style: const TextStyle(fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Основные параметры
                      const Text(
                        'Основные параметры',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildPremiumField(
                        controller: _weightController,
                        label: 'Вес',
                        unit: 'кг',
                        icon: Icons.monitor_weight,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _bodyFatController,
                        label: 'Процент жира',
                        unit: '%',
                        icon: Icons.percent,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Шея, грудь, талия, бёдра
                      const Text(
                        'Шея, грудь, талия, бёдра',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildPremiumField(
                        controller: _neckController,
                        label: 'Шея',
                        unit: 'см',
                        icon: Icons.straighten, // Линейка вместо гантели
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _chestController,
                        label: 'Грудь',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _waistController,
                        label: 'Талия',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _hipsController,
                        label: 'Бёдра',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Руки и ноги
                      const Text(
                        'Руки и ноги',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildPremiumField(
                        controller: _bicepsLeftController,
                        label: 'Бицепс (левый)',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _bicepsRightController,
                        label: 'Бицепс (правый)',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _thighsLeftController,
                        label: 'Бедро (левое)',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _thighsRightController,
                        label: 'Бедро (правое)',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _calvesController,
                        label: 'Икры',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildPremiumField(
                        controller: _shouldersController,
                        label: 'Плечи',
                        unit: 'см',
                        icon: Icons.straighten,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Заметки
                      _buildPremiumField(
                        controller: _notesController,
                        label: 'Заметки',
                        icon: Icons.note,
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      GestureDetector(
                        onTap: _saveMeasurement,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.green,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Сохранить изменения' : 'Добавить замер',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    String unit = '',
    IconData? icon,
    int maxLines = 1,
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
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: Colors.green, size: 20) : null,
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
}