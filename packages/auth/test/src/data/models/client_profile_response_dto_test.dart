import 'package:auth/src/data/models/responses/client_profile_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientProfileResponseModel.fromJson', () {
    test('parses a full client profile', () {
      final model = ClientProfileResponseModel.fromJson(const {
        'id': 'client-1',
        'name': 'Mohamed Shahat',
        'email': 'user@example.com',
        'phone': null,
        'preferredLanguage': 'en',
      });

      expect(model.id, 'client-1');
      expect(model.name, 'Mohamed Shahat');
      expect(model.email, 'user@example.com');
      expect(model.phone, isNull);
      expect(model.preferredLanguage, 'en');
    });

    test('parses a phone-only client (email null)', () {
      final model = ClientProfileResponseModel.fromJson(const {
        'id': 'client-2',
        'name': 'Mohamed',
        'email': null,
        'phone': '+971501234567',
        'preferredLanguage': 'ar',
      });

      expect(model.email, isNull);
      expect(model.phone, '+971501234567');
    });

    test('unwraps a `data` envelope', () {
      final model = ClientProfileResponseModel.fromJson(const {
        'data': {'id': 'client-3', 'preferredLanguage': 'en'},
      });

      expect(model.id, 'client-3');
      expect(model.name, isNull);
    });
  });
}
