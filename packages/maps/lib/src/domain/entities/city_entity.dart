import 'package:equatable/equatable.dart';

class CityEntity extends Equatable {
  const CityEntity({required this.id, required this.name});

  final String id;

  /// Already localized by the backend based on the request's language.
  final String name;

  @override
  List<Object?> get props => [id, name];
}
