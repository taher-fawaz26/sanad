import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/auth_response_model.dart';
import 'package:auth/src/data/models/responses/login_response_dto.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:network/network.dart';

/// Google OAuth — exchanges a Firebase ID token for a SANAD session.
///
/// Split into [socialSignup] / [socialLogin] to mirror the backend's split
/// endpoints (`auth/social/signup` vs `auth/social/login`) — the Firebase
/// hand-off (Google popup → Firebase credential) is identical either way;
/// only the SANAD endpoint posted to, and therefore the response shape,
/// differs.
abstract class GoogleAuthDataSource {
  TaskEither<Failure, AuthResponseEntity> socialSignup();
  TaskEither<Failure, LoginResult> socialLogin();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  GoogleAuthDataSourceImpl({
    required BaseApiClient apiClient,
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  }) : _apiClient = apiClient,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _firebaseAuth = firebaseAuth;

  final BaseApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  /// Injected in tests; `null` in production, where Firebase is resolved
  /// lazily by [_auth].
  final FirebaseAuth? _firebaseAuth;

  /// Resolved on first use, never in the constructor.
  ///
  /// `FirebaseAuth.instance` throws `[core/no-app]` when
  /// `Firebase.initializeApp()` has not run — and `sanad_client` has no
  /// Firebase configuration at all. Touching it from the constructor made an
  /// app without Firebase fail to build `AuthRepository`, which took every
  /// auth use case down with it, including the email and phone OTP flows that
  /// need no Firebase whatsoever.
  ///
  /// Reading it here instead keeps the blast radius to Google sign-in: the
  /// throw happens inside [_obtainFirebaseToken]'s `tryCatch` and maps to
  /// `errors.google_sign_in_failed` like any other SDK-level failure.
  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  TaskEither<Failure, String> _obtainFirebaseToken() =>
      TaskEither<Failure, String>.tryCatch(
        () async {
          final googleUser = await _googleSignIn.signIn();
          if (googleUser == null) throw const _CancelledException();

          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          if (idToken == null) throw const _CancelledException();

          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: idToken,
          );
          final userCred = await _auth.signInWithCredential(credential);
          final firebaseToken = await userCred.user?.getIdToken();
          if (firebaseToken == null) throw const _CancelledException();

          return firebaseToken;
        },
        (error, _) {
          if (error is _CancelledException) {
            return const NetworkFailure(
              message: 'errors.google_sign_in_cancelled',
            );
          }
          // Anything else here is a native/SDK-level failure — e.g. a
          // `PlatformException` from google_sign_in (a mismatched SHA-1 or
          // OAuth client surfaces as `ApiException: 10`) or a
          // `FirebaseAuthException`. That text is developer-facing, not
          // something to show a user, so it's collapsed to one generic,
          // localized key rather than echoed via `error.toString()`.
          return const NetworkFailure(
            message: 'errors.google_sign_in_failed',
          );
        },
      );

  @override
  TaskEither<Failure, AuthResponseEntity> socialSignup() =>
      _obtainFirebaseToken().flatMap(
        (firebaseToken) => _apiClient.request<AuthResponseEntity>(
          path: AuthApiPaths.socialSignup,
          method: RequestMethod.post,
          body: {'strategy': 'google', 'firebaseTokenId': firebaseToken},
          parser: (data) =>
              AuthResponseModel.fromJson(data as Map<String, dynamic>),
        ),
      );

  @override
  TaskEither<Failure, LoginResult> socialLogin() =>
      _obtainFirebaseToken().flatMap(
        (firebaseToken) => _apiClient.request<LoginResult>(
          path: AuthApiPaths.socialLogin,
          method: RequestMethod.post,
          body: {'strategy': 'google', 'firebaseTokenId': firebaseToken},
          parser: (data) =>
              LoginResponseModel.fromJson(data as Map<String, dynamic>),
        ),
      );
}

class _CancelledException implements Exception {
  const _CancelledException();
}
