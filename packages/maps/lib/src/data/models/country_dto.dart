import 'package:maps/src/domain/entities/country_entity.dart';

class CountryDto {
  const CountryDto({
    required this.id,
    required this.name,
    required this.code,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) => CountryDto(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String,
  );

  final String id;
  final String name;
  final String code;

  CountryEntity toDomain() => CountryEntity(id: id, name: name, code: code);
}
