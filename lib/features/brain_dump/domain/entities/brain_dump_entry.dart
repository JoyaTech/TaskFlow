import 'package:equatable/equatable.dart';

/// Core BrainDumpEntry entity - represents a captured thought or idea
/// Designed for ADHD users who need to quickly capture fleeting thoughts
class BrainDumpEntry extends Equatable {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> tags;
  final bool isProcessed; // Whether this has been converted to tasks
  final String? mood; // Optional mood indicator for ADHD emotional context

  const BrainDumpEntry({
    required this.id,
    required this.content,
    required this.createdAt,
    this.tags = const [],
    this.isProcessed = false,
    this.mood,
  });

  /// Creates a copy with updated fields
  BrainDumpEntry copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    List<String>? tags,
    bool? isProcessed,
    String? mood,
  }) {
    return BrainDumpEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isProcessed: isProcessed ?? this.isProcessed,
      mood: mood ?? this.mood,
    );
  }

  /// Mark this entry as processed (converted to tasks)
  BrainDumpEntry markAsProcessed() {
    return copyWith(isProcessed: true);
  }

  /// Extract potential tasks from content (simple heuristic)
  List<String> get potentialTasks {
    // Simple extraction - lines that start with - or * or numbers
    final lines = content.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .where((line) => 
            line.startsWith('-') || 
            line.startsWith('*') || 
            line.startsWith('•') ||
            RegExp(r'^\d+\.').hasMatch(line))
        .map((line) => line.replaceFirst(RegExp(r'^[-*•]\s*'), '').replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .toList();
    
    return lines;
  }

  /// Get word count for progress tracking
  int get wordCount => content.trim().split(RegExp(r'\s+')).length;

  @override
  List<Object?> get props => [
        id,
        content,
        createdAt,
        tags,
        isProcessed,
        mood,
      ];

  @override
  String toString() {
    return 'BrainDumpEntry(id: $id, wordCount: $wordCount, isProcessed: $isProcessed)';
  }
}
