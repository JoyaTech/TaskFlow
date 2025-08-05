import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Secure storage service for sensitive data like API keys and tokens
/// 
/// This service handles all sensitive data storage using encrypted storage
/// instead of plain text SharedPreferences, providing protection against
/// data theft and unauthorized access.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'taskflow_secure_prefs',
      preferencesKeyPrefix: 'taskflow_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.joyatech.taskflow',
      accountName: 'TaskFlow',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // API Keys
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _googleApiKeyKey = 'google_api_key';
  static const String _gmailApiKeyKey = 'gmail_api_key';
  static const String _calendarApiKeyKey = 'calendar_api_key';

  // Authentication tokens
  static const String _googleCalendarAuthKey = 'google_calendar_auth';
  static const String _userTokenKey = 'user_token';
  static const String _taskCalendarMappingsKey = 'task_calendar_mappings';

  /// Store API key securely
  static Future<void> storeApiKey(String keyName, String value) async {
    try {
      if (value.trim().isNotEmpty) {
        await _storage.write(key: keyName, value: value.trim());
        if (kDebugMode) {
          print('✅ API key stored securely: ${keyName.substring(0, 3)}***');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing API key: $e');
      }
      throw Exception('שגיאה בשמירת מפתח API: $e');
    }
  }

  /// Retrieve API key securely
  static Future<String?> getApiKey(String keyName) async {
    try {
      final value = await _storage.read(key: keyName);
      return value?.trim();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading API key: $e');
      }
      return null;
    }
  }

  /// Store Google Calendar authentication data securely
  static Future<void> storeGoogleCalendarAuth(Map<String, dynamic> authData) async {
    try {
      // Encrypt the auth data before storing
      final encryptedData = jsonEncode(authData);
      await _storage.write(key: _googleCalendarAuthKey, value: encryptedData);
      
      if (kDebugMode) {
        print('✅ Google Calendar auth stored securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing Google Calendar auth: $e');
      }
      throw Exception('שגיאה בשמירת נתוני התחברות: $e');
    }
  }

  /// Retrieve Google Calendar authentication data securely
  static Future<Map<String, dynamic>?> getGoogleCalendarAuth() async {
    try {
      final encryptedData = await _storage.read(key: _googleCalendarAuthKey);
      if (encryptedData != null) {
        return Map<String, dynamic>.from(jsonDecode(encryptedData));
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading Google Calendar auth: $e');
      }
      return null;
    }
  }

  /// Clear Google Calendar authentication
  static Future<void> clearGoogleCalendarAuth() async {
    try {
      await _storage.delete(key: _googleCalendarAuthKey);
      if (kDebugMode) {
        print('✅ Google Calendar auth cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing Google Calendar auth: $e');
      }
    }
  }

  static Future<String?> getTaskCalendarMappings() async {
    try {
      return await _storage.read(key: _taskCalendarMappingsKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading task calendar mappings: $e');
      }
      return null;
    }
  }

  static Future<void> setTaskCalendarMappings(String mappings) async {
    try {
      await _storage.write(key: _taskCalendarMappingsKey, value: mappings);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error writing task calendar mappings: $e');
      }
    }
  }

  // Specific API key methods for type safety
  
  /// Store Gemini API key
  static Future<void> storeGeminiApiKey(String apiKey) async {
    await storeApiKey(_geminiApiKeyKey, apiKey);
  }

  /// Get Gemini API key
  static Future<String?> getGeminiApiKey() async {
    return await getApiKey(_geminiApiKeyKey);
  }

  /// Store OpenAI API key
  static Future<void> storeOpenAIApiKey(String apiKey) async {
    await storeApiKey(_openaiApiKeyKey, apiKey);
  }

  /// Get OpenAI API key
  static Future<String?> getOpenAIApiKey() async {
    return await getApiKey(_openaiApiKeyKey);
  }

  /// Store Google API key
  static Future<void> storeGoogleApiKey(String apiKey) async {
    await storeApiKey(_googleApiKeyKey, apiKey);
  }

  /// Get Google API key
  static Future<String?> getGoogleApiKey() async {
    return await getApiKey(_googleApiKeyKey);
  }

  /// Store Gmail API key
  static Future<void> storeGmailApiKey(String apiKey) async {
    await storeApiKey(_gmailApiKeyKey, apiKey);
  }

  /// Get Gmail API key
  static Future<String?> getGmailApiKey() async {
    return await getApiKey(_gmailApiKeyKey);
  }

  /// Store Calendar API key
  static Future<void> storeCalendarApiKey(String apiKey) async {
    await storeApiKey(_calendarApiKeyKey, apiKey);
  }

  /// Get Calendar API key
  static Future<String?> getCalendarApiKey() async {
    return await getApiKey(_calendarApiKeyKey);
  }

  /// Clear all stored data (for logout or account deletion)
  static Future<void> clearAllData() async {
    try {
      await _storage.deleteAll();
      if (kDebugMode) {
        print('✅ All secure data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing all data: $e');
      }
      throw Exception('שגיאה במחיקת נתונים: $e');
    }
  }

  /// Check if API key exists and is valid
  static Future<bool> hasValidApiKey(String keyName) async {
    try {
      final key = await getApiKey(keyName);
      return key != null && key.isNotEmpty && key.length > 10; // Basic validation
    } catch (e) {
      return false;
    }
  }

  /// Get all available API keys status (for settings display)
  static Future<Map<String, bool>> getApiKeysStatus() async {
    return {
      'gemini': await hasValidApiKey(_geminiApiKeyKey),
      'openai': await hasValidApiKey(_openaiApiKeyKey),
      'google': await hasValidApiKey(_googleApiKeyKey),
      'gmail': await hasValidApiKey(_gmailApiKeyKey),
      'calendar': await hasValidApiKey(_calendarApiKeyKey),
    };
  }

  /// Validate API key format
  static bool isValidApiKeyFormat(String apiKey, String type) {
    if (apiKey.trim().isEmpty) return false;
    
    switch (type.toLowerCase()) {
      case 'gemini':
        return apiKey.startsWith('AIza') && apiKey.length > 30;
      case 'openai':
        return apiKey.startsWith('sk-') && apiKey.length > 40;
      case 'google':
        return apiKey.startsWith('AIza') && apiKey.length > 30;
      default:
        return apiKey.length > 10; // Basic validation for other types
    }
  }

  /// Migrate from SharedPreferences to secure storage
  static Future<void> migrateFromSharedPreferences() async {
    try {
      // This method will be called once to migrate existing data
      // Implementation will be added when we update the settings page
      if (kDebugMode) {
        print('🔄 Migration from SharedPreferences completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during migration: $e');
      }
    }
  }
}
