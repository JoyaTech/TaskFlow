import '../../../tasks/domain/entities/task.dart';
import '../../data/datasources/google_calendar_datasource.dart';

/// Use case for syncing a task to Google Calendar
/// Handles the business logic for calendar integration
class SyncTaskToCalendar {
  final GoogleCalendarDataSource _calendarDataSource;

  SyncTaskToCalendar(this._calendarDataSource);

  /// Sync a single task to Google Calendar
  /// Returns the calendar event ID if successful
  Future<String?> call(Task task, {String? targetCalendarId}) async {
    try {
      // Validate that the task has required information
      if (task.title.trim().isEmpty) {
        throw ArgumentError('Task title cannot be empty for calendar sync');
      }

      // Check if we have calendar permissions
      final hasPermissions = await _calendarDataSource.hasCalendarPermissions();
      if (!hasPermissions) {
        throw Exception('Calendar permissions not granted. Please authenticate first.');
      }

      // Sync the task to calendar
      final eventId = await _calendarDataSource.syncTaskToCalendar(
        task,
        calendarId: targetCalendarId,
      );

      if (eventId == null) {
        throw Exception('Failed to create calendar event');
      }

      return eventId;
    } catch (e) {
      // Log the error for debugging
      print('Error syncing task to calendar: $e');
      rethrow;
    }
  }

  /// Sync multiple tasks to Google Calendar
  Future<Map<String, String?>> syncMultipleTasks(
    List<Task> tasks, {
    String? targetCalendarId,
  }) async {
    final results = <String, String?>{};
    
    for (final task in tasks) {
      try {
        final eventId = await call(task, targetCalendarId: targetCalendarId);
        results[task.id] = eventId;
      } catch (e) {
        print('Failed to sync task ${task.id}: $e');
        results[task.id] = null;
      }
    }
    
    return results;
  }

  /// Update a calendar event when task changes
  Future<void> updateCalendarEvent(
    Task task,
    String eventId, {
    String? calendarId,
  }) async {
    try {
      await _calendarDataSource.updateCalendarEvent(
        task,
        eventId,
        calendarId: calendarId,
      );
    } catch (e) {
      print('Error updating calendar event: $e');
      rethrow;
    }
  }

  /// Remove a task from the calendar
  Future<void> removeFromCalendar(
    String eventId, {
    String? calendarId,
  }) async {
    try {
      await _calendarDataSource.deleteCalendarEvent(
        eventId,
        calendarId: calendarId,
      );
    } catch (e) {
      print('Error removing event from calendar: $e');
      rethrow;
    }
  }
}
