import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trainapp/config/di/providers.dart';
import '../../domain/entities/body_measurement.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/datasources/progress_remote_datasource.dart';
import '../../../../config/di/providers.dart';

// Провайдеры
final progressRemoteDataSourceProvider = Provider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProgressRemoteDataSource(client);
});

final progressRepositoryProvider = Provider((ref) {
  final dataSource = ref.watch(progressRemoteDataSourceProvider);
  return ProgressRepositoryImpl(dataSource);
});

// Состояние для замеров
class MeasurementsState {
  final List<BodyMeasurement> measurements;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;
  
  MeasurementsState({
    this.measurements = const [],
    this.isLoading = false,
    this.error,
    this.stats,
  });
  
  MeasurementsState copyWith({
    List<BodyMeasurement>? measurements,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return MeasurementsState(
      measurements: measurements ?? this.measurements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

// Состояние для фото
class PhotosState {
  final List<ProgressPhoto> photos;
  final bool isLoading;
  final String? error;
  
  PhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.error,
  });
  
  PhotosState copyWith({
    List<ProgressPhoto>? photos,
    bool? isLoading,
    String? error,
  }) {
    return PhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ViewModel для замеров
class MeasurementsViewModel extends StateNotifier<MeasurementsState> {
  final ProgressRepository _repository;
  
  MeasurementsViewModel(this._repository) : super(MeasurementsState());
  
  Future<void> loadMeasurements(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final measurements = await _repository.getMeasurements(userId);
      final stats = await _repository.getProgressStats(userId);
      state = state.copyWith(
        measurements: measurements,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> addMeasurement(BodyMeasurement measurement) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newMeasurement = await _repository.addMeasurement(measurement);
      final updatedMeasurements = [newMeasurement, ...state.measurements];
      final stats = await _repository.getProgressStats(measurement.userId);
      state = state.copyWith(
        measurements: updatedMeasurements,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
  
  Future<void> updateMeasurement(BodyMeasurement measurement) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await _repository.updateMeasurement(measurement);
      final updatedMeasurements = state.measurements.map((m) {
        return m.id == updated.id ? updated : m;
      }).toList();
      final stats = await _repository.getProgressStats(measurement.userId);
      state = state.copyWith(
        measurements: updatedMeasurements,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
  
  Future<void> deleteMeasurement(String measurementId, String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteMeasurement(measurementId);
      final updatedMeasurements = state.measurements.where((m) => m.id != measurementId).toList();
      final stats = await _repository.getProgressStats(userId);
      state = state.copyWith(
        measurements: updatedMeasurements,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// ViewModel для фото
class PhotosViewModel extends StateNotifier<PhotosState> {
  final ProgressRepository _repository;
  
  PhotosViewModel(this._repository) : super(PhotosState());
  
  Future<void> loadPhotos(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final photos = await _repository.getProgressPhotos(userId);
      state = state.copyWith(photos: photos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  Future<void> addPhoto(ProgressPhoto photo, String imagePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newPhoto = await _repository.addProgressPhoto(photo, imagePath);
      final updatedPhotos = [newPhoto, ...state.photos];
      state = state.copyWith(photos: updatedPhotos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
  
  Future<void> deletePhoto(String photoId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteProgressPhoto(photoId);
      final updatedPhotos = state.photos.where((p) => p.id != photoId).toList();
      state = state.copyWith(photos: updatedPhotos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

// Провайдеры ViewModel - ЭТО САМОЕ ВАЖНОЕ!
final measurementsViewModelProvider = StateNotifierProvider<MeasurementsViewModel, MeasurementsState>((ref) {
  final repository = ref.watch(progressRepositoryProvider);
  return MeasurementsViewModel(repository);
});

final photosViewModelProvider = StateNotifierProvider<PhotosViewModel, PhotosState>((ref) {
  final repository = ref.watch(progressRepositoryProvider);
  return PhotosViewModel(repository);
});