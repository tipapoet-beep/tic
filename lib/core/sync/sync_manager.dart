import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sync_queue.dart';
import 'sync_status.dart';
import 'sync_conflict_resolver.dart';
import '../database/local_database.dart';
import '../utils/logger.dart';

enum ConnectionStatus {
  online,
  offline,
  unknown;
  
  String get description {
    switch (this) {
      case ConnectionStatus.online:
        return 'Подключено к сети';
      case ConnectionStatus.offline:
        return 'Офлайн-режим';
      case ConnectionStatus.unknown:
        return 'Проверка соединения...';
    }
  }
}

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();
  
  final SyncQueue _queue = SyncQueue();
  final ConflictResolver _resolver = ConflictResolver();
  
  ValueNotifier<ConnectionStatus> connectionStatus = 
      ValueNotifier(ConnectionStatus.unknown);
  ValueNotifier<bool> isSyncing = ValueNotifier(false);
  ValueNotifier<int> pendingCount = ValueNotifier(0);
  
  late BuildContext _context;
  bool _isInitialized = false;
  
  Future<void> init(BuildContext context) async {
    if (_isInitialized) return;
    
    _context = context;
    await _queue.init();
    _updatePendingCount();
    await _checkConnection();
    
    _isInitialized = true;
  }
  
  Future<void> _checkConnection() async {
    try {
      // Исправлено: используем currentSession вместо getSession
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        connectionStatus.value = ConnectionStatus.online;
        _checkPendingEntries();
      } else {
        // Если нет сессии, пробуем обновить
        final response = await Supabase.instance.client.auth.refreshSession();
        if (response != null) {
          connectionStatus.value = ConnectionStatus.online;
          _checkPendingEntries();
        } else {
          connectionStatus.value = ConnectionStatus.offline;
        }
      }
    } catch (e) {
      Logger.log('🌐 No internet connection: $e');
      connectionStatus.value = ConnectionStatus.offline;
      
      // Если есть сохраненные данные, работаем в офлайн-режиме
      if (await LocalDatabase().isEmpty()) {
        _showWelcomeBackDialog();
      }
    }
  }
  
  void _showWelcomeBackDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: _context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Добро пожаловать!'),
          content: const Text(
            'Вы находитесь в офлайн-режиме. '
            'Приложение будет работать с локальными данными. '
            'При подключении к интернету изменения синхронизируются автоматически.'
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    });
  }
  
  Future<void> _checkPendingEntries() async {
    if (connectionStatus.value == ConnectionStatus.offline) return;
    
    final pending = _queue.getPendingCount();
    if (pending > 0) {
      _showSyncDialog(pending);
    } else if (_queue.hasConflicts()) {
      _showConflictDialog();
    }
  }
  
  void _showSyncDialog(int pendingCount) {
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Ожидают синхронизации'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'За время отсутствия сети было внесено $pendingCount изменений.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Вы хотите отправить эти изменения в облако?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Сохраняем локально без синхронизации
            },
            child: const Text('Оставить локально'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startSync();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Синхронизировать'),
          ),
        ],
      ),
    );
  }
  
  void _showConflictDialog() {
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Конфликт версий'),
        content: const Text(
          'Обнаружены конфликты между локальной и облачной версиями данных. '
          'Необходимо разрешить конфликты вручную.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: показать список конфликтов
            },
            child: const Text('Разрешить конфликты'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startSync() async {
    isSyncing.value = true;
    
    try {
      final pending = _queue.getPendingEntries();
      
      for (final entry in pending) {
        try {
          // Отправляем на сервер
          final result = await _sendToServer(entry);
          
          if (result.success) {
            await _queue.updateStatus(entry.id, SyncStatus.synced);
          } else if (result.conflict) {
            await _queue.updateStatus(entry.id, SyncStatus.conflict);
          }
        } catch (e) {
          Logger.error('Sync failed for entry ${entry.id}', error: e);
        }
      }
      
      _updatePendingCount();
      
      if (_queue.hasConflicts()) {
        _showConflictDialog();
      } else {
        _showSuccessDialog();
      }
    } finally {
      isSyncing.value = false;
    }
  }
  
  Future<SyncResult> _sendToServer(SyncEntry entry) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Проверяем версию на сервере
      final serverVersion = await _getServerVersion(entry.tableName, entry.recordId);
      
      if (serverVersion > entry.version) {
        return SyncResult(conflict: true, success: false);
      }
      
      // Отправляем данные
      await supabase
          .from(entry.tableName)
          .upsert(entry.data)
          .eq('id', entry.recordId);
          
      return SyncResult(success: true);
    } catch (e) {
      return SyncResult(success: false);
    }
  }
  
  Future<int> _getServerVersion(String table, String id) async {
    try {
      final response = await Supabase.instance.client
          .from(table)
          .select('version')
          .eq('id', id)
          .maybeSingle();
          
      return response?['version'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  void _showSuccessDialog() {
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Синхронизация завершена'),
        content: const Text('Все изменения успешно сохранены в облаке.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _updatePendingCount() {
    pendingCount.value = _queue.getPendingCount();
  }
  
  // Добавить запись в очередь синхронизации
  Future<void> addToQueue(SyncEntry entry) async {
    await _queue.addToQueue(entry);
    _updatePendingCount();
    
    // Если онлайн, предлагаем синхронизировать
    if (connectionStatus.value == ConnectionStatus.online && 
        _queue.getPendingCount() > 0) {
      _showSyncDialog(_queue.getPendingCount());
    }
  }
  
  // Получить данные с учетом офлайн-режима
  Future<T?> getData<T>({
    required String table,
    required String id,
    required Future<T?> Function() remoteGetter,
    required Future<T?> Function() localGetter,
    required Future<void> Function(T) localSaver,
  }) async {
    // Сначала пробуем локально
    final localData = await localGetter();
    
    if (connectionStatus.value == ConnectionStatus.offline) {
      return localData;
    }
    
    // Если онлайн, проверяем свежесть данных
    try {
      final remoteData = await remoteGetter();
      
      if (remoteData != null) {
        // Сравниваем версии
        final syncEntry = await _getSyncEntry(table, id);
        
        if (syncEntry != null && syncEntry.status == SyncStatus.pending) {
          // Есть локальные изменения, не загружаем
          return localData;
        }
        
        // Сохраняем свежие данные локально
        await localSaver(remoteData);
        return remoteData;
      }
    } catch (e) {
      // Ошибка сети - возвращаем локальные данные
      Logger.error('Failed to fetch remote data', error: e);
    }
    
    return localData;
  }
  
  Future<SyncEntry?> _getSyncEntry(String table, String id) async {
    // TODO: получить запись из очереди
    return null;
  }
}

class SyncResult {
  final bool success;
  final bool conflict;
  
  SyncResult({this.success = false, this.conflict = false});
}