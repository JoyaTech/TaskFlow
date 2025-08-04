import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindflow/task_model.dart';

class VoiceService {
  static final SpeechToText _speechToText = SpeechToText();
  static bool _speechEnabled = false;
  static bool _isListening = false;

  static Future<bool> initialize() async {
    _speechEnabled = await _speechToText.initialize();
    return _speechEnabled;
  }

  static bool get isAvailable => _speechEnabled;
  static bool get isListening => _isListening;

  static Future<String?> startListening() async {
    if (!_speechEnabled) return null;

    String recognizedText = '';
    
    try {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
        },
        localeId: 'he-IL', // Hebrew locale
        listenMode: ListenMode.dictation,
      );

      // Wait for speech to complete
      await Future.delayed(const Duration(seconds: 5));
      await _speechToText.stop();
      _isListening = false;

      return recognizedText.isNotEmpty ? recognizedText : null;
    } catch (e) {
      _isListening = false;
      if (kDebugMode) print('Voice recognition error: $e');
      return null;
    }
  }

  static Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  static Future<TaskParseResult?> parseHebrewCommand(String hebrewText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final openaiKey = prefs.getString('openai_api_key');
      
      if (openaiKey == null || openaiKey.isEmpty) {
        // Fallback to simple parsing for demo
        return _simpleParseHebrew(hebrewText);
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openaiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''אתה עוזר שמנתח פקודות קוליות בעברית למשימות. 
החזר תמיד JSON בפורמט הזה:
{
  "title": "כותרת המשימה",
  "description": "תיאור אופציונלי",
  "dueDate": "2024-01-15T15:00:00Z" או null,
  "priority": "important" או "simple" או "later",
  "type": "task" או "reminder" או "note" או "event"
}

דוגמאות:
"צור משימה מחר בשלוש לכבס כביסה" → task עם dueDate מחר בשעה 15:00
"תזכיר לי להתקשר לאמא הערב" → reminder עם dueDate היום בערב
"כתוב פתק להביא מטען" → note ללא dueDate
"קבע פגישה עם דן ביום ראשון בצהריים" → event ביום ראשון בצהריים'''
            },
            {
              'role': 'user',
              'content': hebrewText,
            }
          ],
          'max_tokens': 200,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final parsedData = jsonDecode(content);
        
        return TaskParseResult(
          title: parsedData['title'],
          description: parsedData['description'] ?? '',
          dueDate: parsedData['dueDate'] != null 
              ? DateTime.parse(parsedData['dueDate']) 
              : null,
          priority: _parsePriority(parsedData['priority']),
          type: _parseType(parsedData['type']),
          originalText: hebrewText,
        );
      } else {
        return _simpleParseHebrew(hebrewText);
      }
    } catch (e) {
      if (kDebugMode) print('OpenAI parsing error: $e');
      return _simpleParseHebrew(hebrewText);
    }
  }

  static TaskParseResult _simpleParseHebrew(String text) {
    // Simple Hebrew parsing fallback
    TaskType type = TaskType.task;
    TaskPriority priority = TaskPriority.simple;
    DateTime? dueDate;
    
    // Detect task type
    if (text.contains('תזכיר') || text.contains('תזכורת')) {
      type = TaskType.reminder;
    } else if (text.contains('כתוב פתק') || text.contains('פתק')) {
      type = TaskType.note;
    } else if (text.contains('פגישה') || text.contains('קבע') || text.contains('מפגש')) {
      type = TaskType.event;
    }
    
    // Detect priority
    if (text.contains('חשוב') || text.contains('דחוף') || text.contains('חיוני')) {
      priority = TaskPriority.important;
    } else if (text.contains('אחר כך') || text.contains('מאוחר יותר')) {
      priority = TaskPriority.later;
    }
    
    // Simple date parsing
    final now = DateTime.now();
    if (text.contains('מחר')) {
      dueDate = DateTime(now.year, now.month, now.day + 1, 9, 0);
    } else if (text.contains('היום')) {
      dueDate = DateTime(now.year, now.month, now.day, 18, 0);
    } else if (text.contains('שבוע')) {
      dueDate = now.add(const Duration(days: 7));
    }
    
    // Extract time if mentioned
    final timeMatch = RegExp(r'(\d{1,2})').firstMatch(text);
    if (timeMatch != null && dueDate != null) {
      final hour = int.tryParse(timeMatch.group(1)!) ?? 9;
      dueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, hour, 0);
    }
    
    // Clean title
    String title = text
        .replaceAll(RegExp(r'(צור משימה|תזכיר לי|כתוב פתק|קבע פגישה)'), '')
        .replaceAll(RegExp(r'(מחר|היום|הערב|בשלוש|בצהריים)'), '')
        .trim();
    
    if (title.isEmpty) title = 'משימה חדשה';
    
    return TaskParseResult(
      title: title,
      description: '',
      dueDate: dueDate,
      priority: priority,
      type: type,
      originalText: text,
    );
  }

  static TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'important':
        return TaskPriority.important;
      case 'later':
        return TaskPriority.later;
      default:
        return TaskPriority.simple;
    }
  }

  static TaskType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'reminder':
        return TaskType.reminder;
      case 'note':
        return TaskType.note;
      case 'event':
        return TaskType.event;
      default:
        return TaskType.task;
    }
  }

  static List<String> getWakeWords() => [
        'היי מטלות',
        'מטלות',
        'מינדפלו',
        'עוזר',
      ];

  static bool containsWakeWord(String text) {
    final lowerText = text.toLowerCase();
    return getWakeWords().any((word) => lowerText.contains(word.toLowerCase()));
  }
}

class TaskParseResult {
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskType type;
  final String originalText;

  TaskParseResult({
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.type,
    required this.originalText,
  });

  Task toTask() => Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        type: type,
        createdAt: DateTime.now(),
        voiceNote: originalText,
      );
}