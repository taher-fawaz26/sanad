import 'package:branches/src/data/models/branch_time_slot_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';

class BranchAvailabilityDto {
  const BranchAvailabilityDto({required this.day, required this.slots});

  factory BranchAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      BranchAvailabilityDto(
        day: json['day'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map((e) => BranchTimeSlotDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String day;

  /// Typed as [BranchTimeSlotDto] so [toMap] requires no runtime cast.
  final List<BranchTimeSlotDto> slots;

  Map<String, dynamic> toMap() => {
        'day': day,
        'slots': slots.map((s) => s.toMap()).toList(),
      };

  BranchAvailabilityEntity toDomain() => BranchAvailabilityEntity(
        day: day,
        slots: slots.map((s) => s.toDomain()).toList(),
      );

  /// Serializes a domain [BranchAvailabilityEntity] to a request map.
  /// Use this in request objects so serialization stays in one place.
  static Map<String, dynamic> entityToMap(BranchAvailabilityEntity entity) => {
        'day': entity.day,
        'slots': entity.slots
            .map((s) => {'from': s.from, 'to': s.to})
            .toList(),
      };
}
