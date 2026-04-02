import 'package:trainapp/features/trainer/data/datasources/trainer_remote_datasource.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/trainer_repository.dart';

class TrainerRepositoryImpl implements TrainerRepository {
  final TrainerRemoteDataSource _remoteDataSource;
  
  TrainerRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<List<Client>> getClients(String trainerId) async {
    return await _remoteDataSource.getClients(trainerId);
  }
  
  @override
  Future<Client> getClientDetails(String clientId) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<void> addClient(String trainerId, String clientId) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<void> removeClient(String trainerId, String clientId) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<Map<String, dynamic>> getClientStats(String clientId) async {
    return await _remoteDataSource.getClientStats(clientId);
  }
  
  @override
  Future<List<Workout>> getClientWorkouts(String clientId) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<List<WorkoutTemplate>> getTemplates(String trainerId) async {
    return await _remoteDataSource.getTemplates(trainerId);
  }
  
  @override
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    return await _remoteDataSource.createTemplate(template);
  }
  
  @override
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteTemplate(String templateId) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<void> assignProgram(String clientId, String templateId, DateTime startDate) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<void> updateProgramProgress(String programId, int progress) async {
    // TODO: Implement
    throw UnimplementedError();
  }
  
  @override
  Future<List<Subscription>> getSubscriptions(String trainerId) async {
    return await _remoteDataSource.getSubscriptions(trainerId);
  }
  
  @override
  Future<Subscription> addSubscription(Subscription subscription) async {
    return await _remoteDataSource.addSubscription(subscription);
  }
  
  @override
  Future<void> updateSubscriptionStatus(String subscriptionId, String status) async {
    // TODO: Implement
    throw UnimplementedError();
  }
}