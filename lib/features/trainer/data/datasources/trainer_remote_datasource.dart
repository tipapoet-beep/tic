import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trainapp/core/base/base_datasource.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/template_exercise.dart';
import '../../domain/entities/subscription.dart';

class TrainerRemoteDataSource extends BaseDataSource {
  TrainerRemoteDataSource(super.client);
  
  // Получение списка клиентов
  Future<List<Client>> getClients(String trainerId) async {
    try {
      log('Fetching clients for trainer: $trainerId');
      
      final supabase = await client;
      final response = await supabase
          .from('trainer_clients')
          .select('''
            client_id,
            status,
            start_date,
            profiles:client_id (
              id, email, full_name, avatar_url, age, height, weight, goals,
              is_registered, phone, telegram, notes
            )
          ''')
          .eq('trainer_id', trainerId);
      
      final clients = <Client>[];
      for (final item in response) {
        final profile = item['profiles'];
        if (profile != null) {
          clients.add(Client(
            id: profile['id'],
            email: profile['email'] ?? '',
            fullName: profile['full_name'] ?? '',
            avatarUrl: profile['avatar_url'],
            age: profile['age'],
            height: profile['height']?.toDouble(),
            weight: profile['weight']?.toDouble(),
            goals: profile['goals'] != null ? List<String>.from(profile['goals']) : null,
            startDate: item['start_date'] != null ? DateTime.parse(item['start_date']) : null,
            lastActive: null,
            workoutsCompleted: 0,
            currentStreak: 0,
            hasActiveSubscription: false,
            subscriptionEnds: null,
            isRegistered: profile['is_registered'] ?? true,
            phone: profile['phone'],
            telegram: profile['telegram'],
            notes: profile['notes'],
          ));
        }
      }
      
      // Добавляем незарегистрированных клиентов
      final unregisteredResponse = await supabase
          .from('unregistered_clients')
          .select('''
            id, full_name, email, phone, created_at
          ''')
          .eq('trainer_id', trainerId);
      
      for (final item in unregisteredResponse) {
        clients.add(Client(
          id: item['id'],
          email: item['email'] ?? '',
          fullName: item['full_name'] ?? '',
          avatarUrl: null,
          age: null,
          height: null,
          weight: null,
          goals: null,
          startDate: item['created_at'] != null ? DateTime.parse(item['created_at']) : null,
          lastActive: null,
          workoutsCompleted: 0,
          currentStreak: 0,
          hasActiveSubscription: false,
          subscriptionEnds: null,
          isRegistered: false,
          phone: item['phone'],
          telegram: null,
          notes: null,
        ));
      }
      
      return clients;
    } catch (e) {
      logError('Failed to fetch clients', error: e);
      throw Exception('Failed to fetch clients: $e');
    }
  }
  
  // Добавление клиента (существующего пользователя)
  Future<void> addClient(String trainerId, String clientId) async {
    try {
      log('Adding client $clientId for trainer $trainerId');
      
      final supabase = await client;
      await supabase
          .from('trainer_clients')
          .insert({
            'trainer_id': trainerId,
            'client_id': clientId,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      logError('Failed to add client', error: e);
      throw Exception('Failed to add client: $e');
    }
  }
  
  // Удаление клиента
  Future<void> removeClient(String trainerId, String clientId) async {
    try {
      log('Removing client $clientId from trainer $trainerId');
      
      final supabase = await client;
      await supabase
          .from('trainer_clients')
          .delete()
          .eq('trainer_id', trainerId)
          .eq('client_id', clientId);
          
      await supabase
          .from('unregistered_clients')
          .delete()
          .eq('trainer_id', trainerId)
          .eq('id', clientId);
    } catch (e) {
      logError('Failed to remove client', error: e);
      throw Exception('Failed to remove client: $e');
    }
  }
  
  // Остальные методы остаются без изменений...
  Future<List<WorkoutTemplate>> getTemplates(String trainerId) async {
    try {
      log('Fetching templates for trainer: $trainerId');
      
      final supabase = await client;
      final response = await supabase
          .from('workout_templates')
          .select('*, template_exercises(*)')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) {
        final template = WorkoutTemplate.fromJson(json);
        final exercises = (json['template_exercises'] as List)
            .map((e) => TemplateExercise.fromJson(e))
            .toList();
        return template.copyWith(exercises: exercises);
      }).toList();
    } catch (e) {
      logError('Failed to fetch templates', error: e);
      throw Exception('Failed to fetch templates: $e');
    }
  }
  
  Future<WorkoutTemplate> createTemplate(WorkoutTemplate template) async {
    try {
      log('Creating template: ${template.title}');
      
      final supabase = await client;
      
      final templateResponse = await supabase
          .from('workout_templates')
          .insert(template.toJson())
          .select()
          .single();
      
      if (template.exercises.isNotEmpty) {
        for (final exercise in template.exercises) {
          await supabase.from('template_exercises').insert({
            ...exercise.toJson(),
            'template_id': templateResponse['id'],
          });
        }
      }
      
      return await getTemplate(templateResponse['id']);
    } catch (e) {
      logError('Failed to create template', error: e);
      throw Exception('Failed to create template: $e');
    }
  }
  
  Future<WorkoutTemplate> getTemplate(String templateId) async {
    try {
      final supabase = await client;
      final response = await supabase
          .from('workout_templates')
          .select('*, template_exercises(*)')
          .eq('id', templateId)
          .single();
      
      final template = WorkoutTemplate.fromJson(response);
      final exercises = (response['template_exercises'] as List)
          .map((e) => TemplateExercise.fromJson(e))
          .toList();
      
      return template.copyWith(exercises: exercises);
    } catch (e) {
      logError('Failed to fetch template', error: e);
      throw Exception('Failed to fetch template: $e');
    }
  }
  
  Future<List<Subscription>> getSubscriptions(String trainerId) async {
    try {
      log('Fetching subscriptions for trainer: $trainerId');
      
      final supabase = await client;
      final response = await supabase
          .from('subscriptions')
          .select('*')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Subscription.fromJson(json)).toList();
    } catch (e) {
      logError('Failed to fetch subscriptions', error: e);
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }
  
  Future<Subscription> addSubscription(Subscription subscription) async {
    try {
      log('Adding subscription for client: ${subscription.clientId}');
      
      final supabase = await client;
      final response = await supabase
          .from('subscriptions')
          .insert(subscription.toJson())
          .select()
          .single();
      
      return Subscription.fromJson(response);
    } catch (e) {
      logError('Failed to add subscription', error: e);
      throw Exception('Failed to add subscription: $e');
    }
  }
  
  Future<Map<String, dynamic>> getClientStats(String clientId) async {
    try {
      log('Fetching stats for client: $clientId');
      
      final supabase = await client;
      
      final workouts = await supabase
          .from('workouts')
          .select('*')
          .eq('client_id', clientId);
      
      final totalWorkouts = workouts.length;
      final completedWorkouts = workouts.where((w) => w['is_completed'] == true).length;
      
      final subscriptions = await supabase
          .from('subscriptions')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);
      
      Map<String, dynamic>? activeSubscription;
      for (final sub in subscriptions) {
        if (sub['status'] == 'active' && 
            DateTime.parse(sub['end_date']).isAfter(DateTime.now())) {
          activeSubscription = sub;
          break;
        }
      }
      
      return {
        'total_workouts': totalWorkouts,
        'completed_workouts': completedWorkouts,
        'completion_rate': totalWorkouts > 0 
            ? (completedWorkouts / totalWorkouts * 100).round() 
            : 0,
        'active_subscription': activeSubscription != null,
        'subscription_end': activeSubscription != null 
            ? activeSubscription['end_date'] 
            : null,
      };
    } catch (e) {
      logError('Failed to fetch client stats', error: e);
      throw Exception('Failed to fetch client stats: $e');
    }
  }
}