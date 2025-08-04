class BrainDump {
  final String id;
  final String content;
  final DateTime createdAt;
  final BrainDumpType type;
  final String? tags;
  final bool isProcessed;
  final String? processedTaskId; // Link to task if converted

  BrainDump({
    required this.id,
    required this.content,
    required this.createdAt,
    this.type = BrainDumpType.thought,
    this.tags,
    this.isProcessed = false,
    this.processedTaskId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'type': type.index,
        'tags': tags,
        'isProcessed': isProcessed ? 1 : 0,
        'processedTaskId': processedTaskId,
      };

  static BrainDump fromMap(Map<String, dynamic> map) => BrainDump(
        id: map['id'],
        content: map['content'],
        createdAt: DateTime.parse(map['createdAt']),
        type: BrainDumpType.values[map['type']],
        tags: map['tags'],
        isProcessed: map['isProcessed'] == 1,
        processedTaskId: map['processedTaskId'],
      );

  // Firestore serialization methods
  Map<String, dynamic> toFirestore() => {
        'content': content,
        'createdAt': createdAt,
        'type': type.index,
        'tags': tags,
        'isProcessed': isProcessed,
        'processedTaskId': processedTaskId,
      };

  static BrainDump fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrainDump(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      type: BrainDumpType.values[data['type'] ?? 0],
      tags: data['tags'],
      isProcessed: data['isProcessed'] ?? false,
      processedTaskId: data['processedTaskId'],
    );
  }

  BrainDump copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    BrainDumpType? type,
    String? tags,
    bool? isProcessed,
    String? processedTaskId,
  }) =>
      BrainDump(
        id: id ?? this.id,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        type: type ?? this.type,
        tags: tags ?? this.tags,
        isProcessed: isProcessed ?? this.isProcessed,
        processedTaskId: processedTaskId ?? this.processedTaskId,
      );
}

enum BrainDumpType {
  thought,      // מחשבה
  idea,         // רעיון
  reminder,     // תזכורת מהירה
  worry,        // דאגה
  inspiration,  // השראה
  random;       // אקראי

  String get hebrewName {
    switch (this) {
      case BrainDumpType.thought:
        return 'מחשבה';
      case BrainDumpType.idea:
        return 'רעיון';
      case BrainDumpType.reminder:
        return 'תזכורת';
      case BrainDumpType.worry:
        return 'דאגה';
      case BrainDumpType.inspiration:
        return 'השראה';
      case BrainDumpType.random:
        return 'אקראי';
    }
  }

  String get emoji {
    switch (this) {
      case BrainDumpType.thought:
        return '💭';
      case BrainDumpType.idea:
        return '💡';
      case BrainDumpType.reminder:
        return '⚡';
      case BrainDumpType.worry:
        return '😰';
      case BrainDumpType.inspiration:
        return '✨';
      case BrainDumpType.random:
        return '🎲';
    }
  }

  String get description {
    switch (this) {
      case BrainDumpType.thought:
        return 'מחשבה שעברה לי בראש';
      case BrainDumpType.idea:
        return 'רעיון שאני לא רוצה לשכוח';
      case BrainDumpType.reminder:
        return 'משהו שאני חייב לזכור';
      case BrainDumpType.worry:
        return 'דאגה שמפריעה לי להתרכז';
      case BrainDumpType.inspiration:
        return 'השראה פתאומית';
      case BrainDumpType.random:
        return 'משהו אקראי';
    }
  }
}
