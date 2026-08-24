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

/// Requests the `GET /categories` list for the category picker (SAN-577:
/// the first step of the Category → Service dependency).
final class AddServiceCategoriesRequested extends AddServiceEvent {
  const AddServiceCategoriesRequested();
}

/// Requests the `GET /services?categoryId=` catalog, scoped to
/// [categoryId], for the service picker — only reachable once a category
/// has been chosen (SAN-577).
final class AddServiceCatalogRequested extends AddServiceEvent {
  const AddServiceCatalogRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}
