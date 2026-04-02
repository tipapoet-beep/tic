import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  
  ProfileRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<Profile?> getProfile(String userId) async {
    return await _remoteDataSource.getProfile(userId);
  }
  
  @override
  Future<Profile> updateProfile(Profile profile) async {
    return await _remoteDataSource.updateProfile(profile);
  }
  
  @override
  Future<String?> uploadAvatar(String userId, String filePath) async {
    return await _remoteDataSource.uploadAvatar(userId, filePath);
  }
  
  @override
  Stream<Profile> getProfileStream(String userId) {
    return _remoteDataSource.getProfileStream(userId);
  }
}