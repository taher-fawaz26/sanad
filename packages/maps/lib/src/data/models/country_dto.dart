import 'package:maps/src/domain/entities/country_entity.dart';

class CountryDto {
  const CountryDto({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.code,
  });

  factory CountryDto.fromJson(Map<String, dynamic> json) => CountryDto(
    id: json['id'] as String,
    nameEn: json['nameEn'] as String,
    nameAr: json['nameAr'] as String,
    code: json['code'] as String,
  );

  final String id;
  final String nameEn;
  final String nameAr;
  final String code;

  CountryEntity toDomain() => CountryEntity(
    id: id,
    nameEn: nameEn,
    nameAr: nameAr,
    code: code,
  );
}
