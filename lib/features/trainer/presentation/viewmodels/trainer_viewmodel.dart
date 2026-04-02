import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trainapp/config/di/providers.dart';
import 'package:trainapp/features/trainer/domain/repositories/trainer_repository_impl.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/workout_template.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/trainer_repository.dart';
import '../../data/datasources/trainer_remote_datasource.dart';
import '../../../../config/di/providers.dart';

// Провайдеры
final trainerRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TrainerRemoteDataSource(client);
});

final trainerRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(trainerRemoteDataSourceProvider);
  return TrainerRepositoryImpl(dataSource);
});

// Состояния
class ClientsState {
  final List<Client> clients;
  final bool isLoading;
  final String? error;
  
  ClientsState({
    this.clients = const [],
    this.isLoading = false,
    this.error,
  });
  
  ClientsState copyWith({
    List<Client>? clients,
    bool? isLoading,
    String? error,
  }) {
    return ClientsState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TemplatesState {
  final List<WorkoutTemplate> templates;
  final bool isLoading;
  final String? error;
  
  TemplatesState({
    this.templates = const [],
    this.isLoading = false,
    this.error,
  });
  
  TemplatesState copyWith({
    List<WorkoutTemplate>? templates,
    bool? isLoading,
    String? error,
  }) {
    return TemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionsState {
  final List<Subscription> subscriptions;
  final bool isLoading;
  final String? error;
  
  SubscriptionsState({
    this.subscriptions = const [],
    this.isLoading = false,
    this.error,
  });
  
  SubscriptionsState copyWith({
    List<Subscription>? subscriptions,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionsState(
      subscriptions: subscriptions ?? this.subscriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ViewModel для клиентов
class ClientsViewModel extends StateNotifier<ClientsState> {
  final TrainerRepository _repository;
  
  ClientsViewModel(this._repository) : super(ClientsState());
  
  Future<void> loadAllClients(String trainerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final clients = await _repository.getClients(trainerId);
      
      clients.sort((a, b) {
        if (a.isRegistered && !b.isRegistered) return -1;
        if (!a.isRegistered && b.isRegistered) return 1;
        return a.fullName.compareTo(b.fullName);
      });
      
      state = state.copyWith(clients: clients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> loadClients(String trainerId) async {
    await loadAllClients(trainerId);
  }
  
  // ✅ ЕДИНСТВЕННЫЙ МЕТОД updateClient - УДАЛИТЕ ДУБЛИКАТ ЕСЛИ ОН ЕСТЬ
  void updateClient(Client updatedClient) {
    final updatedClients = state.clients.map((c) {
      return c.id == updatedClient.id ? updatedClient : c;
    }).toList();
    state = state.copyWith(clients: updatedClients);
  }
}

// ViewModel для шаблонов
class TemplatesViewModel extends StateNotifier<TemplatesState> {
  final TrainerRepository _repository;
  
  TemplatesViewModel(this._repository) : super(TemplatesState());
  
  Future<void> loadTemplates(String trainerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final templates = await _repository.getTemplates(trainerId);
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> createTemplate(WorkoutTemplate template) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newTemplate = await _repository.createTemplate(template);
      state = state.copyWith(
        templates: [newTemplate, ...state.templates],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// ViewModel для подписок
class SubscriptionsViewModel extends StateNotifier<SubscriptionsState> {
  final TrainerRepository _repository;
  
  SubscriptionsViewModel(this._repository) : super(SubscriptionsState());
  
  Future<void> loadSubscriptions(String trainerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final subscriptions = await _repository.getSubscriptions(trainerId);
      state = state.copyWith(subscriptions: subscriptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> addSubscription(Subscription subscription) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newSubscription = await _repository.addSubscription(subscription);
      state = state.copyWith(
        subscriptions: [newSubscription, ...state.subscriptions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Провайдеры ViewModel
final clientsViewModelProvider = StateNotifierProvider<ClientsViewModel, ClientsState>((ref) {
  final repository = ref.watch(trainerRepositoryProvider);
  return ClientsViewModel(repository);
});

final templatesViewModelProvider = StateNotifierProvider<TemplatesViewModel, TemplatesState>((ref) {
  final repository = ref.watch(trainerRepositoryProvider);
  return TemplatesViewModel(repository);
});

final subscriptionsViewModelProvider = StateNotifierProvider<SubscriptionsViewModel, SubscriptionsState>((ref) {
  final repository = ref.watch(trainerRepositoryProvider);
  return SubscriptionsViewModel(repository);
});