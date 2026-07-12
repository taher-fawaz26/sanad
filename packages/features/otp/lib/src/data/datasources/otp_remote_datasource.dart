import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:otp/src/data/endpoints/otp_api_paths.dart';
import 'package:otp/src/data/models/validate_otp_request.dart';

abstract class OtpRemoteDataSource {
  TaskEither<Failure, LoginResponseModel> validateOtp(ValidateOtpRequest model);

  TaskEither<Failure, void> resendOtp({
    required String identifier,
    required String purpose,
  });
}

class OtpRemoteDataSourceImpl implements OtpRemoteDataSource {
  const OtpRemoteDataSourceImpl(this._apiClient);

  final BaseApiClient _apiClient;

  @override
  TaskEither<Failure, LoginResponseModel> validateOtp(
    ValidateOtpRequest model,
  ) =>
      _apiClient.request<LoginResponseModel>(
        path: OtpApiPaths.validateOtp,
        method: RequestMethod.post,
        body: model.toMap(),
        parser: (data) =>
            LoginResponseModel.fromJson(data as Map<String, dynamic>),
      );

  @override
  TaskEither<Failure, void> resendOtp({
    required String identifier,
    required String purpose,
  }) =>
      _apiClient.request<void>(
        path: OtpApiPaths.resendOtp,
        method: RequestMethod.post,
        body: {'identifier': identifier, 'purpose': purpose},
        parser: (_) {},
      );
}
