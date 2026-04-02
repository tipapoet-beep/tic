import 'package:trainapp/features/trainer/domain/entities/subscription.dart';
import 'package:trainapp/features/trainer/domain/entities/workout_template.dart';

import '../entities/client.dart';

abstract class TrainerRepository {
  // Управление клиентами
  Future<List<Client>> getClients(String trainerId);
  Future<Client> getClientDetails(String clientId);
  Future<void> addClient(String trainerId, String clientId);
  Future<void> removeClient(String trainerId, String clientId);
  
  // Статистика по клиентам
  Future<Map<String, dynamic>> getClientStats(String clientId);
  Future<List<Workout>> getClientWorkouts(String clientId);
  
  // Шаблоны тренировок
  Future<List<WorkoutTemplate>> getTemplates(String trainerId);
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template);
  Future<WorkoutTemplate> updateTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(String templateId);
  
  // Назначение программ
  Future<void> assignProgram(String clientId, String templateId, DateTime startDate);
  Future<void> updateProgramProgress(String programId, int progress);
  
  // Финансы
  Future<List<Subscription>> getSubscriptions(String trainerId);
  Future<Subscription> addSubscription(Subscription subscription);
  Future<void> updateSubscriptionStatus(String subscriptionId, String status);
}

class Workout {
}