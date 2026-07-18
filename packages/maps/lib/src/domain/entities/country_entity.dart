import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  const CountryEntity({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.code,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String code;

  @override
  List<Object?> get props => [id, nameEn, nameAr, code];
}
