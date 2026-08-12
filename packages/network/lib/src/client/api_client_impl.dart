import 'dart:async';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/src/client/base_api_client.dart';
import 'package:network/src/client/error_mapper.dart';
import 'package:network/src/client/secure_dio_client.dart';
import 'package:network/src/connectivity/network_guard.dart';

/// Concrete [BaseApiClient] using Dio.
///
/// Dio types ([Response], [DioException]) are fully contained here.
/// Nothing from Dio leaks to callers — only [Failure] or parsed `T`.
class ApiClientImpl implements BaseApiClient {
  const ApiClientImpl(this._secureDio, this._networkGuard);

  final SecureDioClient _secureDio;
  final NetworkGuard _networkGuard;

  Dio get _dio => _secureDio.dio;

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
  }) {
    final httpTask = TaskEither<Failure, T>.tryCatch(
      () async {
        final response = await _executeDioRequest(path, method, query, body);
        return await parser(response.data);
      },
      (error, _) => ErrorMapper.mapError(error),
    );

    return _networkGuard.execute(action: httpTask);
  }

  Future<Response<dynamic>> _executeDioRequest(
    String path,
    RequestMethod method,
    Map<String, dynamic>? query,
    dynamic body,
  ) => switch (method) {
    RequestMethod.get => _dio.get(path, queryParameters: query),
    RequestMethod.post => _dio.post(path, queryParameters: query, data: body),
    RequestMethod.put => _dio.put(path, queryParameters: query, data: body),
    RequestMethod.patch => _dio.patch(path, queryParameters: query, data: body),
    RequestMethod.delete => _dio.delete(
      path,
      queryParameters: query,
      data: body,
    ),
  };
}
