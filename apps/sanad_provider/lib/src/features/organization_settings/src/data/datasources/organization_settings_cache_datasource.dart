import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/working_hours_response.dart';
import 'package:storage/storage.dart';

/// Persisted cache for the general-settings business profile + working
/// hours — the two "display" reads a cold-open should show instantly.
/// Provider-completion and the category catalog stay network-only (a live
/// progress checklist and a picker-support list, respectively — staleness
/// there is either misleading or low-value).
///
/// Keys are namespaced by the signed-in user's id so a different account
/// logging in on the same device naturally misses the cache instead of
/// ever seeing a previous account's business data.
abstract interface class OrganizationSettingsCacheDataSource {
  Future<MeSettingsResponse?> readProfile(String userId);
  Future<void> writeProfile(String userId, MeSettingsResponse response);

  Future<WorkingHoursResponse?> readWorkingHours(String userId);
  Future<void> writeWorkingHours(String userId, WorkingHoursResponse response);
}

class OrganizationSettingsCacheDataSourceImpl
    implements OrganizationSettingsCacheDataSource {
  const OrganizationSettingsCacheDataSourceImpl(this._storage);

  final LocalStorage _storage;

  static const _boxName = HiveBoxes.organizationSettings;

  @override
  Future<MeSettingsResponse?> readProfile(String userId) async {
    final json = await _storage.load(
      key: _profileKey(userId),
      boxName: _boxName,
    );
    if (json is! Map) return null;
    try {
      return MeSettingsResponse.fromJson(_deepConvert(json));
    } on Object {
      // A stale/incompatible cached shape (e.g. after a schema change) is
      // not worth crashing over — treat it as a cache miss.
      return null;
    }
  }

  @override
  Future<void> writeProfile(
    String userId,
    MeSettingsResponse response,
  ) => _storage.save(
    key: _profileKey(userId),
    value: response.toJson(),
    boxName: _boxName,
  );

  @override
  Future<WorkingHoursResponse?> readWorkingHours(String userId) async {
    final json = await _storage.load(
      key: _workingHoursKey(userId),
      boxName: _boxName,
    );
    if (json is! Map) return null;
    try {
      return WorkingHoursResponse.fromJson(_deepConvert(json));
    } on Object {
      return null;
    }
  }

  @override
  Future<void> writeWorkingHours(
    String userId,
    WorkingHoursResponse response,
  ) => _storage.save(
    key: _workingHoursKey(userId),
    value: response.toJson(),
    boxName: _boxName,
  );

  String _profileKey(String userId) => 'profile_$userId';
  String _workingHoursKey(String userId) => 'working_hours_$userId';

  /// Hive returns nested maps as `Map<dynamic, dynamic>` (not
  /// `Map<String, dynamic>`) on read-back, unlike `dart:convert`'s
  /// `jsonDecode` — the DTOs' `fromJson` casts assume the latter. Recursively
  /// normalizes so a cache-sourced payload parses identically to a live HTTP
  /// response.
  Map<String, dynamic> _deepConvert(Object? value) {
    if (value is Map) {
      return value.map(
        (key, val) => MapEntry(key as String, _deepConvertValue(val)),
      );
    }
    throw ArgumentError('Expected a Map, got ${value.runtimeType}');
  }

  Object? _deepConvertValue(Object? value) {
    if (value is Map) return _deepConvert(value);
    if (value is List) return value.map(_deepConvertValue).toList();
    return value;
  }
}
