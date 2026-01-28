/// Synchronization status for diary entries
enum SyncStatus {
  /// Entry is synced with the server
  synced,

  /// Entry has pending changes to sync
  pending,

  /// Sync failed and needs retry
  failed;

  /// Check if sync is complete
  bool get isSynced => this == SyncStatus.synced;

  /// Check if sync is pending
  bool get isPending => this == SyncStatus.pending;

  /// Check if sync failed
  bool get isFailed => this == SyncStatus.failed;
}
