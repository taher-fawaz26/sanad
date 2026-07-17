import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';

class BranchTimeSlotDto {
  const BranchTimeSlotDto({required this.from, required this.to});

  factory BranchTimeSlotDto.fromJson(Map<String, dynamic> json) =>
      BranchTimeSlotDto(
        from: json['from'] as String,
        to: json['to'] as String,
      );

  final String from;
  final String to;

  Map<String, dynamic> toMap() => {'from': from, 'to': to};

  BranchTimeSlotEntity toDomain() => BranchTimeSlotEntity(from: from, to: to);
}
