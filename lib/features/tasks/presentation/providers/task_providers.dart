import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/manage_task.dart';

// Repository provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl();
});

// Use cases providers
final getTasksUseCaseProvider = Provider<GetTasks>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return GetTasks(repository);
});

final manageTaskUseCaseProvider = Provider<ManageTask>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return ManageTask(repository);
});

// Task list state provider
final taskListProvider = StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
  final getTasks = ref.watch(getTasksUseCaseProvider);
  final manageTask = ref.watch(manageTaskUseCaseProvider);
  return TaskListNotifier(getTasks, manageTask);
});

// Filtered task providers
final pendingTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.whenData((tasks) => tasks.where((task) => !task.isCompleted).toList());
});

final completedTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.whenData((tasks) => tasks.where((task) => task.isCompleted).toList());
});

final todayTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.whenData((tasks) => tasks.where((task) => task.isDueToday).toList());
});

final overdueTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.whenData((tasks) => tasks.where((task) => task.isOverdue).toList());
});

final importantTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.whenData((tasks) => tasks.where((task) => task.priority == TaskPriority.important).toList());
});

// Task statistics provider
final taskStatsProvider = Provider<TaskStats>((ref) {
  final taskListState = ref.watch(taskListProvider);
  return taskListState.when(
    data: (tasks) => TaskStats.fromTasks(tasks),
    loading: () => const TaskStats(total: 0, completed: 0, pending: 0, overdue: 0),
    error: (_, __) => const TaskStats(total: 0, completed: 0, pending: 0, overdue: 0),
  );
});

// Task filter state
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// Filtered tasks based on current filter
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final taskListState = ref.watch(taskListProvider);

  return taskListState.whenData((tasks) {
    switch (filter) {
      case TaskFilter.all:
        return tasks;
      case TaskFilter.pending:
        return tasks.where((task) => !task.isCompleted).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.isCompleted).toList();
      case TaskFilter.today:
        return tasks.where((task) => task.isDueToday).toList();
      case TaskFilter.overdue:
        return tasks.where((task) => task.isOverdue).toList();
      case TaskFilter.important:
        return tasks.where((task) => task.priority == TaskPriority.important).toList();
    }
  });
});

/// StateNotifier for managing task list state
class TaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final GetTasks _getTasks;
  final ManageTask _manageTask;

  TaskListNotifier(this._getTasks, this._manageTask) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  /// Load all tasks
  Future<void> loadTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _getTasks();
      state = AsyncValue.data(tasks);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a new task
  Future<void> addTask({
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.simple,
    TaskType type = TaskType.task,
    String? voiceNote,
    List<String> tags = const [],
  }) async {
    try {
      final newTask = await _manageTask.create(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        type: type,
        voiceNote: voiceNote,
        tags: tags,
      );

      state = state.whenData((tasks) => [...tasks, newTask]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = await _manageTask.update(task);
      
      state = state.whenData((tasks) => tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a task
  Future<void> deleteTask(String id) async {
    try {
      await _manageTask.delete(id);
      state = state.whenData((tasks) => tasks.where((t) => t.id != id).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle task completion
  Future<void> toggleTaskCompletion(String id) async {
    try {
      final updatedTask = await _manageTask.toggleComplete(id);
      state = state.whenData((tasks) => tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update task priority
  Future<void> updateTaskPriority(String id, TaskPriority priority) async {
    try {
      final updatedTask = await _manageTask.updatePriority(id, priority);
      state = state.whenData((tasks) => tasks.map((t) => t.id == updatedTask.id ? updatedTask : t).toList());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh tasks from repository
  Future<void> refresh() async {
    await loadTasks();
  }
}

/// Enum for task filtering
enum TaskFilter {
  all,
  pending,
  completed,
  today,
  overdue,
  important;

  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'כל המשימות';
      case TaskFilter.pending:
        return 'בהמתנה';
      case TaskFilter.completed:
        return 'הושלמו';
      case TaskFilter.today:
        return 'היום';
      case TaskFilter.overdue:
        return 'פיגור';
      case TaskFilter.important:
        return 'חשובות';
    }
  }
}

/// Data class for task statistics
class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  factory TaskStats.fromTasks(List<Task> tasks) {
    final total = tasks.length;
    final completed = tasks.where((task) => task.isCompleted).length;
    final pending = tasks.where((task) => !task.isCompleted).length;
    final overdue = tasks.where((task) => task.isOverdue).length;

    return TaskStats(
      total: total,
      completed: completed,
      pending: pending,
      overdue: overdue,
    );
  }

  double get completionRate => total > 0 ? completed / total : 0.0;
}
