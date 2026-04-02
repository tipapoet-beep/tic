import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile?> getProfile(String userId);
  Future<Profile> updateProfile(Profile profile);
  Future<String?> uploadAvatar(String userId, String filePath);
  Stream<Profile> getProfileStream(String userId);
}