import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trainapp/config/di/providers.dart';
import 'package:uuid/uuid.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../domain/entities/subscription.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';
import '../../../../core/theme/premium_theme.dart';

class AddSubscriptionPage extends ConsumerStatefulWidget {
  final String? clientId; // для предварительного выбора
  
  const AddSubscriptionPage({super.key, this.clientId});

  @override
  ConsumerState<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends ConsumerState<AddSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _planNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  String? _selectedClientId;
  bool _isLoading = false;
  
  final List<Map<String, dynamic>> _planTemplates = [
    {'name': '1 месяц', 'days': 30, 'price': 3000},
    {'name': '3 месяца', 'days': 90, 'price': 8000},
    {'name': '6 месяцев', 'days': 180, 'price': 15000},
    {'name': '12 месяцев', 'days': 365, 'price': 28000},
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
  }
  
  @override
  void dispose() {
    _planNameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
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
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = picked.add(const Duration(days: 30));
      });
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 365)),
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
        _endDate = picked;
      });
    }
  }
  
  void _applyTemplate(Map<String, dynamic> template) {
    setState(() {
      _planNameController.text = template['name'];
      _priceController.text = template['price'].toString();
      _endDate = _startDate.add(Duration(days: template['days']));
    });
  }
  
  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      Helpers.showSnackBar(context, 'Выберите клиента', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final userId = await ref.read(currentUserIdProvider.future);
      if (userId == null) return;
      
      final subscription = Subscription(
        id: const Uuid().v4(),
        clientId: _selectedClientId!,
        trainerId: userId,
        planName: _planNameController.text,
        price: double.parse(_priceController.text),
        startDate: _startDate,
        endDate: _endDate,
        status: 'active',
        paymentStatus: 'pending',
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
      );
      
      await ref.read(subscriptionsViewModelProvider.notifier)
          .addSubscription(subscription);
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Абонемент создан');
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
    final clientsState = ref.watch(clientsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Новый абонемент',
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
                      /// Выбор клиента
                      if (widget.clientId == null) ...[
                        PremiumCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: DropdownButtonFormField<String>(
                              value: _selectedClientId,
                              decoration: const InputDecoration(
                                labelText: 'Клиент',
                                labelStyle: TextStyle(color: Colors.grey),
                                prefixIcon: Icon(Icons.person, color: Colors.green),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: const Color(0xFF1A1D24),
                              items: clientsState.clients.map((client) {
                                return DropdownMenuItem(
                                  value: client.id,
                                  child: Text(client.fullName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedClientId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Выберите клиента';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      /// Шаблоны абонементов
                      const Text(
                        'Быстрый выбор',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _planTemplates.map((template) {
                          return GestureDetector(
                            onTap: () => _applyTemplate(template),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A1D24),
                                    Color(0xFF22262F),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${template['name']} (${template['price']}₽)',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      /// Название плана
                      PremiumTextField(
                        controller: _planNameController,
                        label: 'Название абонемента',
                        hint: 'Например: Базовый',
                        prefixIcon: Icons.card_membership,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      /// Стоимость
                      PremiumTextField(
                        controller: _priceController,
                        label: 'Стоимость',
                        hint: '₽',
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите стоимость';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Введите число';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      /// Даты
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectStartDate(context),
                              child: PremiumCard(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
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
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              Helpers.formatDate(_startDate),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectEndDate(context),
                              child: PremiumCard(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
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
                                              'Дата окончания',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              Helpers.formatDate(_endDate),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      /// Заметки
                      PremiumTextField(
                        controller: _notesController,
                        label: 'Заметки',
                        hint: 'Необязательно',
                        prefixIcon: Icons.note,
                        maxLines: 3,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      /// Кнопка сохранения
                      Container(
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
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _saveSubscription,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                      'Создать абонемент',
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Кастомное поле ввода с премиальным стилем
class PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  
  const PremiumTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });
  
  @override
  Widget build(BuildContext context) {
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
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.green, size: 20)
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