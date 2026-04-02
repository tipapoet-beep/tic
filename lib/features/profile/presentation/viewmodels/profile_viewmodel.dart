import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../../../config/di/providers.dart';

final profileRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRemoteDataSource(client);
});

final profileRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(dataSource);
});

class ProfileState {
  final Profile? profile;
  final bool isLoading;
  final String? error;
  
  ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });
  
  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  
  ProfileViewModel(this._repository) : super(ProfileState());
  
  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repository.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> updateProfile(Profile profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateProfile(profile);
      state = state.copyWith(profile: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
  
  Future<String?> uploadAvatar(String userId, String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final url = await _repository.uploadAvatar(userId, filePath);
      if (url != null && state.profile != null) {
        final updated = state.profile!.copyWith(avatarUrl: url);
        await updateProfile(updated);
      }
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
  
  void listenToProfile(String userId) {
    _repository.getProfileStream(userId).listen((profile) {
      state = state.copyWith(profile: profile);
    });
  }
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileViewModel(repository);
});