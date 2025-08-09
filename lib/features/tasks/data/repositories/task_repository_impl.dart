import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

/// Implementation of TaskRepository
/// Coordinates between local and remote data sources
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl({
    TaskLocalDataSource? localDataSource,
    TaskRemoteDataSource? remoteDataSource,
  })  : _localDataSource = localDataSource ?? TaskLocalDataSourceImpl(),
        _remoteDataSource = remoteDataSource ?? TaskRemoteDataSourceImpl();

  @override
  Future<List<Task>> getAllTasks() async {
    try {
      // Try to get from local first
      final localTasks = await _localDataSource.getAllTasks();
      final tasks = localTasks.map((model) => model.toEntity()).toList();
      
      // TODO: Implement background sync with remote
      return tasks;
    } catch (e) {
      // Fallback to empty list
      return [];
    }
  }

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      final taskModel = await _localDataSource.getTaskById(id);
      return taskModel?.toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Task>> getTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? dueBefore,
    DateTime? dueAfter,
    List<String>? tags,
  }) async {
    try {
      final taskModels = await _localDataSource.getTasks(
        priority: priority,
        type: type,
        isCompleted: isCompleted,
        dueBefore: dueBefore,
        dueAfter: dueAfter,
        tags: tags,
      );
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Task>> getTasksDueToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return await getTasks(
      dueAfter: today,
      dueBefore: tomorrow,
    );
  }

  @override
  Future<List<Task>> getOverdueTasks() async {
    final now = DateTime.now();
    return await getTasks(
      dueBefore: now,
      isCompleted: false,
    );
  }

  @override
  Future<List<Task>> getUpcomingTasks() async {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    
    return await getTasks(
      dueAfter: now,
      dueBefore: sevenDaysFromNow,
      isCompleted: false,
    );
  }

  @override
  Future<List<Task>> getCompletedTasks() async {
    return await getTasks(isCompleted: true);
  }

  @override
  Future<Task> addTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final savedModel = await _localDataSource.addTask(taskModel);
      
      // TODO: Sync with remote in background
      
      return savedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final updatedModel = await _localDataSource.updateTask(taskModel);
      
      // TODO: Sync with remote in background
      
      return updatedModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _localDataSource.deleteTask(id);
      
      // TODO: Sync with remote in background
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Task> completeTask(String id) async {
    try {
      final task = await getTaskById(id);
      if (task == null) {
        throw Exception('Task not found: $id');
      }
      
      final completedTask = task.complete();
      return await updateTask(completedTask);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Task> incompleteTask(String id) async {
    try {
      final task = await getTaskById(id);
      if (task == null) {
        throw Exception('Task not found: $id');
      }
      
      final incompleteTask = task.incomplete();
      return await updateTask(incompleteTask);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    try {
      final taskModels = await _localDataSource.searchTasks(query);
      return taskModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, int>> getTaskCounts() async {
    try {
      final allTasks = await getAllTasks();
      return {
        'total': allTasks.length,
        'completed': allTasks.where((task) => task.isCompleted).length,
        'pending': allTasks.where((task) => !task.isCompleted).length,
        'overdue': allTasks.where((task) => task.isOverdue).length,
        'today': allTasks.where((task) => task.isDueToday).length,
        'upcoming': allTasks.where((task) => task.isUpcoming).length,
        'important': allTasks.where((task) => task.priority == TaskPriority.important).length,
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return _localDataSource.watchAllTasks()
        .map((taskModels) => taskModels.map((model) => model.toEntity()).toList());
  }

  @override
  Stream<List<Task>> watchTasks({
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
  }) {
    return _localDataSource.watchTasks(
      priority: priority,
      type: type,
      isCompleted: isCompleted,
    ).map((taskModels) => taskModels.map((model) => model.toEntity()).toList());
  }

  @override
  Future<void> syncTasks() async {
    try {
      // TODO: Implement full sync logic
      // 1. Get all local tasks
      // 2. Get all remote tasks
      // 3. Resolve conflicts (last modified wins, etc.)
      // 4. Update both local and remote as needed
      
      // For now, just a placeholder
      print('Syncing tasks... (not implemented yet)');
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  @override
  Future<void> clearAllTasks() async {
    try {
      await _localDataSource.clearAllTasks();
      // TODO: Also clear remote if needed
    } catch (e) {
      rethrow;
    }
  }
}
