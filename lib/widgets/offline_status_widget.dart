import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_data_provider.dart';
import '../services/data_sync_service.dart';

class OfflineStatusWidget extends StatelessWidget {
  final bool showSyncButton;
  final bool compact;

  const OfflineStatusWidget({
    super.key,
    this.showSyncButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineDataProvider>(
      builder: (context, offlineProvider, child) {
        if (compact) {
          return _buildCompactStatus(context, offlineProvider);
        } else {
          return _buildFullStatus(context, offlineProvider);
        }
      },
    );
  }

  Widget _buildCompactStatus(BuildContext context, OfflineDataProvider provider) {
    if (provider.isOnline && provider.syncStatus == SyncStatus.idle) {
      return const SizedBox.shrink(); // Hide when online and synced
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(provider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(provider),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(provider),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullStatus(BuildContext context, OfflineDataProvider provider) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(provider),
                  color: _getStatusColor(provider),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(provider),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(provider),
                  ),
                ),
                const Spacer(),
                if (showSyncButton && provider.isOnline)
                  _buildSyncButton(context, provider),
              ],
            ),
            if (!provider.isOnline || provider.syncStatus != SyncStatus.idle) ...[
              const SizedBox(height: 8),
              Text(
                _getStatusDescription(provider),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (provider.lastSyncError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sync Error: ${provider.lastSyncError}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.clearSyncError(),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            ],
            if (provider.lastSyncTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last sync: ${_formatLastSyncTime(provider.lastSyncTime!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, OfflineDataProvider provider) {
    final isSyncing = provider.syncStatus == SyncStatus.syncing;
    
    return ElevatedButton.icon(
      onPressed: isSyncing ? null : () => _performSync(context, provider),
      icon: isSyncing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync, size: 16),
      label: Text(isSyncing ? 'Syncing...' : 'Sync'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _performSync(BuildContext context, OfflineDataProvider provider) async {
    try {
      final result = await provider.forcSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Sync completed successfully'
                  : 'Sync failed: ${result.error}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(OfflineDataProvider provider) {
    if (!provider.isOnline) {
      return Colors.orange;
    }
    
    switch (provider.syncStatus) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.idle:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(OfflineDataProvider provider) {
    if (!provider.isOnline) {
      return Icons.cloud_off;
    }
    
    switch (provider.syncStatus) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.error:
        return Icons.sync_problem;
      case SyncStatus.completed:
        return Icons.cloud_done;
      case SyncStatus.idle:
        return Icons.cloud_done;
    }
  }

  String _getStatusText(OfflineDataProvider provider) {
    if (!provider.isOnline) {
      return 'Offline';
    }
    
    switch (provider.syncStatus) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.error:
        return 'Sync Error';
      case SyncStatus.completed:
        return 'Synced';
      case SyncStatus.idle:
        return 'Online';
    }
  }

  String _getStatusDescription(OfflineDataProvider provider) {
    if (!provider.isOnline) {
      return 'You\'re currently offline. Changes will be synced when you\'re back online.';
    }
    
    switch (provider.syncStatus) {
      case SyncStatus.syncing:
        return 'Synchronizing your data with the server...';
      case SyncStatus.error:
        return 'Failed to sync data. Please check your connection and try again.';
      case SyncStatus.completed:
        return 'All data has been synchronized successfully.';
      case SyncStatus.idle:
        return 'Connected and up to date.';
    }
  }

  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Sync statistics widget
class SyncStatisticsWidget extends StatelessWidget {
  const SyncStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineDataProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: provider.getSyncStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats = snapshot.data!;
            
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sync Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Unsynced Bookings', stats['unsynced_bookings']),
                    _buildStatRow('Unsynced Notifications', stats['unsynced_notifications']),
                    _buildStatRow('Pending Sync Items', stats['pending_sync_items']),
                    const Divider(),
                    _buildStatRow('Status', stats['sync_status']),
                    if (stats['last_sync_time'] != null)
                      _buildStatRow('Last Sync', _formatDateTime(stats['last_sync_time'])),
                    if (stats['last_error'] != null)
                      _buildStatRow('Last Error', stats['last_error'], isError: true),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, dynamic value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: isError ? Colors.red : null,
              fontWeight: isError ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}