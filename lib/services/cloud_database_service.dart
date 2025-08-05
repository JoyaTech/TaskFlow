import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/auth_service.dart';
import 'package:mindflow/services/validation_service.dart';

/// Production-ready Firestore database service with authentication enforcement
/// 
/// This service replaces direct database access with secure, authenticated
/// operations. All operations require user authentication and enforce
/// user-specific data isolation.
class CloudDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _initialized = false;

  /// Initialize the cloud database service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Enable offline persistence for better performance
      if (!kIsWeb) {
        await _firestore.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
      }

      _initialized = true;
      if (kDebugMode) {
        print('✅ CloudDatabaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ CloudDatabaseService initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Ensure user is authenticated before any operation
  static void _requireAuth() {
    if (!AuthService.isLoggedIn) {
      throw Exception('משתמש לא מחובר - נדרשת התחברות לביצוע פעולה זו');
    }
  }

  /// Get current user's tasks collection reference
  static CollectionReference<Map<String, dynamic>> _getUserTasksRef() {
    _requireAuth();
    return _firestore
        .collection('tasks')
        .doc(AuthService.currentUserId!)
        .collection('user_tasks');
  }

  /// Get current user's brain dumps collection reference
  static CollectionReference<Map<String, dynamic>> _getUserBrainDumpsRef() {
    _requireAuth();
    return _firestore
        .collection('brain_dumps')
        .doc(AuthService.currentUserId!)
        .collection('user_brain_dumps');
  }

  /// Insert a new task with authentication and validation
  static Future<bool> insertTask(Task task) async {
    try {
      _requireAuth();

      // Validate task data
      final validation = ValidationService.validateTaskInput(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        voiceNote: task.voiceNote,
      );

      if (!validation['isValid']) {
        throw Exception('נתוני המשימה לא תקינים: ${validation['errors'].join(', ')}');
      }

      final tasksRef = _getUserTasksRef();
      final taskData = {
        'id': task.id,
        'userId': AuthService.currentUserId!, // Always include userId
        'title': validation['sanitizedData']['title'],
        'description': validation['sanitizedData']['description'],
        'dueDate': task.dueDate?.toIso8601String(),
        'priority': task.priority.index,
        'type': task.type.index,
        'isCompleted': task.isCompleted,
        'createdAt': task.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'voiceNote': validation['sanitizedData']['voiceNote'],
        'syncStatus': 'synced',
      };

      await tasksRef.doc(task.id).set(taskData);

      if (kDebugMode) {
        print('✅ Task inserted to cloud: ${task.title}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inserting task to cloud: $e');
      }
      throw Exception('שגיאה בשמירת משימה: $e');
    }
  }

  /// Get all tasks for the current user
  static Future<List<Task>> getAllTasks() async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      final snapshot = await tasksRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _taskFromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting all tasks from cloud: $e');
      }
      return [];
    }
  }

  /// Get today's tasks for the current user
  static Future<List<Task>> getTodayTasks() async {
    try {
      _requireAuth();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final tasksRef = _getUserTasksRef();
      final snapshot = await tasksRef
          .where('dueDate', isGreaterThanOrEqualTo: today.toIso8601String())
          .where('dueDate', isLessThan: tomorrow.toIso8601String())
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => _taskFromFirestore(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting today tasks from cloud: $e');
      }
      return [];
    }
  }

  /// Update a task with authentication validation
  static Future<bool> updateTask(Task task) async {
    try {
      _requireAuth();

      // Validate task data
      final validation = ValidationService.validateTaskInput(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        voiceNote: task.voiceNote,
      );

      if (!validation['isValid']) {
        throw Exception('נתוני המשימה לא תקינים: ${validation['errors'].join(', ')}');
      }

      final tasksRef = _getUserTasksRef();
      final updateData = {
        'title': validation['sanitizedData']['title'],
        'description': validation['sanitizedData']['description'],
        'dueDate': task.dueDate?.toIso8601String(),
        'priority': task.priority.index,
        'type': task.type.index,
        'isCompleted': task.isCompleted,
        'updatedAt': DateTime.now().toIso8601String(),
        'voiceNote': validation['sanitizedData']['voiceNote'],
        'syncStatus': 'synced',
      };

      await tasksRef.doc(task.id).update(updateData);

      if (kDebugMode) {
        print('✅ Task updated in cloud: ${task.title}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating task in cloud: $e');
      }
      throw Exception('שגיאה בעדכון משימה: $e');
    }
  }

  /// Delete a task with authentication validation
  static Future<bool> deleteTask(String taskId) async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      await tasksRef.doc(taskId).delete();

      if (kDebugMode) {
        print('✅ Task deleted from cloud: $taskId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting task from cloud: $e');
      }
      throw Exception('שגיאה במחיקת משימה: $e');
    }
  }

  /// Mark task as completed with authentication validation
  static Future<bool> markTaskCompleted(String taskId) async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      await tasksRef.doc(taskId).update({
        'isCompleted': true,
        'updatedAt': DateTime.now().toIso8601String(),
        'syncStatus': 'synced',
      });

      if (kDebugMode) {
        print('✅ Task marked as completed in cloud: $taskId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking task completed in cloud: $e');
      }
      return false;
    }
  }

  /// Get task by ID with authentication validation
  static Future<Task?> getTaskById(String taskId) async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      final doc = await tasksRef.doc(taskId).get();

      if (doc.exists) {
        return _taskFromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting task by ID from cloud: $e');
      }
      return null;
    }
  }

  /// Search and filter tasks with authentication validation
  static Future<List<Task>> searchAndFilterTasks({
    String query = '',
    TaskType? type,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    String sortBy = 'createdAt',
    bool descending = true,
    int? limit,
  }) async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      Query<Map<String, dynamic>> queryRef = tasksRef;

      // Apply filters
      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.index);
      }

      if (priority != null) {
        queryRef = queryRef.where('priority', isEqualTo: priority.index);
      }

      if (startDate != null) {
        queryRef = queryRef.where('dueDate', 
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      if (endDate != null) {
        queryRef = queryRef.where('dueDate', 
            isLessThanOrEqualTo: endDate.toIso8601String());
      }

      if (isCompleted != null) {
        queryRef = queryRef.where('isCompleted', isEqualTo: isCompleted);
      }

      // Apply sorting
      queryRef = queryRef.orderBy(sortBy, descending: descending);

      // Apply limit
      if (limit != null) {
        queryRef = queryRef.limit(limit);
      }

      final snapshot = await queryRef.get();
      List<Task> tasks = snapshot.docs
          .map((doc) => _taskFromFirestore(doc.data()))
          .toList();

      // Client-side text search (Firestore doesn't support full-text search)
      if (query.isNotEmpty) {
        final sanitizedQuery = ValidationService.sanitizeUserInput(query.toLowerCase());
        tasks = tasks.where((task) =>
            task.title.toLowerCase().contains(sanitizedQuery) ||
            task.description.toLowerCase().contains(sanitizedQuery)).toList();
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error searching tasks in cloud: $e');
      }
      return [];
    }
  }

  /// Get database statistics for the current user
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      _requireAuth();

      final tasksRef = _getUserTasksRef();
      
      // Get all tasks
      final allTasksSnapshot = await tasksRef.get();
      final totalTasks = allTasksSnapshot.docs.length;
      
      // Get completed tasks
      final completedSnapshot = await tasksRef
          .where('isCompleted', isEqualTo: true)
          .get();
      final completedTasks = completedSnapshot.docs.length;
      
      // Get today's tasks
      final todayTasks = await getTodayTasks();
      
      // Get overdue tasks
      final now = DateTime.now();
      final overdueSnapshot = await tasksRef
          .where('dueDate', isLessThan: now.toIso8601String())
          .where('isCompleted', isEqualTo: false)
          .get();
      final overdueTasks = overdueSnapshot.docs.length;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'todayTasks': todayTasks.length,
        'overdueTasks': overdueTasks,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting database stats from cloud: $e');
      }
      return {};
    }
  }

  /// Listen to tasks changes in real-time
  static Stream<List<Task>> watchAllTasks() {
    _requireAuth();
    
    return _getUserTasksRef()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc.data()))
            .toList());
  }

  /// Listen to today's tasks changes in real-time
  static Stream<List<Task>> watchTodayTasks() {
    _requireAuth();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _getUserTasksRef()
        .where('dueDate', isGreaterThanOrEqualTo: today.toIso8601String())
        .where('dueDate', isLessThan: tomorrow.toIso8601String())
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _taskFromFirestore(doc.data()))
            .toList());
  }

  /// Convert Firestore document to Task object
  static Task _taskFromFirestore(Map<String, dynamic> data) {
    return Task(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate'] != null 
          ? DateTime.parse(data['dueDate'])
          : null,
      priority: TaskPriority.values[data['priority'] ?? 1],
      type: TaskType.values[data['type'] ?? 0],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: DateTime.parse(data['createdAt']),
      voiceNote: data['voiceNote'],
    );
  }

  /// Export user data to JSON (with authentication)
  static Future<Map<String, dynamic>> exportUserData() async {
    try {
      _requireAuth();

      final tasks = await getAllTasks();
      final userProfile = await AuthService.getUserProfile();

      return {
        'user': userProfile,
        'tasks': tasks.map((task) => task.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error exporting user data: $e');
      }
      throw Exception('שגיאה בייצוא נתונים: $e');
    }
  }

  /// Backup user data to cloud storage
  static Future<void> backupUserData() async {
    try {
      _requireAuth();

      final userData = await exportUserData();
      
      await _firestore
          .collection('backups')
          .doc(AuthService.currentUserId!)
          .collection('user_backups')
          .doc(DateTime.now().millisecondsSinceEpoch.toString())
          .set(userData);

      if (kDebugMode) {
        print('✅ User data backed up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error backing up user data: $e');
      }
      throw Exception('שגיאה ביצירת גיבוי: $e');
    }
  }
}
