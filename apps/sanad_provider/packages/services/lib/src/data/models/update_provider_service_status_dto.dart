import 'package:services/src/domain/entities/provider_service_status.dart';

/// `UpdateProviderServiceStatusDto` — PATCH
/// /provider-services/:id/status request body. [status] must be
/// `active` or `inactive` (`all` is a filter-only value).
class UpdateProviderServiceStatusDto {
  const UpdateProviderServiceStatusDto({required this.status});

  final ProviderServiceStatus status;

  Map<String, dynamic> toJson() => {'status': status.toApi()};
}
