import 'package:trainapp/features/calendar/data/datasources/calendar_remote_datasource.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';


class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _remoteDataSource;

  CalendarRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CalendarEvent>> getEvents(String userId, DateTime start, DateTime end) async {
    return await _remoteDataSource.getEvents(userId, start, end);
  }

  @override
  Future<CalendarEvent> createEvent(CalendarEvent event) async {
    return await _remoteDataSource.createEvent(event);
  }

  @override
  Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    return await _remoteDataSource.updateEvent(event);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _remoteDataSource.deleteEvent(eventId);
  }

  @override
  Future<CalendarEvent> createEventFromWorkout(String userId, String workoutId, String title, DateTime date) async {
    return await _remoteDataSource.createEventFromWorkout(userId, workoutId, title, date);
  }
}