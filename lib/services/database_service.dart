import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/validation_service.dart';

/// Production-ready SQLite database service
/// 
/// Replaces MockDatabaseService with persistent, secure, and scalable
/// database operations. Includes data validation, error handling,
/// and proper transaction management.
class DatabaseService {
  static Database? _database;
  static bool _initialized = false;
  static final _databaseLock = Completer<void>();

  // Database configuration
  static const String _databaseName = 'taskflow_database.db';
  static const int _databaseVersion = 1;

  /// Get database instance (singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Prevent multiple initialization attempts
    if (!_databaseLock.isCompleted) {
      await _databaseLock.future;
      if (_database != null) return _database!;
    }

    _database = await _initDatabase();
    _databaseLock.complete();
    return _database!;
  }

  /// Initialize the database with proper schema
  static Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      if (kDebugMode) {
        print('📗 Initializing database at: $path');
      }

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
        onOpen: _onDatabaseOpen,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Database initialization error: $e');
      }
      throw Exception('שגיאה בפתיחת בסיס הנתונים: $e');
    }
  }

  /// Create database tables
  static Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Tasks table
      await txn.execute('''
        CREATE TABLE tasks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL CHECK(length(title) >= 1 AND length(title) <= 200),
          description TEXT DEFAULT '',
          due_date INTEGER,
          priority INTEGER NOT NULL DEFAULT 1 CHECK(priority >= 0 AND priority <= 2),
          type INTEGER NOT NULL DEFAULT 0 CHECK(type >= 0 AND type <= 3),
          is_completed INTEGER NOT NULL DEFAULT 0 CHECK(is_completed IN (0, 1)),
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          voice_note TEXT,
          calendar_event_id TEXT,
          sync_status INTEGER NOT NULL DEFAULT 0 CHECK(sync_status >= 0 AND sync_status <= 2)
        )
      ''');

      // Create indexes for better performance
      await txn.execute('''
        CREATE INDEX idx_tasks_due_date ON tasks(due_date)
      ''');

      await txn.execute('''
        CREATE INDEX idx_tasks_created_at ON tasks(created_at)
      ''');

      await txn.execute('''
        CREATE INDEX idx_tasks_priority ON tasks(priority)
      ''');

      await txn.execute('''
        CREATE INDEX idx_tasks_type ON tasks(type)
      ''');

      await txn.execute('''
        CREATE INDEX idx_tasks_completed ON tasks(is_completed)
      ''');

      // User preferences table
      await txn.execute('''
        CREATE TABLE user_preferences (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Sync metadata table for future cloud sync
      await txn.execute('''
        CREATE TABLE sync_metadata (
          entity_type TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          last_sync INTEGER NOT NULL,
          sync_hash TEXT,
          PRIMARY KEY (entity_type, entity_id)
        )
      ''');

      if (kDebugMode) {
        print('✅ Database tables created successfully');
      }
    });
  }

  /// Handle database upgrades
  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('🔄 Upgrading database from version $oldVersion to $newVersion');
    }

    // Future database migrations will be handled here
    // For now, we only have version 1
  }

  /// Called when database is opened
  static Future<void> _onDatabaseOpen(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    
    // Set WAL mode for better performance
    await db.execute('PRAGMA journal_mode = WAL');
    
    if (kDebugMode) {
      print('✅ Database opened successfully with optimizations');
    }
  }

  /// Initialize database and sample data
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await database; // This will initialize the database
      
      // Check if we need sample data
      final taskCount = await getTaskCount();
      if (taskCount == 0) {
        await _initializeSampleData();
      }

      _initialized = true;
      if (kDebugMode) {
        print('✅ DatabaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Database initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Get total task count
  static Future<int> getTaskCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting task count: $e');
      }
      return 0;
    }
  }

  /// Insert a new task with validation
  static Future<bool> insertTask(Task task) async {
    try {
      // ✅ VALIDATION: Validate task data
      final validation = ValidationService.validateTaskInput(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        voiceNote: task.voiceNote,
      );

      if (!validation['isValid']) {
        if (kDebugMode) {
          print('⚠️ Task validation failed: ${validation['errors']}');
        }
        throw Exception('נתוני המשימה לא תקינים: ${validation['errors'].join(', ')}');
      }

      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'tasks',
        {
          'id': task.id,
          'title': validation['sanitizedData']['title'],
          'description': validation['sanitizedData']['description'],
          'due_date': task.dueDate?.millisecondsSinceEpoch,
          'priority': task.priority.index,
          'type': task.type.index,
          'is_completed': task.isCompleted ? 1 : 0,
          'created_at': task.createdAt.millisecondsSinceEpoch,
          'updated_at': now,
          'voice_note': validation['sanitizedData']['voiceNote'],
          'sync_status': 0, // Not synced
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        print('✅ Task inserted: ${task.title}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inserting task: $e');
      }
      throw Exception('שגיאה בשמירת משימה: $e');
    }
  }

  /// Get all tasks
  static Future<List<Task>> getAllTasks() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _taskFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting all tasks: $e');
      }
      return [];
    }
  }

  /// Get today's tasks
  static Future<List<Task>> getTodayTasks() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'due_date >= ? AND due_date < ?',
        whereArgs: [
          today.millisecondsSinceEpoch,
          tomorrow.millisecondsSinceEpoch,
        ],
        orderBy: 'due_date ASC',
      );

      return maps.map((map) => _taskFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting today tasks: $e');
      }
      return [];
    }
  }

  /// Get completed tasks count for today
  static Future<int> getTodayCompletedTasksCount() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM tasks 
        WHERE due_date >= ? AND due_date < ? AND is_completed = 1
      ''', [today.millisecondsSinceEpoch, tomorrow.millisecondsSinceEpoch]);

      return result.first['count'] as int;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting completed tasks count: $e');
      }
      return 0;
    }
  }

  /// Update a task
  static Future<bool> updateTask(Task task) async {
    try {
      // ✅ VALIDATION: Validate task data
      final validation = ValidationService.validateTaskInput(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        voiceNote: task.voiceNote,
      );

      if (!validation['isValid']) {
        throw Exception('נתוני המשימה לא תקינים: ${validation['errors'].join(', ')}');
      }

      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final rowsAffected = await db.update(
        'tasks',
        {
          'title': validation['sanitizedData']['title'],
          'description': validation['sanitizedData']['description'],
          'due_date': task.dueDate?.millisecondsSinceEpoch,
          'priority': task.priority.index,
          'type': task.type.index,
          'is_completed': task.isCompleted ? 1 : 0,
          'updated_at': now,
          'voice_note': validation['sanitizedData']['voiceNote'],
          'sync_status': 1, // Modified, needs sync
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );

      if (kDebugMode) {
        print('✅ Task updated: ${task.title}');
      }
      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating task: $e');
      }
      throw Exception('שגיאה בעדכון משימה: $e');
    }
  }

  /// Delete a task
  static Future<bool> deleteTask(String id) async {
    try {
      final db = await database;
      final rowsAffected = await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('✅ Task deleted: $id');
      }
      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting task: $e');
      }
      throw Exception('שגיאה במחיקת משימה: $e');
    }
  }

  /// Mark task as completed
  static Future<bool> markTaskCompleted(String id) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final rowsAffected = await db.update(
        'tasks',
        {
          'is_completed': 1,
          'updated_at': now,
          'sync_status': 1, // Modified, needs sync
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (kDebugMode) {
        print('✅ Task marked as completed: $id');
      }
      return rowsAffected > 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking task completed: $e');
      }
      return false;
    }
  }

  /// Get task by ID
  static Future<Task?> getTaskById(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return _taskFromMap(maps.first);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting task by ID: $e');
      }
      return null;
    }
  }

  /// Search and filter tasks with advanced options
  static Future<List<Task>> searchAndFilterTasks({
    String query = '',
    TaskType? type,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    String sortBy = 'created_at',
    bool descending = true,
    int? limit,
  }) async {
    try {
      final db = await database;
      
      // Build query conditions
      final List<String> conditions = [];
      final List<dynamic> arguments = [];

      if (query.isNotEmpty) {
        final sanitizedQuery = ValidationService.sanitizeUserInput(query);
        conditions.add('(title LIKE ? OR description LIKE ?)');
        arguments.add('%$sanitizedQuery%');
        arguments.add('%$sanitizedQuery%');
      }

      if (type != null) {
        conditions.add('type = ?');
        arguments.add(type.index);
      }

      if (priority != null) {
        conditions.add('priority = ?');
        arguments.add(priority.index);
      }

      if (startDate != null) {
        conditions.add('due_date >= ?');
        arguments.add(startDate.millisecondsSinceEpoch);
      }

      if (endDate != null) {
        conditions.add('due_date <= ?');
        arguments.add(endDate.millisecondsSinceEpoch);
      }

      if (isCompleted != null) {
        conditions.add('is_completed = ?');
        arguments.add(isCompleted ? 1 : 0);
      }

      // Build final query
      String whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : '';
      String orderByClause = '$sortBy ${descending ? 'DESC' : 'ASC'}';

      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: whereClause,
        whereArgs: arguments.isNotEmpty ? arguments : null,
        orderBy: orderByClause,
        limit: limit,
      );

      return maps.map((map) => _taskFromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching tasks: $e');
      }
      return [];
    }
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final db = await database;
      
      final totalTasks = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
      final completedTasks = await db.rawQuery('SELECT COUNT(*) as count FROM tasks WHERE is_completed = 1');
      final todayTasks = await getTodayTasks();
      final overdueQuery = await db.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE due_date < ? AND is_completed = 0
      ''', [DateTime.now().millisecondsSinceEpoch]);

      return {
        'totalTasks': totalTasks.first['count'],
        'completedTasks': completedTasks.first['count'],
        'todayTasks': todayTasks.length,
        'overdueTasks': overdueQuery.first['count'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting database stats: $e');
      }
      return {};
    }
  }

  /// Initialize sample data
  static Future<void> _initializeSampleData() async {
    try {
      final now = DateTime.now();
      final sampleTasks = [
        Task(
          id: '1',
          title: 'להתקשר לרופא',
          description: 'לקבוע תור לבדיקה שנתית',
          dueDate: now.add(const Duration(days: 1)),
          priority: TaskPriority.important,
          type: TaskType.reminder,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        Task(
          id: '2',
          title: 'לקנות מתנה לאמא',
          description: 'יום הולדת השבוע',
          dueDate: now.add(const Duration(days: 3)),
          priority: TaskPriority.simple,
          type: TaskType.task,
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        Task(
          id: '3',
          title: 'פגישה עם המנהל',
          description: 'לדבר על העלאת משכורת',
          dueDate: now.add(const Duration(days: 7)),
          priority: TaskPriority.important,
          type: TaskType.event,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        Task(
          id: '4',
          title: 'להביא מטען לטלפון',
          description: 'תזכורת קולית מהבוקר',
          priority: TaskPriority.later,
          type: TaskType.note,
          createdAt: now.subtract(const Duration(hours: 1)),
          voiceNote: 'תזכורת קולית: להביא מטען חדש לטלפון',
        ),
        Task(
          id: '5',
          title: 'לשלוח אימייל לעובדים',
          description: 'עדכון על הפגישה של מחר',
          dueDate: now.add(const Duration(hours: 4)),
          priority: TaskPriority.important,
          type: TaskType.task,
          createdAt: now.subtract(const Duration(minutes: 30)),
          isCompleted: true,
        ),
      ];

      for (final task in sampleTasks) {
        await insertTask(task);
      }

      if (kDebugMode) {
        print('✅ Sample data initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing sample data: $e');
      }
    }
  }

  /// Convert database map to Task object
  static Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['due_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['due_date'])
          : null,
      priority: TaskPriority.values[map['priority'] ?? 1],
      type: TaskType.values[map['type'] ?? 0],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      voiceNote: map['voice_note'],
    );
  }

  /// Backup database to a JSON string (for export/backup)
  static Future<String> exportToJson() async {
    try {
      final tasks = await getAllTasks();
      final taskMaps = tasks.map((task) => task.toMap()).toList();
      
      return taskMaps.toString(); // Simple export, can be enhanced with proper JSON
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting data: $e');
      }
      throw Exception('שגיאה בייצוא נתונים: $e');
    }
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initialized = false;
      
      if (kDebugMode) {
        print('✅ Database closed successfully');
      }
    }
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete('tasks');
      await db.delete('user_preferences');
      await db.delete('sync_metadata');
      
      if (kDebugMode) {
        print('✅ All data cleared successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing data: $e');
      }
      throw Exception('שגיאה בניקוי נתונים: $e');
    }
  }
}
