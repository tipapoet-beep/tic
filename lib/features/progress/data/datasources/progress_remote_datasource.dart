import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../domain/entities/body_measurement.dart';
import '../../domain/entities/progress_photo.dart';
import '../../../../core/base/base_datasource.dart';

class ProgressRemoteDataSource extends BaseDataSource {
  ProgressRemoteDataSource(super.client);
  
  // Замеры тела
  Future<List<BodyMeasurement>> getMeasurements(String userId) async {
    try {
      log('Fetching measurements for user: $userId');
      
      final supabase = await client;
      final response = await supabase
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => BodyMeasurement.fromJson(json))
          .toList();
    } catch (e) {
      logError('Failed to fetch measurements', error: e);
      throw Exception('Failed to fetch measurements: $e');
    }
  }
  
  Future<BodyMeasurement> addMeasurement(BodyMeasurement measurement) async {
    try {
      log('Adding measurement for user: ${measurement.userId}');
      
      final supabase = await client;
      final response = await supabase
          .from('body_measurements')
          .insert(measurement.toJson())
          .select()
          .single();
      
      logSuccess('Measurement added successfully');
      return BodyMeasurement.fromJson(response);
    } catch (e) {
      logError('Failed to add measurement', error: e);
      throw Exception('Failed to add measurement: $e');
    }
  }
  
  Future<BodyMeasurement> updateMeasurement(BodyMeasurement measurement) async {
    try {
      log('Updating measurement: ${measurement.id}');
      
      final supabase = await client;
      final response = await supabase
          .from('body_measurements')
          .update(measurement.toJson())
          .eq('id', measurement.id)
          .select()
          .single();
      
      logSuccess('Measurement updated successfully');
      return BodyMeasurement.fromJson(response);
    } catch (e) {
      logError('Failed to update measurement', error: e);
      throw Exception('Failed to update measurement: $e');
    }
  }
  
  Future<void> deleteMeasurement(String measurementId) async {
    try {
      log('Deleting measurement: $measurementId');
      
      final supabase = await client;
      await supabase
          .from('body_measurements')
          .delete()
          .eq('id', measurementId);
      
      logSuccess('Measurement deleted successfully');
    } catch (e) {
      logError('Failed to delete measurement', error: e);
      throw Exception('Failed to delete measurement: $e');
    }
  }
  
  // Фото прогресса
  Future<List<ProgressPhoto>> getProgressPhotos(String userId) async {
    try {
      log('Fetching progress photos for user: $userId');
      
      final supabase = await client;
      final response = await supabase
          .from('progress_photos')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
      
      return (response as List)
          .map((json) => ProgressPhoto.fromJson(json))
          .toList();
    } catch (e) {
      logError('Failed to fetch progress photos', error: e);
      throw Exception('Failed to fetch progress photos: $e');
    }
  }
  
  Future<ProgressPhoto> addProgressPhoto(ProgressPhoto photo, String imagePath) async {
    try {
      log('Adding progress photo for user: ${photo.userId}');
      
      final supabase = await client;
      
      // Загружаем фото в storage
      final file = File(imagePath);
      final fileName = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'progress_photos/${photo.userId}/$fileName';
      
      await supabase.storage.from('progress_photos').upload(
        storagePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600'),
      );
      
      final photoUrl = supabase.storage.from('progress_photos').getPublicUrl(storagePath);
      
      // Создаем запись в БД
      final updatedPhoto = photo.copyWith(photoUrl: photoUrl);
      final response = await supabase
          .from('progress_photos')
          .insert(updatedPhoto.toJson())
          .select()
          .single();
      
      logSuccess('Progress photo added successfully');
      return ProgressPhoto.fromJson(response);
    } catch (e) {
      logError('Failed to add progress photo', error: e);
      throw Exception('Failed to add progress photo: $e');
    }
  }
  
  Future<void> deleteProgressPhoto(String photoId) async {
    try {
      log('Deleting progress photo: $photoId');
      
      final supabase = await client;
      
      // Сначала получаем URL фото чтобы удалить из storage
      final photo = await supabase
          .from('progress_photos')
          .select('photo_url')
          .eq('id', photoId)
          .single();
      
      // Удаляем из storage
      if (photo['photo_url'] != null) {
        final url = photo['photo_url'] as String;
        final uri = Uri.parse(url);
        final path = uri.path.replaceFirst('/storage/v1/object/public/progress_photos/', '');
        
        await supabase.storage.from('progress_photos').remove([path]);
      }
      
      // Удаляем запись из БД
      await supabase
          .from('progress_photos')
          .delete()
          .eq('id', photoId);
      
      logSuccess('Progress photo deleted successfully');
    } catch (e) {
      logError('Failed to delete progress photo', error: e);
      throw Exception('Failed to delete progress photo: $e');
    }
  }
  
  // Статистика прогресса
  Future<Map<String, dynamic>> getProgressStats(String userId) async {
    try {
      log('Fetching progress stats for user: $userId');
      
      final measurements = await getMeasurements(userId);
      
      if (measurements.isEmpty) {
        return {
          'firstMeasurement': null,
          'latestMeasurement': null,
          'changes': {},
          'progress': [],
        };
      }
      
      final first = measurements.last;
      final latest = measurements.first;
      
      final changes = <String, double?>{};
      if (first.weight != null && latest.weight != null) {
        changes['weight'] = latest.weight! - first.weight!;
      }
      if (first.chest != null && latest.chest != null) {
        changes['chest'] = latest.chest! - first.chest!;
      }
      if (first.waist != null && latest.waist != null) {
        changes['waist'] = latest.waist! - first.waist!;
      }
      if (first.hips != null && latest.hips != null) {
        changes['hips'] = latest.hips! - first.hips!;
      }
      
      final progress = measurements.reversed.map((m) {
        return {
          'date': m.date.toIso8601String(),
          'weight': m.weight,
          'chest': m.chest,
          'waist': m.waist,
          'hips': m.hips,
        };
      }).toList();
      
      return {
        'firstMeasurement': first,
        'latestMeasurement': latest,
        'changes': changes,
        'progress': progress,
      };
    } catch (e) {
      logError('Failed to fetch progress stats', error: e);
      throw Exception('Failed to fetch progress stats: $e');
    }
  }
}