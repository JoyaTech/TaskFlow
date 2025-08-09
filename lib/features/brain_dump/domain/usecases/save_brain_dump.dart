import 'package:uuid/uuid.dart';
import '../entities/brain_dump_entry.dart';
import '../repositories/brain_dump_repository.dart';

/// Use case for saving a brain dump entry
/// Handles the core business logic for capturing user thoughts
class SaveBrainDump {
  final BrainDumpRepository repository;
  final Uuid _uuid = const Uuid();

  SaveBrainDump(this.repository);

  /// Execute the use case to save a brain dump
  Future<BrainDumpEntry> call({
    required String content,
    String? mood,
    List<String> tags = const [],
  }) async {
    // Validate input
    if (content.trim().isEmpty) {
      throw ArgumentError('Brain dump content cannot be empty');
    }

    // Create the brain dump entry
    final entry = BrainDumpEntry(
      id: _uuid.v4(),
      content: content.trim(),
      createdAt: DateTime.now(),
      tags: tags,
      mood: mood,
    );

    // Save to repository
    await repository.saveBrainDump(entry);

    return entry;
  }
}
