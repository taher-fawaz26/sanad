/// `UpdateServiceStatusDto` — PATCH /services/{id}/status request body.
class UpdateServiceStatusDto {
  const UpdateServiceStatusDto({required this.isActive});

  final bool isActive;

  Map<String, dynamic> toJson() => {'isActive': isActive};
}
