import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/tasks/domain/entities/task.dart';
import '../features/tasks/data/repositories/task_repository_impl.dart';
import 'database_service.dart';
import 'auth_service.dart';

/// Data Sync Service implementing "Last Write Wins" strategy
/// Phase 1: Simple synchronization for stable foundation
class DataSyncService {
  final DatabaseService _databaseService;
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isOnline = false;
  bool _isSyncing = false;
  
  // Sync configuration
  static const Duration _syncInterval = Duration(minutes: 5);
  static const Duration _retryDelay = Duration(seconds: 30);
  
  DataSyncService(
    this._databaseService,
    this._authService,
    this._firestore,
    this._connectivity,
  );

  /// Initialize sync service and start monitoring
  Future<void> initialize() async {
    print('🔄 DataSyncService: Initializing...');
    
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    print('🌐 DataSyncService: Initial connectivity - ${_isOnline ? "Online" : "Offline"}');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final wasOnline = _isOnline;
        _isOnline = result != ConnectivityResult.none;
        
        print('🌐 DataSyncService: Connectivity changed - ${_isOnline ? "Online" : "Offline"}');
        
        // If we just came online, trigger immediate sync
        if (!wasOnline && _isOnline) {
          print('🔄 DataSyncService: Back online - triggering immediate sync');
          await syncNow();
        }
        
        // Restart periodic sync if online
        if (_isOnline) {
          _startPeriodicSync();
        } else {
          _stopPeriodicSync();
        }
      },
    );

    // Start periodic sync if online
    if (_isOnline) {
      _startPeriodicSync();
      // Trigger initial sync
      await syncNow();
    }
  }

  /// Start periodic synchronization
  void _startPeriodicSync() {
    _stopPeriodicSync();
    if (_isOnline) {
      print('⏰ DataSyncService: Starting periodic sync (${_syncInterval.inMinutes} min intervals)');
      _periodicSyncTimer = Timer.periodic(_syncInterval, (_) => syncNow());
    }
  }

  /// Stop periodic synchronization
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Trigger immediate synchronization
  Future<SyncResult> syncNow() async {
    if (!_isOnline || _isSyncing) {
      print('⚠️  DataSyncService: Sync skipped - ${!_isOnline ? "Offline" : "Already syncing"}');
      return SyncResult.skipped;
    }

    final user = _authService.currentUser;
    if (user == null) {
      print('⚠️  DataSyncService: Sync skipped - User not authenticated');
      return SyncResult.noAuth;
    }

    _isSyncing = true;
    print('🔄 DataSyncService: Starting sync for user ${user.uid}');
    
    try {
      // Get all local tasks
      final localTasks = await _databaseService.getAllTasks();
      print('📱 DataSyncService: Found ${localTasks.length} local tasks');

      // Get all remote tasks
      final remoteTasks = await _getRemoteTasks(user.uid);
      print('☁️  DataSyncService: Found ${remoteTasks.length} remote tasks');

      int uploaded = 0;
      int downloaded = 0;
      int conflicts = 0;

      // Phase 1: Simple "Last Write Wins" strategy
      final syncedTaskIds = <String>{};
      
      // Process local tasks
      for (final localTask in localTasks) {
        final remoteTask = remoteTasks
            .where((t) => t.id == localTask.id)
            .firstOrNull;

        if (remoteTask == null) {
          // Local task doesn't exist remotely - upload it
          await _uploadTask(user.uid, localTask);
          uploaded++;
          syncedTaskIds.add(localTask.id);
        } else {
          // Task exists both locally and remotely
          final localUpdated = localTask.lastUpdatedAt ?? DateTime.now();
          final remoteUpdated = remoteTask.lastUpdatedAt ?? DateTime.now();
          
          if (localUpdated.isAfter(remoteUpdated)) {
            // Local is newer - upload to remote
            await _uploadTask(user.uid, localTask);
            uploaded++;
            conflicts++;
          } else if (remoteUpdated.isAfter(localUpdated)) {
            // Remote is newer - download to local
            await _downloadTask(remoteTask);
            downloaded++;
            conflicts++;
          }
          // If same timestamp, no action needed (already in sync)
          
          syncedTaskIds.add(localTask.id);
        }
      }

      // Process remaining remote tasks (not in local)
      for (final remoteTask in remoteTasks) {
        if (!syncedTaskIds.contains(remoteTask.id)) {
          // Remote task doesn't exist locally - download it
          await _downloadTask(remoteTask);
          downloaded++;
        }
      }

      print('✅ DataSyncService: Sync completed - ↑$uploaded ↓$downloaded ⚡$conflicts conflicts');
      return SyncResult.success(
        uploaded: uploaded,
        downloaded: downloaded,
        conflicts: conflicts,
      );

    } catch (e) {
      print('❌ DataSyncService: Sync failed - $e');
      
      // Schedule retry for transient errors
      if (_isTransientError(e)) {
        print('🔁 DataSyncService: Scheduling retry in ${_retryDelay.inSeconds}s');
        Timer(_retryDelay, () => syncNow());
      }
      
      return SyncResult.failed(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  /// Get all tasks from remote Firestore
  Future<List<Task>> _getRemoteTasks(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Upload task to remote Firestore
  Future<void> _uploadTask(String userId, Task task) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(task.id)
        .set(task.toFirestore());
  }

  /// Download task to local database
  Future<void> _downloadTask(Task task) async {
    await _databaseService.saveTask(task);
  }

  /// Check if error is transient and should be retried
  bool _isTransientError(dynamic error) {
    if (error is FirebaseException) {
      // Retry on network or server errors
      return error.code == 'unavailable' ||
             error.code == 'deadline-exceeded' ||
             error.code == 'resource-exhausted';
    }
    
    // Retry on general connectivity issues
    return error.toString().contains('network') ||
           error.toString().contains('timeout') ||
           error.toString().contains('connection');
  }

  /// Get current sync status
  SyncStatus get status => SyncStatus(
    isOnline: _isOnline,
    isSyncing: _isSyncing,
    lastSyncTime: _lastSyncTime,
  );

  DateTime? _lastSyncTime;

  /// Dispose resources
  void dispose() {
    print('🔄 DataSyncService: Disposing...');
    _connectivitySubscription?.cancel();
    _stopPeriodicSync();
  }
}

/// Sync operation result
sealed class SyncResult {
  const SyncResult();
  
  static const SyncResult skipped = SyncResultSkipped();
  static const SyncResult noAuth = SyncResultNoAuth();
  
  static SyncResult success({
    required int uploaded,
    required int downloaded,
    required int conflicts,
  }) => SyncResultSuccess(
    uploaded: uploaded,
    downloaded: downloaded,
    conflicts: conflicts,
  );
  
  static SyncResult failed(String error) => SyncResultFailed(error);
}

class SyncResultSuccess extends SyncResult {
  final int uploaded;
  final int downloaded;
  final int conflicts;
  
  const SyncResultSuccess({
    required this.uploaded,
    required this.downloaded,
    required this.conflicts,
  });
  
  @override
  String toString() => 'SyncSuccess(↑$uploaded ↓$downloaded ⚡$conflicts)';
}

class SyncResultFailed extends SyncResult {
  final String error;
  const SyncResultFailed(this.error);
  
  @override
  String toString() => 'SyncFailed($error)';
}

class SyncResultSkipped extends SyncResult {
  const SyncResultSkipped();
  
  @override
  String toString() => 'SyncSkipped';
}

class SyncResultNoAuth extends SyncResult {
  const SyncResultNoAuth();
  
  @override
  String toString() => 'SyncNoAuth';
}

/// Current sync status
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  const SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    this.lastSyncTime,
  });
  
  @override
  String toString() => 'SyncStatus(${isOnline ? "Online" : "Offline"}, ${isSyncing ? "Syncing" : "Idle"})';
}

/// Riverpod providers for sync service
final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  final databaseService = ref.read(databaseServiceProvider);
  final authService = ref.read(authServiceProvider);
  final firestore = FirebaseFirestore.instance;
  final connectivity = Connectivity();
  
  final syncService = DataSyncService(
    databaseService,
    authService,
    firestore,
    connectivity,
  );
  
  // Initialize when first accessed
  syncService.initialize();
  
  ref.onDispose(() => syncService.dispose());
  
  return syncService;
});

/// Provider for current sync status
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.watch(dataSyncServiceProvider);
  
  // Create a stream that updates sync status periodically
  return Stream.periodic(const Duration(seconds: 1), (_) => syncService.status);
});

/// Provider for manual sync trigger
final manualSyncProvider = FutureProvider.family<SyncResult, void>((ref, _) async {
  final syncService = ref.read(dataSyncServiceProvider);
  return await syncService.syncNow();
});

// Extension to add Task Firestore serialization
extension TaskFirestore on Task {
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.index,
      'type': type.index,
      'dueDate': dueDate?.toIso8601String(),
      'tags': tags,
      'lastUpdatedAt': (lastUpdatedAt ?? DateTime.now()).toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  static Task fromFirestore(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      priority: TaskPriority.values[data['priority'] ?? 0],
      type: TaskType.values[data['type'] ?? 0],
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      tags: List<String>.from(data['tags'] ?? []),
      lastUpdatedAt: data['lastUpdatedAt'] != null 
          ? DateTime.parse(data['lastUpdatedAt']) 
          : null,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }
}
