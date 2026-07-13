import 'package:app_logger/src/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    appLogger.e(
      '[${bloc.runtimeType}] Error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    if (!kReleaseMode) {
      appLogger.d(
        '${bloc.runtimeType}: '
        '${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
      );
    }
    super.onChange(bloc, change);
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    if (!kReleaseMode) appLogger.d('[${bloc.runtimeType}] Event: $event');
    super.onEvent(bloc, event);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    if (!kReleaseMode) appLogger.d('[${bloc.runtimeType}] Closed');
    super.onClose(bloc);
  }
}
