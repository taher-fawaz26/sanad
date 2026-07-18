import 'package:equatable/equatable.dart';

class AreaEntity extends Equatable {
  const AreaEntity({
    required this.id,
    required this.placeId,
    required this.nameEn,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
    required this.cityId,
    required this.countryId,
  });

  final String id;
  final String placeId;
  final String nameEn;
  final String nameAr;
  final double latitude;
  final double longitude;
  final String cityId;
  final String countryId;

  @override
  List<Object?> get props => [
    id,
    placeId,
    nameEn,
    nameAr,
    latitude,
    longitude,
    cityId,
    countryId,
  ];
}
