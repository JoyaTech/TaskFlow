import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/core/services/ai_processing_service.dart';
import 'package:mindflow/features/tasks/domain/usecases/create_task_with_ai.dart';
import 'package:mindflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:mindflow/services/secure_storage_service.dart';
import '../../../gmail/data/gmail_datasource.dart';
import '../../../tasks/data/repositories/task_repository_impl.dart';
import '../../../tasks/data/datasources/task_local_datasource.dart';

// Export TaskCreationResult from the use case
export 'package:mindflow/features/tasks/domain/usecases/create_task_with_ai.dart' show TaskCreationResult;

// AI Processing Service Provider with real API key from secure storage
final aiProcessingServiceProvider = FutureProvider<AIProcessingService>((ref) async {
  // Get API key from secure storage
  final secureStorage = SecureStorageService();
  String? apiKey = await secureStorage.getOpenAIApiKeyInstance();
  
  // Fallback to Gemini if OpenAI not available
  if (apiKey == null || apiKey.isEmpty) {
    apiKey = await secureStorage.getGeminiApiKeyInstance();
  }
  
  // If still no API key, throw descriptive error
  if (apiKey == null || apiKey.isEmpty) {
    throw AIProcessingException(
      'No AI API key found. Please configure your OpenAI or Gemini API key in Settings.',
    );
  }
  
  return AIProcessingService(apiKey: apiKey);
});

// Task Repository Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final localDataSource = TaskLocalDataSourceImpl();
  return TaskRepositoryImpl(localDataSource: localDataSource);
});

// Create Task with AI Use Case Provider (async)
final createTaskWithAIProvider = FutureProvider<CreateTaskWithAI>((ref) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  final aiService = await ref.read(aiProcessingServiceProvider.future);
  
  return CreateTaskWithAI(
    taskRepository: taskRepository,
    aiService: aiService,
  );
});

// Gmail Data Source Provider (async)
final gmailDataSourceProvider = FutureProvider<GmailDataSource>((ref) async {
  final aiService = await ref.read(aiProcessingServiceProvider.future);
  return GmailDataSource(aiService: aiService);
});

// AI Processing State Management
class AIProcessingNotifier extends StateNotifier<bool> {
  AIProcessingNotifier(this._createTaskWithAI, this._gmailDataSource) : super(false);

  final CreateTaskWithAI _createTaskWithAI;
  final GmailDataSource _gmailDataSource;

  /// Process natural language text input and create tasks
  Future<TaskCreationResult?> processTextInput(String input) async {
    if (input.trim().isEmpty) return null;

    state = true;
    try {
      final result = await _createTaskWithAI.call(input);
      return result;
    } catch (e) {
      print('Error processing text input: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Process voice input and create tasks
  Future<TaskCreationResult?> processVoiceInput(String audioFilePath) async {
    state = true;
    try {
      final result = await _createTaskWithAI.createFromVoice(audioFilePath);
      return result;
    } catch (e) {
      print('Error processing voice input: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Scan emails and convert to tasks
  Future<void> scanEmails() async {
    state = true;
    try {
      final emailTasks = await _gmailDataSource.fetchActionableEmails(limit: 10);
      print('Found ${emailTasks.length} actionable emails');
      // Process each email task...
      for (final emailTask in emailTasks) {
        // Convert EmailTask to regular Task and save
        print('Processing email: ${emailTask.subject}');
      }
    } catch (e) {
      print('Error scanning emails: $e');
      rethrow;
    } finally {
      state = false;
    }
  }

  /// Handle overwhelmed state
  Future<void> handleOverwhelmedState() async {
    state = true;
    try {
      // Create simple, encouraging tasks
      await _createTaskWithAI.call('אני מרגיש המום, עזור לי עם משימות פשוטות');
    } catch (e) {
      print('Error handling overwhelmed state: $e');
      rethrow;
    } finally {
      state = false;
    }
  }
}

// AI Processing Provider
final aiTaskProcessingProvider = StateNotifierProvider<AIProcessingNotifier, bool>((ref) {
  final createTaskWithAI = ref.read(createTaskWithAIProvider);
  final gmailDataSource = ref.read(gmailDataSourceProvider);
  
  return AIProcessingNotifier(createTaskWithAI, gmailDataSource);
});

// Voice Input State Management
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

enum VoiceInputState {
  idle,
  listening,
  processing,
  error,
}

final voiceInputProvider = StateNotifierProvider<VoiceInputNotifier, VoiceInputState>((ref) {
  return VoiceInputNotifier();
});

// Smart Input State Management
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
