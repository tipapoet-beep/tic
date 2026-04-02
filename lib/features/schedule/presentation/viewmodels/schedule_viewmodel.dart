import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trainapp/features/schedule/data/datasource/schedule_remote_datasource.dart';
import 'package:trainapp/features/schedule/domain/repositories/schedule_repository_impl.dart';
import 'package:trainapp/features/trainer/domain/entities/client.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../../../config/di/providers.dart';


// Провайдеры
final scheduleRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ScheduleRemoteDataSource(client);
});

final scheduleRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(scheduleRemoteDataSourceProvider);
  return ScheduleRepositoryImpl(dataSource);
});

// Состояние
class ScheduleState {
  final List<ScheduleSlot> slots;
  final DateTime currentWeekStart;
  final bool isLoading;
  final String? error;
  final Map<int, List<ScheduleSlot>> slotsByHour;
  final Map<String, Client> registeredClients;
  final Map<String, Map<String, dynamic>> unregisteredClients;

  ScheduleState({
    this.slots = const [],
    required this.currentWeekStart,
    this.isLoading = false,
    this.error,
    Map<int, List<ScheduleSlot>>? slotsByHour,
    this.registeredClients = const {},
    this.unregisteredClients = const {},
  }) : slotsByHour = slotsByHour ?? {};

  ScheduleState copyWith({
    List<ScheduleSlot>? slots,
    DateTime? currentWeekStart,
    bool? isLoading,
    String? error,
    Map<int, List<ScheduleSlot>>? slotsByHour,
    Map<String, Client>? registeredClients,
    Map<String, Map<String, dynamic>>? unregisteredClients,
  }) {
    return ScheduleState(
      slots: slots ?? this.slots,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      slotsByHour: slotsByHour ?? this.slotsByHour,
      registeredClients: registeredClients ?? this.registeredClients,
      unregisteredClients: unregisteredClients ?? this.unregisteredClients,
    );
  }
}

// ViewModel
class ScheduleViewModel extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;
  final Ref _ref;

  ScheduleViewModel(this._repository, this._ref)
      : super(ScheduleState(currentWeekStart: _getStartOfWeek(DateTime.now())));

  static DateTime _getStartOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String getWeekRange() {
    final start = state.currentWeekStart;
    final end = start.add(const Duration(days: 6));
    return '${start.day}.${start.month} - ${end.day}.${end.month}';
  }

  Future<void> loadWeekSchedule() async {
    print('🔄 Loading week schedule...');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userId = await _ref.read(currentUserIdProvider.future);
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Пользователь не авторизован');
        return;
      }

      final endOfWeek = state.currentWeekStart.add(const Duration(days: 7));
      final slots = await _repository.getWeekSchedule(userId, state.currentWeekStart, endOfWeek);
      
      final Map<int, List<ScheduleSlot>> slotsByHour = {};
      for (final slot in slots) {
        final hour = slot.hour;
        if (!slotsByHour.containsKey(hour)) {
          slotsByHour[hour] = [];
        }
        slotsByHour[hour]!.add(slot);
      }
      
      state = state.copyWith(slots: slots, slotsByHour: slotsByHour, isLoading: false);
      
    } catch (e, stackTrace) {
      print('❌ Error loading schedule: $e');
      print('📚 Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadClients() async {
    try {
      final userId = await _ref.read(currentUserIdProvider.future);
      if (userId == null) return;

      final registeredResponse = await _ref.read(supabaseClientProvider)
          .from('trainer_clients')
          .select('''
            client_id,
            profiles:client_id (
              id, full_name, avatar_url
            )
          ''')
          .eq('trainer_id', userId);

      final Map<String, Client> registeredClients = {};
      for (final item in registeredResponse) {
        final profile = item['profiles'];
        if (profile != null) {
          registeredClients[profile['id']] = Client(
            id: profile['id'],
            email: '',
            fullName: profile['full_name'] ?? '',
            avatarUrl: profile['avatar_url'],
            workoutsCompleted: 0,
            currentStreak: 0,
            hasActiveSubscription: false,
            isRegistered: true,
          );
        }
      }

      final unregisteredResponse = await _ref.read(supabaseClientProvider)
          .from('unregistered_clients')
          .select('id, full_name')
          .eq('trainer_id', userId);

      final Map<String, Map<String, dynamic>> unregisteredClients = {};
      for (final item in unregisteredResponse) {
        unregisteredClients[item['id']] = {
          'id': item['id'],
          'fullName': item['full_name'],
        };
      }

      state = state.copyWith(
        registeredClients: registeredClients,
        unregisteredClients: unregisteredClients,
      );
    } catch (e) {
      print('❌ Error loading clients: $e');
    }
  }

  Future<void> nextWeek() async {
    final nextWeekStart = state.currentWeekStart.add(const Duration(days: 7));
    state = state.copyWith(currentWeekStart: nextWeekStart);
    await loadWeekSchedule();
  }

  Future<void> previousWeek() async {
    final prevWeekStart = state.currentWeekStart.subtract(const Duration(days: 7));
    state = state.copyWith(currentWeekStart: prevWeekStart);
    await loadWeekSchedule();
  }

  Future<void> goToCurrentWeek() async {
    final currentWeekStart = _getStartOfWeek(DateTime.now());
    state = state.copyWith(currentWeekStart: currentWeekStart);
    await loadWeekSchedule();
  }

  Future<ScheduleSlot?> createSlot({
    required String clientId,
    required DateTime startTime,
    required DateTime endTime,
    bool isRegistered = true,
    String? workoutId,
    String? workoutTitle,
    String? notes,
  }) async {
    print('➕ Creating slot for client $clientId at $startTime');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userId = await _ref.read(currentUserIdProvider.future);
      if (userId == null) throw Exception('Пользователь не авторизован');

      final uuid = const Uuid();
      
      final Map<String, dynamic> slotData = {
        'id': workoutId ?? uuid.v4(),
        'trainer_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'workout_id': workoutId,
        'workout_title': workoutTitle,
        'is_completed': false,
        'notes': notes,
      };

      if (isRegistered) {
        slotData['client_id'] = clientId;
      } else {
        slotData['unregistered_client_id'] = clientId;
      }

      print('📅 Slot data: $slotData');

      final supabase = _ref.read(supabaseClientProvider);
      final response = await supabase
          .from('schedule_slots')
          .insert(slotData)
          .select()
          .single();

      final newSlot = ScheduleSlot.fromJson(response);
      
      final updatedSlots = [...state.slots, newSlot];
      final updatedSlotsByHour = Map<int, List<ScheduleSlot>>.from(state.slotsByHour);
      final hour = newSlot.hour;
      
      if (!updatedSlotsByHour.containsKey(hour)) {
        updatedSlotsByHour[hour] = [];
      }
      updatedSlotsByHour[hour]!.add(newSlot);
      
      state = state.copyWith(
        slots: updatedSlots,
        slotsByHour: updatedSlotsByHour,
        isLoading: false,
      );
      
      return newSlot;
    } catch (e) {
      print('❌ Error creating slot: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await _repository.deleteSlot(slotId);
      
      final updatedSlots = state.slots.where((s) => s.id != slotId).toList();
      final Map<int, List<ScheduleSlot>> updatedSlotsByHour = {};
      
      for (final slot in updatedSlots) {
        final hour = slot.hour;
        if (!updatedSlotsByHour.containsKey(hour)) {
          updatedSlotsByHour[hour] = [];
        }
        updatedSlotsByHour[hour]!.add(slot);
      }
      
      state = state.copyWith(slots: updatedSlots, slotsByHour: updatedSlotsByHour);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleCompletion(String slotId) async {
    try {
      final slot = state.slots.firstWhere((s) => s.id == slotId);
      final newStatus = !slot.isCompleted;
      
      await _repository.toggleCompletion(slotId, newStatus);
      
      final updatedSlots = state.slots.map((s) {
        if (s.id == slotId) {
          return s.copyWith(isCompleted: newStatus);
        }
        return s;
      }).toList();
      
      final updatedSlotsByHour = Map<int, List<ScheduleSlot>>.from(state.slotsByHour);
      final hour = slot.hour;
      
      if (updatedSlotsByHour.containsKey(hour)) {
        updatedSlotsByHour[hour] = updatedSlotsByHour[hour]!.map((s) {
          if (s.id == slotId) {
            return s.copyWith(isCompleted: newStatus);
          }
          return s;
        }).toList();
      }
      
      state = state.copyWith(slots: updatedSlots, slotsByHour: updatedSlotsByHour);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Возвращает список слотов для конкретного дня
  List<ScheduleSlot> getSlotsForDay(DateTime date) {
    if (state.slots.isEmpty) return [];
    
    return state.slots.where((slot) {
      return slot.startTime.year == date.year &&
             slot.startTime.month == date.month &&
             slot.startTime.day == date.day;
    }).toList();
  }

  /// Возвращает список слотов для конкретного часа
  List<ScheduleSlot> getSlotsForHour(int hour) {
    return state.slotsByHour[hour] ?? [];
  }

  /// Возвращает всех клиентов для выпадающего списка
  List<Map<String, dynamic>> getAllClientsForDropdown() {
    final List<Map<String, dynamic>> clients = [];
    
    for (final entry in state.registeredClients.entries) {
      clients.add({
        'id': entry.key,
        'name': entry.value.fullName,
        'isRegistered': true,
      });
    }
    
    for (final entry in state.unregisteredClients.entries) {
      clients.add({
        'id': entry.key,
        'name': entry.value['fullName'],
        'isRegistered': false,
      });
    }
    
    clients.sort((a, b) => a['name'].compareTo(b['name']));
    return clients;
  }
}

// Провайдер ViewModel
final scheduleViewModelProvider = StateNotifierProvider<ScheduleViewModel, ScheduleState>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleViewModel(repository, ref);
});