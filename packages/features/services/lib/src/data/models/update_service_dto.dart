/// `UpdateServiceDto` — PATCH /services/{id} request body. All fields
/// optional; sending `mediaIds` replaces the image set entirely.
class UpdateServiceDto {
  const UpdateServiceDto({
    this.name,
    this.description,
    this.categoryId,
    this.price,
    this.isActive,
    this.mediaIds,
  });

  final String? name;
  final String? description;
  final String? categoryId;
  final num? price;
  final bool? isActive;
  final List<String>? mediaIds;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (categoryId != null) 'categoryId': categoryId,
    if (price != null) 'price': price,
    if (isActive != null) 'isActive': isActive,
    if (mediaIds != null) 'mediaIds': mediaIds,
  };
}
