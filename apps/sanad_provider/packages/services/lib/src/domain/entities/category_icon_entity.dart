import 'package:equatable/equatable.dart';

/// `CategoryIconResponseDto` — a category's icon media record.
class CategoryIconEntity extends Equatable {
  const CategoryIconEntity({required this.id, required this.url});

  final String id;
  final String url;

  @override
  List<Object?> get props => [id, url];
}
