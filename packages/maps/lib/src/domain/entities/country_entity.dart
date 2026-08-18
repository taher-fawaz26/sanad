import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  const CountryEntity({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;

  /// Already localized by the backend based on the request's language.
  final String name;
  final String code;

  @override
  List<Object?> get props => [id, name, code];
}
