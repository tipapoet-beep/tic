import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/helpers.dart';
import '../../services/auth_service.dart';

abstract class BaseDataSource {
  final SupabaseClient _client;
  
  BaseDataSource(this._client);

  // Для обычных запросов - с обновлением сессии
  Future<SupabaseClient> get client async {
    await AuthService().refreshSessionIfNeeded();
    return _client;
  }

  // Для стримов - прямой доступ без Future (стримы не могут быть async)
  SupabaseClient get rawClient => _client;

  void log(String message) => Logger.log(message);
  void logError(String message, {dynamic error}) => Logger.error(message, error: error);
  void logSuccess(String message) => Logger.success(message);
}