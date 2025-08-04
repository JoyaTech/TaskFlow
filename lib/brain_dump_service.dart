import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mindflow/brain_dump_model.dart';

class BrainDumpService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'brain_dumps';

  static CollectionReference get _brainDumpsCollection =>
      _firestore.collection(_collectionName);

  /// Get all brain dumps, sorted by creation date (newest first)
  static Future<List<BrainDump>> getAllBrainDumps() async {
    try {
      final querySnapshot = await _brainDumpsCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get brain dumps: $e');
    }
  }

  /// Get recent brain dumps (last 24 hours)
  static Future<List<BrainDump>> getRecentBrainDumps() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final querySnapshot = await _brainDumpsCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent brain dumps: $e');
    }
  }

  /// Get brain dumps by type
  static Future<List<BrainDump>> getBrainDumpsByType(BrainDumpType type) async {
    try {
      final querySnapshot = await _brainDumpsCollection
          .where('type', isEqualTo: type.index)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get brain dumps by type: $e');
    }
  }

  /// Get unprocessed brain dumps (not yet converted to tasks)
  static Future<List<BrainDump>> getUnprocessedBrainDumps() async {
    try {
      final querySnapshot = await _brainDumpsCollection
          .where('isProcessed', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get unprocessed brain dumps: $e');
    }
  }

  /// Insert a new brain dump
  static Future<void> insertBrainDump(BrainDump brainDump) async {
    try {
      await _brainDumpsCollection.doc(brainDump.id).set(brainDump.toFirestore());
    } catch (e) {
      throw Exception('Failed to insert brain dump: $e');
    }
  }

  /// Update an existing brain dump
  static Future<void> updateBrainDump(BrainDump brainDump) async {
    try {
      await _brainDumpsCollection.doc(brainDump.id).update(brainDump.toFirestore());
    } catch (e) {
      throw Exception('Failed to update brain dump: $e');
    }
  }

  /// Delete a brain dump
  static Future<void> deleteBrainDump(String id) async {
    try {
      await _brainDumpsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete brain dump: $e');
    }
  }

  /// Mark brain dump as processed (converted to task)
  static Future<void> markAsProcessed(String id, String taskId) async {
    try {
      await _brainDumpsCollection.doc(id).update({
        'isProcessed': true,
        'processedTaskId': taskId,
      });
    } catch (e) {
      throw Exception('Failed to mark brain dump as processed: $e');
    }
  }

  /// Search brain dumps by content
  static Future<List<BrainDump>> searchBrainDumps(String query) async {
    try {
      final querySnapshot = await _brainDumpsCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .where((brainDump) =>
              brainDump.content.toLowerCase().contains(query.toLowerCase()) ||
              (brainDump.tags?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search brain dumps: $e');
    }
  }

  /// Get count of unprocessed brain dumps
  static Future<int> getUnprocessedCount() async {
    try {
      final querySnapshot = await _brainDumpsCollection
          .where('isProcessed', isEqualTo: false)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unprocessed count: $e');
    }
  }

  /// Get brain dumps from today
  static Future<List<BrainDump>> getTodayBrainDumps() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final querySnapshot = await _brainDumpsCollection
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('createdAt', isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => BrainDump.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get today brain dumps: $e');
    }
  }

  /// Initialize with sample brain dump data
  static Future<void> initSampleBrainDumps() async {
    try {
      final now = DateTime.now();
      final sampleBrainDumps = [
        BrainDump(
          id: 'bd_1',
          content: 'לזכור להחליף סיסמה לבנק',
          createdAt: now.subtract(const Duration(minutes: 5)),
          type: BrainDumpType.reminder,
        ),
        BrainDump(
          id: 'bd_2',
          content: 'רעיון לאפליקציה שתזכיר לי לשתות מים',
          createdAt: now.subtract(const Duration(hours: 2)),
          type: BrainDumpType.idea,
        ),
        BrainDump(
          id: 'bd_3',
          content: 'דאגה: האם זכרתי לנעול את הבית?',
          createdAt: now.subtract(const Duration(hours: 3)),
          type: BrainDumpType.worry,
        ),
        BrainDump(
          id: 'bd_4',
          content: 'מחשבה: האם כדאי ללמוד פייתון או ג\'אווה?',
          createdAt: now.subtract(const Duration(hours: 5)),
          type: BrainDumpType.thought,
        ),
        BrainDump(
          id: 'bd_5',
          content: 'השראה לשיר על הגשם של היום',
          createdAt: now.subtract(const Duration(days: 1)),
          type: BrainDumpType.inspiration,
        ),
      ];

      for (final brainDump in sampleBrainDumps) {
        await insertBrainDump(brainDump);
      }
    } catch (e) {
      throw Exception('Failed to initialize sample brain dumps: $e');
    }
  }

  // Stream methods for real-time updates
  static Stream<List<BrainDump>> watchAllBrainDumps() {
    return _brainDumpsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BrainDump.fromFirestore(doc))
            .toList());
  }

  static Stream<List<BrainDump>> watchUnprocessedBrainDumps() {
    return _brainDumpsCollection
        .where('isProcessed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BrainDump.fromFirestore(doc))
            .toList());
  }

  static Stream<int> watchUnprocessedCount() {
    return _brainDumpsCollection
        .where('isProcessed', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
