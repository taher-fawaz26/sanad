import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/email_verify_response.dart';
import 'package:auth/src/domain/entities/email_auth_result.dart';
import 'package:core/core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:network/network.dart';

// ignore: one_member_abstracts — consistent with AuthRemoteDataSource pattern
abstract class GoogleAuthDataSource {
  TaskEither<Failure, EmailAuthResult> signInWithGoogle();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  GoogleAuthDataSourceImpl({
    required BaseApiClient apiClient,
    GoogleSignIn? googleSignIn,
    FirebaseAuth? firebaseAuth,
  })  : _apiClient = apiClient,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final BaseApiClient _apiClient;
  final GoogleSignIn _googleSignIn;
  final FirebaseAuth _firebaseAuth;

  @override
  TaskEither<Failure, EmailAuthResult> signInWithGoogle() =>
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
          final userCred =
              await _firebaseAuth.signInWithCredential(credential);
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
          return NetworkFailure(message: error.toString());
        },
      ).flatMap(
        (firebaseToken) => _apiClient.request<EmailAuthResult>(
          path: AuthApiPaths.googleSignIn,
          method: RequestMethod.post,
          body: {'strategy': 'google', 'firebaseTokenId': firebaseToken},
          parser: (data) =>
              EmailVerifyResponse.fromJson(data as Map<String, dynamic>),
        ),
      );
}

class _CancelledException implements Exception {
  const _CancelledException();
}
