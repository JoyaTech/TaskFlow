import '../../domain/entities/brain_dump_entry.dart';

/// Data model for BrainDumpEntry with serialization capabilities
class BrainDumpModel extends BrainDumpEntry {
  const BrainDumpModel({
    required String id,
    required String content,
    required DateTime createdAt,
    List<String> tags = const [],
    bool isProcessed = false,
    String? mood,
  }) : super(
          id: id,
          content: content,
          createdAt: createdAt,
          tags: tags,
          isProcessed: isProcessed,
          mood: mood,
        );

  /// Create from domain entity
  factory BrainDumpModel.fromEntity(BrainDumpEntry entry) {
    return BrainDumpModel(
      id: entry.id,
      content: entry.content,
      createdAt: entry.createdAt,
      tags: entry.tags,
      isProcessed: entry.isProcessed,
      mood: entry.mood,
    );
  }

  /// Convert to domain entity
  BrainDumpEntry toEntity() {
    return BrainDumpEntry(
      id: id,
      content: content,
      createdAt: createdAt,
      tags: tags,
      isProcessed: isProcessed,
      mood: mood,
    );
  }

  /// Create from SQLite map
  factory BrainDumpModel.fromMap(Map<String, dynamic> map) {
    return BrainDumpModel(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      tags: (map['tags'] as String? ?? '').split(',').where((t) => t.isNotEmpty).toList(),
      isProcessed: (map['is_processed'] as int) == 1,
      mood: map['mood'] as String?,
    );
  }

  /// Convert to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'tags': tags.join(','),
      'is_processed': isProcessed ? 1 : 0,
      'mood': mood,
    };
  }

  /// Create from Firestore document
  factory BrainDumpModel.fromFirestore(Map<String, dynamic> firestore, String id) {
    return BrainDumpModel(
      id: id,
      content: firestore['content'] ?? '',
      createdAt: firestore['created_at']?.toDate() ?? DateTime.now(),
      tags: List<String>.from(firestore['tags'] ?? []),
      isProcessed: firestore['is_processed'] ?? false,
      mood: firestore['mood'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'created_at': createdAt,
      'tags': tags,
      'is_processed': isProcessed,
      'mood': mood,
    };
  }

  /// Create a copy with updated fields
  @override
  BrainDumpModel copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    List<String>? tags,
    bool? isProcessed,
    String? mood,
  }) {
    return BrainDumpModel(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isProcessed: isProcessed ?? this.isProcessed,
      mood: mood ?? this.mood,
    );
  }
}
