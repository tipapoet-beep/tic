import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  
  AuthRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    
    final profile = result['profile'] as Map<String, dynamic>;
    return UserModel.fromJson(profile);
  }
  
  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final result = await _remoteDataSource.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
    
    return User(
      id: result['user']!.id,
      email: email,
      fullName: fullName,
      role: role,
    );
  }
  
  @override
  Future<void> logout() async {
    await _remoteDataSource.logout();
  }
  
  @override
  Future<User?> getCurrentUser() async {
    // TODO: Implement get current user
    return null;
  }
  
  @override
  Future<void> resetPassword(String email) async {
    await _remoteDataSource.resetPassword(email);
  }
  
  @override
  Stream<User?> onAuthStateChanged() {
    // TODO: Implement auth state changes
    return const Stream.empty();
  }
}