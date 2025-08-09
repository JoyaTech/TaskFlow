import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// AI Processing Service that integrates with OpenAI APIs
/// Handles voice-to-text, intent recognition, and structured data extraction
class AIProcessingService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  late final String _apiKey;
  
  AIProcessingService({required String apiKey}) : _apiKey = apiKey;

  /// Process voice input using Whisper API for speech-to-text
  Future<String> processVoiceToText(File audioFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audio/transcriptions'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });

      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'he'; // Hebrew language
      request.fields['response_format'] = 'json';

      request.files.add(
        await http.MultipartFile.fromPath('file', audioFile.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['text'] ?? '';
      } else {
        throw AIProcessingException(
          'Whisper API Error: ${response.statusCode} - $responseBody',
        );
      }
    } catch (e) {
      throw AIProcessingException('Failed to process voice input: $e');
    }
  }

  /// Analyze text using GPT for intent recognition and structured data extraction
  Future<AIAnalysisResult> analyzeTextIntent(String text) async {
    try {
      final systemPrompt = _buildSystemPrompt();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
          'max_tokens': 500,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final analysisJson = json.decode(content);
        
        return AIAnalysisResult.fromJson(analysisJson);
      } else {
        throw AIProcessingException(
          'GPT API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw AIProcessingException('Failed to analyze text intent: $e');
    }
  }

  /// Analyze emotional state and context from text
  Future<EmotionalAnalysis> analyzeEmotionalState(String text) async {
    try {
      final systemPrompt = _buildEmotionalAnalysisPrompt();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.2,
          'max_tokens': 300,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final content = jsonResponse['choices'][0]['message']['content'];
        final emotionalJson = json.decode(content);
        
        return EmotionalAnalysis.fromJson(emotionalJson);
      } else {
        throw AIProcessingException(
          'Emotional Analysis API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw AIProcessingException('Failed to analyze emotional state: $e');
    }
  }

  /// Build system prompt for intent recognition
  String _buildSystemPrompt() {
    return '''
You are an AI assistant specialized in analyzing Hebrew text for task management intent recognition. 
Your job is to extract structured data from user input for a task management app that supports ADHD users.

Analyze the input text and return a JSON response with the following structure:
{
  "intent": "create_task|edit_task|brain_dump|schedule_event|search_tasks|general_query",
  "confidence": 0.95,
  "extracted_data": {
    "title": "extracted task title",
    "description": "additional details if any",
    "due_date": "ISO 8601 format if mentioned (YYYY-MM-DDTHH:mm:ss)",
    "priority": "important|simple|later",
    "type": "task|event",
    "tags": ["tag1", "tag2"],
    "location": "location if mentioned",
    "duration_minutes": 60
  },
  "context_analysis": {
    "urgency_level": "high|medium|low",
    "complexity": "simple|moderate|complex",
    "requires_focus": true|false
  }
}

Guidelines:
- Support both Hebrew and English input
- Recognize time expressions like "היום" (today), "מחר" (tomorrow), "בשבוע הבא" (next week)
- Detect priority indicators like "דחוף" (urgent), "חשוב" (important)
- Extract locations, people names, and context clues
- If intent is unclear, use "general_query" with low confidence
- For brain dumps, detect stream-of-consciousness or emotional content
- Always include confidence score based on clarity of intent
''';
  }

  /// Build system prompt for emotional analysis
  String _buildEmotionalAnalysisPrompt() {
    return '''
You are an AI assistant specialized in emotional state analysis for ADHD task management.
Analyze the text for emotional indicators and return structured emotional intelligence data.

Return JSON with this structure:
{
  "emotional_state": {
    "primary_emotion": "overwhelmed|excited|frustrated|calm|anxious|motivated|tired",
    "intensity": 0.8,
    "secondary_emotions": ["stressed", "hopeful"]
  },
  "cognitive_load": {
    "level": "high|medium|low",
    "indicators": ["scattered thoughts", "many topics", "urgent language"]
  },
  "adhd_indicators": {
    "hyperfocus_state": true|false,
    "executive_dysfunction": true|false,
    "emotional_dysregulation": true|false,
    "overwhelm_level": 0.7
  },
  "recommendations": {
    "break_down_tasks": true|false,
    "suggest_break": true|false,
    "prioritize_simple_tasks": true|false,
    "provide_encouragement": true|false
  }
}

Guidelines:
- Detect overwhelm through scattered language, many topics, or urgent tone
- Identify hyperfocus through detailed, obsessive language about one topic
- Recognize executive dysfunction through procrastination language or decision paralysis
- Look for time pressure, perfectionism, or self-criticism
- Support both Hebrew and English emotional expressions
- Consider ADHD-specific challenges in emotional regulation
''';
  }
}

/// Result of AI text analysis with structured data
class AIAnalysisResult {
  final String intent;
  final double confidence;
  final ExtractedData extractedData;
  final ContextAnalysis contextAnalysis;

  AIAnalysisResult({
    required this.intent,
    required this.confidence,
    required this.extractedData,
    required this.contextAnalysis,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      intent: json['intent'] ?? 'general_query',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      extractedData: ExtractedData.fromJson(json['extracted_data'] ?? {}),
      contextAnalysis: ContextAnalysis.fromJson(json['context_analysis'] ?? {}),
    );
  }
}

/// Extracted structured data from user input
class ExtractedData {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final String? priority;
  final String? type;
  final List<String> tags;
  final String? location;
  final int? durationMinutes;

  ExtractedData({
    this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.type,
    this.tags = const [],
    this.location,
    this.durationMinutes,
  });

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      title: json['title'],
      description: json['description'],
      dueDate: json['due_date'] != null 
          ? DateTime.tryParse(json['due_date']) 
          : null,
      priority: json['priority'],
      type: json['type'],
      tags: List<String>.from(json['tags'] ?? []),
      location: json['location'],
      durationMinutes: json['duration_minutes'],
    );
  }
}

/// Context analysis of the user input
class ContextAnalysis {
  final String urgencyLevel;
  final String complexity;
  final bool requiresFocus;

  ContextAnalysis({
    required this.urgencyLevel,
    required this.complexity,
    required this.requiresFocus,
  });

  factory ContextAnalysis.fromJson(Map<String, dynamic> json) {
    return ContextAnalysis(
      urgencyLevel: json['urgency_level'] ?? 'low',
      complexity: json['complexity'] ?? 'simple',
      requiresFocus: json['requires_focus'] ?? false,
    );
  }
}

/// Emotional analysis result with ADHD-specific insights
class EmotionalAnalysis {
  final EmotionalState emotionalState;
  final CognitiveLoad cognitiveLoad;
  final ADHDIndicators adhdIndicators;
  final Recommendations recommendations;

  EmotionalAnalysis({
    required this.emotionalState,
    required this.cognitiveLoad,
    required this.adhdIndicators,
    required this.recommendations,
  });

  factory EmotionalAnalysis.fromJson(Map<String, dynamic> json) {
    return EmotionalAnalysis(
      emotionalState: EmotionalState.fromJson(json['emotional_state'] ?? {}),
      cognitiveLoad: CognitiveLoad.fromJson(json['cognitive_load'] ?? {}),
      adhdIndicators: ADHDIndicators.fromJson(json['adhd_indicators'] ?? {}),
      recommendations: Recommendations.fromJson(json['recommendations'] ?? {}),
    );
  }

  /// Check if user is in an overwhelmed state
  bool get isOverwhelmed => 
      adhdIndicators.overwhelmLevel > 0.6 || 
      emotionalState.primaryEmotion == 'overwhelmed';

  /// Check if user needs task breakdown support
  bool get needsTaskBreakdown =>
      recommendations.breakDownTasks ||
      cognitiveLoad.level == 'high' ||
      adhdIndicators.executiveDysfunction;
}

class EmotionalState {
  final String primaryEmotion;
  final double intensity;
  final List<String> secondaryEmotions;

  EmotionalState({
    required this.primaryEmotion,
    required this.intensity,
    required this.secondaryEmotions,
  });

  factory EmotionalState.fromJson(Map<String, dynamic> json) {
    return EmotionalState(
      primaryEmotion: json['primary_emotion'] ?? 'calm',
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      secondaryEmotions: List<String>.from(json['secondary_emotions'] ?? []),
    );
  }
}

class CognitiveLoad {
  final String level;
  final List<String> indicators;

  CognitiveLoad({
    required this.level,
    required this.indicators,
  });

  factory CognitiveLoad.fromJson(Map<String, dynamic> json) {
    return CognitiveLoad(
      level: json['level'] ?? 'low',
      indicators: List<String>.from(json['indicators'] ?? []),
    );
  }
}

class ADHDIndicators {
  final bool hyperfocusState;
  final bool executiveDysfunction;
  final bool emotionalDysregulation;
  final double overwhelmLevel;

  ADHDIndicators({
    required this.hyperfocusState,
    required this.executiveDysfunction,
    required this.emotionalDysregulation,
    required this.overwhelmLevel,
  });

  factory ADHDIndicators.fromJson(Map<String, dynamic> json) {
    return ADHDIndicators(
      hyperfocusState: json['hyperfocus_state'] ?? false,
      executiveDysfunction: json['executive_dysfunction'] ?? false,
      emotionalDysregulation: json['emotional_dysregulation'] ?? false,
      overwhelmLevel: (json['overwhelm_level'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Recommendations {
  final bool breakDownTasks;
  final bool suggestBreak;
  final bool prioritizeSimpleTasks;
  final bool provideEncouragement;

  Recommendations({
    required this.breakDownTasks,
    required this.suggestBreak,
    required this.prioritizeSimpleTasks,
    required this.provideEncouragement,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    return Recommendations(
      breakDownTasks: json['break_down_tasks'] ?? false,
      suggestBreak: json['suggest_break'] ?? false,
      prioritizeSimpleTasks: json['prioritize_simple_tasks'] ?? false,
      provideEncouragement: json['provide_encouragement'] ?? false,
    );
  }
}

/// Custom exception for AI processing errors
class AIProcessingException implements Exception {
  final String message;
  AIProcessingException(this.message);

  @override
  String toString() => 'AIProcessingException: $message';
}
