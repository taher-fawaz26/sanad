import 'package:core/core.dart';
import 'package:forgot_password/src/data/endpoints/forgot_password_api_paths.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';

abstract class ForgotPasswordRemoteDataSource {
  TaskEither<Failure, void> requestForgotPassword({required String identifier});

  TaskEither<Failure, void> verifyForgotPasswordOtp({
    required String identifier,
    required int otp,
  });

  TaskEither<Failure, void> resetPassword({
    required String identifier,
    required String password,
  });
}

class ForgotPasswordRemoteDataSourceImpl
    implements ForgotPasswordRemoteDataSource {
  const ForgotPasswordRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, void> requestForgotPassword({
    required String identifier,
  }) =>
      _apiClient.request<void>(
        path: ForgotPasswordApiPaths.forgotPassword,
        method: RequestMethod.post,
        body: {'identifier': identifier},
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> verifyForgotPasswordOtp({
    required String identifier,
    required int otp,
  }) =>
      _apiClient.request<void>(
        path: ForgotPasswordApiPaths.validateOtp,
        method: RequestMethod.post,
        body: {
          'identifier': identifier,
          'otp': otp,
          'purpose': OtpPurpose.forgotPassword.wireValue,
        },
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> resetPassword({
    required String identifier,
    required String password,
  }) =>
      _apiClient.request<void>(
        path: ForgotPasswordApiPaths.resetPassword,
        method: RequestMethod.post,
        body: {'identifier': identifier, 'password': password},
        parser: (_) {},
      );
}
