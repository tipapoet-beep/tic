import 'package:flutter/material.dart';
import '../sync/sync_manager.dart';

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncManager = SyncManager();
    final theme = Theme.of(context);
    
    return ValueListenableBuilder(
      valueListenable: syncManager.connectionStatus,
      builder: (context, status, _) {
        if (status == ConnectionStatus.offline) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.wifi_off,
                  size: 14,
                  color: Colors.grey,
                ),
                SizedBox(width: 4),
                Text(
                  'Офлайн',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ValueListenableBuilder<bool>(
          valueListenable: syncManager.isSyncing,
          builder: (context, isSyncing, _) {
            if (isSyncing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Синхр.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}