import '../../domain/entities/task.dart';

/// Data layer model for Task entity with serialization capabilities
/// Extends Task to add conversion methods for persistence
class TaskModel extends Task {
  const TaskModel({
    required String id,
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.simple,
    TaskType type = TaskType.task,
    bool isCompleted = false,
    required DateTime createdAt,
    DateTime? completedAt,
    String? voiceNote,
    List<String> tags = const [],
  }) : super(
          id: id,
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          type: type,
          isCompleted: isCompleted,
          createdAt: createdAt,
          completedAt: completedAt,
          voiceNote: voiceNote,
          tags: tags,
        );

  /// Create a TaskModel from a domain Task entity
  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      type: task.type,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      voiceNote: task.voiceNote,
      tags: task.tags,
    );
  }

  /// Convert TaskModel to a domain Task entity
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      type: type,
      isCompleted: isCompleted,
      createdAt: createdAt,
      completedAt: completedAt,
      voiceNote: voiceNote,
      tags: tags,
    );
  }

  /// Create a TaskModel from a map (e.g., from SQLite)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      priority: TaskPriority.values[map['priority'] as int],
      type: TaskType.values[map['type'] as int],
      isCompleted: (map['isCompleted'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      voiceNote: map['voiceNote'] as String?,
      tags: (map['tags'] as String).split(',').where((t) => t.isNotEmpty).toList(),
    );
  }

  /// Convert TaskModel to a map (e.g., for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.index,
      'type': type.index,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'voiceNote': voiceNote,
      'tags': tags.join(','),
    };
  }

  /// Create a TaskModel from a Firestore document
  factory TaskModel.fromFirestore(Map<String, dynamic> firestore, String id) {
    return TaskModel(
      id: id,
      title: firestore['title'] ?? '',
      description: firestore['description'] ?? '',
      dueDate: firestore['dueDate']?.toDate(),
      priority: TaskPriority.values[firestore['priority'] ?? 0],
      type: TaskType.values[firestore['type'] ?? 0],
      isCompleted: firestore['isCompleted'] ?? false,
      createdAt: firestore['createdAt']?.toDate() ?? DateTime.now(),
      completedAt: firestore['completedAt']?.toDate(),
      voiceNote: firestore['voiceNote'],
      tags: List<String>.from(firestore['tags'] ?? []),
    );
  }

  /// Convert TaskModel to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority.index,
      'type': type.index,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'voiceNote': voiceNote,
      'tags': tags,
    };
  }

  /// Create a copy of this TaskModel with the given fields replaced
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    String? voiceNote,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      voiceNote: voiceNote ?? this.voiceNote,
      tags: tags ?? this.tags,
    );
  }
}

