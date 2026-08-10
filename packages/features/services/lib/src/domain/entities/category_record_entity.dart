import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/category_icon_entity.dart';

/// `CategoryResponseDto` — a real service category from `GET /categories`.
///
/// Distinct from the branches-catalog `ServiceEntity.category` (a plain
/// string label used by an unrelated existing flow) — this is the full
/// category record used to drive the real category picker.
class CategoryRecordEntity extends Equatable {
  const CategoryRecordEntity({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String name;
  final String description;
  final CategoryIconEntity? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    description,
    icon,
    createdAt,
    updatedAt,
  ];
}
