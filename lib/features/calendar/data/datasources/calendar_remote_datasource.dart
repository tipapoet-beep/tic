import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/calendar_event.dart';
import '../../../../core/base/base_datasource.dart';

class CalendarRemoteDataSource extends BaseDataSource {
  CalendarRemoteDataSource(super.client);

  // Получение событий за период
  Future<List<CalendarEvent>> getEvents(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      log('Fetching events for user $userId from ${start.toIso8601String()} to ${end.toIso8601String()}');

      final supabase = await client;
      final response = await supabase
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .gte('start_date', start.toIso8601String())
          .lte('start_date', end.toIso8601String())
          .order('start_date');

      return (response as List)
          .map((json) => CalendarEvent.fromJson(json))
          .toList();
    } catch (e) {
      logError('Failed to fetch events', error: e);
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Создание события
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      log('Creating event: ${event.title}');

      final supabase = await client;
      final response = await supabase
          .from('calendar_events')
          .insert(event.toJson())
          .select()
          .single();

      logSuccess('Event created');
      return CalendarEvent.fromJson(response);
    } catch (e) {
      logError('Failed to create event', error: e);
      throw Exception('Failed to create event: $e');
    }
  }

  // Обновление события
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    try {
      log('Updating event: ${event.id}');

      final supabase = await client;
      final response = await supabase
          .from('calendar_events')
          .update(event.toJson())
          .eq('id', event.id)
          .select()
          .single();

      logSuccess('Event updated');
      return CalendarEvent.fromJson(response);
    } catch (e) {
      logError('Failed to update event', error: e);
      throw Exception('Failed to update event: $e');
    }
  }

  // Удаление события
  Future<void> deleteEvent(String eventId) async {
    try {
      log('Deleting event: $eventId');

      final supabase = await client;
      await supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);

      logSuccess('Event deleted');
    } catch (e) {
      logError('Failed to delete event', error: e);
      throw Exception('Failed to delete event: $e');
    }
  }

  // Автоматическое создание события из тренировки
  Future<CalendarEvent> createEventFromWorkout(
    String userId,
    String workoutId,
    String title,
    DateTime date,
  ) async {
    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title,
      startDate: date,
      type: EventType.workout,
      workoutId: workoutId,
      createdAt: DateTime.now(),
      colorHex: '#FFD700', // Жёлтый цвет
    );

    return await createEvent(event);
  }
}