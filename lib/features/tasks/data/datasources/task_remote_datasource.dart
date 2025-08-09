import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../../domain/entities/task.dart';

/// Abstract interface for remote task data operations
abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getAllTasks(String userId);
  Future<TaskModel?> getTaskById(String userId, String taskId);
  Future<TaskModel> addTask(String userId, TaskModel task);
  Future<TaskModel> updateTask(String userId, TaskModel task);
  Future<void> deleteTask(String userId, String taskId);
  Stream<List<TaskModel>> watchAllTasks(String userId);
}

/// Firestore implementation of TaskRemoteDataSource
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  
  TaskRemoteDataSourceImpl({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the user's tasks collection reference
  CollectionReference _getUserTasksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  @override
  Future<List<TaskModel>> getAllTasks(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _getUserTasksCollection(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks from Firestore: $e');
    }
  }

  @override
  Future<TaskModel?> getTaskById(String userId, String taskId) async {
    try {
      final DocumentSnapshot doc = await _getUserTasksCollection(userId)
          .doc(taskId)
          .get();

      if (doc.exists) {
        return TaskModel.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch task from Firestore: $e');
    }
  }

  @override
  Future<TaskModel> addTask(String userId, TaskModel task) async {
    try {
      final DocumentReference docRef = await _getUserTasksCollection(userId)
          .add(task.toFirestore());

      // Return the task with the generated Firestore ID
      return task.copyWith(id: docRef.id) as TaskModel;
    } catch (e) {
      throw Exception('Failed to add task to Firestore: $e');
    }
  }

  @override
  Future<TaskModel> updateTask(String userId, TaskModel task) async {
    try {
      await _getUserTasksCollection(userId)
          .doc(task.id)
          .update(task.toFirestore());

      return task;
    } catch (e) {
      throw Exception('Failed to update task in Firestore: $e');
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _getUserTasksCollection(userId)
          .doc(taskId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete task from Firestore: $e');
    }
  }

  @override
  Stream<List<TaskModel>> watchAllTasks(String userId) {
    try {
      return _getUserTasksCollection(userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((querySnapshot) => querySnapshot.docs
              .map((doc) => TaskModel.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to watch tasks from Firestore: $e');
    }
  }
}
