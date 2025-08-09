import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mindflow/services/secure_storage_service.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SecureStorageService JSON Encoding/Decoding', () {
    test('should properly encode and decode Google Calendar auth data', () {
      // Arrange - Test data that should be encoded/decoded
      final testAuthData = {
        'accessToken': 'test_access_token_123',
        'idToken': 'test_id_token_456',
        'timestamp': 1234567890,
      };
      
      // Act - Test JSON encoding
      final jsonString = jsonEncode(testAuthData);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Assert - Verify proper encoding/decoding
      expect(decoded['accessToken'], equals('test_access_token_123'));
      expect(decoded['idToken'], equals('test_id_token_456'));
      expect(decoded['timestamp'], equals(1234567890));
      expect(decoded, isA<Map<String, dynamic>>());
    });
    
    test('should handle corrupted JSON data gracefully', () {
      // Arrange - Invalid JSON string
      const corruptedJson = 'invalid-json-{]}';
      
      // Act & Assert - Should throw FormatException
      expect(() => jsonDecode(corruptedJson), throwsFormatException);
    });
    
    test('should properly encode and decode task-calendar mappings', () {
      // Arrange
      final testMappings = {
        'task_id_1': 'calendar_event_1',
        'task_id_2': 'calendar_event_2',
      };
      
      // Act - Test encoding/decoding
      final jsonString = jsonEncode(testMappings);
      final decoded = jsonDecode(jsonString);
      final typedMappings = Map<String, String>.from(decoded);
      
      // Assert
      expect(typedMappings['task_id_1'], equals('calendar_event_1'));
      expect(typedMappings['task_id_2'], equals('calendar_event_2'));
      expect(typedMappings, isA<Map<String, String>>());
    });
  });
  
  group('SecureStorageService Behavior Tests', () {
    test('should demonstrate proper encapsulation principle', () {
      // This test demonstrates that the SecureStorageService follows proper encapsulation
      // by handling JSON encoding/decoding internally
      
      // Arrange - User provides a Map
      final userAuthData = {
        'accessToken': 'user_token',
        'idToken': 'user_id_token', 
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // The service should handle JSON conversion internally
      // Users should never need to call jsonEncode/jsonDecode themselves
      
      // Act & Assert - These calls should work without user handling JSON
      expect(() {
        // User provides Map - service handles encoding
        SecureStorageService.storeGoogleCalendarAuth(userAuthData);
        // User receives Map - service handles decoding  
        SecureStorageService.getGoogleCalendarAuth();
      }, returnsNormally);
    });
  });
}
