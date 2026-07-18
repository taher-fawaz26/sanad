import 'package:maps/src/domain/entities/area_entity.dart';

class AreaDto {
  const AreaDto({
    required this.id,
    required this.placeId,
    required this.nameEn,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
    required this.cityId,
    required this.countryId,
  });

  factory AreaDto.fromJson(Map<String, dynamic> json) => AreaDto(
    id: json['id'] as String,
    placeId: json['placeId'] as String,
    nameEn: json['nameEn'] as String,
    nameAr: json['nameAr'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    cityId: json['cityId'] as String,
    countryId: json['countryId'] as String,
  );

  final String id;
  final String placeId;
  final String nameEn;
  final String nameAr;
  final double latitude;
  final double longitude;
  final String cityId;
  final String countryId;

  AreaEntity toDomain() => AreaEntity(
    id: id,
    placeId: placeId,
    nameEn: nameEn,
    nameAr: nameAr,
    latitude: latitude,
    longitude: longitude,
    cityId: cityId,
    countryId: countryId,
  );
}
