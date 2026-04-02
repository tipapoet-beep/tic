import '../entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> getEvents(String userId, DateTime start, DateTime end);
  Future<CalendarEvent> createEvent(CalendarEvent event);
  Future<CalendarEvent> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(String eventId);
  Future<CalendarEvent> createEventFromWorkout(String userId, String workoutId, String title, DateTime date);
}