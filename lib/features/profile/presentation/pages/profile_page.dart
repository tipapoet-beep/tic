import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/config/di/providers.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../domain/entities/profile.dart';
import '../../../../core/widgets/animated_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/premium_theme.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId;
  final bool isReadOnly;
  
  const ProfilePage({
    super.key,
    this.userId,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _instagramController;
  late TextEditingController _telegramController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _educationController;
  late TextEditingController _achievementsController;
  late TextEditingController _awardsController;
  late TextEditingController _experienceYearsController;
  
  String? _selectedGoal;
  String? _selectedExperience;
  int? _selectedFrequency;
  List<String> _selectedSpecialties = [];
  
  final List<String> _goals = ['Похудение', 'Набор массы', 'Выносливость', 'Здоровье', 'Рельеф'];
  final List<String> _experienceLevels = ['beginner', 'intermediate', 'advanced'];
  final List<int> _frequencies = [1, 2, 3, 4, 5, 6];
  final List<String> _availableSpecialties = ['Фитнес', 'Бодибилдинг', 'Пауэрлифтинг', 'Кроссфит', 'Йога', 'Пилатес'];
  
  @override
  void initState() {
    super.initState();
    _initControllers();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = widget.userId ?? await ref.read(currentUserIdProvider.future);
      if (userId != null) {
        ref.read(profileViewModelProvider.notifier).loadProfile(userId);
      }
    });
  }
  
  void _initControllers() {
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _phoneController = TextEditingController();
    _instagramController = TextEditingController();
    _telegramController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _educationController = TextEditingController();
    _achievementsController = TextEditingController();
    _awardsController = TextEditingController();
    _experienceYearsController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _telegramController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _educationController.dispose();
    _achievementsController.dispose();
    _awardsController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }
  
  void _updateControllers(Profile profile) {
    _nameController.text = profile.fullName;
    _bioController.text = profile.bio ?? '';
    _cityController.text = profile.city ?? '';
    _phoneController.text = profile.phone ?? '';
    _instagramController.text = profile.instagram ?? '';
    _telegramController.text = profile.telegram ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _educationController.text = profile.education ?? '';
    _achievementsController.text = profile.achievements?.join(', ') ?? '';
    _awardsController.text = profile.awards?.join(', ') ?? '';
    _experienceYearsController.text = profile.experienceYears?.toString() ?? '';
    _selectedGoal = profile.goals?.isNotEmpty == true ? profile.goals!.first : null;
    _selectedExperience = profile.experienceLevel;
    _selectedFrequency = profile.trainingFrequency;
    _selectedSpecialties = profile.specialties ?? [];
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D24),
        title: const Text(
          'Выход',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти из аккаунта?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final profile = state.profile;
    final isOwnProfile = widget.userId == null && !widget.isReadOnly;
    final canEdit = !widget.isReadOnly && isOwnProfile;
    final isClient = profile?.role == 'client';
    
    if (state.isLoading && profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    
    if (profile != null && !_isEditing) {
      _updateControllers(profile);
    }
    
    final isTrainer = profile?.role == 'trainer';
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          widget.isReadOnly ? profile?.fullName ?? 'Профиль' : 'Мой профиль',
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
          // Кнопка уведомлений (только для клиента в своём профиле)
          if (isClient && !widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.green),
              onPressed: () => context.push('/notifications'),
              tooltip: 'Запросы от тренеров',
            ),
          if (canEdit && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => setState(() => _isEditing = true),
            )
          else if (canEdit && _isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() => _isEditing = false);
                if (profile != null) _updateControllers(profile);
              },
            ),
          // Кнопка выхода
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: PremiumBackground(
        child: profile == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Профиль не найден', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final userId = await ref.read(currentUserIdProvider.future);
                        if (userId != null) {
                          ref.read(profileViewModelProvider.notifier).loadProfile(userId);
                        }
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
                          border: Border.all(color: Colors.green.withOpacity(0.3), width: 0.5),
                        ),
                        child: const Text('Загрузить', style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ],
                ),
              )
            : _buildContent(profile, isTrainer, canEdit),
      ),
    );
  }
  
  Widget _buildContent(Profile profile, bool isTrainer, bool canEdit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Аватар
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                    ),
                    border: Border.all(color: Colors.green, width: 2),
                    image: profile.avatarUrl != null
                        ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: profile.avatarUrl == null
                      ? Icon(Icons.person, size: 60, color: Colors.green)
                      : null,
                ),
                if (canEdit && _isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            if (_isEditing)
              _buildEditForm(isTrainer)
            else
              _buildViewForm(profile, isTrainer),
            
            if (canEdit && _isEditing) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isEditing = false);
                        _updateControllers(profile);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A1D24), Color(0xFF22262F)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: const Text('Отмена', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _saveProfile,
                      child: Container(
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
                        child: const Text('Сохранить', textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Кнопка выхода (для режима просмотра)
            if (!_isEditing)
              GestureDetector(
                onTap: _logout,
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
                    border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Выйти',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildViewForm(Profile profile, bool isTrainer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Имя', profile.fullName),
        _buildInfoRow('Email', profile.email),
        
        if (isTrainer) ...[
          if (profile.experienceYears != null) _buildInfoRow('Стаж', '${profile.experienceYears} лет'),
          if (profile.specialties != null && profile.specialties!.isNotEmpty)
            _buildInfoRow('Направления', profile.specialties!.join(', ')),
          if (profile.education != null) _buildInfoRow('Образование', profile.education!),
          if (profile.achievements != null && profile.achievements!.isNotEmpty)
            _buildInfoRow('Достижения', profile.achievements!.join(', ')),
          if (profile.awards != null && profile.awards!.isNotEmpty)
            _buildInfoRow('Награды', profile.awards!.join(', ')),
        ] else ...[
          if (profile.age != null) _buildInfoRow('Возраст', '${profile.age} лет'),
          if (profile.height != null) _buildInfoRow('Рост', '${profile.height} см'),
          if (profile.weight != null) _buildInfoRow('Вес', '${profile.weight} кг'),
          if (profile.goals != null && profile.goals!.isNotEmpty)
            _buildInfoRow('Цель', profile.goals!.first),
          if (profile.experienceLevel != null)
            _buildInfoRow('Уровень', _getExperienceText(profile.experienceLevel!)),
          if (profile.trainingFrequency != null)
            _buildInfoRow('Тренировок/неделя', '${profile.trainingFrequency} раз(а)'),
        ],
        
        if (profile.city != null) _buildInfoRow('Город', profile.city!),
        if (profile.bio != null) _buildInfoRow('О себе', profile.bio!),
        if (profile.phone != null) _buildInfoRow('Телефон', profile.phone!),
        if (profile.instagram != null) _buildInfoRow('Instagram', '@${profile.instagram}'),
        if (profile.telegram != null) _buildInfoRow('Telegram', '@${profile.telegram}'),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditForm(bool isTrainer) {
    return Column(
      children: [
        _buildPremiumTextField(_nameController, 'Полное имя', Icons.person),
        const SizedBox(height: 16),
        _buildPremiumTextField(_bioController, 'О себе', Icons.info, maxLines: 3),
        const SizedBox(height: 16),
        _buildPremiumTextField(_cityController, 'Город', Icons.location_city),
        const SizedBox(height: 16),
        
        if (isTrainer) ...[
          _buildPremiumTextField(_experienceYearsController, 'Стаж (лет)', Icons.work, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const Text('Направления тренировок', style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                    border: Border.all(color: isSelected ? Colors.green : Colors.white.withOpacity(0.2), width: 0.5),
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
          const SizedBox(height: 16),
          _buildPremiumTextField(_educationController, 'Образование', Icons.school, maxLines: 2),
          const SizedBox(height: 16),
          _buildPremiumTextField(_achievementsController, 'Достижения (через запятую)', Icons.emoji_events, maxLines: 2),
          const SizedBox(height: 16),
          _buildPremiumTextField(_awardsController, 'Награды (через запятую)', Icons.military_tech, maxLines: 2),
        ] else ...[
          _buildPremiumDropdown(_selectedGoal, _goals, 'Цель', Icons.flag),
          const SizedBox(height: 16),
          _buildPremiumDropdown(_selectedExperience, _experienceLevels, 'Уровень подготовки', Icons.fitness_center, 
              getLabel: (v) => _getExperienceText(v)),
          const SizedBox(height: 16),
          _buildPremiumDropdown(_selectedFrequency, _frequencies, 'Тренировок в неделю', Icons.calendar_today,
              getLabel: (v) => '$v раз(а)'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPremiumTextField(_ageController, 'Возраст', Icons.cake, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildPremiumTextField(_heightController, 'Рост (см)', Icons.height, keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(_weightController, 'Вес (кг)', Icons.monitor_weight, keyboardType: TextInputType.number),
        ],
        
        const SizedBox(height: 16),
        _buildPremiumTextField(_phoneController, 'Телефон', Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildPremiumTextField(_instagramController, 'Instagram', Icons.camera_alt, prefixText: '@'),
        const SizedBox(height: 16),
        _buildPremiumTextField(_telegramController, 'Telegram', Icons.send, prefixText: '@'),
      ],
    );
  }
  
  Widget _buildPremiumTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
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
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.green, size: 20),
              prefixText: prefixText,
              prefixStyle: const TextStyle(color: Colors.green),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) => label == 'Полное имя' && (value == null || value.isEmpty) ? 'Введите имя' : null,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPremiumDropdown<T>(
    T? value,
    List<T> items,
    String label,
    IconData icon, {
    String Function(T)? getLabel,
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
          child: DropdownButtonFormField<T>(
            value: value,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.green),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF1A1D24),
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(getLabel != null ? getLabel(item) : item.toString()),
            )).toList(),
            onChanged: (newValue) => setState(() => value = newValue),
          ),
        ),
      ],
    );
  }
  
  String _getExperienceText(String level) {
    switch (level) {
      case 'beginner': return 'Начинающий';
      case 'intermediate': return 'Средний';
      case 'advanced': return 'Продвинутый';
      default: return level;
    }
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null && mounted) {
      final userId = await ref.read(currentUserIdProvider.future);
      if (userId != null) {
        final url = await ref.read(profileViewModelProvider.notifier)
            .uploadAvatar(userId, pickedFile.path);
        if (url != null && mounted) {
          Helpers.showSnackBar(context, 'Фото загружено');
        }
      }
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final profile = ref.read(profileViewModelProvider).profile;
    if (profile == null) return;
    
    final isTrainer = profile.role == 'trainer';
    
    final updatedProfile = profile.copyWith(
      fullName: _nameController.text,
      bio: _bioController.text.isEmpty ? null : _bioController.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      instagram: _instagramController.text.isEmpty ? null : _instagramController.text,
      telegram: _telegramController.text.isEmpty ? null : _telegramController.text,
      age: isTrainer ? null : (_ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null),
      height: isTrainer ? null : (_heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null),
      weight: isTrainer ? null : (_weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null),
      goals: isTrainer ? null : (_selectedGoal != null ? [_selectedGoal!] : null),
      experienceLevel: isTrainer ? null : _selectedExperience,
      trainingFrequency: isTrainer ? null : _selectedFrequency,
      experienceYears: isTrainer ? int.tryParse(_experienceYearsController.text) : null,
      specialties: isTrainer ? _selectedSpecialties : null,
      education: isTrainer ? (_educationController.text.isEmpty ? null : _educationController.text) : null,
      achievements: isTrainer ? (_achievementsController.text.isNotEmpty 
          ? _achievementsController.text.split(',').map((s) => s.trim()).toList() : null) : null,
      awards: isTrainer ? (_awardsController.text.isNotEmpty 
          ? _awardsController.text.split(',').map((s) => s.trim()).toList() : null) : null,
    );
    
    try {
      await ref.read(profileViewModelProvider.notifier).updateProfile(updatedProfile);
      setState(() => _isEditing = false);
      if (mounted) Helpers.showSnackBar(context, 'Профиль обновлён');
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Ошибка: $e', isError: true);
    }
  }
}