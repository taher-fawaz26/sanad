import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/media_ref_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// A provider's request for a service that doesn't exist in the catalog
/// (`/service-requests`).
///
/// [description], [rejectionReason], and [images] are only populated by the
/// detail endpoint (`GET /service-requests/:id`) — list rows
/// (`GET /service-requests`) carry everything else. Approval does not mean
/// the provider can use the service yet; admin still has to add it to the
/// catalog.
class ServiceRequestEntity extends Equatable {
  const ServiceRequestEntity({
    required this.id,
    required this.name,
    required this.unifiedRequestId,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.rejectionReason,
    this.images = const [],
  });

  final String id;
  final String name;
  final String unifiedRequestId;
  final CategoryRefEntity category;
  final ServiceRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? rejectionReason;
  final List<MediaRefEntity> images;

  @override
  List<Object?> get props => [
    id,
    name,
    unifiedRequestId,
    category,
    status,
    createdAt,
    updatedAt,
    description,
    rejectionReason,
    images,
  ];
}
