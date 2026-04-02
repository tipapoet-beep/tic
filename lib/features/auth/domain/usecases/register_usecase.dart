import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  
  RegisterUseCase(this.repository);
  
  Future<User> call({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
      throw Exception('Все поля обязательны для заполнения');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Неверный формат email');
    }
    
    if (password.length < 6) {
      throw Exception('Пароль должен быть не менее 6 символов');
    }
    
    if (role != 'client' && role != 'trainer') {
      throw Exception('Некорректная роль пользователя');
    }
    
    return await repository.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
  }
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}