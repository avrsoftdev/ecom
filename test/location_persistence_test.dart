import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferences Location Persistence Tests', () {
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    test('should save and load location data correctly', () async {
      // Arrange
      const locationStorageKey = 'saved_location';

      // Act - Save location
      await sharedPreferences.setString(locationStorageKey, '''
      {
        "address": "Test Address",
        "latitude": 28.6139,
        "longitude": 77.2090,
        "distanceInKm": 5.0,
        "isWithinServiceArea": true
      }
      ''');

      // Assert - Load location
      final savedLocationJson = sharedPreferences.getString(locationStorageKey);
      expect(savedLocationJson, isNotNull);
      expect(savedLocationJson, contains('Test Address'));
      expect(savedLocationJson, contains('28.6139'));
      expect(savedLocationJson, contains('77.2090'));
      expect(savedLocationJson, contains('5.0'));
      expect(savedLocationJson, contains('true'));
    });

    test('should handle empty SharedPreferences correctly', () async {
      // Act & Assert
      final savedLocationJson = sharedPreferences.getString('saved_location');
      expect(savedLocationJson, isNull);
    });
  });
}
