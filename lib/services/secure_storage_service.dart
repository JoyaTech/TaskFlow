import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Generic methods
  static Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  static Future<void> deleteAllSecureData() async {
    await _storage.deleteAll();
  }

  // Static API Key Getters
  static Future<String?> getOpenAIApiKey() => readSecureData('openai_api_key');
  static Future<String?> getGeminiApiKey() => readSecureData('gemini_api_key');
  static Future<String?> getGoogleApiKey() => readSecureData('google_api_key');
  static Future<String?> getGmailApiKey() => readSecureData('gmail_api_key');
  static Future<String?> getCalendarApiKey() => readSecureData('calendar_api_key');

  // Static API Key Setters (Store methods)
  static Future<void> storeOpenAIApiKey(String key) => writeSecureData('openai_api_key', key);
  static Future<void> storeGeminiApiKey(String key) => writeSecureData('gemini_api_key', key);
  static Future<void> storeGoogleApiKey(String key) => writeSecureData('google_api_key', key);
  static Future<void> storeGmailApiKey(String key) => writeSecureData('gmail_api_key', key);
  static Future<void> storeCalendarApiKey(String key) => writeSecureData('calendar_api_key', key);

  // Google Calendar Authentication methods with JSON encapsulation
  static const _googleAuthKey = 'google_calendar_auth';
  static const _taskCalendarMappingsKey = 'task_calendar_mappings';
  
  /// Store Google Calendar authentication data as a Map
  /// The service handles JSON encoding internally
  static Future<void> storeGoogleCalendarAuth(Map<String, dynamic> authData) async {
    try {
      final String authDataJson = jsonEncode(authData);
      await writeSecureData(_googleAuthKey, authDataJson);
    } catch (e) {
      if (kDebugMode) print('Error encoding Google Calendar auth data: $e');
      rethrow;
    }
  }
  
  /// Retrieve Google Calendar authentication data as a Map
  /// The service handles JSON decoding internally and gracefully handles corruption
  static Future<Map<String, dynamic>?> getGoogleCalendarAuth() async {
    try {
      final String? authDataJson = await readSecureData(_googleAuthKey);
      if (authDataJson == null || authDataJson.isEmpty) {
        return null;
      }
      
      return jsonDecode(authDataJson) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('Error decoding Google Calendar auth data (possibly corrupted): $e');
      // If decoding fails (corrupt data), delete it and return null
      await clearGoogleCalendarAuth();
      return null;
    }
  }
  
  /// Clear Google Calendar authentication data
  static Future<void> clearGoogleCalendarAuth() async {
    await deleteSecureData(_googleAuthKey);
  }

  /// Store task-calendar mappings as a Map
  /// The service handles JSON encoding internally
  static Future<void> setTaskCalendarMappings(Map<String, String> mappings) async {
    try {
      final String mappingsJson = jsonEncode(mappings);
      await writeSecureData(_taskCalendarMappingsKey, mappingsJson);
    } catch (e) {
      if (kDebugMode) print('Error encoding task-calendar mappings: $e');
      rethrow;
    }
  }
  
  /// Retrieve task-calendar mappings as a Map
  /// The service handles JSON decoding internally and gracefully handles corruption
  static Future<Map<String, String>?> getTaskCalendarMappings() async {
    try {
      final String? mappingsJson = await readSecureData(_taskCalendarMappingsKey);
      if (mappingsJson == null || mappingsJson.isEmpty) {
        return null;
      }
      
      final decoded = jsonDecode(mappingsJson);
      return Map<String, String>.from(decoded);
    } catch (e) {
      if (kDebugMode) print('Error decoding task-calendar mappings (possibly corrupted): $e');
      // If decoding fails (corrupt data), delete it and return null
      await deleteSecureData(_taskCalendarMappingsKey);
      return null;
    }
  }

  // Instance methods for backward compatibility
  final _instanceStorage = const FlutterSecureStorage();

  Future<void> writeSecureDataInstance(String key, String value) async {
    await _instanceStorage.write(key: key, value: value);
  }

  Future<String?> readSecureDataInstance(String key) async {
    return await _instanceStorage.read(key: key);
  }

  Future<void> deleteSecureDataInstance(String key) async {
    await _instanceStorage.delete(key: key);
  }

  Future<void> deleteAllSecureDataInstance() async {
    await _instanceStorage.deleteAll();
  }

  // Instance API Key methods
  Future<String?> getOpenAIApiKeyInstance() => readSecureDataInstance('openai_api_key');
  Future<String?> getGeminiApiKeyInstance() => readSecureDataInstance('gemini_api_key');
  Future<String?> getGoogleApiKeyInstance() => readSecureDataInstance('google_api_key');
  Future<String?> getGmailApiKeyInstance() => readSecureDataInstance('gmail_api_key');
  Future<String?> getCalendarApiKeyInstance() => readSecureDataInstance('calendar_api_key');

  Future<void> storeOpenAIApiKeyInstance(String key) => writeSecureDataInstance('openai_api_key', key);
  Future<void> storeGeminiApiKeyInstance(String key) => writeSecureDataInstance('gemini_api_key', key);
  Future<void> storeGoogleApiKeyInstance(String key) => writeSecureDataInstance('google_api_key', key);
  Future<void> storeGmailApiKeyInstance(String key) => writeSecureDataInstance('gmail_api_key', key);
  Future<void> storeCalendarApiKeyInstance(String key) => writeSecureDataInstance('calendar_api_key', key);
}
