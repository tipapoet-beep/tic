import '../../domain/entities/body_measurement.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ProgressRemoteDataSource _remoteDataSource;
  
  ProgressRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<List<BodyMeasurement>> getMeasurements(String userId) async {
    return await _remoteDataSource.getMeasurements(userId);
  }
  
  @override
  Future<BodyMeasurement> addMeasurement(BodyMeasurement measurement) async {
    return await _remoteDataSource.addMeasurement(measurement);
  }
  
  @override
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    return await _remoteDataSource.updateMeasurement(measurement);
  }
  
  @override
  Future<void> deleteMeasurement(String measurementId) async {
    await _remoteDataSource.deleteMeasurement(measurementId);
  }
  
  @override
  Future<List<ProgressPhoto>> getProgressPhotos(String userId) async {
    return await _remoteDataSource.getProgressPhotos(userId);
  }
  
  @override
  Future<ProgressPhoto> addProgressPhoto(ProgressPhoto photo, String imagePath) async {
    return await _remoteDataSource.addProgressPhoto(photo, imagePath);
  }
  
  @override
  Future<void> deleteProgressPhoto(String photoId) async {
    await _remoteDataSource.deleteProgressPhoto(photoId);
  }
  
  @override
  Future<Map<String, dynamic>> getProgressStats(String userId) async {
    return await _remoteDataSource.getProgressStats(userId);
  }
}