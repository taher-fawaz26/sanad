import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:core/core.dart';

class BranchTimeSlotDto extends BranchTimeSlotEntity
    implements EntityConverter<BranchTimeSlotEntity> {
  const BranchTimeSlotDto({required super.from, required super.to});

  factory BranchTimeSlotDto.fromJson(Map<String, dynamic> json) =>
      BranchTimeSlotDto(
        from: json['from'] as String,
        to: json['to'] as String,
      );

  Map<String, dynamic> toMap() => {'from': from, 'to': to};

  @override
  BranchTimeSlotEntity toEntity() =>
      BranchTimeSlotEntity(from: from, to: to);
}
