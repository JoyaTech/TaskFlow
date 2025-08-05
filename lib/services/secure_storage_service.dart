import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  // Generic methods
  Future<void> writeSecureData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readSecureData(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecureData(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAllSecureData() async {
    await _storage.deleteAll();
  }

  // Specific API Key Getters
  Future<String?> getOpenAIApiKey() => readSecureData('openai_api_key');
  Future<String?> getGeminiApiKey() => readSecureData('gemini_api_key');
  Future<String?> getGoogleApiKey() => readSecureData('google_api_key');
  // You had gmail and calendar keys, let's add them for completeness
  // Although they might not be needed if using Google Sign-In for OAuth
  Future<String?> getGmailApiKey() => readSecureData('gmail_api_key');
  Future<String?> getCalendarApiKey() => readSecureData('calendar_api_key');

  // Specific API Key Setters (Store methods)
  Future<void> storeOpenAIApiKey(String key) => writeSecureData('openai_api_key', key);
  Future<void> storeGeminiApiKey(String key) => writeSecureData('gemini_api_key', key);
  Future<void> storeGoogleApiKey(String key) => writeSecureData('google_api_key', key);
  Future<void> storeGmailApiKey(String key) => writeSecureData('gmail_api_key', key);
  Future<void> storeCalendarApiKey(String key) => writeSecureData('calendar_api_key', key);
}
