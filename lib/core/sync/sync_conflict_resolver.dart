import 'package:flutter/material.dart';

enum ConflictResolutionStrategy {
  useLocal,      // Использовать локальную версию
  useRemote,     // Использовать удаленную версию
  merge,         // Объединить (для совместимых полей)
  manual;        // Ручное разрешение
}

class ConflictInfo {
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime localModified;
  final DateTime remoteModified;
  
  ConflictInfo({
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.remoteData,
    required this.localModified,
    required this.remoteModified,
  });
  
  // Определить, какие поля конфликтуют
  List<String> get conflictingFields {
    final conflicts = <String>[];
    final allKeys = {...localData.keys, ...remoteData.keys};
    
    for (final key in allKeys) {
      final localValue = localData[key];
      final remoteValue = remoteData[key];
      
      if (localValue != remoteValue) {
        conflicts.add(key);
      }
    }
    
    return conflicts;
  }
  
  // Автоматическая стратегия на основе времени
  ConflictResolutionStrategy get autoStrategy {
    if (localModified.isAfter(remoteModified)) {
      return ConflictResolutionStrategy.useLocal;
    } else if (remoteModified.isAfter(localModified)) {
      return ConflictResolutionStrategy.useRemote;
    } else {
      return ConflictResolutionStrategy.manual;
    }
  }
}

class ConflictResolver {
  // Разрешить конфликт
  Future<Map<String, dynamic>> resolveConflict(
    ConflictInfo conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    switch (strategy) {
      case ConflictResolutionStrategy.useLocal:
        return conflict.localData;
        
      case ConflictResolutionStrategy.useRemote:
        return conflict.remoteData;
        
      case ConflictResolutionStrategy.merge:
        return _mergeData(conflict.localData, conflict.remoteData);
        
      case ConflictResolutionStrategy.manual:
        throw Exception('Manual resolution required');
    }
  }
  
  // Объединение данных (для неконфликтующих полей)
  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = {...remote}; // начинаем с удаленной версии
    
    // Добавляем локальные поля, которых нет в удаленных
    for (final entry in local.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }
    
    return merged;
  }
  
  // Показать диалог ручного разрешения конфликта
  Future<Map<String, dynamic>?> showManualResolutionDialog(
    BuildContext context,
    ConflictInfo conflict,
  ) async {
    final theme = Theme.of(context);
    
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: const Text('Конфликт версий'),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Обнаружены расхождения между локальной и облачной версиями. Выберите, какую версию сохранить:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Локальная версия
              _buildVersionCard(
                context,
                title: 'Локальная версия',
                time: conflict.localModified,
                data: conflict.localData,
                conflicts: conflict.conflictingFields,
                onSelect: () => Navigator.pop(dialogContext, conflict.localData),
              ),
              
              const SizedBox(height: 12),
              
              // Удаленная версия
              _buildVersionCard(
                context,
                title: 'Облачная версия',
                time: conflict.remoteModified,
                data: conflict.remoteData,
                conflicts: conflict.conflictingFields,
                onSelect: () => Navigator.pop(dialogContext, conflict.remoteData),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVersionCard(
    BuildContext context, {
    required String title,
    required DateTime time,
    required Map<String, dynamic> data,
    required List<String> conflicts,
    required VoidCallback onSelect,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...data.entries.take(3).map((entry) {
              final isConflict = conflicts.contains(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    if (isConflict)
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 14,
                      ),
                    if (isConflict) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isConflict ? Colors.orange : null,
                          fontWeight: isConflict ? FontWeight.bold : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (data.length > 3)
              Text(
                '... и еще ${data.length - 3} полей',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}