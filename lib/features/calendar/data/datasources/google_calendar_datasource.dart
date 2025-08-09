import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../../../tasks/domain/entities/task.dart';

/// Google Calendar data source for syncing tasks
/// Handles one-way sync from TaskFlow to Google Calendar
class GoogleCalendarDataSource {
  calendar.CalendarApi? _calendarApi;
  AuthClient? _authClient;
  
  /// Initialize Google Calendar API with authentication
  Future<void> initialize({
    required String clientId,
    required String clientSecret,
    required List<String> scopes,
  }) async {
    try {
      // For production, you would implement proper OAuth flow
      // This is a simplified version for demo purposes
      final credentials = ServiceAccountCredentials.fromJson({
        // Add your service account JSON here
        // For now, we'll use a placeholder
      });
      
      _authClient = await clientViaServiceAccount(
        credentials,
        scopes,
      );
      
      _calendarApi = calendar.CalendarApi(_authClient!);
    } catch (e) {
      print('Failed to initialize Google Calendar: $e');
      rethrow;
    }
  }

  /// Sync a task to Google Calendar as an event
  Future<String?> syncTaskToCalendar(Task task, {String? calendarId}) async {
    if (_calendarApi == null) {
      throw Exception('Google Calendar not initialized. Call initialize() first.');
    }

    try {
      final event = calendar.Event()
        ..summary = task.title
        ..description = _buildEventDescription(task)
        ..start = _buildEventDateTime(task)
        ..end = _buildEventEndTime(task)
        ..colorId = _getEventColorId(task.priority)
        ..extendedProperties = calendar.EventExtendedProperties()
        ..extendedProperties!.private = {
          'taskflow_task_id': task.id,
          'task_priority': task.priority.name,
          'task_type': task.type.name,
        };

      // Use primary calendar if no specific calendar ID provided
      final targetCalendarId = calendarId ?? 'primary';
      
      final createdEvent = await _calendarApi!.events.insert(
        event,
        targetCalendarId,
      );

      return createdEvent.id;
    } catch (e) {
      print('Failed to sync task to calendar: $e');
      rethrow;
    }
  }

  /// Update an existing calendar event
  Future<void> updateCalendarEvent(
    Task task,
    String eventId, {
    String? calendarId,
  }) async {
    if (_calendarApi == null) {
      throw Exception('Google Calendar not initialized.');
    }

    try {
      final event = calendar.Event()
        ..summary = task.title
        ..description = _buildEventDescription(task)
        ..start = _buildEventDateTime(task)
        ..end = _buildEventEndTime(task)
        ..colorId = _getEventColorId(task.priority);

      final targetCalendarId = calendarId ?? 'primary';
      
      await _calendarApi!.events.update(
        event,
        targetCalendarId,
        eventId,
      );
    } catch (e) {
      print('Failed to update calendar event: $e');
      rethrow;
    }
  }

  /// Delete a calendar event
  Future<void> deleteCalendarEvent(String eventId, {String? calendarId}) async {
    if (_calendarApi == null) {
      throw Exception('Google Calendar not initialized.');
    }

    try {
      final targetCalendarId = calendarId ?? 'primary';
      await _calendarApi!.events.delete(targetCalendarId, eventId);
    } catch (e) {
      print('Failed to delete calendar event: $e');
      rethrow;
    }
  }

  /// Get user's calendar list
  Future<List<calendar.CalendarListEntry>> getCalendarList() async {
    if (_calendarApi == null) {
      throw Exception('Google Calendar not initialized.');
    }

    try {
      final calendarList = await _calendarApi!.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      print('Failed to get calendar list: $e');
      rethrow;
    }
  }

  /// Check if user has granted calendar permissions
  Future<bool> hasCalendarPermissions() async {
    try {
      if (_calendarApi == null) return false;
      
      // Try to access the calendar list as a permission check
      await _calendarApi!.calendarList.list();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Build event description from task details
  String _buildEventDescription(Task task) {
    final buffer = StringBuffer();
    
    if (task.description.isNotEmpty) {
      buffer.writeln(task.description);
      buffer.writeln();
    }
    
    buffer.writeln('📱 נוצר ב-TaskFlow');
    buffer.writeln('🎯 עדיפות: ${task.priority.hebrewName} ${task.priority.emoji}');
    buffer.writeln('📋 סוג: ${task.type.hebrewName} ${task.type.emoji}');
    
    if (task.tags.isNotEmpty) {
      buffer.writeln('🏷️ תגיות: ${task.tags.join(', ')}');
    }
    
    if (task.voiceNote != null && task.voiceNote!.isNotEmpty) {
      buffer.writeln('🎤 הערה קולית: ${task.voiceNote}');
    }
    
    return buffer.toString();
  }

  /// Build event start time
  calendar.EventDateTime _buildEventDateTime(Task task) {
    final dateTime = task.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    
    return calendar.EventDateTime()
      ..dateTime = dateTime
      ..timeZone = 'Asia/Jerusalem'; // Israel timezone
  }

  /// Build event end time (1 hour after start by default)
  calendar.EventDateTime _buildEventEndTime(Task task) {
    final startTime = task.dueDate ?? DateTime.now().add(const Duration(hours: 1));
    final endTime = startTime.add(const Duration(hours: 1));
    
    return calendar.EventDateTime()
      ..dateTime = endTime
      ..timeZone = 'Asia/Jerusalem';
  }

  /// Get Google Calendar color ID based on task priority
  String _getEventColorId(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return '11'; // Red
      case TaskPriority.simple:
        return '9';  // Blue
      case TaskPriority.later:
        return '8';  // Gray
    }
  }

  /// Dispose resources
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _calendarApi = null;
  }
}
