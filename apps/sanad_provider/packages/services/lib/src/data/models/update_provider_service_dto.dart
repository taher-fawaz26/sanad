/// `UpdateProviderServiceDto` — PATCH /provider-services/:id request body.
///
/// The new contract only allows editing the description; `serviceId`
/// cannot change and images are managed via the dedicated image endpoints.
class UpdateProviderServiceDto {
  const UpdateProviderServiceDto({required this.description});

  final String description;

  Map<String, dynamic> toJson() => {'description': description};
}
