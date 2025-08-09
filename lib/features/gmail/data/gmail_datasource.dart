// Stub file for Gmail Data Source
import '../../../core/services/ai_processing_service.dart';

class EmailTask {
  final String subject;
  final String content;
  final String sender;
  
  EmailTask({
    required this.subject,
    required this.content,
    required this.sender,
  });
}

class GmailDataSource {
  final AIProcessingService aiService;

  GmailDataSource({required this.aiService});

  Future<List<EmailTask>> fetchActionableEmails({int limit = 10}) async {
    // Stub implementation - return empty list for now
    return [];
  }
}
