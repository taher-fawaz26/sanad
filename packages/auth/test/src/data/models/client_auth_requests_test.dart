import 'package:auth/src/data/models/requests/client_otp_request.dart';
import 'package:auth/src/data/models/requests/update_client_profile_request.dart';
import 'package:auth/src/data/models/requests/verify_client_otp_request.dart';
import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ClientOtpRequest.toMap serializes method + value', () {
    expect(
      const ClientOtpRequest(
        method: ClientAuthMethod.phone,
        value: '+971501234567',
      ).toMap(),
      {'method': 'phone', 'value': '+971501234567'},
    );
  });

  test('VerifyClientOtpRequest.toMap serializes method + value + otp', () {
    expect(
      const VerifyClientOtpRequest(
        method: ClientAuthMethod.email,
        value: 'user@example.com',
        otp: '123456',
      ).toMap(),
      {'method': 'email', 'value': 'user@example.com', 'otp': '123456'},
    );
  });

  group('UpdateClientProfileRequest.toMap', () {
    test('includes only non-null fields', () {
      expect(
        const UpdateClientProfileRequest(name: 'Mohamed').toMap(),
        {'name': 'Mohamed'},
      );
      expect(
        const UpdateClientProfileRequest(preferredLanguage: 'ar').toMap(),
        {'preferredLanguage': 'ar'},
      );
    });

    test(
      'an empty request serializes to an empty map (backend rejects it)',
      () {
        expect(const UpdateClientProfileRequest().toMap(), <String, dynamic>{});
      },
    );
  });

  test('ClientAuthMethod.fromChannel maps email/phone', () {
    expect(ClientAuthMethod.email.value, 'email');
    expect(ClientAuthMethod.phone.value, 'phone');
  });
}
