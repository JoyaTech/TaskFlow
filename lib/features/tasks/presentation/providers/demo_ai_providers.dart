import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';

// Demo AI Processing Notifier for testing UI without API keys
class DemoAIProcessingNotifier extends StateNotifier<bool> {
  DemoAIProcessingNotifier() : super(false);

  /// Demo: Process natural language text input and create tasks
  Future<DemoTaskCreationResult?> processTextInput(String input) async {
    if (input.trim().isEmpty) return null;

    state = true;
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create demo result based on input
      return _createDemoResult(input);
    } catch (e) {
      print('Error processing text input: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Demo: Process voice input
  Future<DemoTaskCreationResult?> processVoiceInput(String transcript) async {
    return await processTextInput(transcript);
  }

  /// Demo: Scan emails (just simulate)
  Future<void> scanEmails() async {
    state = true;
    try {
      await Future.delayed(const Duration(seconds: 3));
      print('Demo: Found 0 actionable emails (no real Gmail access)');
    } finally {
      state = false;
    }
  }

  /// Demo: Handle overwhelmed state
  Future<DemoTaskCreationResult?> handleOverwhelmedState() async {
    return await processTextInput('אני מרגיש המום, תעזור לי עם משימות פשוטות');
  }

  DemoTaskCreationResult _createDemoResult(String input) {
    // Simple demo logic based on input
    String title = input;
    if (title.length > 50) {
      title = title.substring(0, 47) + '...';
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Created from AI: "$input"',
      priority: _guessPriority(input),
      type: TaskType.task,
      createdAt: DateTime.now(),
      tags: _generateTags(input),
    );

    final recommendations = _generateDemoRecommendations(input);
    final wasOptimized = input.contains('המום') || input.length > 100;
    final confidence = input.length > 10 ? 0.85 : 0.6;

    List<Task> subTasks = [];
    if (wasOptimized) {
      // Create demo subtasks for complex inputs
      subTasks = [
        Task(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          title: 'התחל: $title',
          description: 'Part of: $title',
          priority: TaskPriority.simple,
          type: TaskType.task,
          createdAt: DateTime.now(),
          tags: ['Sub-task 1/2', 'Part of bigger task'],
        ),
        Task(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          title: 'סיים: $title',
          description: 'Part of: $title',
          priority: TaskPriority.simple,
          type: TaskType.task,
          createdAt: DateTime.now(),
          tags: ['Sub-task 2/2', 'Part of bigger task'],
        ),
      ];
    }

    return DemoTaskCreationResult(
      mainTask: task,
      subTasks: subTasks,
      recommendations: recommendations,
      confidence: confidence,
      wasOptimized: wasOptimized,
    );
  }

  TaskPriority _guessPriority(String input) {
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains('דחוף') || lowerInput.contains('חשוב') || lowerInput.contains('urgent')) {
      return TaskPriority.important;
    }
    if (lowerInput.contains('אחר כך') || lowerInput.contains('later')) {
      return TaskPriority.later;
    }
    return TaskPriority.simple;
  }

  List<String> _generateTags(String input) {
    final tags = <String>['AI Created'];
    
    if (input.contains('פגישה') || input.contains('meeting')) {
      tags.add('Meeting');
    }
    if (input.contains('קנה') || input.contains('shopping')) {
      tags.add('Shopping');
    }
    if (input.contains('תזכורת') || input.contains('reminder')) {
      tags.add('Reminder');
    }
    if (input.contains('המום') || input.contains('overwhelm')) {
      tags.add('Take your time');
    }
    
    return tags;
  }

  List<String> _generateDemoRecommendations(String input) {
    final recommendations = <String>[];
    
    if (input.contains('המום') || input.contains('overwhelm')) {
      recommendations.addAll([
        '🧘 קח 5 נשימות עמוקות לפני שתתחיל',
        '🎯 התמקד רק בצעד הראשון',
        '⏰ קבע טיימר ל-15 דקות מקסימום',
      ]);
    }
    
    if (input.contains('פגישה') || input.contains('meeting')) {
      recommendations.addAll([
        '📅 הוסף לקלנדר',
        '📝 הכן רשימת נושאים',
        '🔔 קבע תזכורת 30 דקות לפני',
      ]);
    }
    
    if (recommendations.isEmpty) {
      recommendations.addAll([
        '💪 אתה יכול! תתחיל בקטן.',
        '🌟 כל צעד קדימה נחשב',
        '🎉 חגוג ניצחונות קטנים בדרך',
      ]);
    }
    
    return recommendations;
  }
}

// Demo AI Processing Provider
final demoAITaskProcessingProvider = StateNotifierProvider<DemoAIProcessingNotifier, bool>((ref) {
  return DemoAIProcessingNotifier();
});

// Voice Input State Management (reuse from main providers)
enum VoiceInputState {
  idle,
  listening,
  processing,
  error,
}

class VoiceInputNotifier extends StateNotifier<VoiceInputState> {
  VoiceInputNotifier() : super(VoiceInputState.idle);

  void startListening() {
    state = VoiceInputState.listening;
  }

  void stopListening() {
    state = VoiceInputState.processing;
  }

  void finishProcessing() {
    state = VoiceInputState.idle;
  }

  void setError(String error) {
    state = VoiceInputState.error;
  }
}

final voiceInputProvider = StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  return VoiceInputNotifier();
});

// Smart Input State Management (reuse from main providers)
class SmartInputNotifier extends StateNotifier<SmartInputState> {
  SmartInputNotifier() : super(SmartInputState.initial());

  void updateInput(String input) {
    state = state.copyWith(input: input);
  }

  void updateSuggestions(List<String> suggestions) {
    state = state.copyWith(suggestions: suggestions);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void reset() {
    state = SmartInputState.initial();
  }
}

class SmartInputState {
  final String input;
  final List<String> suggestions;
  final bool isProcessing;

  SmartInputState({
    required this.input,
    required this.suggestions,
    required this.isProcessing,
  });

  factory SmartInputState.initial() {
    return SmartInputState(
      input: '',
      suggestions: [],
      isProcessing: false,
    );
  }

  SmartInputState copyWith({
    String? input,
    List<String>? suggestions,
    bool? isProcessing,
  }) {
    return SmartInputState(
      input: input ?? this.input,
      suggestions: suggestions ?? this.suggestions,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

final smartInputProvider = StateNotifierProvider<SmartInputNotifier, SmartInputState>((ref) {
  return SmartInputNotifier();
});

// Demo Task Creation Result
class DemoTaskCreationResult {
  final Task mainTask;
  final List<Task> subTasks;
  final List<String> recommendations;
  final double confidence;
  final bool wasOptimized;

  DemoTaskCreationResult({
    required this.mainTask,
    required this.subTasks,
    required this.recommendations,
    required this.confidence,
    required this.wasOptimized,
  });
}
