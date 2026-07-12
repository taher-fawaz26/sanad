import 'package:branches/src/data/models/branch_time_slot_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:core/core.dart';

class BranchAvailabilityDto extends BranchAvailabilityEntity
    implements EntityConverter<BranchAvailabilityEntity> {
  const BranchAvailabilityDto({required super.day, required super.slots});

  factory BranchAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      BranchAvailabilityDto(
        day: json['day'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map(
              (e) =>
                  BranchTimeSlotDto.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'slots': slots
            .cast<BranchTimeSlotDto>()
            .map((s) => s.toMap())
            .toList(),
      };

  @override
  BranchAvailabilityEntity toEntity() => BranchAvailabilityEntity(
        day: day,
        slots: slots,
      );
}
