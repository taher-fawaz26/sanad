/// `CreateServiceRequestDto` — POST /service-requests request body.
class CreateServiceRequestDto {
  const CreateServiceRequestDto({
    this.requestedServiceName,
    this.requestedCategoryName,
    required this.description,
    required this.mediaIds,
  });

  final String? requestedServiceName;
  final String? requestedCategoryName;
  final String description;
  final List<String> mediaIds;

  Map<String, dynamic> toJson() => {
    if (requestedServiceName != null && requestedServiceName!.isNotEmpty)
      'requestedServiceName': requestedServiceName,
    if (requestedCategoryName != null && requestedCategoryName!.isNotEmpty)
      'requestedCategoryName': requestedCategoryName,
    'description': description,
    'mediaIds': mediaIds,
  };
}
