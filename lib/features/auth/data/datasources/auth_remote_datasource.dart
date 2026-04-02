import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/helpers.dart';

class AuthRemoteDataSource {
  final SupabaseClient _client;
  
  AuthRemoteDataSource(this._client);
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.log('Attempting login for email: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('User not found');
      }
      
      // Получаем профиль пользователя
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();
      
      Logger.success('Login successful for user: ${response.user!.id}');
      
      return {
        'user': response.user,
        'session': response.session,
        'profile': profile,
      };
    } on AuthException catch (e) {
      Logger.error('Auth error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      Logger.error('Login failed', error: e);
      throw Exception('Failed to login: $e');
    }
  }
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      Logger.log('Attempting registration for email: $email');
      
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Registration failed');
      }
      
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      Logger.success('Registration successful for user: ${response.user!.id}');
      
      return {
        'user': response.user,
        'session': response.session,
      };
    } on AuthException catch (e) {
      Logger.error('Auth error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      Logger.error('Registration failed', error: e);
      throw Exception('Failed to register: $e');
    }
  }
  
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
      Logger.log('Logout successful');
    } catch (e) {
      Logger.error('Logout failed', error: e);
      throw Exception('Failed to logout: $e');
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      Logger.log('Password reset email sent to: $email');
    } catch (e) {
      Logger.error('Password reset failed', error: e);
      throw Exception('Failed to reset password: $e');
    }
  }
}