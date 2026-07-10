import 'package:equatable/equatable.dart';
import 'package:core/core.dart';

enum RequestStatus { initial, loading, success, failure }

class BaseRequestState<T> extends Equatable {
  const BaseRequestState({
    this.status = RequestStatus.initial,
    this.data,
    this.failure,
  });

  final RequestStatus status;
  final T? data;
  final Failure? failure;

  const BaseRequestState.initial() : this(status: RequestStatus.initial);
  const BaseRequestState.loading({T? previousData})
    : this(status: RequestStatus.loading, data: previousData);
  const BaseRequestState.success(T data)
    : this(status: RequestStatus.success, data: data);
  const BaseRequestState.failure(Failure failure)
    : this(status: RequestStatus.failure, failure: failure);

  bool get isInitial => status == RequestStatus.initial;
  bool get isLoading => status == RequestStatus.loading;
  bool get isSuccess => status == RequestStatus.success;
  bool get hasError => status == RequestStatus.failure;
  bool get hasData => data != null;
  bool get isEmpty {
    if (data == null) return true;
    if (data is Iterable) return (data as Iterable).isEmpty;
    return false;
  }

  BaseRequestState<T> copyWith({
    RequestStatus? status,
    T? data,
    Failure? failure,
    bool clearData = false,
    bool clearFailure = false,
  }) =>
      BaseRequestState<T>(
        status: status ?? this.status,
        data: clearData ? null : (data ?? this.data),
        failure: clearFailure ? null : (failure ?? this.failure),
      );

  @override
  List<Object?> get props => [status, data, failure];
}
