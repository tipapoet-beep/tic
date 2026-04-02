import 'package:hive/hive.dart';
import 'sync_status.dart';

class SyncQueue {
  static const String _boxName = 'sync_queue';
  late Box<Map> _box;
  
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }
  
  // Добавить запись в очередь
  Future<void> addToQueue(SyncEntry entry) async {
    await _box.put(entry.id, entry.toJson());
  }
  
  // Получить все ожидающие записи
  List<SyncEntry> getPendingEntries() {
    return _box.values
        .map((json) => SyncEntry.fromJson(Map<String, dynamic>.from(json)))
        .where((entry) => entry.status == SyncStatus.pending)
        .toList();
  }
  
  // Обновить статус записи
  Future<void> updateStatus(String id, SyncStatus status) async {
    final json = _box.get(id);
    if (json != null) {
      final entry = SyncEntry.fromJson(Map<String, dynamic>.from(json));
      final updated = SyncEntry(
        id: entry.id,
        tableName: entry.tableName,
        recordId: entry.recordId,
        data: entry.data,
        status: status,
        createdAt: entry.createdAt,
        syncedAt: status == SyncStatus.synced ? DateTime.now() : null,
        version: entry.version,
      );
      await _box.put(id, updated.toJson());
    }
  }
  
  // Удалить запись из очереди
  Future<void> removeFromQueue(String id) async {
    await _box.delete(id);
  }
  
  // Очистить очередь
  Future<void> clearQueue() async {
    await _box.clear();
  }
  
  // Получить количество ожидающих записей
  int getPendingCount() {
    return _box.values
        .where((json) {
          final entry = SyncEntry.fromJson(Map<String, dynamic>.from(json));
          return entry.status == SyncStatus.pending;
        })
        .length;
  }
  
  // Проверить, есть ли конфликты
  bool hasConflicts() {
    return _box.values.any((json) {
      final entry = SyncEntry.fromJson(Map<String, dynamic>.from(json));
      return entry.status == SyncStatus.conflict;
    });
  }
}