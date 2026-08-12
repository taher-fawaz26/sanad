/// `CreateProviderServiceDto` — POST /provider-services request body.
///
/// [serviceId] must come from `GET /services` (the catalog) and cannot be
/// changed after creation. [imageIds] are media ids from the upload
/// service; the first one becomes the primary image.
class CreateProviderServiceDto {
  const CreateProviderServiceDto({
    required this.serviceId,
    required this.description,
    required this.imageIds,
  });

  final String serviceId;
  final String description;
  final List<String> imageIds;

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'description': description,
    'imageIds': imageIds,
  };
}
