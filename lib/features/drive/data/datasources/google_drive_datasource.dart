import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/drive_file.dart';
import '../../../../core/services/ai_processing_service.dart';

/// Google Drive Data Source for document and file integration
/// Provides file management, task-document linking, and AI-powered content analysis
class GoogleDriveDataSource {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.metadata',
  ];

  late GoogleSignIn _googleSignIn;
  late AIProcessingService _aiService;
  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;

  GoogleDriveDataSource({required AIProcessingService aiService})
      : _aiService = aiService {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );
  }

  /// Initialize Google Drive authentication
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
        _driveApi = drive.DriveApi(client);
        return true;
      }
      return false;
    } catch (e) {
      throw DriveException('Failed to initialize Google Drive: $e');
    }
  }

  /// Get files that could be linked to tasks
  Future<List<DriveFile>> getTaskRelevantFiles({
    String? query,
    int maxResults = 50,
  }) async {
    await _ensureAuthenticated();

    try {
      String searchQuery = query ?? _buildTaskRelevantQuery();

      final listResponse = await _driveApi!.files.list(
        q: searchQuery,
        pageSize: maxResults,
        fields: 'files(id,name,mimeType,createdTime,modifiedTime,owners,parents,webViewLink,iconLink,size)',
        orderBy: 'modifiedTime desc',
      );

      final driveFiles = <DriveFile>[];
      
      if (listResponse.files != null) {
        for (final file in listResponse.files!) {
          try {
            final driveFile = await _convertToDriveFile(file);
            driveFiles.add(driveFile);
          } catch (e) {
            // Skip individual file errors, continue processing
            print('Error processing file ${file.id}: $e');
          }
        }
      }

      return driveFiles;
    } catch (e) {
      throw DriveException('Failed to get task relevant files: $e');
    }
  }

  /// Analyze document content for task extraction using AI
  Future<DocumentAnalysis> analyzeDocumentContent(String fileId) async {
    await _ensureAuthenticated();

    try {
      // Get file metadata
      final file = await _driveApi!.files.get(fileId);
      
      // Extract text content based on file type
      String content = '';
      
      if (file.mimeType == 'application/vnd.google-apps.document') {
        content = await _extractGoogleDocContent(fileId);
      } else if (file.mimeType == 'text/plain' || 
                 file.mimeType?.startsWith('text/') == true) {
        content = await _extractTextFileContent(fileId);
      } else if (file.mimeType?.startsWith('application/') == true) {
        // For other file types, use OCR or skip
        content = await _extractWithOCR(fileId);
      }

      if (content.isEmpty) {
        throw DriveException('No extractable content found in file');
      }

      // Analyze content with AI
      final intentAnalysis = await _aiService.analyzeTextIntent(content);
      final emotionalAnalysis = await _aiService.analyzeEmotionalState(content);

      return DocumentAnalysis(
        fileId: fileId,
        fileName: file.name ?? 'Unknown',
        contentPreview: content.length > 500 
            ? '${content.substring(0, 500)}...' 
            : content,
        extractedTasks: _extractTasksFromAnalysis(intentAnalysis),
        keyTopics: _extractKeyTopics(content, intentAnalysis),
        urgencyIndicators: _extractUrgencyIndicators(intentAnalysis),
        emotionalContext: emotionalAnalysis,
        lastAnalyzed: DateTime.now(),
      );
    } catch (e) {
      throw DriveException('Failed to analyze document content: $e');
    }
  }

  /// Create a new folder for organizing task-related documents
  Future<String> createTaskFolder(String taskId, String taskTitle) async {
    await _ensureAuthenticated();

    try {
      // Create a folder with task-specific name
      final folderName = 'MindFlow Task: $taskTitle';
      
      final folder = drive.File(
        name: folderName,
        mimeType: 'application/vnd.google-apps.folder',
        description: 'Documents and files related to task ID: $taskId',
      );

      final createdFolder = await _driveApi!.files.create(folder);
      
      // Set folder to be shared appropriately
      await _setFolderPermissions(createdFolder.id!);

      return createdFolder.id!;
    } catch (e) {
      throw DriveException('Failed to create task folder: $e');
    }
  }

  /// Link a document to a specific task
  Future<void> linkDocumentToTask(String fileId, String taskId) async {
    await _ensureAuthenticated();

    try {
      // Add custom properties to link file to task
      final file = drive.File(
        properties: {
          'mindflow_task_id': taskId,
          'mindflow_linked_at': DateTime.now().toIso8601String(),
        },
      );

      await _driveApi!.files.update(file, fileId);
    } catch (e) {
      throw DriveException('Failed to link document to task: $e');
    }
  }

  /// Get all documents linked to a specific task
  Future<List<DriveFile>> getTaskLinkedDocuments(String taskId) async {
    await _ensureAuthenticated();

    try {
      final searchQuery = "properties has {key='mindflow_task_id' and value='$taskId'}";
      
      final listResponse = await _driveApi!.files.list(
        q: searchQuery,
        fields: 'files(id,name,mimeType,createdTime,modifiedTime,webViewLink,iconLink)',
      );

      final linkedFiles = <DriveFile>[];
      
      if (listResponse.files != null) {
        for (final file in listResponse.files!) {
          final driveFile = await _convertToDriveFile(file);
          linkedFiles.add(driveFile);
        }
      }

      return linkedFiles;
    } catch (e) {
      throw DriveException('Failed to get task linked documents: $e');
    }
  }

  /// Upload a file and link it to a task
  Future<String> uploadFileForTask(
    File file,
    String fileName,
    String taskId, {
    String? folderId,
  }) async {
    await _ensureAuthenticated();

    try {
      final media = drive.Media(file.openRead(), file.lengthSync());
      
      final driveFile = drive.File(
        name: fileName,
        parents: folderId != null ? [folderId] : null,
        properties: {
          'mindflow_task_id': taskId,
          'mindflow_uploaded_at': DateTime.now().toIso8601String(),
        },
      );

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return uploadedFile.id!;
    } catch (e) {
      throw DriveException('Failed to upload file for task: $e');
    }
  }

  /// Search documents using natural language query
  Future<List<DriveFile>> searchDocumentsWithAI(String naturalQuery) async {
    await _ensureAuthenticated();

    try {
      // Use AI to enhance search query
      final analysis = await _aiService.analyzeTextIntent(naturalQuery);
      final enhancedQuery = _buildEnhancedSearchQuery(analysis, naturalQuery);

      final listResponse = await _driveApi!.files.list(
        q: enhancedQuery,
        pageSize: 20,
        fields: 'files(id,name,mimeType,createdTime,modifiedTime,webViewLink)',
        orderBy: 'relevance',
      );

      final searchResults = <DriveFile>[];
      
      if (listResponse.files != null) {
        for (final file in listResponse.files!) {
          final driveFile = await _convertToDriveFile(file);
          searchResults.add(driveFile);
        }
      }

      return searchResults;
    } catch (e) {
      throw DriveException('Failed to search documents with AI: $e');
    }
  }

  /// Watch for changes in task-related files
  Future<void> setupFileWatch(String taskId, String callbackUrl) async {
    await _ensureAuthenticated();

    try {
      final watchRequest = drive.Channel(
        id: 'mindflow_task_$taskId',
        type: 'web_hook',
        address: callbackUrl,
      );

      await _driveApi!.files.watch(watchRequest, 'root');
    } catch (e) {
      throw DriveException('Failed to setup file watch: $e');
    }
  }

  // Helper methods

  Future<void> _ensureAuthenticated() async {
    if (_driveApi == null || _currentUser == null) {
      final success = await initialize();
      if (!success) {
        throw DriveException('Google Drive authentication failed');
      }
    }
  }

  String _buildTaskRelevantQuery() {
    return "mimeType contains 'document' or "
           "mimeType contains 'spreadsheet' or "
           "mimeType contains 'presentation' or "
           "mimeType = 'text/plain' or "
           "name contains 'task' or "
           "name contains 'todo' or "
           "name contains 'project' or "
           "name contains 'meeting' or "
           "fullText contains 'deadline' or "
           "fullText contains 'action items'";
  }

  Future<DriveFile> _convertToDriveFile(drive.File file) async {
    return DriveFile(
      id: file.id!,
      name: file.name ?? 'Unknown',
      mimeType: file.mimeType ?? 'unknown',
      createdAt: file.createdTime ?? DateTime.now(),
      modifiedAt: file.modifiedTime ?? DateTime.now(),
      webViewLink: file.webViewLink,
      iconLink: file.iconLink,
      size: file.size?.toInt(),
      isFolder: file.mimeType == 'application/vnd.google-apps.folder',
      owners: file.owners?.map((owner) => owner.displayName ?? '').toList() ?? [],
      isShared: file.shared ?? false,
    );
  }

  Future<String> _extractGoogleDocContent(String fileId) async {
    try {
      final exportResponse = await _driveApi!.files.export(
        fileId,
        'text/plain',
      );
      
      return await exportResponse.stream.bytesToString();
    } catch (e) {
      throw DriveException('Failed to extract Google Doc content: $e');
    }
  }

  Future<String> _extractTextFileContent(String fileId) async {
    try {
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      
      return await response.stream.bytesToString();
    } catch (e) {
      throw DriveException('Failed to extract text file content: $e');
    }
  }

  Future<String> _extractWithOCR(String fileId) async {
    // Placeholder for OCR integration
    // Could integrate with Google Vision API or similar
    return '';
  }

  List<TaskSuggestion> _extractTasksFromAnalysis(AIAnalysisResult analysis) {
    final tasks = <TaskSuggestion>[];
    
    if (analysis.intent == 'create_task' && analysis.confidence > 0.6) {
      tasks.add(TaskSuggestion(
        title: analysis.extractedData.title ?? 'Untitled Task',
        description: analysis.extractedData.description,
        dueDate: analysis.extractedData.dueDate,
        priority: analysis.extractedData.priority ?? 'simple',
        tags: analysis.extractedData.tags,
        confidence: analysis.confidence,
      ));
    }

    return tasks;
  }

  List<String> _extractKeyTopics(String content, AIAnalysisResult analysis) {
    final topics = <String>[];
    
    // Extract from AI analysis
    topics.addAll(analysis.extractedData.tags);
    
    // Simple keyword extraction
    final words = content.toLowerCase().split(RegExp(r'\W+'));
    final commonWords = ['project', 'meeting', 'deadline', 'task', 'action', 'review'];
    
    for (final word in commonWords) {
      if (words.contains(word)) {
        topics.add(word);
      }
    }

    return topics.toSet().toList();
  }

  List<String> _extractUrgencyIndicators(AIAnalysisResult analysis) {
    final indicators = <String>[];
    
    if (analysis.contextAnalysis.urgencyLevel == 'high') {
      indicators.add('High urgency detected');
    }
    
    if (analysis.extractedData.dueDate != null) {
      final daysUntilDue = analysis.extractedData.dueDate!
          .difference(DateTime.now()).inDays;
      if (daysUntilDue <= 1) {
        indicators.add('Due within 24 hours');
      } else if (daysUntilDue <= 7) {
        indicators.add('Due this week');
      }
    }

    return indicators;
  }

  String _buildEnhancedSearchQuery(AIAnalysisResult analysis, String originalQuery) {
    final queryParts = <String>[originalQuery];
    
    if (analysis.extractedData.tags.isNotEmpty) {
      for (final tag in analysis.extractedData.tags) {
        queryParts.add('fullText:"$tag"');
      }
    }
    
    if (analysis.extractedData.type == 'event') {
      queryParts.add('(fullText:"meeting" or fullText:"appointment")');
    }

    return queryParts.join(' or ');
  }

  Future<void> _setFolderPermissions(String folderId) async {
    // Set appropriate sharing permissions for the task folder
    // This could be customized based on team/organization needs
  }
}

/// Document analysis result with AI-extracted insights
class DocumentAnalysis {
  final String fileId;
  final String fileName;
  final String contentPreview;
  final List<TaskSuggestion> extractedTasks;
  final List<String> keyTopics;
  final List<String> urgencyIndicators;
  final EmotionalAnalysis emotionalContext;
  final DateTime lastAnalyzed;

  DocumentAnalysis({
    required this.fileId,
    required this.fileName,
    required this.contentPreview,
    required this.extractedTasks,
    required this.keyTopics,
    required this.urgencyIndicators,
    required this.emotionalContext,
    required this.lastAnalyzed,
  });
}

/// Task suggestion extracted from document
class TaskSuggestion {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String priority;
  final List<String> tags;
  final double confidence;

  TaskSuggestion({
    required this.title,
    this.description,
    this.dueDate,
    required this.priority,
    required this.tags,
    required this.confidence,
  });
}

/// Custom exception for Drive operations
class DriveException implements Exception {
  final String message;
  DriveException(this.message);

  @override
  String toString() => 'DriveException: $message';
}
