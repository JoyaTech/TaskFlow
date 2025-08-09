import '../../../../core/services/ai_processing_service.dart';

/// Represents an actionable email that can be converted to a task
/// Enhanced with AI-extracted data and ADHD-specific context
class EmailTask {
  final String id;
  final String messageId;
  final String threadId;
  final String subject;
  final String body;
  final String sender;
  final DateTime receivedAt;
  final bool isUnread;
  final List<String> labels;

  // AI-extracted task suggestions
  final String suggestedTitle;
  final String? suggestedDescription;
  final DateTime? suggestedDueDate;
  final String suggestedPriority; // 'important', 'simple', 'later'
  final List<String> suggestedTags;
  final double actionConfidence; // 0.0 - 1.0

  // ADHD-specific context
  final bool requiresFocus;
  final String complexityLevel; // 'simple', 'moderate', 'complex'
  final EmotionalAnalysis emotionalContext;

  // Conversion state
  final bool isConverted;
  final String? linkedTaskId;
  final DateTime? convertedAt;

  EmailTask({
    required this.id,
    required this.messageId,
    required this.threadId,
    required this.subject,
    required this.body,
    required this.sender,
    required this.receivedAt,
    required this.isUnread,
    required this.labels,
    required this.suggestedTitle,
    this.suggestedDescription,
    this.suggestedDueDate,
    required this.suggestedPriority,
    required this.suggestedTags,
    required this.actionConfidence,
    required this.requiresFocus,
    required this.complexityLevel,
    required this.emotionalContext,
    this.isConverted = false,
    this.linkedTaskId,
    this.convertedAt,
  });

  /// Create a copy with updated values
  EmailTask copyWith({
    String? id,
    String? messageId,
    String? threadId,
    String? subject,
    String? body,
    String? sender,
    DateTime? receivedAt,
    bool? isUnread,
    List<String>? labels,
    String? suggestedTitle,
    String? suggestedDescription,
    DateTime? suggestedDueDate,
    String? suggestedPriority,
    List<String>? suggestedTags,
    double? actionConfidence,
    bool? requiresFocus,
    String? complexityLevel,
    EmotionalAnalysis? emotionalContext,
    bool? isConverted,
    String? linkedTaskId,
    DateTime? convertedAt,
  }) {
    return EmailTask(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      threadId: threadId ?? this.threadId,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      isUnread: isUnread ?? this.isUnread,
      labels: labels ?? this.labels,
      suggestedTitle: suggestedTitle ?? this.suggestedTitle,
      suggestedDescription: suggestedDescription ?? this.suggestedDescription,
      suggestedDueDate: suggestedDueDate ?? this.suggestedDueDate,
      suggestedPriority: suggestedPriority ?? this.suggestedPriority,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      actionConfidence: actionConfidence ?? this.actionConfidence,
      requiresFocus: requiresFocus ?? this.requiresFocus,
      complexityLevel: complexityLevel ?? this.complexityLevel,
      emotionalContext: emotionalContext ?? this.emotionalContext,
      isConverted: isConverted ?? this.isConverted,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      convertedAt: convertedAt ?? this.convertedAt,
    );
  }

  /// Check if this email task is high priority
  bool get isHighPriority => 
      suggestedPriority == 'important' || 
      actionConfidence > 0.8 ||
      emotionalContext.isOverwhelmed;

  /// Check if this email task should be simplified for ADHD users
  bool get shouldSimplify =>
      emotionalContext.needsTaskBreakdown ||
      complexityLevel == 'complex' ||
      requiresFocus;

  /// Get ADHD-friendly task breakdown suggestions
  List<String> get adhdBreakdownSuggestions {
    if (!shouldSimplify) return [];

    final suggestions = <String>[];

    if (requiresFocus) {
      suggestions.add('Schedule focused time for this task');
    }

    if (complexityLevel == 'complex') {
      suggestions.add('Break this into smaller sub-tasks');
    }

    if (emotionalContext.recommendations.suggestBreak) {
      suggestions.add('Take a break before tackling this');
    }

    if (emotionalContext.recommendations.provideEncouragement) {
      suggestions.add('You got this! Start with the easiest part');
    }

    return suggestions;
  }

  /// Get the sender's name without email address
  String get senderName {
    final match = RegExp(r'^([^<]+)<').firstMatch(sender);
    if (match != null) {
      return match.group(1)?.trim() ?? sender;
    }
    return sender.split('@').first;
  }

  /// Get a preview of the email body (first 200 characters)
  String get bodyPreview {
    final cleanBody = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanBody.length > 200 
        ? '${cleanBody.substring(0, 200)}...'
        : cleanBody;
  }

  /// Check if this email is urgent based on content analysis
  bool get isUrgent {
    final urgentKeywords = [
      'urgent', 'asap', 'immediately', 'deadline',
      'critical', 'important', 'emergency'
    ];
    
    final lowerSubject = subject.toLowerCase();
    final lowerBody = body.toLowerCase();
    
    return urgentKeywords.any((keyword) =>
        lowerSubject.contains(keyword) || lowerBody.contains(keyword));
  }

  /// Get recommended action time based on ADHD context
  String get recommendedActionTime {
    if (emotionalContext.isOverwhelmed) {
      return 'When feeling calmer';
    }
    
    if (requiresFocus && emotionalContext.adhdIndicators.hyperfocusState) {
      return 'During current focus session';
    }
    
    if (isUrgent) {
      return 'Within 2 hours';
    }
    
    if (suggestedDueDate != null) {
      final daysUntilDue = suggestedDueDate!.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 1) {
        return 'Today';
      } else if (daysUntilDue <= 3) {
        return 'This week';
      }
    }
    
    return 'When energy allows';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmailTask && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;

  @override
  String toString() {
    return 'EmailTask(messageId: $messageId, subject: $subject, '
           'confidence: $actionConfidence, priority: $suggestedPriority)';
  }
}
