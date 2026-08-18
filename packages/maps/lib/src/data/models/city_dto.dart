import 'package:maps/src/domain/entities/city_entity.dart';

class CityDto {
  const CityDto({required this.id, required this.name});

  factory CityDto.fromJson(Map<String, dynamic> json) =>
      CityDto(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  CityEntity toDomain() => CityEntity(id: id, name: name);
}
