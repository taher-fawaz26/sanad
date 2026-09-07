import 'package:branches/src/data/models/branch_time_slot_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';

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

  /// Deserialization boundary for *every* backend availability payload — a
  /// branch's own custom `availability` and the company schedule alike. The
  /// backend returns Title-case day codes (`"Saturday"`) on read, so normalize
  /// to the package's canonical all-caps form here so day-keyed consumers (the
  /// details working-hours summary) don't render every day as "Closed"
  /// (SAN-780). The inverse conversion for writes lives in [entityToMap].
  BranchAvailabilityEntity toDomain() => BranchAvailabilityEntity(
    day: BranchWeekdays.normalize(day),
    slots: slots.map((s) => s.toDomain()).toList(),
  );

  /// Serializes a domain [BranchAvailabilityEntity] to a request map — the
  /// single write boundary for branch availability (create + update).
  ///
  /// The domain keeps canonical all-caps day codes, but the backend requires
  /// Title-case on write and rejects `"SATURDAY"` with `400 day must be one of
  /// the following values: Monday, …`. So denormalize the day here via
  /// [BranchWeekdays.toApiDay] — the canonical casing must never leak into the
  /// request body (SAN-780 write-path regression).
  static Map<String, dynamic> entityToMap(BranchAvailabilityEntity entity) => {
    'day': BranchWeekdays.toApiDay(entity.day),
    'slots': entity.slots.map((s) => {'from': s.from, 'to': s.to}).toList(),
  };
}
