import 'package:auth/src/data/endpoints/auth_api_paths.dart';
import 'package:auth/src/data/models/login_response_model.dart';
import 'package:auth/src/data/models/requests/login_model_request.dart';
import 'package:auth/src/data/models/requests/register_model_request.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// Remote data source interface for core auth operations.
abstract class AuthRemoteDataSource {
  TaskEither<Failure, LoginResponseModel> login(LoginModelRequest model);
  TaskEither<Failure, void> logout();
  TaskEither<Failure, void> register(RegisterModelRequest model);
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
  TaskEither<Failure, void> logout() => TaskEither.right(null);

  @override
  TaskEither<Failure, void> register(RegisterModelRequest model) =>
      _apiClient.request<void>(
        path: AuthApiPaths.register,
        method: RequestMethod.post,
        body: model.toMap(),
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
