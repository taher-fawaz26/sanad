/// Backend endpoints for the service provider's weekly working hours.
abstract final class WorkingHoursApiPaths {
  WorkingHoursApiPaths._();

  /// `GET`/`PUT` — `WorkingHoursResponseDto` / `UpsertWorkingHoursDto`.
  static const String workingHours = 'service-provider/working-hours';
}
