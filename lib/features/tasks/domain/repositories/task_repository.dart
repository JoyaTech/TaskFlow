import '../entities/task.dart';

/// Abstract repository interface for task operations
/// This defines the contract without implementation details
abstract class TaskRepository {
  /// Get all tasks
  Future<List<Task>> getAllTasks();

  /// Get task by ID
  Future<Task?> getTaskById(String id);

  /// Get tasks with optional filtering
  Future<List<Task>> getTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    List<String>? tags,
  });

  /// Get tasks due today
  Future<List<Task>> getTasksDueToday();

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks();

  /// Get upcoming tasks (due within 7 days)
  Future<List<Task>> getUpcomingTasks();

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks();

  /// Add a new task
  Future<Task> addTask(Task task);

  /// Update an existing task
  Future<Task> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Mark task as completed
  Future<Task> completeTask(String id);

  /// Mark task as incomplete
  Future<Task> incompleteTask(String id);

  /// Search tasks by query
  Future<List<Task>> searchTasks(String query);

  /// Get tasks count by status
  Future<Map<String, int>> getTaskCounts();

  /// Stream of all tasks (for real-time updates)
  Stream<List<Task>> watchAllTasks();

  /// Stream of tasks with filtering
  Stream<List<Task>> watchTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
  });

  /// Sync tasks with remote storage (if available)
  Future<void> syncTasks();

  /// Clear all tasks (useful for testing or reset)
  Future<void> clearAllTasks();
}
