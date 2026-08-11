import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';

/// Reads/writes the service provider's weekly working hours —
/// `service-provider/working-hours`.
abstract interface class WorkingHoursRepository {
  /// `GET` — `null` means no working hours are configured yet.
  TaskEither<Failure, List<WorkingHoursDayEntity>?> getWorkingHours();

  /// `PUT` — send an empty list to clear all working hours. Returns the
  /// persisted schedule as confirmed by the backend.
  TaskEither<Failure, List<WorkingHoursDayEntity>?> updateWorkingHours(
    List<WorkingHoursDayEntity> availability,
  );
}
