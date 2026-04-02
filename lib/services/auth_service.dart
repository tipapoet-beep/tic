import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Проверка и обновление сессии
  Future<bool> refreshSessionIfNeeded() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      // Проверяем, истёк ли токен
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt < now + 300) { // Если истекает через 5 минут или меньше
          print('Refreshing session...');
          final newSession = await _client.auth.refreshSession();
          return newSession != null;
        }
      }
      return true;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }

  // Получение текущего пользователя с проверкой сессии
  Future<User?> getCurrentUser() async {
    await refreshSessionIfNeeded();
    return _client.auth.currentUser;
  }

  // Выход из системы
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}