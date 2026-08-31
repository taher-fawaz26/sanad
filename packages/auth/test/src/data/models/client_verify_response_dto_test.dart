import 'package:auth/src/data/models/responses/client_verify_response_dto.dart';
import 'package:auth/src/domain/enums/auth_account_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientVerifyResponseModel.fromJson', () {
    test('parses an ACTIVE first-time client (user present, name null)', () {
      final model = ClientVerifyResponseModel.fromJson(const {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'status': 'ACTIVE',
        'user': {
          'id': 'client-1',
          'name': null,
          'email': 'user@example.com',
          'phone': null,
          'preferredLanguage': 'en',
        },
      });

      expect(model.status, AuthAccountStatus.active);
      expect(model.accessToken, 'access');
      expect(model.refreshToken, 'refresh');
      expect(model.user, isNotNull);
      expect(model.user!.name, isNull);
      expect(model.user!.email, 'user@example.com');
      expect(model.user!.phone, isNull);
      expect(model.user!.preferredLanguage, 'en');
    });

    test('parses a phone-only client (email null, phone set)', () {
      final model = ClientVerifyResponseModel.fromJson(const {
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'status': 'ACTIVE',
        'user': {
          'id': 'client-2',
          'name': 'Mohamed',
          'email': null,
          'phone': '+971501234567',
          'preferredLanguage': 'ar',
        },
      });

      expect(model.user!.email, isNull);
      expect(model.user!.phone, '+971501234567');
      expect(model.user!.name, 'Mohamed');
    });

    test('parses a non-ACTIVE result with null tokens and no user', () {
      final model = ClientVerifyResponseModel.fromJson(const {
        'accessToken': null,
        'refreshToken': null,
        'status': 'SUSPENDED',
        'user': null,
      });

      expect(model.status, AuthAccountStatus.suspended);
      expect(model.accessToken, isNull);
      expect(model.refreshToken, isNull);
      expect(model.user, isNull);
    });

    test('defaults a missing preferredLanguage to "en"', () {
      final model = ClientVerifyResponseModel.fromJson(const {
        'status': 'ACTIVE',
        'user': {'id': 'client-3'},
      });

      expect(model.user!.preferredLanguage, 'en');
    });

    test('throws when status is missing', () {
      expect(
        () => ClientVerifyResponseModel.fromJson(const {'user': null}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
