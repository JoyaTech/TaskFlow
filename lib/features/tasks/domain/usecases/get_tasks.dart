import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for getting tasks with various filters
/// Encapsulates the business logic for task retrieval
class GetTasks {
  final TaskRepository _repository;

  const GetTasks(this._repository);

  /// Get all tasks
  Future<List<Task>> call() async {
    return await _repository.getAllTasks();
  }

  /// Get tasks with filtering options
  Future<List<Task>> filtered({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    List<String>? tags,
  }) async {
    return await _repository.getTasks(
      priority: priority,
      type: type,
      isCompleted: isCompleted,
      dueBefore: dueBefore,
      dueAfter: dueAfter,
      tags: tags,
    );
  }

  /// Get tasks due today
  Future<List<Task>> dueToday() async {
    return await _repository.getTasksDueToday();
  }

  /// Get overdue tasks
  Future<List<Task>> overdue() async {
    return await _repository.getOverdueTasks();
  }

  /// Get upcoming tasks
  Future<List<Task>> upcoming() async {
    return await _repository.getUpcomingTasks();
  }

  /// Get completed tasks
  Future<List<Task>> completed() async {
    return await _repository.getCompletedTasks();
  }

  /// Get pending tasks (not completed)
  Future<List<Task>> pending() async {
    return await _repository.getTasks(isCompleted: false);
  }

  /// Get important tasks
  Future<List<Task>> important() async {
    return await _repository.getTasks(priority: TaskPriority.important);
  }
}
