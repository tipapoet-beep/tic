import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../../../core/base/base_datasource.dart';
import '../../../trainer/domain/entities/client.dart';

class ScheduleRemoteDataSource extends BaseDataSource {
  ScheduleRemoteDataSource(super.client);

  // Получение слотов за неделю
  Future<List<ScheduleSlot>> getWeekSchedule(String trainerId, DateTime startOfWeek, DateTime endOfWeek) async {
    try {
      log('Fetching schedule for trainer $trainerId from ${startOfWeek.toIso8601String()} to ${endOfWeek.toIso8601String()}');

      final supabase = await client;
      final response = await supabase
          .from('schedule_slots')
          .select('''
            *,
            client:client_id (
              id, full_name, avatar_url, is_registered, phone, telegram
            ),
            unregistered_client:unregistered_client_id (
              id, full_name, phone, telegram
            )
          ''')
          .eq('trainer_id', trainerId)
          .gte('start_time', startOfWeek.toIso8601String())
          .lte('start_time', endOfWeek.toIso8601String())
          .order('start_time');

      log('Found ${response.length} slots');

      return (response as List).map((json) {
        final slot = ScheduleSlot.fromJson(json);
        
        // Если есть зарегистрированный клиент
        if (json['client'] != null) {
          final client = Client(
            id: json['client']['id'],
            email: '',
            fullName: json['client']['full_name'] ?? '',
            avatarUrl: json['client']['avatar_url'],
            workoutsCompleted: 0,
            currentStreak: 0,
            hasActiveSubscription: false,
            isRegistered: json['client']['is_registered'] ?? true,
            phone: json['client']['phone'],
            telegram: json['client']['telegram'],
            notes: null,
          );
          return slot.copyWith(client: client);
        }
        
        // Если есть незарегистрированный клиент
        if (json['unregistered_client'] != null) {
          return slot.copyWith(
            unregisteredClientName: json['unregistered_client']['full_name'],
          );
        }
        
        return slot;
      }).toList();
    } catch (e) {
      logError('Failed to fetch schedule', error: e);
      throw Exception('Failed to fetch schedule: $e');
    }
  }

  // Создание слота для зарегистрированного клиента
  Future<ScheduleSlot> createSlotForRegistered(ScheduleSlot slot) async {
    try {
      log('Creating schedule slot for registered client ${slot.clientId} at ${slot.startTime}');

      final supabase = await client;
      final response = await supabase
          .from('schedule_slots')
          .insert({
            'id': slot.id,
            'trainer_id': slot.trainerId,
            'client_id': slot.clientId,
            'start_time': slot.startTime.toIso8601String(),
            'end_time': slot.endTime.toIso8601String(),
            'workout_id': slot.workoutId,
            'workout_title': slot.workoutTitle,
            'notes': slot.notes,
          })
          .select()
          .single();

      logSuccess('Schedule slot created');
      return ScheduleSlot.fromJson(response);
    } catch (e) {
      logError('Failed to create schedule slot', error: e);
      throw Exception('Failed to create schedule slot: $e');
    }
  }

  // Создание слота для незарегистрированного клиента
  Future<ScheduleSlot> createSlotForUnregistered(ScheduleSlot slot) async {
    try {
      log('Creating schedule slot for unregistered client ${slot.unregisteredClientId} at ${slot.startTime}');

      final supabase = await client;
      final response = await supabase
          .from('schedule_slots')
          .insert({
            'id': slot.id,
            'trainer_id': slot.trainerId,
            'unregistered_client_id': slot.unregisteredClientId,
            'start_time': slot.startTime.toIso8601String(),
            'end_time': slot.endTime.toIso8601String(),
            'workout_id': slot.workoutId,
            'workout_title': slot.workoutTitle,
            'notes': slot.notes,
          })
          .select()
          .single();

      logSuccess('Schedule slot created for unregistered client');
      return ScheduleSlot.fromJson(response);
    } catch (e) {
      logError('Failed to create schedule slot', error: e);
      throw Exception('Failed to create schedule slot: $e');
    }
  }

  // Обновление слота
  Future<ScheduleSlot> updateSlot(ScheduleSlot slot) async {
    try {
      log('Updating schedule slot ${slot.id}');

      final supabase = await client;
      final response = await supabase
          .from('schedule_slots')
          .update({
            'start_time': slot.startTime.toIso8601String(),
            'end_time': slot.endTime.toIso8601String(),
            'workout_id': slot.workoutId,
            'workout_title': slot.workoutTitle,
            'is_completed': slot.isCompleted,
            'notes': slot.notes,
          })
          .eq('id', slot.id)
          .select()
          .single();

      logSuccess('Schedule slot updated');
      return ScheduleSlot.fromJson(response);
    } catch (e) {
      logError('Failed to update schedule slot', error: e);
      throw Exception('Failed to update schedule slot: $e');
    }
  }

  // Удаление слота
  Future<void> deleteSlot(String slotId) async {
    try {
      log('Deleting schedule slot $slotId');

      final supabase = await client;
      await supabase
          .from('schedule_slots')
          .delete()
          .eq('id', slotId);

      logSuccess('Schedule slot deleted');
    } catch (e) {
      logError('Failed to delete schedule slot', error: e);
      throw Exception('Failed to delete schedule slot: $e');
    }
  }

  // Отметка выполнения
  Future<void> toggleCompletion(String slotId, bool isCompleted) async {
    try {
      final supabase = await client;
      await supabase
          .from('schedule_slots')
          .update({'is_completed': isCompleted})
          .eq('id', slotId);
      
      log('Toggled completion for slot $slotId to $isCompleted');
    } catch (e) {
      logError('Failed to toggle completion', error: e);
      throw Exception('Failed to toggle completion: $e');
    }
  }
}