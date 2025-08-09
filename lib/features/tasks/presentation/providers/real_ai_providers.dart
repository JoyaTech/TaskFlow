import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/services/secure_storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/entities/task.dart';
import '../../use_cases/create_task_with_ai.dart';

/// Real AI Processing State
class AIProcessingState {
  final bool isProcessing;
  final String? error;
  final List<Task> generatedTasks;
  
  const AIProcessingState({
    this.isProcessing = false,
    this.error,
    this.generatedTasks = const [],
  });
  
  AIProcessingState copyWith({
    bool? isProcessing,
    String? error,
    List<Task>? generatedTasks,
  }) {
    return AIProcessingState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      generatedTasks: generatedTasks ?? this.generatedTasks,
    );
  }
}

/// Real AI Processing Service
class RealAIProcessingService {
  final String? openaiKey;
  final String? geminiKey;
  
  RealAIProcessingService({
    this.openaiKey,
    this.geminiKey,
  });
  
  bool get hasValidKey => 
      (openaiKey != null && openaiKey!.isNotEmpty) ||
      (geminiKey != null && geminiKey!.isNotEmpty);
  
  /// Process voice input using real AI
  Future<List<Map<String, dynamic>>> processVoiceInput(String transcribedText) async {
    if (!hasValidKey) {
      throw Exception('No valid API key available');
    }
    
    try {
      // Try Gemini first (better for Hebrew), then fallback to OpenAI
      if (geminiKey != null && geminiKey!.isNotEmpty) {
        return await _processWithGemini(transcribedText);
      } else if (openaiKey != null && openaiKey!.isNotEmpty) {
        return await _processWithOpenAI(transcribedText);
      } else {
        throw Exception('No API keys configured');
      }
    } catch (e) {
      print('Real AI processing failed: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> _processWithGemini(String input) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$geminiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contents': [
          {
            'parts': [
              {
                'text': '''
אתה עוזר AI חכם למשימות בעברית. נתח את הטקסט הבא וחלץ משימות:

"$input"

החזר JSON עם מערך של משימות. כל משימה צריכה להכיל:
- title (כותרת קצרה בעברית)
- description (תיאור מפורט בעברית) 
- dueDate (תאריך יעד בפורמט ISO, או null)
- priority (high/medium/low)
- isCompleted (תמיד false)
- tags (מערך של תגיות רלוונטיות בעברית)

דוגמה:
{
  "tasks": [
    {
      "title": "קניות לשבת",
      "description": "לקנות ירקות ופירות בשוק",
      "dueDate": "2024-01-20T10:00:00Z",
      "priority": "medium",
      "isCompleted": false,
      "tags": ["קניות", "שבת"]
    }
  ]
}

החזר רק JSON תקין, ללא טקסט נוסף:
'''
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.95,
        }
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final generatedText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      
      try {
        // Extract JSON from the response
        final jsonStart = generatedText.indexOf('{');
        final jsonEnd = generatedText.lastIndexOf('}') + 1;
        final jsonText = generatedText.substring(jsonStart, jsonEnd);
        final parsed = json.decode(jsonText);
        
        return List<Map<String, dynamic>>.from(parsed['tasks'] ?? []);
      } catch (e) {
        // If parsing fails, create a single task from the input
        return [_createFallbackTask(input)];
      }
    } else {
      throw Exception('Gemini API failed: ${response.statusCode}');
    }
  }
  
  Future<List<Map<String, dynamic>>> _processWithOpenAI(String input) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openaiKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': '''אתה עוזר AI חכם למשימות בעברית. נתח טקסט וחלץ משימות. 
החזר JSON עם מערך tasks, כל משימה עם: title, description, dueDate (ISO או null), priority (high/medium/low), isCompleted (false), tags (מערך בעברית).
החזר רק JSON תקין.'''
          },
          {
            'role': 'user',
            'content': input
          }
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices']?[0]?['message']?['content'] ?? '';
      
      try {
        final parsed = json.decode(content);
        return List<Map<String, dynamic>>.from(parsed['tasks'] ?? []);
      } catch (e) {
        return [_createFallbackTask(input)];
      }
    } else {
      throw Exception('OpenAI API failed: ${response.statusCode}');
    }
  }
  
  Map<String, dynamic> _createFallbackTask(String input) {
    return {
      'title': input.length > 50 ? input.substring(0, 50) + '...' : input,
      'description': input,
      'dueDate': null,
      'priority': 'medium',
      'isCompleted': false,
      'tags': ['AI', 'קול'],
    };
  }
  
  /// Scan emails for tasks (placeholder - requires Gmail API integration)
  Future<List<Map<String, dynamic>>> scanEmails() async {
    // TODO: Implement Gmail API scanning
    await Future.delayed(const Duration(seconds: 2));
    
    // For now, return simulated results
    return [
      {
        'title': 'פגישה עם לקוח ביום שני',
        'description': 'פגישה שנמצאה באימייל מ-john@company.com',
        'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'priority': 'high',
        'isCompleted': false,
        'tags': ['אימייל', 'פגישה'],
      }
    ];
  }
  
  /// Help with overwhelmed state
  Future<List<Map<String, dynamic>>> handleOverwhelmedState(List<Task> existingTasks) async {
    if (!hasValidKey) {
      throw Exception('No valid API key available');
    }
    
    final tasksText = existingTasks.map((t) => '- ${t.title}').join('\n');
    final prompt = '''
יש לי רשימת משימות והרגשתי המומה. עזור לי לפרק ולארגן:

משימות קיימות:
$tasksText

אנא:
1. פרק משימות גדולות לקטנות יותר
2. סדר לפי עדיפות
3. הצע לדחות משימות לא דחופות
4. צור 3-5 משימות קטנות לביצוע היום

החזר JSON עם מערך משימות מחדש.
''';
    
    return await processVoiceInput(prompt);
  }
}

/// Real AI Task Processing Notifier
class RealAITaskProcessingNotifier extends StateNotifier<AIProcessingState> {
  final CreateTaskWithAI _createTaskWithAI;
  final SecureStorageService _secureStorage;
  
  RealAITaskProcessingNotifier(
    this._createTaskWithAI,
    this._secureStorage,
  ) : super(const AIProcessingState());
  
  Future<RealAIProcessingService> _getAIService() async {
    final openaiKey = await _secureStorage.getOpenAIApiKeyInstance();
    final geminiKey = await _secureStorage.getGeminiApiKeyInstance();
    
    return RealAIProcessingService(
      openaiKey: openaiKey,
      geminiKey: geminiKey,
    );
  }
  
  Future<void> processVoiceInput(String transcribedText) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      final aiService = await _getAIService();
      
      if (!aiService.hasValidKey) {
        throw Exception('אין מפתח API מוגדר. עבור להגדרות להוסיף מפתח.');
      }
      
      final tasksData = await aiService.processVoiceInput(transcribedText);
      final tasks = <Task>[];
      
      for (final taskData in tasksData) {
        final task = await _createTaskWithAI.call(
          CreateTaskWithAIParams(
            title: taskData['title'] ?? 'משימה חדשה',
            description: taskData['description'] ?? '',
            priority: _mapPriority(taskData['priority']),
            dueDate: taskData['dueDate'] != null 
                ? DateTime.tryParse(taskData['dueDate'])
                : null,
            tags: List<String>.from(taskData['tags'] ?? []),
          ),
        );
        tasks.add(task);
      }
      
      state = state.copyWith(
        isProcessing: false,
        generatedTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> processSmartInput(String input) async {
    await processVoiceInput(input); // Same logic for now
  }
  
  Future<void> scanEmails() async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      final aiService = await _getAIService();
      final tasksData = await aiService.scanEmails();
      final tasks = <Task>[];
      
      for (final taskData in tasksData) {
        final task = await _createTaskWithAI.call(
          CreateTaskWithAIParams(
            title: taskData['title'] ?? 'משימה מאימייל',
            description: taskData['description'] ?? '',
            priority: _mapPriority(taskData['priority']),
            dueDate: taskData['dueDate'] != null 
                ? DateTime.tryParse(taskData['dueDate'])
                : null,
            tags: List<String>.from(taskData['tags'] ?? []),
          ),
        );
        tasks.add(task);
      }
      
      state = state.copyWith(
        isProcessing: false,
        generatedTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> handleOverwhelmedState(List<Task> existingTasks) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      final aiService = await _getAIService();
      
      if (!aiService.hasValidKey) {
        throw Exception('אין מפתח API מוגדר. עבור להגדרות להוסיף מפתח.');
      }
      
      final tasksData = await aiService.handleOverwhelmedState(existingTasks);
      final tasks = <Task>[];
      
      for (final taskData in tasksData) {
        final task = await _createTaskWithAI.call(
          CreateTaskWithAIParams(
            title: taskData['title'] ?? 'משימה מעבודת AI',
            description: taskData['description'] ?? '',
            priority: _mapPriority(taskData['priority']),
            dueDate: taskData['dueDate'] != null 
                ? DateTime.tryParse(taskData['dueDate'])
                : null,
            tags: List<String>.from(taskData['tags'] ?? []),
          ),
        );
        tasks.add(task);
      }
      
      state = state.copyWith(
        isProcessing: false,
        generatedTasks: tasks,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }
  
  TaskPriority _mapPriority(dynamic priority) {
    switch (priority?.toString().toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
  
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  void clearGeneratedTasks() {
    state = state.copyWith(generatedTasks: []);
  }
}

/// Providers
final realAITaskProcessingProvider = StateNotifierProvider<RealAITaskProcessingNotifier, AIProcessingState>((ref) {
  final createTaskWithAI = ref.read(createTaskWithAIProvider);
  final secureStorage = SecureStorageService();
  
  return RealAITaskProcessingNotifier(createTaskWithAI, secureStorage);
});

/// Helper to check if real AI is available
final realAIAvailableProvider = FutureProvider<bool>((ref) async {
  final secureStorage = SecureStorageService();
  final openaiKey = await secureStorage.getOpenAIApiKeyInstance();
  final geminiKey = await secureStorage.getGeminiApiKeyInstance();
  
  return (openaiKey != null && openaiKey.isNotEmpty) ||
         (geminiKey != null && geminiKey.isNotEmpty);
});
