import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindflow/task_model.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'tasks';

  static CollectionReference get _tasksCollection =>
      _firestore.collection(_collectionName);

  static Future<List<Task>> getAllTasks() async {
    try {
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all tasks: $e');
    }
  }

  static Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('priority', isEqualTo: priority.index)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by priority: $e');
    }
  }

  static Future<List<Task>> getTasksByType(TaskType type) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('type', isEqualTo: type.index)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by type: $e');
    }
  }

  static Future<List<Task>> getTodayTasks() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final querySnapshot = await _tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('dueDate', isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy('dueDate')
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get today tasks: $e');
    }
  }

  static Future<List<Task>> getUpcomingTasks() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _tasksCollection
          .where('dueDate', isGreaterThan: Timestamp.fromDate(now))
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .limit(10)
          .get();
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming tasks: $e');
    }
  }

  static Future<void> insertTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toFirestore());
    } catch (e) {
      throw Exception('Failed to insert task: $e');
    }
  }

  static Future<void> updateTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toFirestore());
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  static Future<void> deleteTask(String id) async {
    try {
      await _tasksCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  static Future<void> markTaskCompleted(String id) async {
    try {
      await _tasksCollection.doc(id).update({'isCompleted': true});
    } catch (e) {
      throw Exception('Failed to mark task completed: $e');
    }
  }

  static Future<Task?> getTaskById(String id) async {
    try {
      final doc = await _tasksCollection.doc(id).get();
      if (doc.exists) {
        return Task.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get task by id: $e');
    }
  }

  static Future<int> getCompletedTasksCount() async {
    try {
      final querySnapshot = await _tasksCollection
          .where('isCompleted', isEqualTo: true)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get completed tasks count: $e');
    }
  }

  static Future<int> getTodayCompletedTasksCount() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final querySnapshot = await _tasksCollection
          .where('isCompleted', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('createdAt', isLessThan: Timestamp.fromDate(tomorrow))
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get today completed tasks count: $e');
    }
  }

  static Future<List<Task>> searchTasks(String query) async {
    try {
      // Firestore doesn't support full-text search like SQL LIKE
      // This is a simplified version - for full-text search consider using Algolia
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .where((task) =>
              task.title.toLowerCase().contains(query.toLowerCase()) ||
              task.description.toLowerCase().contains(query.toLowerCase()) ||
              (task.voiceNote?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }

  /// Advanced search and filtering
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
    try {
      Query queryRef = _tasksCollection;
      
      // Apply filters
      if (type != null) {
        queryRef = queryRef.where('type', isEqualTo: type.index);
      }
      
      if (priority != null) {
        queryRef = queryRef.where('priority', isEqualTo: priority.index);
      }
      
      if (isCompleted != null) {
        queryRef = queryRef.where('isCompleted', isEqualTo: isCompleted);
      }
      
      if (startDate != null) {
        queryRef = queryRef.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        queryRef = queryRef.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Apply sorting
      queryRef = queryRef.orderBy(sortBy, descending: descending);
      
      final querySnapshot = await queryRef.get();
      
      List<Task> tasks = querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
      
      // Apply text search filter on the client side
      if (query.isNotEmpty) {
        tasks = tasks.where((task) =>
            task.title.toLowerCase().contains(query.toLowerCase()) ||
            task.description.toLowerCase().contains(query.toLowerCase()) ||
            (task.voiceNote?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
      }
      
      return tasks;
    } catch (e) {
      throw Exception('Failed to search and filter tasks: $e');
    }
  }

  /// Get tasks by date range
  static Future<List<Task>> getTasksByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Task.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date range: $e');
    }
  }

  static Future<void> initSampleData() async {
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
          description: '',
          priority: TaskPriority.later,
          type: TaskType.note,
          createdAt: now.subtract(const Duration(hours: 1)),
          voiceNote: 'תזכורת קולית: להביא מטען חדש',
        ),
      ];

      for (final task in sampleTasks) {
        await insertTask(task);
      }
    } catch (e) {
      throw Exception('Failed to initialize sample data: $e');
    }
  }

  // Stream methods for real-time updates
  static Stream<List<Task>> watchAllTasks() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Task>> watchTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _tasksCollection
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('dueDate', isLessThan: Timestamp.fromDate(tomorrow))
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }
}