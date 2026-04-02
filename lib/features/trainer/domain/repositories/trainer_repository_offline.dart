import 'package:trainapp/features/trainer/data/datasources/trainer_remote_datasource.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/trainer_repository.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../../core/utils/logger.dart';
import 'package:uuid/uuid.dart';

class TrainerRepositoryOffline implements TrainerRepository {
  final TrainerRemoteDataSource _remoteDataSource;
  final LocalDatabase _localDb;
  final SyncManager _syncManager;
  
  TrainerRepositoryOffline(this._remoteDataSource)
      : _localDb = LocalDatabase(),
        _syncManager = SyncManager();
  
  @override
  Future<List<Client>> getClients(String trainerId) async {
    final localKey = 'clients_$trainerId';
    
    // Сначала пробуем локально
    final localData = await _localDb.get(LocalDatabase.clientsBox, localKey);
    
    if (localData != null && localData['clients'] != null) {
      final clients = (localData['clients'] as List)
          .map((json) => Client.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Фоново обновляем, если есть интернет
      if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
        _syncManager.getData(
          table: 'trainer_clients',
          id: localKey,
          remoteGetter: () async => await _remoteDataSource.getClients(trainerId),
          localGetter: () async => clients,
          localSaver: (data) async => await _localDb.put(
            LocalDatabase.clientsBox,
            localKey,
            {'clients': data.map((c) => c.toJson()).toList()},
          ),
        );
      }
      
      return clients;
    }
    
    // Если локально пусто, пытаемся с сервера
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        final remote = await _remoteDataSource.getClients(trainerId);
        await _localDb.put(
          LocalDatabase.clientsBox,
          localKey,
          {'clients': remote.map((c) => c.toJson()).toList()},
        );
        return remote;
      } catch (e) {
        Logger.error('Failed to load clients', error: e);
        return [];
      }
    }
    
    return [];
  }
  
  @override
  Future<Client> getClientDetails(String clientId) async {
    // Сначала пробуем локально
    final localData = await _localDb.get(LocalDatabase.clientsBox, clientId);
    
    if (localData != null) {
      return Client.fromJson(localData);
    }
    
    // Если локально нет, пробуем с сервера
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        // TODO: implement getClientDetails in remote datasource
        throw UnimplementedError();
      } catch (e) {
        Logger.error('Failed to load client details', error: e);
      }
    }
    
    throw Exception('Client not found');
  }
  
  @override
  Future<void> addClient(String trainerId, String clientId) async {
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        await _remoteDataSource.addClient(trainerId, clientId);
        
        // Обновляем локальный кеш
        final clients = await getClients(trainerId);
        await _localDb.put(
          LocalDatabase.clientsBox,
          'clients_$trainerId',
          {'clients': clients.map((c) => c.toJson()).toList()},
        );
      } catch (e) {
        Logger.error('Failed to add client', error: e);
        rethrow;
      }
    } else {
      // В офлайн-режиме добавляем в очередь
      await _syncManager.addToQueue(
        SyncEntry(
          id: const Uuid().v4(),
          tableName: 'trainer_clients',
          recordId: clientId,
          data: {
            'trainer_id': trainerId,
            'client_id': clientId,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
          },
          status: SyncStatus.pending,
          createdAt: DateTime.now(),
          version: 1,
        ),
      );
    }
  }
  
  @override
  Future<void> removeClient(String trainerId, String clientId) async {
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        await _remoteDataSource.removeClient(trainerId, clientId);
      } catch (e) {
        Logger.error('Failed to remove client', error: e);
        rethrow;
      }
    } else {
      await _syncManager.addToQueue(
        SyncEntry(
          id: const Uuid().v4(),
          tableName: 'trainer_clients',
          recordId: clientId,
          data: {'_deleted': true, 'trainer_id': trainerId},
          status: SyncStatus.pending,
          createdAt: DateTime.now(),
          version: 1,
        ),
      );
    }
  }
  
  @override
  Future<Map<String, dynamic>> getClientStats(String clientId) async {
    if (_syncManager.connectionStatus.value == ConnectionStatus.online) {
      try {
        return await _remoteDataSource.getClientStats(clientId);
      } catch (e) {
        Logger.error('Failed to get client stats', error: e);
      }
    }
    
    // Возвращаем заглушку в офлайн-режиме
    return {
      'total_workouts': 0,
      'completed_workouts': 0,
      'completion_rate': 0,
      'active_subscription': false,
      'subscription_end': null,
    };
  }
  
  @override
  Future<List<Workout>> getClientWorkouts(String clientId) async {
    // TODO: implement getClientWorkouts
    throw UnimplementedError();
  }
  
  @override
  Future<List<WorkoutTemplate>> getTemplates(String trainerId) async {
    // TODO: implement getTemplates
    throw UnimplementedError();
  }
  
  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    // TODO: implement createTemplate
    throw UnimplementedError();
  }
  
  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    // TODO: implement updateTemplate
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteTemplate(String templateId) async {
    // TODO: implement deleteTemplate
    throw UnimplementedError();
  }
  
  @override
  Future<void> assignProgram(String clientId, String templateId, DateTime startDate) async {
    // TODO: implement assignProgram
    throw UnimplementedError();
  }
  
  @override
  Future<void> updateProgramProgress(String programId, int progress) async {
    // TODO: implement updateProgramProgress
    throw UnimplementedError();
  }
  
  @override
  Future<List<Subscription>> getSubscriptions(String trainerId) async {
    // TODO: implement getSubscriptions
    throw UnimplementedError();
  }
  
  @override
  Future<Subscription> addSubscription(Subscription subscription) async {
    // TODO: implement addSubscription
    throw UnimplementedError();
  }
  
  @override
  Future<void> updateSubscriptionStatus(String subscriptionId, String status) async {
    // TODO: implement updateSubscriptionStatus
    throw UnimplementedError();
  }
}