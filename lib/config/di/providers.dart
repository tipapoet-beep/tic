import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

// Провайдер для AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Провайдер для Supabase клиента
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Провайдер для текущего пользователя с автообновлением
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUser();
});

// Провайдер для ID текущего пользователя
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  return user?.id;
});