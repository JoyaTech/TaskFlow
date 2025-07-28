class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskType type;
  final bool isCompleted;
  final DateTime createdAt;
  final String? voiceNote;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.simple,
    this.type = TaskType.task,
    this.isCompleted = false,
    required this.createdAt,
    this.voiceNote,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
        'type': type.index,
        'isCompleted': isCompleted ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'voiceNote': voiceNote,
      };

  static Task fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
        priority: TaskPriority.values[map['priority']],
        type: TaskType.values[map['type']],
        isCompleted: map['isCompleted'] == 1,
        createdAt: DateTime.parse(map['createdAt']),
        voiceNote: map['voiceNote'],
      );

  // Firestore serialization methods
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'priority': priority.index,
        'type': type.index,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
        'voiceNote': voiceNote,
      };

  static Task fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: data['dueDate']?.toDate(),
      priority: TaskPriority.values[data['priority'] ?? 0],
      type: TaskType.values[data['type'] ?? 0],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      voiceNote: data['voiceNote'],
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskType? type,
    bool? isCompleted,
    DateTime? createdAt,
    String? voiceNote,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        type: type ?? this.type,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        voiceNote: voiceNote ?? this.voiceNote,
      );
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