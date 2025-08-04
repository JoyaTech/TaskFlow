import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/brain_dump_model.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'mindflow_local.db';
  static const int _databaseVersion = 1;

  /// Get database instance
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize local database
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        dueDate INTEGER,
        priority INTEGER NOT NULL,
        type INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        voiceNote TEXT,
        syncStatus INTEGER NOT NULL DEFAULT 0,
        lastSyncAt INTEGER
      )
    ''');

    // Brain dumps table
    await db.execute('''
      CREATE TABLE brain_dumps (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        type INTEGER NOT NULL,
        tags TEXT,
        isProcessed INTEGER NOT NULL,
        processedTaskId TEXT,
        syncStatus INTEGER NOT NULL DEFAULT 0,
        lastSyncAt INTEGER
      )
    ''');

    // Sync queue table for offline changes
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        recordId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        userId TEXT PRIMARY KEY,
        settings TEXT NOT NULL,
        lastSyncAt INTEGER
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_tasks_userId ON tasks(userId)');
    await db.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate)');
    await db.execute('CREATE INDEX idx_tasks_syncStatus ON tasks(syncStatus)');
    await db.execute('CREATE INDEX idx_brain_dumps_userId ON brain_dumps(userId)');
    await db.execute('CREATE INDEX idx_brain_dumps_syncStatus ON brain_dumps(syncStatus)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database schema changes
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
  }

  // ============= TASKS OPERATIONS =============

  /// Insert task locally
  static Future<void> insertTask(Task task, {bool syncNeeded = true}) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await db.insert(
      'tasks',
      {
        'id': task.id,
        'userId': userId,
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'priority': task.priority.index,
        'type': task.type.index,
        'isCompleted': task.isCompleted ? 1 : 0,
        'createdAt': task.createdAt.millisecondsSinceEpoch,
        'voiceNote': task.voiceNote,
        'syncStatus': syncNeeded ? SyncStatus.needsSync.index : SyncStatus.synced.index,
        'lastSyncAt': syncNeeded ? null : DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (syncNeeded) {
      await _addToSyncQueue('tasks', task.id, 'INSERT', task.toFirestore());
    }
  }

  /// Update task locally
  static Future<void> updateTask(Task task, {bool syncNeeded = true}) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await db.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'priority': task.priority.index,
        'type': task.type.index,
        'isCompleted': task.isCompleted ? 1 : 0,
        'voiceNote': task.voiceNote,
        'syncStatus': syncNeeded ? SyncStatus.needsSync.index : SyncStatus.synced.index,
        'lastSyncAt': syncNeeded ? null : DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [task.id, userId],
    );

    if (syncNeeded) {
      await _addToSyncQueue('tasks', task.id, 'UPDATE', task.toFirestore());
    }
  }

  /// Delete task locally
  static Future<void> deleteTask(String taskId, {bool syncNeeded = true}) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await db.delete(
      'tasks',
      where: 'id = ? AND userId = ?',
      whereArgs: [taskId, userId],
    );

    if (syncNeeded) {
      await _addToSyncQueue('tasks', taskId, 'DELETE', {});
    }
  }

  /// Get all tasks locally
  static Future<List<Task>> getAllTasks() async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  /// Get tasks by criteria
  static Future<List<Task>> getTasksByCriteria({
    TaskType? type,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    String whereClause = 'userId = ?';
    List<dynamic> whereArgs = [userId];

    if (type != null) {
      whereClause += ' AND type = ?';
      whereArgs.add(type.index);
    }

    if (priority != null) {
      whereClause += ' AND priority = ?';
      whereArgs.add(priority.index);
    }

    if (isCompleted != null) {
      whereClause += ' AND isCompleted = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (startDate != null) {
      whereClause += ' AND dueDate >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND dueDate <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final maps = await db.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  /// Search tasks locally
  static Future<List<Task>> searchTasks(String query) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await db.query(
      'tasks',
      where: 'userId = ? AND (title LIKE ? OR description LIKE ? OR voiceNote LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  // ============= BRAIN DUMPS OPERATIONS =============

  /// Insert brain dump locally
  static Future<void> insertBrainDump(BrainDump brainDump, {bool syncNeeded = true}) async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await db.insert(
      'brain_dumps',
      {
        'id': brainDump.id,
        'userId': userId,
        'content': brainDump.content,
        'createdAt': brainDump.createdAt.millisecondsSinceEpoch,
        'type': brainDump.type.index,
        'tags': brainDump.tags,
        'isProcessed': brainDump.isProcessed ? 1 : 0,
        'processedTaskId': brainDump.processedTaskId,
        'syncStatus': syncNeeded ? SyncStatus.needsSync.index : SyncStatus.synced.index,
        'lastSyncAt': syncNeeded ? null : DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (syncNeeded) {
      await _addToSyncQueue('brain_dumps', brainDump.id, 'INSERT', brainDump.toFirestore());
    }
  }

  /// Get all brain dumps locally
  static Future<List<BrainDump>> getAllBrainDumps() async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await db.query(
      'brain_dumps',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _brainDumpFromMap(map)).toList();
  }

  // ============= SYNC OPERATIONS =============

  /// Add operation to sync queue
  static Future<void> _addToSyncQueue(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    final db = await database;
    
    await db.insert('sync_queue', {
      'tableName': tableName,
      'recordId': recordId,
      'operation': operation,
      'data': data.toString(), // In production, use JSON encoding
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
  }

  /// Get pending sync operations
  static Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    
    return await db.query(
      'sync_queue',
      orderBy: 'createdAt ASC',
      limit: 50, // Process in batches
    );
  }

  /// Mark sync operation as completed
  static Future<void> markSyncCompleted(int syncId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [syncId]);
  }

  /// Increment sync attempt count
  static Future<void> incrementSyncAttempt(int syncId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [syncId],
    );
  }

  /// Check connectivity and sync if online
  static Future<bool> syncWithFirestore() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false; // No internet connection
    }

    try {
      final pendingOperations = await getPendingSyncOperations();
      
      for (final operation in pendingOperations) {
        try {
          // TODO: Implement actual sync with Firestore
          // This would call the appropriate Firestore methods based on operation type
          
          await markSyncCompleted(operation['id']);
        } catch (e) {
          await incrementSyncAttempt(operation['id']);
          if (kDebugMode) print('Sync failed for operation ${operation['id']}: $e');
          
          // Remove operations that have failed too many times
          if (operation['attempts'] >= 5) {
            await markSyncCompleted(operation['id']);
          }
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) print('Sync error: $e');
      return false;
    }
  }

  /// Clear all local data (for logout or reset)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('brain_dumps');
    await db.delete('sync_queue');
    await db.delete('user_settings');
  }

  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final userId = AuthService.currentUserId;
    if (userId == null) return {};

    final taskCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tasks WHERE userId = ?', [userId])
    ) ?? 0;

    final brainDumpCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM brain_dumps WHERE userId = ?', [userId])
    ) ?? 0;

    final pendingSyncCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sync_queue')
    ) ?? 0;

    return {
      'tasks': taskCount,
      'brainDumps': brainDumpCount,
      'pendingSync': pendingSyncCount,
    };
  }

  // ============= HELPER METHODS =============

  /// Convert database map to Task
  static Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) : null,
      priority: TaskPriority.values[map['priority']],
      type: TaskType.values[map['type']],
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      voiceNote: map['voiceNote'],
    );
  }

  /// Convert database map to BrainDump
  static BrainDump _brainDumpFromMap(Map<String, dynamic> map) {
    return BrainDump(
      id: map['id'],
      content: map['content'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      type: BrainDumpType.values[map['type']],
      tags: map['tags'],
      isProcessed: map['isProcessed'] == 1,
      processedTaskId: map['processedTaskId'],
    );
  }
}

/// Sync status enum
enum SyncStatus {
  synced,      // Data is synced with Firestore
  needsSync,   // Data needs to be synced
  syncing,     // Currently syncing
  failed,      // Sync failed
}
