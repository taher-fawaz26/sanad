import 'package:maps/src/domain/entities/city_entity.dart';

class CityDto {
  const CityDto({
    required this.id,
    required this.nameEn,
    required this.nameAr,
  });

  factory CityDto.fromJson(Map<String, dynamic> json) => CityDto(
    id: json['id'] as String,
    nameEn: json['nameEn'] as String,
    nameAr: json['nameAr'] as String,
  );

  final String id;
  final String nameEn;
  final String nameAr;

  CityEntity toDomain() => CityEntity(id: id, nameEn: nameEn, nameAr: nameAr);
}
