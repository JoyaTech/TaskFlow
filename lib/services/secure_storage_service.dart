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

  // Google Calendar Authentication methods
  static Future<String?> getGoogleCalendarAuth() => readSecureData('google_calendar_auth');
  static Future<void> storeGoogleCalendarAuth(String authData) => writeSecureData('google_calendar_auth', authData);
  static Future<void> clearGoogleCalendarAuth() => deleteSecureData('google_calendar_auth');

  // Task-Calendar Mappings
  static Future<String?> getTaskCalendarMappings() => readSecureData('task_calendar_mappings');
  static Future<void> setTaskCalendarMappings(String mappings) => writeSecureData('task_calendar_mappings', mappings);

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
