part of 'request_new_service_bloc.dart';

sealed class RequestNewServiceEvent extends Equatable {
  const RequestNewServiceEvent();

  @override
  List<Object?> get props => [];
}

final class RequestNewServiceSubmittedEvent extends RequestNewServiceEvent {
  const RequestNewServiceSubmittedEvent(this.params);

  final CreateServiceRequestParams params;

  @override
  List<Object?> get props => [params];
}

/// Requests the `GET /categories` list for the category picker.
final class RequestNewServiceCategoriesRequested
    extends RequestNewServiceEvent {
  const RequestNewServiceCategoriesRequested();
}
