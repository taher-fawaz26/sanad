import 'dart:async';

import 'package:auth/src/data/datasources/auth_remote_datasource.dart';
import 'package:auth/src/data/models/requests/client_otp_request.dart';
import 'package:auth/src/data/models/requests/update_client_profile_request.dart';
import 'package:auth/src/data/models/requests/verify_client_otp_request.dart';
import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Captures every `request` call so the test can assert the `authRequired`
/// flag each endpoint sends. Returns an empty-ish success so the datasource's
/// parser runs on a benign shape.
class _CapturingApiClient implements BaseApiClient {
  final List<({String path, bool authRequired})> calls = [];

  dynamic responseFor(String path) {
    if (path.contains('resend-info')) {
      return {'canResend': true, 'retryAfterSeconds': 0};
    }
    if (path.contains('verify')) {
      return {
        'accessToken': 'a',
        'refreshToken': 'r',
        'status': 'ACTIVE',
        'user': {'id': '1', 'name': null},
      };
    }
    return <String, dynamic>{};
  }

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
    bool authRequired = true,
  }) {
    calls.add((path: path, authRequired: authRequired));
    return TaskEither<Failure, T>.tryCatch(
      () async => parser(responseFor(path)),
      (e, _) => UnknownFailure(message: e.toString()),
    );
  }
}

void main() {
  late _CapturingApiClient api;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    api = _CapturingApiClient();
    dataSource = AuthRemoteDataSourceImpl(api);
  });

  group('client OTP endpoints are unauthenticated (Auth: None)', () {
    test('request-otp passes authRequired: false', () async {
      await dataSource
          .requestClientOtp(
            const ClientOtpRequest(
              method: ClientAuthMethod.email,
              value: 'a@b.com',
            ),
          )
          .run();

      expect(api.calls.single.path, contains('client/request-otp'));
      expect(api.calls.single.authRequired, isFalse);
    });

    test('resend-info passes authRequired: false', () async {
      await dataSource
          .getClientResendInfo(ClientAuthMethod.email, 'a@b.com')
          .run();

      expect(api.calls.single.path, contains('client/resend-info'));
      expect(api.calls.single.authRequired, isFalse);
    });

    test('verify passes authRequired: false', () async {
      await dataSource
          .verifyClientOtp(
            const VerifyClientOtpRequest(
              method: ClientAuthMethod.email,
              value: 'a@b.com',
              otp: '123456',
            ),
          )
          .run();

      expect(api.calls.single.path, contains('client/verify'));
      expect(api.calls.single.authRequired, isFalse);
    });

    test('updateClientProfile (clients/me) stays authenticated', () async {
      // PATCH clients/me runs on the freshly-issued session — it must keep the
      // default authenticated behaviour, unlike the three public endpoints.
      await dataSource
          .updateClientProfile(
            const UpdateClientProfileRequest(name: 'Sara'),
          )
          .run();

      expect(api.calls.single.path, contains('clients/me'));
      expect(api.calls.single.authRequired, isTrue);
    });
  });
}
