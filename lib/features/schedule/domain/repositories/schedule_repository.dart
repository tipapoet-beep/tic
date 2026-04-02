import '../entities/schedule_slot.dart';

abstract class ScheduleRepository {
  Future<List<ScheduleSlot>> getWeekSchedule(String trainerId, DateTime startOfWeek, DateTime endOfWeek);
  Future<ScheduleSlot> createSlotForRegistered(ScheduleSlot slot);
  Future<ScheduleSlot> createSlotForUnregistered(ScheduleSlot slot);
  Future<ScheduleSlot> updateSlot(ScheduleSlot slot);
  Future<void> deleteSlot(String slotId);
  Future<void> toggleCompletion(String slotId, bool isCompleted);
}