import 'package:equatable/equatable.dart';

/// The category reference nested inside catalog services, provider
/// services, and service requests under the new backend contract.
///
/// `name`/`description` are returned already localized by the backend via
/// the `Accept-Language` header — no client-side translation.
class CategoryRefEntity extends Equatable {
  const CategoryRefEntity({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String? description;

  @override
  List<Object?> get props => [id, name, description];
}
