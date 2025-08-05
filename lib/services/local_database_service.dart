import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/brain_dump_model.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LocalDatabaseService {
  Database? _database;
  final _dbReadyCompleter = Completer<void>();

  LocalDatabaseService() {
    _initDatabase();
  }

  Future<void> get onDbReady => _dbReadyCompleter.future;

  static const String _databaseName = 'mindflow_local.db';
  static const int _databaseVersion = 1;

  Future<void> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _dbReadyCompleter.complete();
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE user_settings (
        userId TEXT PRIMARY KEY,
        settings TEXT NOT NULL,
        lastSyncAt INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_tasks_userId ON tasks(userId)');
    await db.execute('CREATE INDEX idx_tasks_dueDate ON tasks(dueDate)');
    await db.execute('CREATE INDEX idx_tasks_syncStatus ON tasks(syncStatus)');
    await db.execute('CREATE INDEX idx_brain_dumps_userId ON brain_dumps(userId)');
    await db.execute('CREATE INDEX idx_brain_dumps_syncStatus ON brain_dumps(syncStatus)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Upgrading database from version $oldVersion to $newVersion');
    }
  }

  Future<void> insertTask(Task task, {bool syncNeeded = true}) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _database!.insert(
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

  Future<void> updateTask(Task task, {bool syncNeeded = true}) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _database!.update(
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

  Future<void> deleteTask(String taskId, {bool syncNeeded = true}) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _database!.delete(
      'tasks',
      where: 'id = ? AND userId = ?',
      whereArgs: [taskId, userId],
    );

    if (syncNeeded) {
      await _addToSyncQueue('tasks', taskId, 'DELETE', {});
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) return null;

    final maps = await _database!.query(
      'tasks',
      where: 'id = ? AND userId = ?',
      whereArgs: [taskId, userId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _taskFromMap(maps.first);
    }
    return null;
  }

  Stream<List<Task>> watchAllTasks() async* {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) {
      yield [];
      return;
    }
    yield* _database!
        .query('tasks', where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC')
        .asStream()
        .map((maps) => maps.map((map) => _taskFromMap(map)).toList());
  }

  Stream<List<Task>> watchTodayTasks() async* {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) {
      yield [];
      return;
    }
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;

    yield* _database!
        .query('tasks',
            where: 'userId = ? AND dueDate >= ? AND dueDate <= ?',
            whereArgs: [userId, startOfDay, endOfDay],
            orderBy: 'dueDate ASC')
        .asStream()
        .map((maps) => maps.map((map) => _taskFromMap(map)).toList());
  }

  Stream<List<Task>> watchCompletedTasks() async* {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) {
      yield [];
      return;
    }
    yield* _database!
        .query('tasks', where: 'userId = ? AND isCompleted = 1', whereArgs: [userId], orderBy: 'createdAt DESC')
        .asStream()
        .map((maps) => maps.map((map) => _taskFromMap(map)).toList());
  }

  Stream<List<Task>> watchNotes() async* {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) {
      yield [];
      return;
    }
    yield* _database!
        .query('tasks', where: 'userId = ? AND type = ?', whereArgs: [userId, TaskType.note.index], orderBy: 'createdAt DESC')
        .asStream()
        .map((maps) => maps.map((map) => _taskFromMap(map)).toList());
  }

  Future<List<Task>> getAllTasks() async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await _database!.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<List<Task>> getTasksByCriteria({
    TaskType? type,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await onDbReady;
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

    final maps = await _database!.query(
      'tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<List<Task>> searchTasks(String query) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await _database!.query(
      'tasks',
      where: 'userId = ? AND (title LIKE ? OR description LIKE ? OR voiceNote LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _taskFromMap(map)).toList();
  }

  Future<void> insertBrainDump(BrainDump brainDump, {bool syncNeeded = true}) async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _database!.insert(
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

  Future<List<BrainDump>> getAllBrainDumps() async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) return [];

    final maps = await _database!.query(
      'brain_dumps',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _brainDumpFromMap(map)).toList();
  }

  Future<void> _addToSyncQueue(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    await onDbReady;
    await _database!.insert('sync_queue', {
      'tableName': tableName,
      'recordId': recordId,
      'operation': operation,
      'data': data.toString(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    await onDbReady;
    return await _database!.query(
      'sync_queue',
      orderBy: 'createdAt ASC',
      limit: 50,
    );
  }

  Future<void> markSyncCompleted(int syncId) async {
    await onDbReady;
    await _database!.delete('sync_queue', where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> incrementSyncAttempt(int syncId) async {
    await onDbReady;
    await _database!.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1 WHERE id = ?',
      [syncId],
    );
  }

  Future<bool> syncWithFirestore() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    try {
      final pendingOperations = await getPendingSyncOperations();
      for (final operation in pendingOperations) {
        try {
          await markSyncCompleted(operation['id']);
        } catch (e) {
          await incrementSyncAttempt(operation['id']);
          if (kDebugMode) print('Sync failed for operation ${operation['id']}: $e');
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

  Future<void> clearAllData() async {
    await onDbReady;
    await _database!.delete('tasks');
    await _database!.delete('brain_dumps');
    await _database!.delete('sync_queue');
    await _database!.delete('user_settings');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    await onDbReady;
    final userId = AuthService.currentUserId;
    if (userId == null) return {};

    final taskCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM tasks WHERE userId = ?', [userId])
    ) ?? 0;

    final brainDumpCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM brain_dumps WHERE userId = ?', [userId])
    ) ?? 0;

    final pendingSyncCount = Sqflite.firstIntValue(
      await _database!.rawQuery('SELECT COUNT(*) FROM sync_queue')
    ) ?? 0;

    return {
      'tasks': taskCount,
      'brainDumps': brainDumpCount,
      'pendingSync': pendingSyncCount,
    };
  }

  Task _taskFromMap(Map<String, dynamic> map) {
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

  BrainDump _brainDumpFromMap(Map<String, dynamic> map) {
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

enum SyncStatus {
  synced,
  needsSync,
  syncing,
  failed,
}
