import '../entities/body_measurement.dart';
import '../entities/progress_photo.dart';

abstract class ProgressRepository {
  // Замеры тела
  Future<List<BodyMeasurement>> getMeasurements(String userId);
  Future<BodyMeasurement> addMeasurement(BodyMeasurement measurement);
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement);
  Future<void> deleteMeasurement(String measurementId);
  
  // Фото прогресса
  Future<List<ProgressPhoto>> getProgressPhotos(String userId);
  Future<ProgressPhoto> addProgressPhoto(ProgressPhoto photo, String imagePath);
  Future<void> deleteProgressPhoto(String photoId);
  
  // Статистика
  Future<Map<String, dynamic>> getProgressStats(String userId);
}