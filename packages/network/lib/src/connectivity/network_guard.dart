import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/src/connectivity/connectivity_service.dart';

/// Gates any async action behind a connectivity check.
class NetworkGuard {
  NetworkGuard(this._connectivity);

  final ConnectivityService _connectivity;

  TaskEither<Failure, T> execute<T>({required TaskEither<Failure, T> action}) {
    return TaskEither(() async {
      final connected = await _connectivity.isConnected();
      if (!connected) {
        return const Left(NoInternetFailure(message: 'No internet connection'));
      }
      return action.run();
    });
  }
}
