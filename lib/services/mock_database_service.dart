import 'package:mindflow/task_model.dart';

/// Mock database service for web compatibility
class MockDatabaseService {
  static final List<Task> _tasks = [];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      await initSampleData();
      _initialized = true;
    }
  }

  static Future<List<Task>> getAllTasks() async {
    await initialize();
    return List.from(_tasks);
  }

  static Future<List<Task>> getTodayTasks() async {
    await initialize();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  static Future<int> getTodayCompletedTasksCount() async {
    final todayTasks = await getTodayTasks();
    return todayTasks.where((task) => task.isCompleted).length;
  }

  static Future<void> insertTask(Task task) async {
    await initialize();
    _tasks.add(task);
  }

  static Future<void> updateTask(Task task) async {
    await initialize();
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  static Future<void> deleteTask(String id) async {
    await initialize();
    _tasks.removeWhere((task) => task.id == id);
  }

  static Future<void> markTaskCompleted(String id) async {
    await initialize();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = Task(
        id: _tasks[index].id,
        title: _tasks[index].title,
        description: _tasks[index].description,
        type: _tasks[index].type,
        priority: _tasks[index].priority,
        dueDate: _tasks[index].dueDate,
        createdAt: _tasks[index].createdAt,
        isCompleted: true,
        voiceNote: _tasks[index].voiceNote,
      );
    }
  }

  static Future<Task?> getTaskById(String id) async {
    await initialize();
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> initSampleData() async {
    if (_tasks.isNotEmpty) return;
    
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
        description: 'יום הולדת השבוع',
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

    _tasks.addAll(sampleTasks);
  }

  // Stream methods for real-time updates (mock implementation)  
  static Stream<List<Task>> watchAllTasks() async* {
    await initialize();
    while (true) {
      yield List.from(_tasks);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  static Stream<List<Task>> watchTodayTasks() async* {
    await initialize();
    while (true) {
      yield await getTodayTasks();
      await Future.delayed(const Duration(seconds: 2));
    }
  }


  static Future<List<Task>> searchAndFilterTasks({
    String query = '',
    TaskType? type,
    TaskPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    await initialize();

    List<Task> results = List.from(_tasks);

    if (query.isNotEmpty) {
      results = results.where((task) =>
          task.title.toLowerCase().contains(query.toLowerCase()) ||
          task.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (type != null) {
      results = results.where((task) => task.type == type).toList();
    }

    if (priority != null) {
      results = results.where((task) => task.priority == priority).toList();
    }

    if (startDate != null) {
      results = results.where((task) => task.dueDate != null && task.dueDate!.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      results = results.where((task) => task.dueDate != null && task.dueDate!.isBefore(endDate)).toList();
    }

    if (isCompleted != null) {
      results = results.where((task) => task.isCompleted == isCompleted).toList();
    }

    results.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case 'dueDate':
          comparison = a.dueDate?.compareTo(b.dueDate ?? DateTime.now()) ?? 0;
          break;
        case 'priority':
          comparison = a.priority.index.compareTo(b.priority.index);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return descending ? -comparison : comparison;
    });

    return results;
  }
