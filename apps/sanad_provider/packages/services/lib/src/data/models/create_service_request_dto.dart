/// `CreateServiceRequestDto` — POST /service-requests request body.
class CreateServiceRequestDto {
  const CreateServiceRequestDto({
    required this.name,
    required this.categoryId,
    required this.description,
    this.imageIds,
  });

  final String name;
  final String categoryId;
  final String description;
  final List<String>? imageIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    'categoryId': categoryId,
    'description': description,
    if (imageIds != null && imageIds!.isNotEmpty) 'imageIds': imageIds,
  };
}
