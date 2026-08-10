import 'package:equatable/equatable.dart';

/// `ServiceRequestCategorySummaryDto` — the category created as a result of
/// an approved service request, if any.
class ServiceRequestCategorySummaryEntity extends Equatable {
  const ServiceRequestCategorySummaryEntity({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  @override
  List<Object?> get props => [id, name, slug];
}
