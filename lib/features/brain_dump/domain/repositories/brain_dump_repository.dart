import '../entities/brain_dump_entry.dart';

/// Abstract repository for brain dump operations
/// Defines the contract for data persistence without implementation details
abstract class BrainDumpRepository {
  /// Save a new brain dump entry
  Future<void> saveBrainDump(BrainDumpEntry entry);

  /// Get all brain dump entries, most recent first
  Future<List<BrainDumpEntry>> getAllBrainDumps();

  /// Get brain dump entries by date range
  Future<List<BrainDumpEntry>> getBrainDumpsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Update an existing brain dump entry
  Future<void> updateBrainDump(BrainDumpEntry entry);

  /// Delete a brain dump entry
  Future<void> deleteBrainDump(String id);

  /// Get unprocessed brain dumps (not converted to tasks yet)
  Future<List<BrainDumpEntry>> getUnprocessedBrainDumps();

  /// Mark brain dump as processed
  Future<void> markAsProcessed(String id);

  /// Search brain dumps by content
  Future<List<BrainDumpEntry>> searchBrainDumps(String query);
}
