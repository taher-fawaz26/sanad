/// `CreateServiceDto` — POST /services request body.
class CreateServiceDto {
  const CreateServiceDto({
    required this.name,
    this.description,
    required this.categoryId,
    required this.price,
    this.isActive,
    this.mediaIds,
  });

  final String name;
  final String? description;
  final String categoryId;
  final num price;
  final bool? isActive;
  final List<String>? mediaIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'categoryId': categoryId,
    'price': price,
    if (isActive != null) 'isActive': isActive,
    if (mediaIds != null && mediaIds!.isNotEmpty) 'mediaIds': mediaIds,
  };
}
