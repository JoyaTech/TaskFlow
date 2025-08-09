/// Represents a Google Drive file that can be linked to tasks
/// Includes metadata, sharing information, and task relationships
class DriveFile {
  final String id;
  final String name;
  final String mimeType;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? webViewLink;
  final String? iconLink;
  final int? size;
  final bool isFolder;
  final List<String> owners;
  final bool isShared;
  
  // Task relationship
  final String? linkedTaskId;
  final DateTime? linkedAt;
  final bool isTaskRelevant;

  DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.createdAt,
    required this.modifiedAt,
    this.webViewLink,
    this.iconLink,
    this.size,
    this.isFolder = false,
    this.owners = const [],
    this.isShared = false,
    this.linkedTaskId,
    this.linkedAt,
    this.isTaskRelevant = false,
  });

  /// Create a copy with updated values
  DriveFile copyWith({
    String? id,
    String? name,
    String? mimeType,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? webViewLink,
    String? iconLink,
    int? size,
    bool? isFolder,
    List<String>? owners,
    bool? isShared,
    String? linkedTaskId,
    DateTime? linkedAt,
    bool? isTaskRelevant,
  }) {
    return DriveFile(
      id: id ?? this.id,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      webViewLink: webViewLink ?? this.webViewLink,
      iconLink: iconLink ?? this.iconLink,
      size: size ?? this.size,
      isFolder: isFolder ?? this.isFolder,
      owners: owners ?? this.owners,
      isShared: isShared ?? this.isShared,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      linkedAt: linkedAt ?? this.linkedAt,
      isTaskRelevant: isTaskRelevant ?? this.isTaskRelevant,
    );
  }

  /// Get human-readable file type
  String get fileType {
    switch (mimeType) {
      case 'application/vnd.google-apps.document':
        return 'Google Doc';
      case 'application/vnd.google-apps.spreadsheet':
        return 'Google Sheets';
      case 'application/vnd.google-apps.presentation':
        return 'Google Slides';
      case 'application/vnd.google-apps.folder':
        return 'Folder';
      case 'application/pdf':
        return 'PDF';
      case 'text/plain':
        return 'Text File';
      case 'image/jpeg':
      case 'image/png':
      case 'image/gif':
        return 'Image';
      default:
        if (mimeType.startsWith('image/')) return 'Image';
        if (mimeType.startsWith('video/')) return 'Video';
        if (mimeType.startsWith('audio/')) return 'Audio';
        return 'File';
    }
  }

  /// Get formatted file size
  String get formattedSize {
    if (size == null) return 'Unknown size';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double fileSize = size!.toDouble();
    int unitIndex = 0;
    
    while (fileSize >= 1024 && unitIndex < units.length - 1) {
      fileSize /= 1024;
      unitIndex++;
    }
    
    return '${fileSize.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  /// Check if file is a Google Workspace document
  bool get isGoogleWorkspaceDoc => mimeType.startsWith('application/vnd.google-apps.');

  /// Check if file can be previewed
  bool get canPreview {
    return isGoogleWorkspaceDoc || 
           mimeType == 'application/pdf' ||
           mimeType.startsWith('image/') ||
           mimeType.startsWith('text/');
  }

  /// Check if file is recently modified (within last 7 days)
  bool get isRecentlyModified {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return modifiedAt.isAfter(weekAgo);
  }

  /// Check if file is linked to a task
  bool get isLinkedToTask => linkedTaskId != null;

  /// Get file icon based on type
  String get iconName {
    if (isFolder) return 'folder';
    
    switch (mimeType) {
      case 'application/vnd.google-apps.document':
        return 'description'; // Document icon
      case 'application/vnd.google-apps.spreadsheet':
        return 'grid_on'; // Spreadsheet icon
      case 'application/vnd.google-apps.presentation':
        return 'slideshow'; // Presentation icon
      case 'application/pdf':
        return 'picture_as_pdf';
      case 'text/plain':
        return 'text_snippet';
      default:
        if (mimeType.startsWith('image/')) return 'image';
        if (mimeType.startsWith('video/')) return 'video_file';
        if (mimeType.startsWith('audio/')) return 'audio_file';
        return 'insert_drive_file';
    }
  }

  /// Get primary owner name
  String get primaryOwner {
    return owners.isNotEmpty ? owners.first : 'Unknown';
  }

  /// Check if file has task-relevant keywords in name
  bool get hasTaskKeywords {
    final lowerName = name.toLowerCase();
    final taskKeywords = [
      'task', 'todo', 'action', 'meeting', 'project', 
      'agenda', 'notes', 'deadline', 'assignment', 'work'
    ];
    
    return taskKeywords.any((keyword) => lowerName.contains(keyword));
  }

  /// Get relevance score for task association (0.0 - 1.0)
  double get taskRelevanceScore {
    double score = 0.0;
    
    // Name-based scoring
    if (hasTaskKeywords) score += 0.3;
    
    // Type-based scoring
    if (isGoogleWorkspaceDoc) score += 0.2;
    if (mimeType == 'text/plain') score += 0.1;
    
    // Recency bonus
    if (isRecentlyModified) score += 0.2;
    
    // Shared files are often work-related
    if (isShared) score += 0.1;
    
    // Already linked files get high score
    if (isLinkedToTask) score += 0.3;
    
    return score.clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriveFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DriveFile(id: $id, name: $name, type: $fileType, '
           'linked: $isLinkedToTask)';
  }
}
