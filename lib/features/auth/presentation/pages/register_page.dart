// lib/features/auth/presentation/pages/register_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'viewmodels/auth_viewmodel.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/premium_theme.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _educationController = TextEditingController();
  final _achievementsController = TextEditingController();
  final _awardsController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  
  String _selectedRole = 'client';
  final List<String> _selectedSpecialties = [];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasAgreedToTerms = false;
  
  final List<String> _availableSpecialties = ['Фитнес', 'Бодибилдинг', 'Пауэрлифтинг', 'Кроссфит', 'Йога', 'Пилатес'];
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _educationController.dispose();
    _achievementsController.dispose();
    _awardsController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_hasAgreedToTerms) {
      Helpers.showSnackBar(
        context, 
        'Необходимо принять пользовательское соглашение', 
        isError: true,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
        },
      );
      
      if (authResponse.user == null) {
        throw Exception('Ошибка регистрации');
      }
      
      final userId = authResponse.user!.id;
      
      final profileData = {
        'id': userId,
        'email': _emailController.text.trim(),
        'full_name': _nameController.text.trim(),
        'role': _selectedRole,
        'has_agreed_to_terms': false,
      };
      
      await Supabase.instance.client
          .from('profiles')
          .insert(profileData);
      
      if (_selectedRole == 'trainer') {
        final trainerData = <String, dynamic>{};
        
        if (_experienceYearsController.text.isNotEmpty) {
          trainerData['experience_years'] = int.tryParse(_experienceYearsController.text);
        }
        if (_selectedSpecialties.isNotEmpty) {
          trainerData['specialties'] = _selectedSpecialties;
        }
        if (_educationController.text.isNotEmpty) {
          trainerData['education'] = _educationController.text;
        }
        if (_achievementsController.text.isNotEmpty) {
          trainerData['achievements'] = [_achievementsController.text];
        }
        if (_awardsController.text.isNotEmpty) {
          trainerData['awards'] = [_awardsController.text];
        }
        
        if (trainerData.isNotEmpty) {
          await Supabase.instance.client
              .from('profiles')
              .update(trainerData)
              .eq('id', userId);
        }
      }
      
      if (mounted) {
        final accepted = await _showTermsAgreementDialog();
        
        if (accepted == true && mounted) {
          await Supabase.instance.client
              .from('profiles')
              .update({'has_agreed_to_terms': true})
              .eq('id', userId);
          
          await Supabase.instance.client.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          if (mounted) {
            Helpers.showSnackBar(context, 'Добро пожаловать!');
            context.go('/feed');
          }
        } else {
          if (mounted) {
            await Supabase.instance.client.auth.admin.deleteUser(userId);
            await Supabase.instance.client
                .from('profiles')
                .delete()
                .eq('id', userId);
            
            Helpers.showSnackBar(
              context, 
              'Для использования приложения необходимо принять пользовательское соглашение', 
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        Helpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showTermsAgreementDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Пользовательское соглашение',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '1. Общие положения',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '1.1. Настоящее Соглашение определяет условия использования приложения "Фитнес Экосистема" (далее — Приложение) и регулирует отношения между Администрацией Приложения и Пользователем.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '2. Информационная поддержка',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '2.1. Приложение предоставляет Пользователю информацию о возможных программах тренировок, средствах и методах физической подготовки, а также предоставляет инструменты для ведения дневника тренировок и учёта индивидуальных показателей.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '3. Отказ от ответственности',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '3.1. Администрация Приложения не несёт ответственности за любые последствия, связанные с использованием информации, полученной в Приложении, включая возможные травмы, ухудшение самочувствия или иные негативные последствия для здоровья.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '3.2. Вся информация, представленная в Приложении, носит ознакомительный характер. Администрация не гарантирует достижение каких-либо результатов от использования Приложения.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '3.3. Перед началом занятий физической культурой и спортом Пользователю рекомендуется пройти медицинское обследование и получить консультацию врача.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '4. Персональные данные',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '4.1. Регистрируясь в Приложении, Пользователь даёт согласие на обработку своих персональных данных, включая фамилию, имя, адрес электронной почты, телефон, фотографии, антропометрические данные (рост, вес, объёмы) и историю тренировок.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '4.2. Персональные данные обрабатываются в целях обеспечения функционирования Приложения, ведения статистики прогресса, а также для связи с тренером (при его назначении).',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '4.3. Администрация обязуется не передавать персональные данные третьим лицам, за исключением случаев, предусмотренных законодательством Российской Федерации.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              
              const Text(
                '5. Заключительные положения',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '5.1. Администрация оставляет за собой право вносить изменения в настоящее Соглашение без предварительного уведомления Пользователя. Новая редакция Соглашения вступает в силу с момента её размещения в Приложении.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                '5.2. Нажимая "Принимаю", Вы подтверждаете, что ознакомились и согласны с условиями настоящего Соглашения.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Принимаю'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: const Text(
          'Регистрация',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Логотип
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Название приложения
                const Text(
                  'Фитнес Экосистема',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                _buildPremiumTextField(
                  controller: _nameController,
                  label: 'Полное имя',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите имя';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPremiumTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите email';
                    if (!Helpers.isValidEmail(value)) return 'Неверный формат email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPremiumTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите пароль';
                    if (value.length < 6) return 'Пароль должен быть не менее 6 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPremiumTextField(
                  controller: _confirmPasswordController,
                  label: 'Подтвердите пароль',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Подтвердите пароль';
                    if (value != _passwordController.text) return 'Пароли не совпадают';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Выбор роли
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выберите роль:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildRoleOption('client', 'Клиент', Icons.person)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRoleOption('trainer', 'Тренер', Icons.fitness_center)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Дополнительные поля для тренера
                if (_selectedRole == 'trainer') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Информация о тренере',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildPremiumTextField(
                          controller: _experienceYearsController,
                          label: 'Стаж (лет)',
                          icon: Icons.work,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        
                        const Text(
                          'Направления тренировок',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSpecialties.map((specialty) {
                            final isSelected = _selectedSpecialties.contains(specialty);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSpecialties.remove(specialty);
                                  } else {
                                    _selectedSpecialties.add(specialty);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  specialty,
                                  style: TextStyle(
                                    color: isSelected ? Colors.green : Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildPremiumTextField(
                          controller: _educationController,
                          label: 'Образование',
                          icon: Icons.school,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildPremiumTextField(
                          controller: _achievementsController,
                          label: 'Достижения',
                          icon: Icons.emoji_events,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        
                        _buildPremiumTextField(
                          controller: _awardsController,
                          label: 'Награды',
                          icon: Icons.military_tech,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Пользовательское соглашение
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _hasAgreedToTerms ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                      width: _hasAgreedToTerms ? 1 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _hasAgreedToTerms,
                        onChanged: (value) => setState(() => _hasAgreedToTerms = value ?? false),
                        activeColor: Colors.green,
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.grey),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _hasAgreedToTerms = !_hasAgreedToTerms),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Я принимаю ',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Пользовательское соглашение',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _showTermsAgreementDialog(),
                                ),
                                const TextSpan(
                                  text: ' и даю согласие на обработку персональных данных',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                else
                  GestureDetector(
                    onTap: _handleRegister,
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
                        'Зарегистрироваться',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Уже есть аккаунт?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      child: const Text('Войти'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoleOption(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey,
                fontWeight: isSelected ? FontWeight.w500 : null,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
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
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.green, size: 20),
              suffixIcon: suffixIcon,
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