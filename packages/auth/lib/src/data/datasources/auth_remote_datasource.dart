import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/auth_otp_purpose.dart';
import 'package:auth/src/data/models/login_response_model.dart';
import 'package:auth/src/data/models/requests/login_model_request.dart';
import 'package:auth/src/data/models/requests/register_model_request.dart';
import 'package:auth/src/data/models/requests/validate_otp_request.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source interface for auth operations.
/// All methods return [TaskEither] — no [Future<Either>] anywhere.
abstract class AuthRemoteDataSource {
  TaskEither<Failure, LoginResponseModel> login(LoginModelRequest model);
  TaskEither<Failure, void> logout();
  TaskEither<Failure, void> register(RegisterModelRequest model);
  TaskEither<Failure, LoginResponseModel> validateOtp(ValidateOtpRequest model);
  TaskEither<Failure, void> requestForgotPassword({required String identifier});
  TaskEither<Failure, void> validateAuthOtpForgotPassword({
    required String identifier,
    required int otp,
  });
  TaskEither<Failure, void> resetPassword({
    required String identifier,
    required String password,
  });
  TaskEither<Failure, void> resendOtp({
    required String identifier,
    required String purpose,
  });
  TaskEither<Failure, void> deleteAccount({required String userSub});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, LoginResponseModel> login(LoginModelRequest model) =>
      _apiClient.request<LoginResponseModel>(
        path: AuthApiPaths.login,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (data) =>
            LoginResponseModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> logout() =>
      // Backend has no logout endpoint yet — return success immediately.
      TaskEither.right(null);

  @override
  TaskEither<Failure, void> register(RegisterModelRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.register,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (_) {},
      );

  @override
  TaskEither<Failure, LoginResponseModel> validateOtp(
    ValidateOtpRequest model,
  ) =>
      _apiClient.request<LoginResponseModel>(
        path: AuthApiPaths.validateOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (data) =>
            LoginResponseModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> requestForgotPassword({
    required String identifier,
  }) =>
      _apiClient.request<void>(
        path: AuthApiPaths.forgotPassword,
        method: RequestMethod.post,
        body: {'identifier': identifier},
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> validateAuthOtpForgotPassword({
    required String identifier,
    required int otp,
  }) =>
      _apiClient.request<void>(
        path: AuthApiPaths.validateOtp,
        method: RequestMethod.post,
        body: {
          'identifier': identifier,
          'otp': otp,
          'purpose': AuthOtpPurpose.forgotPassword.wireValue,
        },
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> resetPassword({
    required String identifier,
    required String password,
  }) =>
      _apiClient.request<void>(
        path: AuthApiPaths.resetPassword,
        method: RequestMethod.post,
        body: {'identifier': identifier, 'password': password},
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> resendOtp({
    required String identifier,
    required String purpose,
  }) =>
      _apiClient.request<void>(
        path: AuthApiPaths.resendOtp,
        method: RequestMethod.post,
        body: {'identifier': identifier, 'purpose': purpose},
        parser: (_) {},
      );

  @override
  TaskEither<Failure, void> deleteAccount({required String userSub}) =>
      _apiClient.request<void>(
        path: AuthApiPaths.userDelete(userSub),
        method: RequestMethod.delete,
        parser: (_) {},
      );
}
