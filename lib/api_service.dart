import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:mindflow/task_model.dart';

class ApiService {
  static const String googleCalendarBaseUrl = 'https://www.googleapis.com/calendar/v3';
  static const String gmailBaseUrl = 'https://gmail.googleapis.com/gmail/v1';

  // Google Calendar Integration
  static Future<bool> syncTaskToCalendar(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarApiKey = prefs.getString('calendar_api_key');
      
      if (calendarApiKey == null || calendarApiKey.isEmpty) {
        if (kDebugMode) print('Calendar API key not configured');
        return false;
      }

      if (task.dueDate == null || task.type != TaskType.event) {
        return false; // Only sync events with due dates
      }

      final eventData = {
        'summary': task.title,
        'description': task.description,
        'start': {
          'dateTime': task.dueDate!.toIso8601String(),
          'timeZone': 'Asia/Jerusalem',
        },
        'end': {
          'dateTime': task.dueDate!.add(const Duration(hours: 1)).toIso8601String(),
          'timeZone': 'Asia/Jerusalem',
        },
        'reminders': {
          'useDefault': false,
          'overrides': [
            {'method': 'popup', 'minutes': 15},
            {'method': 'email', 'minutes': 60},
          ],
        },
      };

      final response = await http.post(
        Uri.parse('$googleCalendarBaseUrl/calendars/primary/events?key=$calendarApiKey'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $calendarApiKey',
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('Event synced to Google Calendar successfully');
        return true;
      } else {
        if (kDebugMode) print('Failed to sync to Calendar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Calendar sync error: $e');
      return false;
    }
  }

  // Gmail Integration for Task Summaries
  static Future<bool> sendTaskSummaryEmail(List<Task> tasks, String recipientEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gmailApiKey = prefs.getString('gmail_api_key');
      
      if (gmailApiKey == null || gmailApiKey.isEmpty) {
        if (kDebugMode) print('Gmail API key not configured');
        return false;
      }

      final emailContent = _buildEmailSummary(tasks);
      final emailData = {
        'raw': base64Encode(utf8.encode(emailContent)),
      };

      final response = await http.post(
        Uri.parse('$gmailBaseUrl/users/me/messages/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $gmailApiKey',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print('Task summary email sent successfully');
        return true;
      } else {
        if (kDebugMode) print('Failed to send email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('Email sending error: $e');
      return false;
    }
  }

  static String _buildEmailSummary(List<Task> tasks) {
    final now = DateTime.now();
    final todayTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final today = DateTime(now.year, now.month, now.day);
      return taskDate == today;
    }).toList();

    final upcomingTasks = tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(DateTime(now.year, now.month, now.day + 1)) && !task.isCompleted;
    }).take(5).toList();

    final completedToday = tasks.where((task) {
      if (!task.isCompleted) return false;
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      final today = DateTime(now.year, now.month, now.day);
      return taskDate == today;
    }).length;

    final emailBody = '''
Subject: סיכום משימות יומי - MindFlow
To: user@example.com
Content-Type: text/html; charset=UTF-8

<html dir="rtl" lang="he">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; }
    .header { background: linear-gradient(135deg, #6B73FF 0%, #9C27B0 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
    .section { background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 15px; }
    .task { background: white; padding: 10px; margin: 8px 0; border-right: 4px solid #6B73FF; border-radius: 5px; }
    .completed { border-right-color: #4CAF50; }
    .priority-high { border-right-color: #F44336; }
    .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🎯 סיכום משימות יומי</h1>
    <p>התקדמות היום: הושלמו $completedToday משימות</p>
  </div>

  <div class="section">
    <h2>📋 משימות להיום</h2>
    ${todayTasks.isEmpty ? '<p>אין משימות להיום - יום נהדר לנוח! 😊</p>' : ''}
    ${todayTasks.map((task) => '''
      <div class="task ${task.isCompleted ? 'completed' : ''} ${task.priority == TaskPriority.important ? 'priority-high' : ''}">
        <strong>${task.type.emoji} ${task.title}</strong>
        ${task.description.isNotEmpty ? '<br><small>${task.description}</small>' : ''}
        ${task.isCompleted ? '<span style="color: #4CAF50;"> ✅ הושלם</span>' : ''}
      </div>
    ''').join('')}
  </div>

  <div class="section">
    <h2>🚀 משימות קרובות</h2>
    ${upcomingTasks.isEmpty ? '<p>אין משימות קרובות רשומות</p>' : ''}
    ${upcomingTasks.map((task) => '''
      <div class="task">
        <strong>${task.type.emoji} ${task.title}</strong>
        ${task.description.isNotEmpty ? '<br><small>${task.description}</small>' : ''}
        <br><small>📅 ${_formatDateHebrew(task.dueDate!)}</small>
      </div>
    ''').join('')}
  </div>

  <div class="footer">
    <p>נשלח מ-MindFlow - עוזר המשימות הישראלי 🇮🇱</p>
    <p>כדי להפסיק לקבל אימיילים אלה, עדכן את ההגדרות באפליקציה</p>
  </div>
</body>
</html>
    ''';

    return emailBody;
  }

  static String _formatDateHebrew(DateTime date) {
    final weekdays = [
      'ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'
    ];
    final months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return 'יום $weekday, ${date.day} ב$month בשעה $hour:$minute';
  }

  // Speech-to-Text with Google
  static Future<String?> transcribeAudioWithGoogle(List<int> audioBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final googleApiKey = prefs.getString('google_api_key');
      
      if (googleApiKey == null || googleApiKey.isEmpty) {
        if (kDebugMode) print('Google API key not configured');
        return null;
      }

      final audioBase64 = base64Encode(audioBytes);
      final requestBody = {
        'config': {
          'encoding': 'WEBM_OPUS',
          'sampleRateHertz': 48000,
          'languageCode': 'he-IL',
          'enableAutomaticPunctuation': true,
        },
        'audio': {
          'content': audioBase64,
        },
      };

      final response = await http.post(
        Uri.parse('https://speech.googleapis.com/v1/speech:recognize?key=$googleApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List?;
        
        if (results != null && results.isNotEmpty) {
          final alternatives = results[0]['alternatives'] as List;
          if (alternatives.isNotEmpty) {
            return alternatives[0]['transcript'] as String;
          }
        }
      } else {
        if (kDebugMode) print('Speech recognition failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Speech recognition error: $e');
    }
    
    return null;
  }

  // Test API connections
  static Future<bool> testOpenAIConnection(String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': 'שלום'},
          ],
          'max_tokens': 5,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('OpenAI test error: $e');
      return false;
    }
  }

  static Future<bool> testGoogleConnection(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/calendar/v3/calendars/primary?key=$apiKey'),
      );

      return response.statusCode == 200 || response.statusCode == 401; // 401 means key is valid but needs auth
    } catch (e) {
      if (kDebugMode) print('Google API test error: $e');
      return false;
    }
  }

  // Helper function to schedule daily summary emails
  static Future<void> scheduleDailySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSent = prefs.getString('last_summary_sent');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastSent != today) {
      // Get all tasks and send summary
      // This would typically be triggered by a background service
      // For now, it's just a placeholder for the functionality
      await prefs.setString('last_summary_sent', today);
    }
  }
}