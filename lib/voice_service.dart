import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindflow/task_model.dart' as taskModel;
import 'package:google_generative_ai/google_generative_ai.dart';

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
      final geminiApiKey = prefs.getString('gemini_api_key');
      
      if (geminiApiKey == null || geminiApiKey.isEmpty) {
        // Fallback to simple parsing for demo
        return _simpleParseHebrew(hebrewText);
      }

      // Initialize Gemini model
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: geminiApiKey,
      );

      // Create the prompt for Hebrew NLU
      final prompt = '''
אתה עוזר חכם לאפליקציית פרודוקטיביות "Focus Flow" המיועדת לאנשים עם ADHD.
המשימה שלך היא לנתח בקשות בעברית ולהחזיר JSON מובנה.

החזר תמיד JSON בפורמט הזה בלבד:
{
  "intent": "create_task" או "create_reminder" או "create_note" או "create_event",
  "entities": {
    "content": "התוכן הנדש",
    "date": "2025-08-05" או null,
    "time": "14:30" או null,
    "priority": "important" או "simple" או "later"
  }
}

דוגמאות:
"צור משימה מחר בשלוש לכבס כביסה" → intent: "create_task", content: "לכבס כביסה", date: "2025-08-05", time: "15:00"
"תזכיר לי להתקשר לאמא הערב" → intent: "create_reminder", content: "להתקשר לאמא", date: היום, time: "19:00"
"כתוב פתק להביא מטען" → intent: "create_note", content: "להביא מטען", date: null, time: null
"פגישה עם דן ביום ראשון בצהריים" → intent: "create_event", content: "פגישה עם דן", date: יום ראשון הקרוב, time: "12:00"

נתח את הבקשה הבאה והחזר רק JSON:
$hebrewText''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        try {
          // Clean the response to extract JSON only
          String jsonString = response.text!.trim();
          if (jsonString.startsWith('```json')) {
            jsonString = jsonString.substring(7);
          }
          if (jsonString.endsWith('```')) {
            jsonString = jsonString.substring(0, jsonString.length - 3);
          }
          
          final parsedData = jsonDecode(jsonString);
          final entities = parsedData['entities'] ?? {};
          
          // Parse date if provided
          DateTime? dueDate;
          if (entities['date'] != null) {
            try {
              dueDate = DateTime.parse(entities['date']);
              // Add time if provided
              if (entities['time'] != null) {
                final timeParts = entities['time'].split(':');
                if (timeParts.length >= 2) {
                  final hour = int.tryParse(timeParts[0]) ?? 9;
                  final minute = int.tryParse(timeParts[1]) ?? 0;
                  dueDate = DateTime(
                    dueDate.year,
                    dueDate.month,
                    dueDate.day,
                    hour,
                    minute,
                  );
                }
              }
            } catch (e) {
              if (kDebugMode) print('Date parsing error: $e');
            }
          }
          
          return TaskParseResult(
            title: entities['content'] ?? hebrewText,
            description: 'נוצר באמצעות זיהוי קולי חכם',
            dueDate: dueDate,
            priority: _parsePriority(entities['priority'] ?? 'simple'),
            type: _parseTypeFromIntent(parsedData['intent'] ?? 'create_task'),
            originalText: hebrewText,
          );
        } catch (e) {
          if (kDebugMode) print('JSON parsing error: $e');
          return _simpleParseHebrew(hebrewText);
        }
      } else {
        return _simpleParseHebrew(hebrewText);
      }
    } catch (e) {
      if (kDebugMode) print('Gemini parsing error: $e');
      return _simpleParseHebrew(hebrewText);
    }
  }

  static taskModel.TaskType _parseTypeFromIntent(String intent) {
    switch (intent) {
      case 'create_reminder':
        return taskModel.TaskType.reminder;
      case 'create_note':
        return taskModel.TaskType.note;
      case 'create_event':
        return taskModel.TaskType.event;
      default:
        return taskModel.TaskType.task;
    }
  }

  static TaskParseResult _simpleParseHebrew(String text) {
    // Simple Hebrew parsing fallback
    taskModel.TaskType type = taskModel.TaskType.task;
    taskModel.TaskPriority priority = taskModel.TaskPriority.simple;
    DateTime? dueDate;
    
    // Detect task type
    if (text.contains('תזכיר') || text.contains('תזכורת')) {
      type = taskModel.TaskType.reminder;
    } else if (text.contains('כתוב פתק') || text.contains('פתק')) {
      type = taskModel.TaskType.note;
    } else if (text.contains('פגישה') || text.contains('קבע') || text.contains('מפגש')) {
      type = taskModel.TaskType.event;
    }
    
    // Detect priority
    if (text.contains('חשוב') || text.contains('דחוף') || text.contains('חיוני')) {
      priority = taskModel.TaskPriority.important;
    } else if (text.contains('אחר כך') || text.contains('מאוחר יותר')) {
      priority = taskModel.TaskPriority.later;
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

  static taskModel.TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'important':
        return taskModel.TaskPriority.important;
      case 'later':
        return taskModel.TaskPriority.later;
      default:
        return taskModel.TaskPriority.simple;
    }
  }

  static taskModel.TaskType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'reminder':
        return taskModel.TaskType.reminder;
      case 'note':
        return taskModel.TaskType.note;
      case 'event':
        return taskModel.TaskType.event;
      default:
        return taskModel.TaskType.task;
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
  final taskModel.TaskPriority priority;
  final taskModel.TaskType type;
  final String originalText;

  TaskParseResult({
    required this.title,
    required this.description,
    this.dueDate,
    required this.priority,
    required this.type,
    required this.originalText,
  });

  taskModel.Task toTask() => taskModel.Task(
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
