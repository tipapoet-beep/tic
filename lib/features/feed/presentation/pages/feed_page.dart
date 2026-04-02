import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/config/di/providers.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../config/di/providers.dart';
import '../../../trainer/presentation/pages/trainer_home_page.dart';
import '../../../client/presentation/pages/client_home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../../core/theme/premium_theme.dart';
import '../widgets/profile_dialog.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  List<Map<String, dynamic>> _items = [];
  List<String> _cities = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedRole = 'trainer';
  bool _isTrainer = false;
  
  // Фильтры
  String _selectedCity = '';
  String _selectedSpecialty = '';
  String _selectedTrainingType = 'all';
  TextEditingController _citySearchController = TextEditingController();
  
  final List<String> _specialties = ['Все направления', 'Фитнес', 'Бодибилдинг', 'Пауэрлифтинг', 'Кроссфит', 'Йога', 'Пилатес'];
  final List<String> _trainingTypes = ['all', 'online', 'offline'];
  final Map<String, String> _trainingTypeLabels = {
    'all': 'Все',
    'online': 'Онлайн',
    'offline': 'Офлайн',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadCities();
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final response = await Supabase.instance.client
          .from('cities')
          .select('name')
          .order('name', ascending: true);
      
      setState(() {
        _cities = (response as List).map((c) => c['name'] as String).toList();
      });
    } catch (e) {
      print('Error loading cities: $e');
      _loadCitiesFromProfiles();
    }
  }

  Future<void> _loadCitiesFromProfiles() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('city')
          .not('city', 'is', null);
      
      final cities = <String>{};
      for (var item in response) {
        final city = item['city'] as String?;
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }
      
      setState(() {
        _cities = cities.toList()..sort();
      });
    } catch (e) {
      print('Error loading cities from profiles: $e');
    }
  }

  Future<void> _loadCurrentUserRole() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && mounted) {
        final role = response['role'] as String;
        setState(() {
          _isTrainer = role == 'trainer';
          _selectedRole = role == 'trainer' ? 'client' : 'trainer';
        });
        _loadItems();
      }
    }
  }

  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('profiles')
          .select('''
            id, full_name, avatar_url, experience_years, specialties, rating, rating_count,
            education, achievements, awards, bio, city, training_type, role
          ''')
          .eq('role', _selectedRole)
          .order('rating', ascending: false);

      if (_searchQuery.isNotEmpty) {
        final userSearch = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('email', _searchQuery)
            .maybeSingle();
        
        if (userSearch != null) {
          query = Supabase.instance.client
              .from('profiles')
              .select('''
                id, full_name, avatar_url, experience_years, specialties, rating, rating_count,
                education, achievements, awards, bio, city, training_type, role
              ''')
              .eq('role', _selectedRole)
              .eq('id', userSearch['id']);
        } else {
          if (mounted) {
            setState(() {
              _items = [];
              _isLoading = false;
            });
          }
          return;
        }
      }

      final response = await query;
      var items = List<Map<String, dynamic>>.from(response);

      if (_selectedCity.isNotEmpty) {
        items = items.where((item) => item['city'] == _selectedCity).toList();
      }
      
      if (_selectedSpecialty.isNotEmpty && _selectedSpecialty != 'Все направления') {
        items = items.where((item) {
          final specialties = item['specialties'] as List?;
          if (specialties == null) return false;
          return specialties.contains(_selectedSpecialty);
        }).toList();
      }
      
      if (_selectedTrainingType != 'all') {
        items = items.where((item) => item['training_type'] == _selectedTrainingType).toList();
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _filteredCities {
    if (_citySearchController.text.isEmpty) {
      return _cities;
    }
    return _cities.where((city) =>
        city.toLowerCase().contains(_citySearchController.text.toLowerCase())
    ).toList();
  }

  void _showFilterDialog() {
    _citySearchController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1D24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Фильтры',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Город с поиском
                    const Text(
                      'Город',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
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
                      child: TextField(
                        controller: _citySearchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Поиск города...',
                          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setStateDialog(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Список городов
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Опция "Все города"
                            GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  _selectedCity = '';
                                  _citySearchController.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: _selectedCity.isEmpty
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 24),
                                    Text(
                                      'Все города',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedCity.isEmpty ? Colors.green : Colors.white,
                                        fontWeight: _selectedCity.isEmpty ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Список городов
                            ..._filteredCities.map((city) {
                              final isSelected = _selectedCity == city;
                              return GestureDetector(
                                onTap: () {
                                  setStateDialog(() {
                                    _selectedCity = city;
                                    _citySearchController.clear();
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 24),
                                      Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? Colors.green : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            
                            if (_filteredCities.isEmpty && _citySearchController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Город "${_citySearchController.text}" не найден',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                            
                            if (_cities.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Нет доступных городов',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Направление
                    const Text(
                      'Направление',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
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
                        value: _selectedSpecialty.isEmpty ? 'Все направления' : _selectedSpecialty,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        dropdownColor: const Color(0xFF1A1D24),
                        items: _specialties.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedSpecialty = value == 'Все направления' ? '' : value!;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Тип тренировок
                    const Text(
                      'Тип тренировок',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
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
                        value: _selectedTrainingType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        dropdownColor: const Color(0xFF1A1D24),
                        items: _trainingTypes.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(_trainingTypeLabels[item]!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            _selectedTrainingType = value!;
                          });
                        },
                      ),
                    ),
                    
                    // Отображение выбранного города
                    if (_selectedCity.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCity,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  _selectedCity = '';
                                });
                              },
                              child: const Icon(Icons.close, color: Colors.grey, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setStateDialog(() {
                    _selectedCity = '';
                    _selectedSpecialty = '';
                    _selectedTrainingType = 'all';
                    _citySearchController.clear();
                  });
                },
                child: const Text(
                  'Сбросить',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _loadItems();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    'Применить',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedRole == 'trainer' ? 'Клиенты' : 'Тренеры';
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Фитнес Экосистема',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: () {
                context.push('/profile');
              },
              tooltip: 'Профиль',
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Лента'),
              Tab(text: 'Кабинет'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Лента
            PremiumBackground(
              child: Column(
                children: [
                  // Строка поиска и фильтра
                  Padding(
                    padding: const EdgeInsets.all(12),
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
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Поиск по email...',
                                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
                                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                                _loadItems();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showFilterDialog,
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
                                color: Colors.white.withOpacity(0.05),
                                width: 0.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: Colors.green,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Список карточек
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.green),
                          )
                        : _error != null
                            ? ErrorView(message: _error!, onRetry: _loadItems)
                            : _items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 80,
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Нет $title',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Попробуйте изменить параметры поиска',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: _items.length,
                                    itemBuilder: (context, index) {
                                      final item = _items[index];
                                      final isFirst = index == 0;
                                      final isLast = index == _items.length - 1;
                                      return _buildCompactCard(item, isFirst, isLast);
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            // Вторая вкладка - Кабинет
            _isTrainer ? const TrainerHomePage() : const ClientHomePage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(Map<String, dynamic> item, bool isFirst, bool isLast) {
    final rating = (item['rating'] ?? 0).toDouble();
    final specialties = item['specialties'] as List? ?? [];
    final isTrainer = _selectedRole == 'trainer';
    final name = item['full_name'] ?? (isTrainer ? 'Клиент' : 'Тренер');
    final experience = item['experience_years'];
    final city = item['city'];

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => ProfileDialog(
                profileData: item,
                isTrainerView: _isTrainer,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.withOpacity(0.15),
                  backgroundImage: item['avatar_url'] != null
                      ? NetworkImage(item['avatar_url'])
                      : null,
                  child: item['avatar_url'] == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          if (experience != null && !isTrainer)
                            _buildCompactChip('${experience} лет', Icons.work),
                          if (specialties.isNotEmpty && !isTrainer)
                            _buildCompactChip(specialties.first, Icons.fitness_center),
                          if (city != null)
                            _buildCompactChip(city, Icons.location_city),
                          if (rating > 0)
                            _buildCompactChip(rating.toStringAsFixed(1), Icons.star),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.green),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  Future<String> _getUserRole(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'];
  }
}