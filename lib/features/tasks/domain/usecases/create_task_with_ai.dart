import 'dart:io';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../../../../core/services/ai_processing_service.dart';

/// AI-powered task creation use case
/// Processes natural language input, extracts structured data, and applies ADHD-friendly optimizations
class CreateTaskWithAI {
  final TaskRepository taskRepository;
  final AIProcessingService aiService;

  CreateTaskWithAI({
    required this.taskRepository,
    required this.aiService,
  });

  /// Create a task from natural language input with AI processing
  Future<TaskCreationResult> call(String naturalInput) async {
    try {
      // Step 1: Analyze the input with AI
      final intentAnalysis = await aiService.analyzeTextIntent(naturalInput);
      final emotionalAnalysis = await aiService.analyzeEmotionalState(naturalInput);

      // Step 2: Apply ADHD-friendly task optimization
      final optimizedTaskData = _optimizeForADHD(
        intentAnalysis, 
        emotionalAnalysis,
      );

      // Step 3: Create the main task
      final mainTask = await _createMainTask(optimizedTaskData);

      // Step 4: Create sub-tasks if needed for ADHD support
      final subTasks = await _createSubTasksIfNeeded(
        mainTask, 
        optimizedTaskData,
        emotionalAnalysis,
      );

      // Step 5: Generate ADHD-specific recommendations
      final recommendations = _generateADHDRecommendations(
        emotionalAnalysis,
        optimizedTaskData,
      );

      return TaskCreationResult(
        mainTask: mainTask,
        subTasks: subTasks,
        recommendations: recommendations,
        emotionalContext: emotionalAnalysis,
        confidence: intentAnalysis.confidence,
        wasOptimized: emotionalAnalysis.isOverwhelmed || 
                     emotionalAnalysis.needsTaskBreakdown,
      );

    } catch (e) {
      throw TaskCreationException('Failed to create task with AI: $e');
    }
  }

  /// Create a task from voice input
  Future<TaskCreationResult> createFromVoice(String audioFilePath) async {
    try {
      // Step 1: Convert voice to text
      final transcription = await aiService.processVoiceToText(
        File(audioFilePath),
      );

      // Step 2: Use regular AI task creation flow
      return await call(transcription);

    } catch (e) {
      throw TaskCreationException('Failed to create task from voice: $e');
    }
  }

  /// Optimize task data for ADHD users
  TaskOptimizationData _optimizeForADHD(
    AIAnalysisResult intentAnalysis,
    EmotionalAnalysis emotionalAnalysis,
  ) {
    final extractedData = intentAnalysis.extractedData;
    final contextAnalysis = intentAnalysis.contextAnalysis;

    // Start with AI-extracted data
    String title = extractedData.title ?? 'Untitled Task';
    String? description = extractedData.description;
    DateTime? dueDate = extractedData.dueDate;
    TaskPriority priority = _mapPriority(extractedData.priority);
    List<String> tags = List.from(extractedData.tags);

    // ADHD Optimization 1: Simplify overwhelming tasks
    if (emotionalAnalysis.isOverwhelmed) {
      // Simplify title if it's too complex
      if (title.length > 50) {
        title = title.substring(0, 47) + '...';
      }

      // Reduce to simple priority if overwhelmed
      if (priority == TaskPriority.important && !_isUrgent(intentAnalysis)) {
        priority = TaskPriority.simple;
      }

      // Add calming tags
      tags.add('Take your time');
    }

    // ADHD Optimization 2: Handle hyperfocus state
    if (emotionalAnalysis.adhdIndicators.hyperfocusState) {
      // Capitalize on hyperfocus - make it important
      if (contextAnalysis.requiresFocus) {
        priority = TaskPriority.important;
        tags.add('Hyperfocus opportunity');
      }
    }

    // ADHD Optimization 3: Executive dysfunction support
    if (emotionalAnalysis.adhdIndicators.executiveDysfunction) {
      // Add starter hints to description
      final starterHints = _generateStarterHints(title, description);
      description = starterHints + (description ?? '');
      
      tags.add('Break it down');
    }

    // ADHD Optimization 4: Time pressure management
    if (dueDate != null && _isUrgentDueDate(dueDate)) {
      if (emotionalAnalysis.isOverwhelmed) {
        // Add buffer time for overwhelmed users
        dueDate = dueDate.subtract(const Duration(hours: 2));
        tags.add('Buffer time added');
      }
    }

    // ADHD Optimization 5: Energy level consideration
    final timeRecommendation = _getOptimalTimeRecommendation(
      emotionalAnalysis,
      contextAnalysis,
    );
    if (timeRecommendation != null) {
      tags.add(timeRecommendation);
    }

    return TaskOptimizationData(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      tags: tags,
      shouldBreakDown: _shouldBreakDownTask(
        contextAnalysis,
        emotionalAnalysis,
      ),
      complexityLevel: contextAnalysis.complexity,
      requiresFocus: contextAnalysis.requiresFocus,
    );
  }

  /// Create the main task from optimized data
  Future<Task> _createMainTask(TaskOptimizationData data) async {
    final task = Task(
      id: '', // Will be assigned by repository
      title: data.title,
      description: data.description ?? '',
      priority: data.priority,
      type: TaskType.task,
      dueDate: data.dueDate,
      tags: data.tags,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    return await taskRepository.addTask(task);
  }

  /// Create sub-tasks if needed for ADHD support
  Future<List<Task>> _createSubTasksIfNeeded(
    Task mainTask,
    TaskOptimizationData data,
    EmotionalAnalysis emotionalAnalysis,
  ) async {
    if (!data.shouldBreakDown) return [];

    final subTasks = <Task>[];
    final subTaskTitles = _generateSubTaskTitles(
      mainTask.title,
      data.complexityLevel,
      emotionalAnalysis,
    );

    for (int i = 0; i < subTaskTitles.length; i++) {
      final subTask = Task(
        id: '', // Will be assigned by repository
        title: subTaskTitles[i],
        description: 'Part of: ${mainTask.title}',
        priority: TaskPriority.simple, // Sub-tasks are always simple
        type: TaskType.task,
        dueDate: data.dueDate != null 
            ? data.dueDate!.subtract(Duration(days: subTaskTitles.length - i))
            : null,
        tags: [
          'Sub-task ${i + 1}/${subTaskTitles.length}',
          'Part of bigger task',
          ...data.tags,
        ],
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      final savedSubTask = await taskRepository.addTask(subTask);
      subTasks.add(savedSubTask);
    }

    return subTasks;
  }

  /// Generate ADHD-specific recommendations
  List<String> _generateADHDRecommendations(
    EmotionalAnalysis emotionalAnalysis,
    TaskOptimizationData data,
  ) {
    final recommendations = <String>[];

    if (emotionalAnalysis.isOverwhelmed) {
      recommendations.add('🧘 Take 5 deep breaths before starting');
      recommendations.add('🎯 Focus on just the first step');
      recommendations.add('⏰ Set a timer for 15 minutes maximum');
    }

    if (emotionalAnalysis.adhdIndicators.hyperfocusState) {
      recommendations.add('🔥 Great time to tackle this - you\'re in the zone!');
      recommendations.add('💧 Don\'t forget to drink water');
      recommendations.add('🍎 Have a snack ready');
    }

    if (data.requiresFocus) {
      recommendations.add('🎧 Put on focus music or noise-cancelling headphones');
      recommendations.add('📵 Put phone in another room');
      recommendations.add('🚪 Find a quiet space');
    }

    if (emotionalAnalysis.recommendations.suggestBreak) {
      recommendations.add('🛋️ Take a short break first');
      recommendations.add('🚶 Maybe go for a quick walk');
    }

    if (emotionalAnalysis.recommendations.provideEncouragement) {
      recommendations.add('💪 You\'ve got this! Start small.');
      recommendations.add('🌟 Every step forward counts');
      recommendations.add('🎉 Celebrate small wins along the way');
    }

    return recommendations;
  }

  // Helper methods

  TaskPriority _mapPriority(String? aiPriority) {
    switch (aiPriority) {
      case 'important':
        return TaskPriority.important;
      case 'later':
        return TaskPriority.later;
      default:
        return TaskPriority.simple;
    }
  }

  bool _isUrgent(AIAnalysisResult analysis) {
    return analysis.contextAnalysis.urgencyLevel == 'high' ||
           analysis.extractedData.dueDate != null &&
           analysis.extractedData.dueDate!
               .difference(DateTime.now()).inHours < 24;
  }

  bool _isUrgentDueDate(DateTime dueDate) {
    return dueDate.difference(DateTime.now()).inHours < 48;
  }

  String _generateStarterHints(String title, String? description) {
    return 'Quick start ideas:\n'
           '• Open the relevant app/website\n'
           '• Gather any materials you need\n'
           '• Break this into 3 smaller steps\n'
           '• Set a 15-minute timer\n\n'
           '${description ?? ""}\n\n';
  }

  String? _getOptimalTimeRecommendation(
    EmotionalAnalysis emotionalAnalysis,
    ContextAnalysis contextAnalysis,
  ) {
    final hour = DateTime.now().hour;

    if (contextAnalysis.requiresFocus) {
      if (hour >= 9 && hour <= 11) {
        return 'Perfect focus time';
      } else if (hour >= 14 && hour <= 16) {
        return 'Afternoon focus window';
      } else {
        return 'Schedule for morning focus';
      }
    }

    if (emotionalAnalysis.emotionalState.primaryEmotion == 'tired') {
      return 'Consider doing this when more energetic';
    }

    return null;
  }

  bool _shouldBreakDownTask(
    ContextAnalysis contextAnalysis,
    EmotionalAnalysis emotionalAnalysis,
  ) {
    return contextAnalysis.complexity == 'complex' ||
           emotionalAnalysis.needsTaskBreakdown ||
           emotionalAnalysis.isOverwhelmed;
  }

  List<String> _generateSubTaskTitles(
    String mainTitle,
    String complexityLevel,
    EmotionalAnalysis emotionalAnalysis,
  ) {
    // Simple AI-based task breakdown
    if (complexityLevel == 'complex' || emotionalAnalysis.isOverwhelmed) {
      return [
        'Plan and prepare for: $mainTitle',
        'Start working on: $mainTitle',
        'Complete and review: $mainTitle',
      ];
    } else {
      return [
        'Begin: $mainTitle',
        'Finish: $mainTitle',
      ];
    }
  }
}

/// Result of AI-powered task creation
class TaskCreationResult {
  final Task mainTask;
  final List<Task> subTasks;
  final List<String> recommendations;
  final EmotionalAnalysis emotionalContext;
  final double confidence;
  final bool wasOptimized;

  TaskCreationResult({
    required this.mainTask,
    required this.subTasks,
    required this.recommendations,
    required this.emotionalContext,
    required this.confidence,
    required this.wasOptimized,
  });

  /// Get total number of tasks created
  int get totalTasksCreated => 1 + subTasks.length;

  /// Check if creation was high-confidence
  bool get isHighConfidence => confidence > 0.7;
}

/// Optimized task data for ADHD users
class TaskOptimizationData {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<String> tags;
  final bool shouldBreakDown;
  final String complexityLevel;
  final bool requiresFocus;

  TaskOptimizationData({
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.tags,
    required this.shouldBreakDown,
    required this.complexityLevel,
    required this.requiresFocus,
  });
}

/// Custom exception for task creation errors
class TaskCreationException implements Exception {
  final String message;
  TaskCreationException(this.message);

  @override
  String toString() => 'TaskCreationException: $message';
}
