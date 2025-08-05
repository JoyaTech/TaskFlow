import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Comprehensive validation service for user input sanitization and security
/// 
/// This service provides protection against XSS attacks, SQL injection,
/// and ensures data integrity throughout the application.
class ValidationService {
  
  // Hebrew characters regex for proper validation
  static final RegExp _hebrewRegex = RegExp(r'[\u0590-\u05FF]');
  static final RegExp _dangerousCharsRegex = RegExp(r'[<>"\'%;()&+=`\\[\\]{}]|[\x00-\x1F]|[\x7F-\x9F]');
  static final RegExp _sqlInjectionRegex = RegExp(r'(\b(ALTER|CREATE|DELETE|DROP|EXEC(UTE){0,1}|INSERT( +INTO){0,1}|MERGE|SELECT|UPDATE|UNION( +ALL){0,1})\b)', caseSensitive: false);
  
  /// Sanitize user input to prevent XSS and injection attacks
  static String sanitizeUserInput(String input) {
    if (input.isEmpty) return input;
    
    try {
      String sanitized = input
          // Remove dangerous characters
          .replaceAll(_dangerousCharsRegex, '')
          // Remove potential SQL injection patterns
          .replaceAll(_sqlInjectionRegex, '')
          // Trim whitespace
          .trim();
      
      // Limit length to prevent memory issues
      const maxLength = 1000;
      if (sanitized.length > maxLength) {
        sanitized = sanitized.substring(0, maxLength);
        if (kDebugMode) {
          print('⚠️ Input truncated to $maxLength characters');
        }
      }
      
      return sanitized;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sanitizing input: $e');
      }
      return ''; // Return empty string on error for safety
    }
  }

  /// Sanitize Hebrew text specifically (for voice commands and task titles)
  static String sanitizeHebrewText(String input) {
    if (input.isEmpty) return input;
    
    try {
      // First apply general sanitization
      String sanitized = sanitizeUserInput(input);
      
      // Additional Hebrew-specific cleaning
      sanitized = sanitized
          // Remove multiple spaces
          .replaceAll(RegExp(r'\s+'), ' ')
          // Remove leading/trailing punctuation
          .replaceAll(RegExp(r'^[^\u0590-\u05FFa-zA-Z0-9]+|[^\u0590-\u05FFa-zA-Z0-9]+$'), '')
          .trim();
      
      return sanitized;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sanitizing Hebrew text: $e');
      }
      return '';
    }
  }

  /// Validate task title
  static bool isValidTaskTitle(String title) {
    if (title.isEmpty) return false;
    
    final sanitized = sanitizeHebrewText(title);
    return sanitized.length >= 1 && 
           sanitized.length <= 200 &&
           sanitized.isNotEmpty;
  }

  /// Validate task description
  static bool isValidTaskDescription(String description) {
    // Description can be empty
    if (description.isEmpty) return true;
    
    final sanitized = sanitizeUserInput(description);
    return sanitized.length <= 1000;
  }

  /// Validate voice command input
  static bool isValidVoiceCommand(String command) {
    if (command.isEmpty) return false;
    
    final sanitized = sanitizeHebrewText(command);
    return sanitized.length >= 2 && 
           sanitized.length <= 500 &&
           _hebrewRegex.hasMatch(sanitized); // Must contain Hebrew characters
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim()) && email.length <= 254;
  }

  /// Validate password strength (enhanced from AuthService)
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    
    // Must contain at least:
    // - One lowercase letter
    // - One uppercase letter  
    // - One number
    // - One special character
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasLower && hasUpper && hasNumber && hasSpecial;
  }

  /// Get password strength score (0-5)
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    return score;
  }

  /// Get password strength text in Hebrew
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'חלשה מאוד';
      case 2:
        return 'חלשה';
      case 3:
        return 'בינונית';
      case 4:
        return 'חזקה';
      case 5:
        return 'מאוד חזקה';
      default:
        return 'לא תקינה';
    }
  }

  /// Validate API key format
  static bool isValidApiKey(String apiKey, String type) {
    if (apiKey.trim().isEmpty) return false;
    
    // Remove any whitespace
    apiKey = apiKey.trim();
    
    switch (type.toLowerCase()) {
      case 'gemini':
        return apiKey.startsWith('AIza') && 
               apiKey.length > 30 && 
               apiKey.length < 100 &&
               RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(apiKey);
               
      case 'openai':
        return apiKey.startsWith('sk-') && 
               apiKey.length > 40 && 
               apiKey.length < 200 &&
               RegExp(r'^sk-[A-Za-z0-9]+$').hasMatch(apiKey);
               
      case 'google':
        return apiKey.startsWith('AIza') && 
               apiKey.length > 30 && 
               apiKey.length < 100 &&
               RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(apiKey);
               
      default:
        return apiKey.length > 10 && 
               apiKey.length < 500 &&
               !_dangerousCharsRegex.hasMatch(apiKey);
    }
  }

  /// Validate user display name
  static bool isValidDisplayName(String name) {
    if (name.isEmpty) return false;
    
    final sanitized = sanitizeHebrewText(name);
    return sanitized.length >= 2 && 
           sanitized.length <= 50 &&
           // Can contain Hebrew, English, spaces, and basic punctuation
           RegExp(r'^[\u0590-\u05FFa-zA-Z0-9\s\-\.]+$').hasMatch(sanitized);
  }

  /// Sanitize and validate date/time input
  static DateTime? validateDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;
    
    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 3650)); // 10 years
    final minPastDate = now.subtract(const Duration(days: 365)); // 1 year ago
    
    // Ensure date is within reasonable bounds
    if (dateTime.isAfter(maxFutureDate) || dateTime.isBefore(minPastDate)) {
      if (kDebugMode) {
        print('⚠️ DateTime out of valid range: $dateTime');
      }
      return null;
    }
    
    return dateTime;
  }

  /// Check if input contains suspicious patterns
  static bool containsSuspiciousPatterns(String input) {
    if (input.isEmpty) return false;
    
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      _sqlInjectionRegex,
    ];
    
    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Rate limiting check (basic implementation)
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  
  static bool isRateLimited(String identifier, {int maxRequests = 10, Duration timeWindow = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final windowStart = now.subtract(timeWindow);
    
    // Clean old entries
    _rateLimitMap[identifier]?.removeWhere((time) => time.isBefore(windowStart));
    
    // Initialize if needed
    _rateLimitMap[identifier] ??= [];
    
    // Check if limit exceeded
    if (_rateLimitMap[identifier]!.length >= maxRequests) {
      if (kDebugMode) {
        print('⚠️ Rate limit exceeded for: $identifier');
      }
      return true;
    }
    
    // Add current request
    _rateLimitMap[identifier]!.add(now);
    return false;
  }

  /// Comprehensive input validation for task creation
  static Map<String, dynamic> validateTaskInput({
    required String title,
    String description = '',
    DateTime? dueDate,
    String? voiceNote,
  }) {
    final Map<String, dynamic> result = {
      'isValid': true,
      'errors': <String>[],
      'sanitizedData': <String, dynamic>{},
    };

    try {
      // Validate and sanitize title
      if (!isValidTaskTitle(title)) {
        result['isValid'] = false;
        result['errors'].add('כותרת המשימה לא תקינה');
      } else {
        result['sanitizedData']['title'] = sanitizeHebrewText(title);
      }

      // Validate and sanitize description
      if (!isValidTaskDescription(description)) {
        result['isValid'] = false;
        result['errors'].add('תיאור המשימה ארוך מדי');
      } else {
        result['sanitizedData']['description'] = sanitizeUserInput(description);
      }

      // Validate date
      final validatedDate = validateDateTime(dueDate);
      result['sanitizedData']['dueDate'] = validatedDate;

      // Validate and sanitize voice note
      if (voiceNote != null) {
        if (voiceNote.length > 2000) {
          result['isValid'] = false;
          result['errors'].add('הערת קול ארוכה מדי');
        } else {
          result['sanitizedData']['voiceNote'] = sanitizeHebrewText(voiceNote);
        }
      }

      // Check for suspicious patterns
      final allText = '$title $description ${voiceNote ?? ''}';
      if (containsSuspiciousPatterns(allText)) {
        result['isValid'] = false;
        result['errors'].add('הטקסט מכיל תוכן חשוד');
        
        if (kDebugMode) {
          print('🚨 Suspicious input detected: ${allText.substring(0, math.min(50, allText.length))}...');
        }
      }
      
    } catch (e) {
      result['isValid'] = false;
      result['errors'].add('שגיאה בולידציה: $e');
      
      if (kDebugMode) {
        print('❌ Task validation error: $e');
      }
    }

    return result;
  }

  /// Clean up rate limiting data (call periodically)
  static void cleanupRateLimitData() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    _rateLimitMap.removeWhere((key, times) {
      times.removeWhere((time) => time.isBefore(oneHourAgo));
      return times.isEmpty;
    });
    
    if (kDebugMode) {
      print('🧹 Rate limit data cleaned up');
    }
  }
}
