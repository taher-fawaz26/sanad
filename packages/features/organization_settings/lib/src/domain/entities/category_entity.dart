import 'package:equatable/equatable.dart';

/// One service category the organization operates under.
class CategoryEntity extends Equatable {
  const CategoryEntity({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
