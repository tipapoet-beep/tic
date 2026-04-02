import 'package:trainapp/features/profile/data/datasources/profile_remote_datasource.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/logger.dart';
import 'package:uuid/uuid.dart';

class ProfileRepositoryOffline implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final LocalDatabase _localDb;
  final SyncManager _syncManager;
  
  ProfileRepositoryOffline(this._remoteDataSource)
      : _localDb = LocalDatabase(),
        _syncManager = SyncManager();
  
  @override
  Future<Profile?> getProfile(String userId) async {
    // Сначала пробуем локально
    final localData = await _localDb.get(LocalDatabase.profilesBox, userId);
    
    if (localData != null) {
      final profile = Profile.fromJson(localData);
      
      // Фоново обновляем, если есть интернет
      if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
        _syncManager.getData(
          table: 'profiles',
          id: userId,
          remoteGetter: () => _remoteDataSource.getProfile(userId),
          localGetter: () async => profile,
          localSaver: (p) async => await _localDb.put(
            LocalDatabase.profilesBox,
            userId,
            p.toJson(),
          ),
        );
      }
      
      return profile;
    }
    
    // Если локально нет, пробуем с сервера
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        final remote = await _remoteDataSource.getProfile(userId);
        if (remote != null) {
          await _localDb.put(
            LocalDatabase.profilesBox,
            userId,
            remote.toJson(),
          );
          return remote;
        }
      } catch (e) {
        Logger.error('Failed to load profile', error: e);
      }
    }
    
    return null;
  }
  
  @override
  Future<Profile> updateProfile(Profile profile) async {
    // Получаем текущую версию из локальной БД
    final existing = await _localDb.get(LocalDatabase.profilesBox, profile.id);
    int currentVersion = 1;
    
    if (existing != null && existing.containsKey('_sync_version')) {
      currentVersion = existing['_sync_version'] as int? ?? 1;
    }
    
    // Сохраняем локально с версией
    final dataWithVersion = {
      ...profile.toJson(),
      '_sync_version': currentVersion + 1,
      '_last_modified': DateTime.now().toIso8601String(),
    };
    
    await _localDb.put(
      LocalDatabase.profilesBox,
      profile.id,
      dataWithVersion,
    );
    
    // Добавляем в очередь синхронизации
    await _syncManager.addToQueue(
      SyncEntry(
        id: const Uuid().v4(),
        tableName: 'profiles',
        recordId: profile.id,
        data: profile.toJson(),
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
        version: currentVersion + 1,
      ),
    );
    
    return profile;
  }
  
  @override
  Future<String?> uploadAvatar(String userId, String filePath) async {
    if (_syncManager.connectionStatus.value == ConnectionStatus.offline) {
      // В офлайн-режиме не можем загрузить фото
      throw Exception('Cannot upload avatar while offline');
    }
    
    try {
      final url = await _remoteDataSource.uploadAvatar(userId, filePath);
      
      // Обновляем профиль с новым URL аватара
      final profile = await getProfile(userId);
      if (profile != null && url != null) {
        await updateProfile(profile.copyWith(avatarUrl: url));
      }
      
      return url;
    } catch (e) {
      Logger.error('Failed to upload avatar', error: e);
      rethrow;
    }
  }
  
  @override
  Stream<Profile> getProfileStream(String userId) {
    // TODO: реализовать стрим с локальной БД
    throw UnimplementedError();
  }
}