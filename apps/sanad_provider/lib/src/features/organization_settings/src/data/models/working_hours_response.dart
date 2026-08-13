import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';

/// Mirrors `WorkingHoursSlotDto` exactly.
class WorkingHoursSlotResponse {
  const WorkingHoursSlotResponse({required this.from, required this.to});

  factory WorkingHoursSlotResponse.fromJson(Map<String, dynamic> json) =>
      WorkingHoursSlotResponse(
        from: json['from'] as String,
        to: json['to'] as String,
      );

  final String from;
  final String to;

  Map<String, dynamic> toJson() => {'from': from, 'to': to};

  WorkingHoursSlotEntity toEntity() =>
      WorkingHoursSlotEntity(from: from, to: to);
}

/// Mirrors `WorkingHoursDayDto` exactly.
class WorkingHoursDayResponse {
  const WorkingHoursDayResponse({required this.day, required this.slots});

  factory WorkingHoursDayResponse.fromJson(Map<String, dynamic> json) =>
      WorkingHoursDayResponse(
        day: json['day'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map(
              (slot) => WorkingHoursSlotResponse.fromJson(
                slot as Map<String, dynamic>,
              ),
            )
            .toList(),
      );

  final String day;
  final List<WorkingHoursSlotResponse> slots;

  Map<String, dynamic> toJson() => {
    'day': day,
    'slots': slots.map((slot) => slot.toJson()).toList(),
  };

  WorkingHoursDayEntity toEntity() => WorkingHoursDayEntity(
    day: day,
    slots: slots.map((slot) => slot.toEntity()).toList(),
  );
}

/// Mirrors `WorkingHoursResponseDto` exactly — both `GET` and `PUT`
/// `service-provider/working-hours` return this shape.
///
/// `availability` is a required key whose value may be `null` — that means
/// "no hours configured", distinct from an empty list.
class WorkingHoursResponse {
  const WorkingHoursResponse({required this.availability});

  factory WorkingHoursResponse.fromJson(Map<String, dynamic> json) {
    final availability = json['availability'] as List<dynamic>?;
    return WorkingHoursResponse(
      availability: availability
          ?.map(
            (day) =>
                WorkingHoursDayResponse.fromJson(day as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final List<WorkingHoursDayResponse>? availability;

  Map<String, dynamic> toJson() => {
    'availability': availability?.map((day) => day.toJson()).toList(),
  };

  List<WorkingHoursDayEntity>? toEntity() =>
      availability?.map((day) => day.toEntity()).toList();
}
