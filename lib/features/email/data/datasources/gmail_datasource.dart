import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/email_task.dart';
import '../../../../core/services/ai_processing_service.dart';

/// Gmail Data Source for email integration and task extraction
class GmailDataSource {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/gmail.labels',
  ];

  late GoogleSignIn _googleSignIn;
  late AIProcessingService _aiService;
  gmail.GmailApi? _gmailApi;
  GoogleSignInAccount? _currentUser;

  GmailDataSource({required AIProcessingService aiService}) 
      : _aiService = aiService {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  /// Initialize Gmail authentication
  Future<bool> initialize() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) {
        _currentUser = await _googleSignIn.signIn();
      }

      if (_currentUser != null) {
        final auth = await _currentUser!.authentication;
        final credentials = AccessCredentials(
          AccessToken(
            'Bearer',
            auth.accessToken!,
            DateTime.now().add(const Duration(hours: 1)),
          ),
          null,
          _scopes,
        );

        final client = authenticatedClient(http.Client(), credentials);
        _gmailApi = gmail.GmailApi(client);
        return true;
      }
      return false;
    } catch (e) {
      throw GmailException('Failed to initialize Gmail: $e');
    }
  }

  /// Get unread emails that could be converted to tasks
  Future<List<EmailTask>> getActionableEmails({
    int maxResults = 50,
    String? labelId,
  }) async {
    await _ensureAuthenticated();

    try {
      final query = _buildActionableEmailQuery();
      
      final listResponse = await _gmailApi!.users.messages.list(
        'me',
        q: query,
        maxResults: maxResults,
        labelIds: labelId != null ? [labelId] : null,
      );

      final emailTasks = <EmailTask>[];
      
      if (listResponse.messages != null) {
        for (final message in listResponse.messages!) {
          try {
            final emailTask = await _convertEmailToTask(message.id!);
            if (emailTask != null) {
              emailTasks.add(emailTask);
            }
          } catch (e) {
            // Skip individual email errors, continue processing
            print('Error processing email ${message.id}: $e');
          }
        }
      }

      return emailTasks;
    } catch (e) {
      throw GmailException('Failed to get actionable emails: $e');
    }
  }

  /// Convert email to task using AI analysis
  Future<EmailTask?> _convertEmailToTask(String messageId) async {
    try {
      final message = await _gmailApi!.users.messages.get('me', messageId);
      
      final emailContent = _extractEmailContent(message);
      final emailMetadata = _extractEmailMetadata(message);

      // Use AI to analyze if email is actionable
      final analysis = await _aiService.analyzeTextIntent(emailContent.body);
      
      // Only convert emails that AI identifies as actionable
      if (analysis.confidence < 0.6 || 
          !['create_task', 'schedule_event'].contains(analysis.intent)) {
        return null;
      }

      // Analyze emotional context for ADHD considerations  
      final emotionalAnalysis = await _aiService.analyzeEmotionalState(
        '${emailContent.subject}\n${emailContent.body}'
      );

      return EmailTask(
        id: messageId,
        messageId: messageId,
        threadId: message.threadId!,
        subject: emailContent.subject,
        body: emailContent.body,
        sender: emailMetadata.sender,
        receivedAt: emailMetadata.receivedAt,
        isUnread: emailMetadata.isUnread,
        labels: emailMetadata.labels,
        // AI-extracted task data
        suggestedTitle: analysis.extractedData.title ?? emailContent.subject,
        suggestedDescription: analysis.extractedData.description,
        suggestedDueDate: analysis.extractedData.dueDate,
        suggestedPriority: _mapAIPriorityToTaskPriority(
          analysis.extractedData.priority,
          analysis.contextAnalysis.urgencyLevel,
        ),
        suggestedTags: analysis.extractedData.tags,
        actionConfidence: analysis.confidence,
        // ADHD-specific insights
        requiresFocus: analysis.contextAnalysis.requiresFocus,
        complexityLevel: analysis.contextAnalysis.complexity,
        emotionalContext: emotionalAnalysis,
      );
    } catch (e) {
      throw GmailException('Failed to convert email to task: $e');
    }
  }

  /// Mark email as converted to task by adding custom label
  Future<void> markEmailAsConverted(String messageId, String taskId) async {
    await _ensureAuthenticated();

    try {
      // Get or create our custom label
      final labelId = await _getOrCreateLabel('MindFlow/Converted');
      
      await _gmailApi!.users.messages.modify(
        gmail.ModifyMessageRequest(
          addLabelIds: [labelId],
          removeLabelIds: ['UNREAD'], // Mark as read
        ),
        'me',
        messageId,
      );

      // Store the task ID in a custom header or metadata
      // This allows for bi-directional sync
      await _addTaskMetadata(messageId, taskId);
    } catch (e) {
      throw GmailException('Failed to mark email as converted: $e');
    }
  }

  /// Sync task updates back to email (add follow-up labels, etc.)
  Future<void> syncTaskStatusToEmail(String messageId, String status) async {
    await _ensureAuthenticated();

    try {
      final labelId = switch (status) {
        'completed' => await _getOrCreateLabel('MindFlow/Completed'),
        'in_progress' => await _getOrCreateLabel('MindFlow/InProgress'),
        'overdue' => await _getOrCreateLabel('MindFlow/Overdue'),
        _ => null,
      };

      if (labelId != null) {
        await _gmailApi!.users.messages.modify(
          gmail.ModifyMessageRequest(addLabelIds: [labelId]),
          'me',
          messageId,
        );
      }
    } catch (e) {
      throw GmailException('Failed to sync task status to email: $e');
    }
  }

  /// Watch for new emails that could become tasks
  Future<void> setupEmailWatch(String callbackUrl) async {
    await _ensureAuthenticated();

    try {
      final watchRequest = gmail.WatchRequest(
        labelIds: ['INBOX', 'UNREAD'],
        topicName: 'projects/your-project-id/topics/gmail-watch',
      );

      await _gmailApi!.users.watch(watchRequest, 'me');
    } catch (e) {
      throw GmailException('Failed to setup email watch: $e');
    }
  }

  /// Search emails with natural language query using AI
  Future<List<EmailTask>> searchEmailsWithAI(String naturalQuery) async {
    await _ensureAuthenticated();

    try {
      // Use AI to convert natural language to Gmail search query
      final analysis = await _aiService.analyzeTextIntent(naturalQuery);
      final searchQuery = _buildGmailSearchQuery(analysis);

      final listResponse = await _gmailApi!.users.messages.list(
        'me',
        q: searchQuery,
        maxResults: 20,
      );

      final results = <EmailTask>[];
      if (listResponse.messages != null) {
        for (final message in listResponse.messages!) {
          final emailTask = await _convertEmailToTask(message.id!);
          if (emailTask != null) {
            results.add(emailTask);
          }
        }
      }

      return results;
    } catch (e) {
      throw GmailException('Failed to search emails with AI: $e');
    }
  }

  // Helper methods

  Future<void> _ensureAuthenticated() async {
    if (_gmailApi == null || _currentUser == null) {
      final success = await initialize();
      if (!success) {
        throw GmailException('Gmail authentication failed');
      }
    }
  }

  String _buildActionableEmailQuery() {
    return 'is:unread -from:noreply -from:no-reply has:attachment OR '
           'subject:(action required OR please review OR urgent OR deadline OR '
           'meeting OR appointment OR reminder OR todo OR task OR follow up)';
  }

  EmailContent _extractEmailContent(gmail.Message message) {
    String subject = '';
    String body = '';

    // Extract subject
    final headers = message.payload?.headers ?? [];
    for (final header in headers) {
      if (header.name?.toLowerCase() == 'subject') {
        subject = header.value ?? '';
        break;
      }
    }

    // Extract body
    if (message.payload?.parts != null) {
      for (final part in message.payload!.parts!) {
        if (part.mimeType == 'text/plain' || part.mimeType == 'text/html') {
          if (part.body?.data != null) {
            body = utf8.decode(base64Url.decode(part.body!.data!));
            break;
          }
        }
      }
    } else if (message.payload?.body?.data != null) {
      body = utf8.decode(base64Url.decode(message.payload!.body!.data!));
    }

    return EmailContent(subject: subject, body: body);
  }

  EmailMetadata _extractEmailMetadata(gmail.Message message) {
    final headers = message.payload?.headers ?? [];
    String sender = '';
    DateTime? receivedAt;

    for (final header in headers) {
      switch (header.name?.toLowerCase()) {
        case 'from':
          sender = header.value ?? '';
          break;
        case 'date':
          receivedAt = DateTime.tryParse(header.value ?? '');
          break;
      }
    }

    return EmailMetadata(
      sender: sender,
      receivedAt: receivedAt ?? DateTime.now(),
      isUnread: message.labelIds?.contains('UNREAD') ?? false,
      labels: message.labelIds ?? [],
    );
  }

  String _mapAIPriorityToTaskPriority(String? aiPriority, String urgencyLevel) {
    if (urgencyLevel == 'high' || aiPriority == 'important') {
      return 'important';
    } else if (urgencyLevel == 'low' || aiPriority == 'later') {
      return 'later';
    }
    return 'simple';
  }

  String _buildGmailSearchQuery(AIAnalysisResult analysis) {
    final parts = <String>[];

    if (analysis.extractedData.title != null) {
      parts.add('subject:${analysis.extractedData.title}');
    }

    if (analysis.extractedData.tags.isNotEmpty) {
      for (final tag in analysis.extractedData.tags) {
        parts.add('($tag)');
      }
    }

    if (analysis.contextAnalysis.urgencyLevel == 'high') {
      parts.add('(urgent OR priority OR asap)');
    }

    return parts.isNotEmpty ? parts.join(' ') : 'is:unread';
  }

  Future<String> _getOrCreateLabel(String labelName) async {
    try {
      final labelsResponse = await _gmailApi!.users.labels.list('me');
      
      // Check if label exists
      for (final label in labelsResponse.labels ?? []) {
        if (label.name == labelName) {
          return label.id!;
        }
      }

      // Create new label
      final newLabel = await _gmailApi!.users.labels.create(
        gmail.Label(
          name: labelName,
          labelListVisibility: 'labelShow',
          messageListVisibility: 'show',
        ),
        'me',
      );

      return newLabel.id!;
    } catch (e) {
      throw GmailException('Failed to get or create label: $e');
    }
  }

  Future<void> _addTaskMetadata(String messageId, String taskId) async {
    // Store task metadata in a way that survives email operations
    // This could be done through custom headers in replies or 
    // through external storage linked by messageId
    // Implementation depends on your specific sync requirements
  }
}

/// Email content extraction result
class EmailContent {
  final String subject;
  final String body;

  EmailContent({required this.subject, required this.body});
}

/// Email metadata extraction result  
class EmailMetadata {
  final String sender;
  final DateTime receivedAt;
  final bool isUnread;
  final List<String> labels;

  EmailMetadata({
    required this.sender,
    required this.receivedAt,
    required this.isUnread,
    required this.labels,
  });
}

/// Custom exception for Gmail operations
class GmailException implements Exception {
  final String message;
  GmailException(this.message);

  @override
  String toString() => 'GmailException: $message';
}
