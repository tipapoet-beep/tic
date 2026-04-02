enum SyncStatus {
  synced,           // Данные синхронизированы
  pending,          // Ожидает синхронизации
  conflict,         // Конфликт версий
  offline;          // Офлайн-режим
  
  String get description {
    switch (this) {
      case SyncStatus.synced:
        return 'Синхронизировано';
      case SyncStatus.pending:
        return 'Ожидает синхронизации';
      case SyncStatus.conflict:
        return 'Требуется разрешение конфликта';
      case SyncStatus.offline:
        return 'Офлайн-режим';
    }
  }
}

class SyncEntry {
  final String id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> data;
  final SyncStatus status;
  final DateTime createdAt;
  final DateTime? syncedAt;
  final int version; // для разрешения конфликтов
  
  SyncEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.data,
    required this.status,
    required this.createdAt,
    this.syncedAt,
    this.version = 1,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'table_name': tableName,
    'record_id': recordId,
    'data': data,
    'status': status.toString(),
    'created_at': createdAt.toIso8601String(),
    'synced_at': syncedAt?.toIso8601String(),
    'version': version,
  };
  
  factory SyncEntry.fromJson(Map<String, dynamic> json) => SyncEntry(
    id: json['id'],
    tableName: json['table_name'],
    recordId: json['record_id'],
    data: Map<String, dynamic>.from(json['data']),
    status: SyncStatus.values.firstWhere(
      (e) => e.toString() == json['status'],
      orElse: () => SyncStatus.pending,
    ),
    createdAt: DateTime.parse(json['created_at']),
    syncedAt: json['synced_at'] != null 
        ? DateTime.parse(json['synced_at']) 
        : null,
    version: json['version'] ?? 1,
  );
}