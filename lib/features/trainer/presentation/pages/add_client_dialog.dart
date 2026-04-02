import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/features/trainer/presentation/viewmodels/trainer_viewmodel.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';

class AddClientDialog extends ConsumerStatefulWidget {
  const AddClientDialog({super.key});

  @override
  ConsumerState<AddClientDialog> createState() => _AddClientDialogState();
}

class _AddClientDialogState extends ConsumerState<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isSearchMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAddClient() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final user = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('email', _emailController.text.trim())
          .maybeSingle();
      
      if (user == null) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Пользователь с таким email не найден', isError: true);
        }
        return;
      }
      
      if (user['role'] != 'client') {
        if (mounted) {
          Helpers.showSnackBar(context, 'Этот пользователь является тренером', isError: true);
        }
        return;
      }
      
      final alreadyAdded = await Supabase.instance.client
          .from('trainer_clients')
          .select()
          .eq('trainer_id', userId)
          .eq('client_id', user['id'])
          .maybeSingle();
      
      if (alreadyAdded != null) {
        if (mounted) {
          Helpers.showSnackBar(context, 'Клиент уже добавлен', isError: true);
        }
        return;
      }
      
      await Supabase.instance.client
          .from('trainer_clients')
          .insert({
            'trainer_id': userId,
            'client_id': user['id'],
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
          });
      
      await ref.read(clientsViewModelProvider.notifier).loadClients(userId);
      
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSnackBar(context, 'Клиент добавлен');
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

  Future<void> _addUnregisteredClient() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', _emailController.text.trim())
          .maybeSingle();
      
      if (existingUser != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D24),
            title: const Text('Пользователь уже зарегистрирован', style: TextStyle(color: Colors.white)),
            content: Text(
              'Пользователь с email ${_emailController.text.trim()} уже зарегистрирован. Добавить его как клиента?',
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Добавить'),
              ),
            ],
          ),
        );
        
        if (confirm == true && mounted) {
          await _addExistingUser(existingUser['id']);
        }
        return;
      }
      
      await Supabase.instance.client
          .from('unregistered_clients')
          .insert({
            'trainer_id': userId,
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            'email': _emailController.text.trim(),
          });
      
      await ref.read(clientsViewModelProvider.notifier).loadClients(userId);
      
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSnackBar(context, 'Клиент добавлен');
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
  
  Future<void> _addExistingUser(String userId) async {
    final trainerId = await _getCurrentUserId();
    if (trainerId == null) return;
    
    try {
      await Supabase.instance.client
          .from('trainer_clients')
          .insert({
            'trainer_id': trainerId,
            'client_id': userId,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
          });
      
      await ref.read(clientsViewModelProvider.notifier).loadClients(trainerId);
      
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSnackBar(context, 'Клиент добавлен');
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
      }
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  const Text(
                    'Добавить клиента',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 22),
                  ),
                ],
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSearchMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isSearchMode ? Colors.green.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSearchMode ? Colors.green : Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'Из ленты',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSearchMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isSearchMode ? Colors.green.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isSearchMode ? Colors.green : Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                        child: const Text(
                          'Без регистрации',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearchMode) ...[
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email клиента',
                        hint: 'Введите email зарегистрированного клиента',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите email';
                          }
                          if (!value.contains('@')) {
                            return 'Неверный формат email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _searchAndAddClient,
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
                              : const Text(
                                  'Найти и добавить',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      _buildTextField(
                        controller: _nameController,
                        label: 'Имя клиента',
                        hint: 'Введите имя',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Введите email (необязательно)',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Телефон (необязательно)',
                        hint: '+7 XXX XXX-XX-XX',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _addUnregisteredClient,
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
                              : const Text(
                                  'Добавить',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: Colors.green, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}