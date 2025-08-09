import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../../domain/entities/task.dart';

/// Abstract interface for local task data operations
abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<List<TaskModel>> getTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    List<String>? tags,
  });
  Future<TaskModel> addTask(TaskModel task);
  Future<TaskModel> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> searchTasks(String query);
  Stream<List<TaskModel>> watchAllTasks();
  Stream<List<TaskModel>> watchTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
  });
  Future<void> clearAllTasks();
}

/// SQLite implementation of TaskLocalDataSource
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static Database? _database;
  static const String _tableName = 'tasks';

  final StreamController<List<TaskModel>> _tasksStreamController = 
      StreamController<List<TaskModel>>.broadcast();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'tasks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        dueDate TEXT,
        priority INTEGER DEFAULT 0,
        type INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        voiceNote TEXT,
        tags TEXT DEFAULT ''
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_tasks_completed ON $_tableName (isCompleted)');
    await db.execute('CREATE INDEX idx_tasks_priority ON $_tableName (priority)');
    await db.execute('CREATE INDEX idx_tasks_type ON $_tableName (type)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON $_tableName (dueDate)');
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    final tasks = List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
    _notifyTasksChanged(tasks);
    return tasks;
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TaskModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<TaskModel>> getTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    List<String>? tags,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (priority != null) {
      whereClause += 'priority = ?';
      whereArgs.add(priority.index);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.index);
    }

    if (isCompleted != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isCompleted = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (dueBefore != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'dueDate <= ?';
      whereArgs.add(dueBefore.toIso8601String());
    }

    if (dueAfter != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'dueDate >= ?';
      whereArgs.add(dueAfter.toIso8601String());
    }

    if (tags != null && tags.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      final tagConditions = tags.map((_) => 'tags LIKE ?').join(' OR ');
      whereClause += '($tagConditions)';
      whereArgs.addAll(tags.map((tag) => '%$tag%'));
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  @override
  Future<TaskModel> addTask(TaskModel task) async {
    final db = await database;
    await db.insert(_tableName, task.toMap());
    
    // Notify listeners
    _notifyTasksChanged();
    
    return task;
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    final db = await database;
    await db.update(
      _tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Notify listeners
    _notifyTasksChanged();
    
    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Notify listeners
    _notifyTasksChanged();
  }

  @override
  Future<List<TaskModel>> searchTasks(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'title LIKE ? OR description LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  @override
  Stream<List<TaskModel>> watchAllTasks() {
    // Initialize the stream with current tasks
    getAllTasks();
    return _tasksStreamController.stream;
  }

  @override
  Stream<List<TaskModel>> watchTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
  }) {
    return watchAllTasks().map((tasks) => tasks.where((task) {
      if (priority != null && task.priority != priority) return false;
      if (type != null && task.type != type) return false;
      if (isCompleted != null && task.isCompleted != isCompleted) return false;
      return true;
    }).toList());
  }

  @override
  Future<void> clearAllTasks() async {
    final db = await database;
    await db.delete(_tableName);
    
    // Notify listeners
    _notifyTasksChanged();
  }

  /// Notify listeners about task changes
  void _notifyTasksChanged([List<TaskModel>? tasks]) {
    if (tasks != null) {
      _tasksStreamController.add(tasks);
    } else {
      // Fetch current tasks and notify
      getAllTasks().then((currentTasks) {
        _tasksStreamController.add(currentTasks);
      });
    }
  }

  void dispose() {
    _tasksStreamController.close();
  }
}
