import 'package:trainapp/features/schedule/data/datasource/schedule_remote_datasource.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/repositories/schedule_repository.dart';


class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _remoteDataSource;

  ScheduleRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ScheduleSlot>> getWeekSchedule(String trainerId, DateTime startOfWeek, DateTime endOfWeek) async {
    return await _remoteDataSource.getWeekSchedule(trainerId, startOfWeek, endOfWeek);
  }

  @override
  Future<ScheduleSlot> createSlotForRegistered(ScheduleSlot slot) async {
    return await _remoteDataSource.createSlotForRegistered(slot);
  }

  @override
  Future<ScheduleSlot> createSlotForUnregistered(ScheduleSlot slot) async {
    return await _remoteDataSource.createSlotForUnregistered(slot);
  }

  @override
  Future<ScheduleSlot> updateSlot(ScheduleSlot slot) async {
    return await _remoteDataSource.updateSlot(slot);
  }

  @override
  Future<void> deleteSlot(String slotId) async {
    await _remoteDataSource.deleteSlot(slotId);
  }

  @override
  Future<void> toggleCompletion(String slotId, bool isCompleted) async {
    await _remoteDataSource.toggleCompletion(slotId, isCompleted);
  }
}