import 'dart:async';

import 'package:auth/auth.dart' show SessionManager;
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_cache_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/working_hours_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/working_hours_repository.dart';

class WorkingHoursRepositoryImpl implements WorkingHoursRepository {
  const WorkingHoursRepositoryImpl(
    this._remote,
    this._networkGuard,
    this._cache,
    this._sessionManager,
  );

  final WorkingHoursRemoteDataSource _remote;
  final NetworkGuard _networkGuard;
  final OrganizationSettingsCacheDataSource _cache;
  final SessionManager _sessionManager;

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> getWorkingHours() =>
      _networkGuard.execute(
        action: _remote.getWorkingHours().map((response) {
          final userId = _sessionManager.user?.id;
          if (userId != null) {
            unawaited(_cache.writeWorkingHours(userId, response));
          }
          return response.toEntity();
        }),
      );

  @override
  Future<List<WorkingHoursDayEntity>?> getCachedWorkingHours() async {
    final userId = _sessionManager.user?.id;
    if (userId == null) return null;
    final cached = await _cache.readWorkingHours(userId);
    return cached?.toEntity();
  }

  @override
  TaskEither<Failure, List<WorkingHoursDayEntity>?> updateWorkingHours(
    List<WorkingHoursDayEntity> availability,
  ) => _networkGuard.execute(
    action: _remote.updateWorkingHours(availability).map((response) {
      final userId = _sessionManager.user?.id;
      if (userId != null) {
        unawaited(_cache.writeWorkingHours(userId, response));
      }
      return response.toEntity();
    }),
  );
}
