import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for managing tasks (CRUD operations)
class ManageTask {
  final TaskRepository _repository;

  const ManageTask(this._repository);

  /// Create a new task
  Future<Task> create({
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.simple,
    TaskType type = TaskType.task,
    String? voiceNote,
    List<String> tags = const [],
  }) async {
    final task = Task(
      id: _generateId(),
      title: title.trim(),
      description: description.trim(),
      dueDate: dueDate,
      priority: priority,
      type: type,
      createdAt: DateTime.now(),
      voiceNote: voiceNote,
      tags: tags,
    );

    return await _repository.addTask(task);
  }

  /// Update an existing task
  Future<Task> update(Task task) async {
    // Business logic: ensure title is not empty
    if (task.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    final updatedTask = task.copyWith(
      title: task.title.trim(),
      description: task.description.trim(),
    );

    return await _repository.updateTask(updatedTask);
  }

  /// Delete a task
  Future<void> delete(String id) async {
    await _repository.deleteTask(id);
  }

  /// Mark task as completed
  Future<Task> complete(String id) async {
    return await _repository.completeTask(id);
  }

  /// Mark task as incomplete
  Future<Task> incomplete(String id) async {
    return await _repository.incompleteTask(id);
  }

  /// Toggle task completion status
  Future<Task> toggleComplete(String id) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw ArgumentError('Task not found: $id');
    }

    return task.isCompleted 
        ? await _repository.incompleteTask(id)
        : await _repository.completeTask(id);
  }

  /// Update task priority
  Future<Task> updatePriority(String id, TaskPriority priority) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw ArgumentError('Task not found: $id');
    }

    final updatedTask = task.copyWith(priority: priority);
    return await _repository.updateTask(updatedTask);
  }

  /// Add tag to task
  Future<Task> addTag(String id, String tag) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw ArgumentError('Task not found: $id');
    }

    if (task.tags.contains(tag)) {
      return task; // Tag already exists
    }

    final updatedTags = [...task.tags, tag.trim()];
    final updatedTask = task.copyWith(tags: updatedTags);
    return await _repository.updateTask(updatedTask);
  }

  /// Remove tag from task
  Future<Task> removeTag(String id, String tag) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw ArgumentError('Task not found: $id');
    }

    final updatedTags = task.tags.where((t) => t != tag).toList();
    final updatedTask = task.copyWith(tags: updatedTags);
    return await _repository.updateTask(updatedTask);
  }

  /// Set due date for task
  Future<Task> setDueDate(String id, DateTime? dueDate) async {
    final task = await _repository.getTaskById(id);
    if (task == null) {
      throw ArgumentError('Task not found: $id');
    }

    final updatedTask = task.copyWith(dueDate: dueDate);
    return await _repository.updateTask(updatedTask);
  }

  /// Generate unique ID for new tasks
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
