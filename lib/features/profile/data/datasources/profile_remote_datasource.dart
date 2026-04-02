import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/profile.dart';
import '../../../../core/base/base_datasource.dart';
import 'dart:io';

class ProfileRemoteDataSource extends BaseDataSource {
  ProfileRemoteDataSource(super.client);
  
  Future<Profile?> getProfile(String userId) async {
    try {
      log('Fetching profile for user: $userId');
      
      final supabase = await client;
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Profile.fromJson(response);
    } catch (e) {
      logError('Failed to fetch profile', error: e);
      return null;
    }
  }
  
  Future<Profile> updateProfile(Profile profile) async {
    try {
      log('Updating profile for user: ${profile.id}');
      
      final supabase = await client;
      final response = await supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();
      
      logSuccess('Profile updated successfully');
      return Profile.fromJson(response);
    } catch (e) {
      logError('Failed to update profile', error: e);
      throw Exception('Failed to update profile: $e');
    }
  }
  
  Future<String?> uploadAvatar(String userId, String filePath) async {
    try {
      log('Uploading avatar for user: $userId');
      
      final supabase = await client;
      final file = File(filePath);
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'avatars/$userId/$fileName';
      
      await supabase.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);
      logSuccess('Avatar uploaded: $publicUrl');
      
      return publicUrl;
    } catch (e) {
      logError('Failed to upload avatar', error: e);
      return null;
    }
  }
  
  Stream<Profile> getProfileStream(String userId) {
    // Используем rawClient для стримов
    return rawClient
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((response) => Profile.fromJson(response.first));
  }
}