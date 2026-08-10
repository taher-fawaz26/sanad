import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';
import 'package:services/src/domain/entities/service_request_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// `ServiceRequestResponseDto` — a provider's request for a new
/// service/category, from `POST /service-requests` and
/// `GET /service-requests/mine`.
class ServiceRequestEntity extends Equatable {
  const ServiceRequestEntity({
    required this.id,
    required this.requestedServiceName,
    required this.requestedCategoryName,
    required this.description,
    required this.status,
    required this.rejectionReason,
    required this.reviewedAt,
    required this.providerId,
    required this.resultingCategory,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? requestedServiceName;
  final String? requestedCategoryName;
  final String description;
  final ServiceRequestStatus status;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String providerId;
  final ServiceRequestCategorySummaryEntity? resultingCategory;
  final List<ServiceMediaEntity> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Display label: `requestedServiceName` when present, else
  /// `requestedCategoryName` (the DTO guarantees at least one is set).
  String get displayName => requestedServiceName ?? requestedCategoryName ?? '';

  @override
  List<Object?> get props => [
    id,
    requestedServiceName,
    requestedCategoryName,
    description,
    status,
    rejectionReason,
    reviewedAt,
    providerId,
    resultingCategory,
    media,
    createdAt,
    updatedAt,
  ];
}
