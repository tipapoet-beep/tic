import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../features/profile/domain/entities/profile.dart';
import '../../features/trainer/domain/entities/client.dart';
import '../sync/sync_status.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();
  
  static const String workoutsBox = 'workouts';
  static const String profilesBox = 'profiles';
  static const String clientsBox = 'clients';
  static const String templatesBox = 'templates';
  static const String settingsBox = 'settings';
  
  bool _isInitialized = false;
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Для веба не инициализируем Hive
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    
    final appDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    
    // Регистрируем адаптеры
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(ProfileAdapter());
    Hive.registerAdapter(ClientAdapter());
    Hive.registerAdapter(SyncStatusAdapter());
    
    // Открываем боксы
    await Hive.openBox<Map>(workoutsBox);
    await Hive.openBox<Map>(profilesBox);
    await Hive.openBox<Map>(clientsBox);
    await Hive.openBox<Map>(templatesBox);
    await Hive.openBox<Map>(settingsBox);
    
    _isInitialized = true;
  }
  
  // Общие методы для работы с данными
  Future<void> put(String boxName, String key, Map<String, dynamic> value) async {
    if (kIsWeb) return; // Веб не поддерживает локальное хранилище
    final box = Hive.box<Map>(boxName);
    await box.put(key, value);
  }
  
  Future<Map<String, dynamic>?> get(String boxName, String key) async {
    if (kIsWeb) return null; // Веб не поддерживает локальное хранилище
    final box = Hive.box<Map>(boxName);
    final value = box.get(key);
    return value != null ? Map<String, dynamic>.from(value) : null;
  }
  
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    if (kIsWeb) return []; // Веб не поддерживает локальное хранилище
    final box = Hive.box<Map>(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }
  
  Future<void> delete(String boxName, String key) async {
    if (kIsWeb) return;
    final box = Hive.box<Map>(boxName);
    await box.delete(key);
  }
  
  Future<void> clear(String boxName) async {
    if (kIsWeb) return;
    final box = Hive.box<Map>(boxName);
    await box.clear();
  }
  
  Future<int> getDatabaseSize() async {
    if (kIsWeb) return 0;
    return 0;
  }
  
  Future<bool> isEmpty() async {
    if (kIsWeb) return true;
    final workouts = Hive.box<Map>(workoutsBox);
    final profiles = Hive.box<Map>(profilesBox);
    final clients = Hive.box<Map>(clientsBox);
    
    return workouts.isEmpty && profiles.isEmpty && clients.isEmpty;
  }
  
  Future<Map<String, int>> getStats() async {
    if (kIsWeb) {
      return {
        'workouts': 0,
        'profiles': 0,
        'clients': 0,
        'templates': 0,
      };
    }
    return {
      'workouts': Hive.box<Map>(workoutsBox).length,
      'profiles': Hive.box<Map>(profilesBox).length,
      'clients': Hive.box<Map>(clientsBox).length,
      'templates': Hive.box<Map>(templatesBox).length,
    };
  }
}

// Адаптеры для Hive (остаются без изменений)
class WorkoutAdapter extends TypeAdapter<Map> {
  @override
  final typeId = 0;
  
  @override
  Map read(BinaryReader reader) {
    return reader.readMap();
  }
  
  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

class ProfileAdapter extends TypeAdapter<Map> {
  @override
  final typeId = 1;
  
  @override
  Map read(BinaryReader reader) {
    return reader.readMap();
  }
  
  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

class ClientAdapter extends TypeAdapter<Map> {
  @override
  final typeId = 2;
  
  @override
  Map read(BinaryReader reader) {
    return reader.readMap();
  }
  
  @override
  void write(BinaryWriter writer, Map obj) {
    writer.writeMap(obj);
  }
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final typeId = 3;
  
  @override
  SyncStatus read(BinaryReader reader) {
    return SyncStatus.values[reader.readInt()];
  }
  
  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeInt(obj.index);
  }
}