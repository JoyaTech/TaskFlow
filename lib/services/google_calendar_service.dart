import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mindflow/task_model.dart';
import 'package:mindflow/services/secure_storage_service.dart';

class GoogleCalendarService {
  static GoogleSignIn? _googleSignIn;
  static calendar.CalendarApi? _calendarApi;
  static bool _isAuthenticated = false;

  static const List<String> _scopes = [
    calendar.CalendarApi.calendarScope,
    calendar.CalendarApi.calendarEventsScope,
  ];

  static GoogleSignIn get _getGoogleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: _scopes,
      signInOption: SignInOption.standard,
    );
    return _googleSignIn!;
  }

  /// Initialize the Google Calendar service
  static Future<bool> initialize() async {
    try {
      // 🔐 SECURITY FIX: Use secure storage for auth data
      final savedAuth = await SecureStorageService.getGoogleCalendarAuth();
      
      if (savedAuth != null) {
        // Try to restore previous authentication
        await _restoreAuthentication();
      }
      
      return _isAuthenticated;
    } catch (e) {
      if (kDebugMode) print('Calendar service initialization error: $e');
      return false;
    }
  }

  /// Check if user is authenticated with Google Calendar
  static bool get isAuthenticated => _isAuthenticated;

  /// Sign in to Google and request Calendar permissions
  static Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _getGoogleSignIn.signIn();
      
      if (account == null) {
        if (kDebugMode) print('User cancelled Google sign-in');
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      
      if (auth.accessToken == null) {
        if (kDebugMode) print('Failed to get access token');
        return false;
      }

      // Create authenticated client
      final authClient = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken('Bearer', auth.accessToken!, DateTime.now().add(const Duration(hours: 1))),
          auth.idToken,
          _scopes,
        ),
      );

      _calendarApi = calendar.CalendarApi(authClient);
      _isAuthenticated = true;

      // Save authentication state
      await _saveAuthentication(auth);
      
      if (kDebugMode) print('Google Calendar authentication successful');
      return true;
    } catch (e) {
      if (kDebugMode) print('Google Calendar sign-in error: $e');
      _isAuthenticated = false;
      return false;
    }
  }

  /// Sign out from Google Calendar
  static Future<void> signOut() async {
    try {
      await _getGoogleSignIn.signOut();
      _calendarApi = null;
      _isAuthenticated = false;
      
      // 🔐 SECURITY FIX: Clear secure authentication data
      await SecureStorageService.clearGoogleCalendarAuth();
      
      if (kDebugMode) print('Google Calendar sign-out successful');
    } catch (e) {
      if (kDebugMode) print('Google Calendar sign-out error: $e');
    }
  }

  /// Create a calendar event from a task
  static Future<bool> createEventFromTask(Task task) async {
    if (!_isAuthenticated || _calendarApi == null) {
      if (kDebugMode) print('Not authenticated with Google Calendar');
      return false;
    }

    try {
      final event = calendar.Event()
        ..summary = task.title
        ..description = _buildEventDescription(task);

      // Set event time
      if (task.dueDate != null) {
        if (task.type == TaskType.event) {
          // For events, create a 1-hour slot
          event.start = calendar.EventDateTime(
            dateTime: task.dueDate!,
            timeZone: 'Asia/Jerusalem',
          );
          event.end = calendar.EventDateTime(
            dateTime: task.dueDate!.add(const Duration(hours: 1)),
            timeZone: 'Asia/Jerusalem',
          );
        } else {
          // For tasks and reminders, create all-day events or use specific time
          if (_isTimeSpecific(task.dueDate!)) {
            event.start = calendar.EventDateTime(
              dateTime: task.dueDate!,
              timeZone: 'Asia/Jerusalem',
            );
            event.end = calendar.EventDateTime(
              dateTime: task.dueDate!.add(const Duration(minutes: 30)),
              timeZone: 'Asia/Jerusalem',
            );
          } else {
            // All-day event
            event.start = calendar.EventDateTime(
              date: DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ),
            );
            event.end = calendar.EventDateTime(
              date: DateTime(
                task.dueDate!.year,
                task.dueDate!.month,
                task.dueDate!.day,
              ),
            );
          }
        }
      } else {
        // No date specified, create for today
        final today = DateTime.now();
        event.start = calendar.EventDateTime(
          date: DateTime(today.year, today.month, today.day),
        );
        event.end = calendar.EventDateTime(
          date: DateTime(today.year, today.month, today.day),
        );
      }

      // Set color based on priority
      event.colorId = _getColorForPriority(task.priority);

      // Add reminders for important tasks
      if (task.priority == TaskPriority.important) {
        event.reminders = calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()..method = 'popup'..minutes = 15,
            calendar.EventReminder()..method = 'popup'..minutes = 60,
          ];
      }

      // Create the event
      final createdEvent = await _calendarApi!.events.insert(event, 'primary');
      
      if (createdEvent.id != null) {
        if (kDebugMode) print('Calendar event created successfully: ${createdEvent.id}');
        
        // Save the calendar event ID to the task for future reference
        await _saveTaskCalendarMapping(task.id, createdEvent.id!);
        
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) print('Error creating calendar event: $e');
      return false;
    }
  }

  /// Update an existing calendar event
  static Future<bool> updateTaskEvent(Task task, String eventId) async {
    if (!_isAuthenticated || _calendarApi == null) {
      return false;
    }

    try {
      final event = await _calendarApi!.events.get('primary', eventId);
      
      // Update event details
      event.summary = task.title;
      event.description = _buildEventDescription(task);
      
      if (task.dueDate != null) {
        event.start = calendar.EventDateTime(
          dateTime: task.dueDate!,
          timeZone: 'Asia/Jerusalem',
        );
        event.end = calendar.EventDateTime(
          dateTime: task.dueDate!.add(const Duration(hours: 1)),
          timeZone: 'Asia/Jerusalem',
        );
      }

      await _calendarApi!.events.update(event, 'primary', eventId);
      
      if (kDebugMode) print('Calendar event updated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating calendar event: $e');
      return false;
    }
  }

  /// Delete a calendar event
  static Future<bool> deleteTaskEvent(String eventId) async {
    if (!_isAuthenticated || _calendarApi == null) {
      return false;
    }

    try {
      await _calendarApi!.events.delete('primary', eventId);
      if (kDebugMode) print('Calendar event deleted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting calendar event: $e');
      return false;
    }
  }

  /// Get upcoming events from calendar
  static Future<List<calendar.Event>> getUpcomingEvents({int days = 7}) async {
    if (!_isAuthenticated || _calendarApi == null) {
      return [];
    }

    try {
      final now = DateTime.now();
      final timeMax = now.add(Duration(days: days));
      
      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 50,
      );

      return events.items ?? [];
    } catch (e) {
      if (kDebugMode) print('Error fetching calendar events: $e');
      return [];
    }
  }

  // Helper methods

  static String _buildEventDescription(Task task) {
    final buffer = StringBuffer();
    
    buffer.writeln('📱 נוצר באמצעות FocusFlow');
    buffer.writeln();
    
    if (task.description.isNotEmpty) {
      buffer.writeln('📝 תיאור: ${task.description}');
      buffer.writeln();
    }
    
    buffer.writeln('🏷️ סוג: ${task.type.hebrewName}');
    buffer.writeln('⭐ עדיפות: ${task.priority.hebrewName}');
    
    if (task.voiceNote != null) {
      buffer.writeln();
      buffer.writeln('🎤 הקלטה מקורית: "${task.voiceNote}"');
    }
    
    buffer.writeln();
    buffer.writeln('נוצר ב-${_formatDateTime(task.createdAt)}');
    
    return buffer.toString();
  }

  static String _getColorForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.important:
        return '11'; // Red
      case TaskPriority.simple:
        return '2';  // Green
      case TaskPriority.later:
        return '5';  // Yellow
    }
  }

  static bool _isTimeSpecific(DateTime dateTime) {
    // Check if the time is not just default (like 00:00 or 09:00)
    return dateTime.hour != 0 || dateTime.minute != 0;
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> _saveAuthentication(GoogleSignInAuthentication auth) async {
    try {
      // 🔐 SECURITY FIX: Use secure storage for auth tokens
      final authData = {
        'accessToken': auth.accessToken,
        'idToken': auth.idToken,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await SecureStorageService.storeGoogleCalendarAuth(authData);
    } catch (e) {
      if (kDebugMode) print('Error saving authentication: $e');
    }
  }

  static Future<void> _restoreAuthentication() async {
    try {
      // 🔐 SECURITY FIX: Use secure storage for auth data
      final authData = await SecureStorageService.getGoogleCalendarAuth();
      
      if (authData == null) return;
      
      final timestamp = authData['timestamp'] as int;
      final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      // Check if token is still valid (less than 1 hour old)
      if (DateTime.now().difference(savedTime).inHours < 1) {
        // Try to restore the session
        final accessToken = authData['accessToken'] as String?;
        if (accessToken != null) {
          final authClient = authenticatedClient(
            Client(),
            AccessCredentials(
              AccessToken('Bearer', accessToken, DateTime.now().add(const Duration(hours: 1))),
              authData['idToken'] as String?,
              _scopes,
            ),
          );

          _calendarApi = calendar.CalendarApi(authClient);
          _isAuthenticated = true;
          
          if (kDebugMode) print('Google Calendar authentication restored');
        }
      } else {
        // Token expired, clear it
        await SecureStorageService.clearGoogleCalendarAuth();
      }
    } catch (e) {
      if (kDebugMode) print('Error restoring authentication: $e');
    }
  }

  static Future<void> _saveTaskCalendarMapping(String taskId, String eventId) async {
    try {
      final secureStorage = SecureStorageService();
      final existingMappings = await SecureStorageService.getTaskCalendarMappings() ?? '{}';
      final mappings = Map<String, String>.from(jsonDecode(existingMappings));
      
      mappings[taskId] = eventId;
      
      await SecureStorageService.setTaskCalendarMappings(jsonEncode(mappings));
    } catch (e) {
      if (kDebugMode) print('Error saving task-calendar mapping: $e');
    }
  }

  static Future<String?> getEventIdForTask(String taskId) async {
    try {
      final secureStorage = SecureStorageService();
      final mappingsString = await SecureStorageService.getTaskCalendarMappings() ?? '{}';
      final mappings = Map<String, String>.from(jsonDecode(mappingsString));
      
      return mappings[taskId];
    } catch (e) {
      if (kDebugMode) print('Error getting event ID for task: $e');
      return null;
    }
  }
}

// HTTP Client wrapper for authenticated requests
class Client extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
