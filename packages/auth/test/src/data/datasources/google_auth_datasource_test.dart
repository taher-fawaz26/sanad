import 'package:auth/src/data/datasources/google_auth_datasource.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockApiClient extends Mock implements BaseApiClient {}

/// Regression coverage for the error-mapping branch of
/// `_obtainFirebaseToken` (SAN-587 / SAN-588): a dismissed account picker
/// must map to the (now-localizable) cancellation key, and every other
/// native/SDK failure — a `PlatformException` chief among them, since that's
/// what a mismatched SHA-1/OAuth client surfaces as — must collapse to one
/// generic, localizable key rather than leak `error.toString()` to the UI.
void main() {
  late _MockGoogleSignIn googleSignIn;
  late _MockFirebaseAuth firebaseAuth;
  late _MockApiClient apiClient;
  late GoogleAuthDataSourceImpl dataSource;

  setUp(() {
    googleSignIn = _MockGoogleSignIn();
    firebaseAuth = _MockFirebaseAuth();
    apiClient = _MockApiClient();
    dataSource = GoogleAuthDataSourceImpl(
      apiClient: apiClient,
      googleSignIn: googleSignIn,
      firebaseAuth: firebaseAuth,
    );
  });

  test(
    'dismissing the account picker (null result) maps to the cancellation '
    'i18n key',
    () async {
      when(() => googleSignIn.signIn()).thenAnswer((_) async => null);

      final result = await dataSource.socialLogin().run();

      expect(
        result,
        const Left<Failure, LoginResult>(
          NetworkFailure(message: 'errors.google_sign_in_cancelled'),
        ),
      );
    },
  );

  test(
    'a PlatformException from the native SDK (e.g. ApiException: 10 from a '
    'SHA-1/OAuth client mismatch) never leaks its raw text to the UI',
    () async {
      when(() => googleSignIn.signIn()).thenThrow(
        PlatformException(
          code: 'sign_in_failed',
          message: 'com.google.android.gms.common.api.ApiException: 10: ',
        ),
      );

      final result = await dataSource.socialLogin().run();

      expect(
        result,
        const Left<Failure, LoginResult>(
          NetworkFailure(message: 'errors.google_sign_in_failed'),
        ),
      );
    },
  );

  test(
    'a generic exception from the Google/Firebase hand-off also collapses '
    'to the generic failure key',
    () async {
      final account = _MockGoogleSignInAccount();
      when(() => googleSignIn.signIn()).thenAnswer((_) async => account);
      when(() => account.authentication).thenThrow(Exception('boom'));

      final result = await dataSource.socialSignup().run();

      expect(
        result,
        const Left<Failure, AuthResponseEntity>(
          NetworkFailure(message: 'errors.google_sign_in_failed'),
        ),
      );
    },
  );
}
