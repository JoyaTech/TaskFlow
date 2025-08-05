import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/cloud_database_service.dart';

/// Production-ready secure Cloud database service
/// 
/// This service acts as a wrapper around CloudDatabaseService for backward 
/// compatibility while ensuring all operations are authenticated and secure.
/// All data operations go through Firebase Firestore with proper security rules.
class DatabaseService {
  static bool _initialized = false;

  /// Initialize the secure cloud database service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await CloudDatabaseService.initialize();
      _initialized = true;
      
      if (kDebugMode) {
        print('✅ Secure DatabaseService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Secure DatabaseService initialization failed: $e');
      }
      rethrow;
    }
  }
  
  // Wrapper methods for backward compatibility - all operations require authentication
  static Future<bool> insertTask(Task task) => CloudDatabaseService.insertTask(task);
  static Future<List<Task>> getAllTasks() => CloudDatabaseService.getAllTasks();
  static Future<List<Task>> getTodayTasks() => CloudDatabaseService.getTodayTasks();
  static Future<bool> updateTask(Task task) => CloudDatabaseService.updateTask(task);
  static Future<bool> deleteTask(String id) => CloudDatabaseService.deleteTask(id);
  static Future<bool> markTaskCompleted(String id) => CloudDatabaseService.markTaskCompleted(id);
  static Future<Task?> getTaskById(String id) => CloudDatabaseService.getTaskById(id);
  static Future<Map<String, dynamic>> getDatabaseStats() => CloudDatabaseService.getDatabaseStats();
  
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
  }) => CloudDatabaseService.searchAndFilterTasks(
    query: query,
    type: type,
    priority: priority,
    startDate: startDate,
    endDate: endDate,
    isCompleted: isCompleted,
    sortBy: sortBy,
    descending: descending,
    limit: limit,
  );
  
  // Stream methods for real-time updates
  static Stream<List<Task>> watchAllTasks() => CloudDatabaseService.watchAllTasks();
  static Stream<List<Task>> watchTodayTasks() => CloudDatabaseService.watchTodayTasks();
  
  // Additional secure methods
  static Future<Map<String, dynamic>> exportUserData() => CloudDatabaseService.exportUserData();
  static Future<void> backupUserData() => CloudDatabaseService.backupUserData();
}
