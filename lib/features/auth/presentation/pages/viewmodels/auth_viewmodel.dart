import 'package:flutter_riverpod/legacy.dart';

import '/config/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../../../config/di/providers.dart';  // ВАЖНО: импортируем провайдеры

// Провайдеры
final authRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);  // теперь supabaseClientProvider найден
  return AuthRemoteDataSource(client);
});

final authRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final loginUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LoginUseCase(repository);
});

final registerUseCaseProvider = Provider((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return RegisterUseCase(repository);
});

// Состояние
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  
  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ViewModel
class AuthViewModel extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  
  AuthViewModel(this._loginUseCase, this._registerUseCase) : super(AuthState());
  
  get ref => null;
  
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _loginUseCase(
        email: email,
        password: password,
      );
      
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _registerUseCase(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
  
  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = AuthState();
  }
}

// Провайдер ViewModel
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  final registerUseCase = ref.watch(registerUseCaseProvider);
  return AuthViewModel(loginUseCase, registerUseCase);
});