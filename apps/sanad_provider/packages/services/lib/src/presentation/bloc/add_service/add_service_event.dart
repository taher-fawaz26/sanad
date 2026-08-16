part of 'add_service_bloc.dart';

sealed class AddServiceEvent extends Equatable {
  const AddServiceEvent();

  @override
  List<Object?> get props => [];
}

final class AddServiceSubmittedEvent extends AddServiceEvent {
  const AddServiceSubmittedEvent(this.params);

  final CreateProviderServiceParams params;

  @override
  List<Object?> get props => [params];
}

/// Requests the `GET /services` catalog for the service-name picker.
final class AddServiceCatalogRequested extends AddServiceEvent {
  const AddServiceCatalogRequested();
}
