import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/trainer_viewmodel.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';

class AddClientDialog extends ConsumerStatefulWidget {
  const AddClientDialog({super.key});

  @override
  ConsumerState<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends ConsumerState<AddClientDialog> {
  // Контроллеры для полей
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  int _selectedTab = 0; // 0 - зарегистрированный, 1 - незарегистрированный
  String? _debugError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Добавление зарегистрированного клиента (по email)
  Future<void> _addRegisteredClient(String email) async {
    print('📧 [REGISTERED] Starting add registered client with email: $email');
    setState(() {
      _isLoading = true;
      _debugError = null;
    });

    try {
      print('📧 [REGISTERED] Getting trainer ID...');
      final trainerId = await ref.read(currentUserIdProvider.future);
      print('📧 [REGISTERED] Trainer ID: $trainerId');
      
      if (trainerId == null) {
        print('❌ [REGISTERED] Trainer ID is null');
        if (mounted) {
          Helpers.showSnackBar(context, 'Ошибка авторизации тренера', isError: true);
        }
        setState(() => _isLoading = false);
        return;
      }

      // Ищем пользователя по email
      print('📧 [REGISTERED] Searching for user with email: $email');
      final userResponse = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .eq('email', email)
          .maybeSingle();

      print('📧 [REGISTERED] User response: $userResponse');

      if (userResponse == null) {
        print('❌ [REGISTERED] User not found');
        if (mounted) {
          Helpers.showSnackBar(
            context, 
            'Пользователь с таким email не найден', 
            isError: true,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Проверяем, не добавлен ли уже клиент
      print('📧 [REGISTERED] Checking if client already exists...');
      final existingRelation = await Supabase.instance.client
          .from('trainer_clients')
          .select()
          .eq('trainer_id', trainerId)
          .eq('client_id', userResponse['id'])
          .maybeSingle();

      print('📧 [REGISTERED] Existing relation: $existingRelation');

      if (existingRelation != null) {
        print('❌ [REGISTERED] Client already added');
        if (mounted) {
          Helpers.showSnackBar(context, 'Этот клиент уже добавлен', isError: true);
        }
        setState(() => _isLoading = false);
        return;
      }

      // Добавляем клиента тренеру
      print('📧 [REGISTERED] Adding client to trainer...');
      final insertData = {
        'trainer_id': trainerId,
        'client_id': userResponse['id'],
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
      };
      print('📧 [REGISTERED] Insert data: $insertData');

      final insertResult = await Supabase.instance.client
          .from('trainer_clients')
          .insert(insertData)
          .select()
          .maybeSingle();

      print('📧 [REGISTERED] Insert result: $insertResult');

      if (mounted) {
        Helpers.showSnackBar(context, 'Клиент успешно добавлен');
        Navigator.pop(context, true);
        
        // Обновляем список клиентов
        print('📧 [REGISTERED] Refreshing clients list...');
        ref.read(clientsViewModelProvider.notifier).loadClients(trainerId);
      }
    } catch (e, stackTrace) {
      print('❌ [REGISTERED] Error: $e');
      print('❌ [REGISTERED] Stack trace: $stackTrace');
      
      setState(() {
        _debugError = e.toString();
      });
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Добавление незарегистрированного клиента (исправленная версия)
Future<void> _addUnregisteredClient() async {
  print('👤 [UNREGISTERED] Starting add unregistered client');
  
  if (_nameController.text.trim().isEmpty) {
    Helpers.showSnackBar(context, 'Введите имя клиента', isError: true);
    return;
  }

  setState(() {
    _isLoading = true;
    _debugError = null;
  });

  try {
    final trainerId = await ref.read(currentUserIdProvider.future);
    if (trainerId == null) return;

    // Создаем профиль без id - база сама сгенерирует
    final profileData = {
      'email': '',
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
      'telegram': _telegramController.text.isNotEmpty ? _telegramController.text.trim() : null,
      'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      'is_registered': false,
      'role': 'client',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    print('👤 [UNREGISTERED] Profile data to insert: $profileData');

    final profileResult = await Supabase.instance.client
        .from('profiles')
        .insert(profileData)
        .select()
        .single();

    print('👤 [UNREGISTERED] Profile insert result: $profileResult');
    
    final clientId = profileResult['id'];

    final relationData = {
      'trainer_id': trainerId,
      'client_id': clientId,
      'status': 'active',
      'start_date': DateTime.now().toIso8601String(),
      'notes': _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
    };
    
    await Supabase.instance.client
        .from('trainer_clients')
        .insert(relationData);

    if (mounted) {
      Helpers.showSnackBar(context, 'Клиент успешно добавлен');
      Navigator.pop(context, true);
      ref.read(clientsViewModelProvider.notifier).loadClients(trainerId);
    }
  } catch (e, stackTrace) {
    print('❌ [UNREGISTERED] Error: $e');
    print('❌ [UNREGISTERED] Stack trace: $stackTrace');
    if (mounted) {
      Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _handleAddClient() {
    if (_isLoading) return;
    
    if (_selectedTab == 0) {
      // Добавление зарегистрированного клиента
      final email = _nameController.text.trim();
      if (email.isEmpty) {
        Helpers.showSnackBar(context, 'Введите email', isError: true);
        return;
      }
      if (!Helpers.isValidEmail(email)) {
        Helpers.showSnackBar(context, 'Введите корректный email', isError: true);
        return;
      }
      _addRegisteredClient(email);
    } else {
      // Добавление незарегистрированного клиента
      _addUnregisteredClient();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Добавить клиента',
                    style: theme.textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Переключатель типа клиента
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? theme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              'С регистрацией',
                              style: TextStyle(
                                color: _selectedTab == 0
                                    ? Colors.black
                                    : theme.disabledColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? theme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              'Без регистрации',
                              style: TextStyle(
                                color: _selectedTab == 1
                                    ? Colors.black
                                    : theme.disabledColor,
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
            
            // Форма с прокруткой
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedTab == 0) ...[
                      // Для зарегистрированных - только email
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: theme.primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Введите email клиента, который уже зарегистрирован в приложении',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Email клиента',
                          hintText: 'client@example.com',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ] else ...[
                      // Для незарегистрированных - полная форма
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: theme.primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Добавьте клиента без регистрации в приложении',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя клиента *',
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          prefixIcon: Icon(Icons.phone),
                          hintText: '+7 (999) 123-45-67',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _telegramController,
                        decoration: const InputDecoration(
                          labelText: 'Telegram',
                          prefixIcon: Icon(Icons.send),
                          hintText: '@username',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Заметки',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                    ],
                    
                    // Отображение ошибки для отладки
                    if (_debugError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ошибка:',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _debugError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Кнопки действий
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedButton(
                      onPressed: _handleAddClient,
                      isLoading: _isLoading,
                      child: const Text('Добавить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}