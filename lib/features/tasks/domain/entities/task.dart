import 'package:equatable/equatable.dart';

/// Core Task entity - represents the business concept of a task
/// This is pure business logic with no dependencies on external frameworks
class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskType type;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? voiceNote;
  final List<String> tags;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.simple,
    this.type = TaskType.task,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.voiceNote,
    this.tags = const [],
  });

  /// Creates a copy of this task with the given fields replaced with new values
  Task copyWith({
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
    return Task(
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

  /// Mark task as completed
  Task complete() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  /// Mark task as incomplete
  Task incomplete() {
    return copyWith(
      isCompleted: false,
      completedAt: null,
    );
  }

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today == taskDay;
  }

  /// Check if task is upcoming (due within next 7 days)
  bool get isUpcoming {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return dueDate!.isAfter(now) && dueDate!.isBefore(sevenDaysFromNow);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        priority,
        type,
        isCompleted,
        createdAt,
        completedAt,
        voiceNote,
        tags,
      ];

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate)';
  }
}

enum TaskPriority {
  important,
  simple,
  later;

  String get hebrewName {
    switch (this) {
      case TaskPriority.important:
        return 'חשוב';
      case TaskPriority.simple:
        return 'פשוט';
      case TaskPriority.later:
        return 'אחר כך';
    }
  }

  String get emoji {
    switch (this) {
      case TaskPriority.important:
        return '🔥';
      case TaskPriority.simple:
        return '✅';
      case TaskPriority.later:
        return '⏰';
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskPriority.important:
        return 0;
      case TaskPriority.simple:
        return 1;
      case TaskPriority.later:
        return 2;
    }
  }
}

enum TaskType {
  task,
  reminder,
  note,
  event;

  String get hebrewName {
    switch (this) {
      case TaskType.task:
        return 'משימה';
      case TaskType.reminder:
        return 'תזכורת';
      case TaskType.note:
        return 'פתק';
      case TaskType.event:
        return 'אירוע';
    }
  }

  String get emoji {
    switch (this) {
      case TaskType.task:
        return '📋';
      case TaskType.reminder:
        return '⏰';
      case TaskType.note:
        return '📝';
      case TaskType.event:
        return '📅';
    }
  }
}
