import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trainapp/features/calendar/domain/repositories/calendar_repository_impl.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../data/datasources/calendar_remote_datasource.dart';
import '../../../../config/di/providers.dart';

// Провайдеры
final calendarRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CalendarRemoteDataSource(client);
});

final calendarRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(calendarRemoteDataSourceProvider);
  return CalendarRepositoryImpl(dataSource);
});

// Состояние календаря
class CalendarState {
  final List<CalendarEvent> events;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final bool isLoading;
  final String? error;

  CalendarState({
    this.events = const [],
    required this.focusedDay,
    this.selectedDay,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    List<CalendarEvent>? events,
    DateTime? focusedDay,
    DateTime? selectedDay,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      events: events ?? this.events,
      focusedDay: focusedDay ?? this.focusedDay,
      selectedDay: selectedDay ?? this.selectedDay,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ViewModel
class CalendarViewModel extends StateNotifier<CalendarState> {
  final CalendarRepository _repository;
  final Ref _ref;

  CalendarViewModel(this._repository, this._ref)
      : super(CalendarState(focusedDay: DateTime.now()));

  Future<String?> _getCurrentUserId() async {
    try {
      final userId = await _ref.read(currentUserIdProvider.future);
      return userId;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  Future<void> loadEvents(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        state = state.copyWith(
          isLoading: false, 
          error: 'Пользователь не авторизован'
        );
        return;
      }

      final events = await _repository.getEvents(userId, start, end);
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      print('Error loading events: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CalendarEvent?> createEvent(CalendarEvent event) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newEvent = await _repository.createEvent(event);
      state = state.copyWith(
        events: [...state.events, newEvent],
        isLoading: false,
      );
      return newEvent;
    } catch (e) {
      print('Error creating event: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<CalendarEvent?> updateEvent(CalendarEvent event) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateEvent(event);
      final updatedEvents = state.events.map((e) {
        return e.id == updated.id ? updated : e;
      }).toList();
      state = state.copyWith(events: updatedEvents, isLoading: false);
      return updated;
    } catch (e) {
      print('Error updating event: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteEvent(eventId);
      final updatedEvents = state.events.where((e) => e.id != eventId).toList();
      state = state.copyWith(events: updatedEvents, isLoading: false);
    } catch (e) {
      print('Error deleting event: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<CalendarEvent?> createEventFromWorkout(
    String workoutId,
    String title,
    DateTime date,
  ) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return null;

    return await createEvent(
      CalendarEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        startDate: date,
        type: EventType.workout,
        workoutId: workoutId,
        createdAt: DateTime.now(),
        colorHex: '#FFD700',
      ),
    );
  }

  void setFocusedDay(DateTime day) {
    state = state.copyWith(focusedDay: day);
  }

  void setSelectedDay(DateTime? day) {
    state = state.copyWith(selectedDay: day);
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.events.where((event) {
      return event.startDate.year == day.year &&
             event.startDate.month == day.month &&
             event.startDate.day == day.day;
    }).toList();
  }
}

// Провайдер ViewModel
final calendarViewModelProvider = StateNotifierProvider<CalendarViewModel, CalendarState>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  return CalendarViewModel(repository, ref);
});