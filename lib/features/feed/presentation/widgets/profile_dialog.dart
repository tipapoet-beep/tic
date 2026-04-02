import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/features/profile/domain/entities/profile.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/utils/helpers.dart';

class ProfileDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> profileData;
  final bool isTrainerView;
  
  const ProfileDialog({
    super.key,
    required this.profileData,
    required this.isTrainerView,
  });

  @override
  ConsumerState<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends ConsumerState<ProfileDialog> {
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) return;
    
    final targetId = widget.profileData['id'];
    
    try {
      final response = await Supabase.instance.client
          .from('trainer_clients')
          .select()
          .or('trainer_id.eq.$currentUserId,client_id.eq.$currentUserId')
          .or('trainer_id.eq.$targetId,client_id.eq.$targetId')
          .maybeSingle();
      
      setState(() {
        _isConnected = response != null;
      });
    } catch (e) {
      print('Error checking connection: $e');
    }
  }

  Future<String?> _getCurrentUserId() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session?.user.id;
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;
      
      final targetId = widget.profileData['id'];
      final currentUserRole = await _getUserRole(currentUserId);
      final targetRole = widget.profileData['role'];
      
      // Только тренер может отправить запрос клиенту
      if (currentUserRole != 'trainer' || targetRole != 'client') {
        throw Exception('Только тренер может добавить клиента');
      }
      
      // Проверяем существующий запрос
      final existingRequest = await Supabase.instance.client
          .from('trainer_requests')
          .select()
          .eq('trainer_id', currentUserId)
          .eq('client_id', targetId)
          .maybeSingle();
      
      if (existingRequest != null) {
        if (existingRequest['status'] == 'pending') {
          Helpers.showSnackBar(context, 'Запрос уже отправлен');
        } else if (existingRequest['status'] == 'accepted') {
          Helpers.showSnackBar(context, 'Клиент уже добавлен');
        } else if (existingRequest['status'] == 'rejected') {
          Helpers.showSnackBar(context, 'Клиент отклонил запрос');
        }
        return;
      }
      
      // Создаём запрос
      await Supabase.instance.client
          .from('trainer_requests')
          .insert({
            'trainer_id': currentUserId,
            'client_id': targetId,
            'status': 'pending',
          });
      
      if (mounted) {
        Helpers.showSnackBar(context, 'Запрос отправлен клиенту');
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

  Future<String> _getUserRole(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    return response['role'];
  }

  void _openChat() {
    final profile = Profile(
      id: widget.profileData['id'],
      email: widget.profileData['email'] ?? '',
      fullName: widget.profileData['full_name'] ?? '',
      role: widget.profileData['role'],
      avatarUrl: widget.profileData['avatar_url'],
      bio: widget.profileData['bio'],
      city: widget.profileData['city'],
      specialties: widget.profileData['specialties'] != null ? List<String>.from(widget.profileData['specialties']) : null,
      experienceYears: widget.profileData['experience_years'],
    );
    
    Navigator.pop(context);
    context.push('/chat/${widget.profileData['id']}', extra: profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profileData;
    final name = profile['full_name'] ?? 'Пользователь';
    final role = profile['role'] == 'trainer' ? 'Тренер' : 'Клиент';
    final specialties = profile['specialties'] as List? ?? [];
    final experience = profile['experience_years'];
    final city = profile['city'];
    final bio = profile['bio'];
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context),
                _avatar(name, profile['avatar_url']),
                _nameAndRole(name, role),
                const SizedBox(height: 20),
                if (experience != null && role == 'Тренер')
                  _infoCard(
                    title: 'Стаж',
                    value: '${experience} лет',
                    icon: Icons.work_outline,
                  ),
                const SizedBox(height: 12),
                if (specialties.isNotEmpty && role == 'Тренер')
                  _infoCard(
                    title: 'Направления',
                    value: specialties.join(', '),
                    icon: Icons.fitness_center_outlined,
                  ),
                const SizedBox(height: 12),
                if (city != null)
                  _infoCard(
                    title: 'Город',
                    value: city,
                    icon: Icons.location_on_outlined,
                  ),
                const SizedBox(height: 12),
                _about(bio),
                const SizedBox(height: 24),
                _actions(context),
                if (widget.isTrainerView && !_isConnected) _connectButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Профиль',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, String? avatarUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFF2A2E38),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _nameAndRole(String name, String role) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              role,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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

  Widget _about(String? bio) {
    if (bio == null || bio.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'О себе',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
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

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _button(
              text: 'Назад',
              onTap: () => Navigator.pop(context),
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _button(
              text: 'Написать',
              isPrimary: true,
              onTap: _openChat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _button(
        text: 'Добавить клиента',
        isPrimary: true,
        onTap: _connect,
        loading: _isLoading,
      ),
    );
  }

  Widget _button({
    required String text,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? Colors.green.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? Colors.green.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: isPrimary ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}