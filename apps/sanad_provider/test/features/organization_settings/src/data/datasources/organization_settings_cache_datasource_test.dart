import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/organization_settings_cache_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/working_hours_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:storage/storage.dart';

// Verbatim `GET /settings` response fields reported against a live account.
const _coverId = 'ba3c3c36-1460-4c73-b65a-b1b3c3f0dc1d';
const _coverUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    '916d86ee-4c74-476d-b89a-31c7222ba752.jpg';
const _profileId = '93804ece-8166-4b6e-b1bf-371f9d067517';
const _profileUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    'e53d2bf5-3b96-48ce-ba3b-da6aa7da9d28.jpg';

/// Mimics Hive's real read-back behavior: nested maps degrade to
/// `Map<dynamic, dynamic>` (never stay `Map<String, dynamic>`), because the
/// box here is opened with an encryption cipher, so every read/write goes
/// through actual binary (de)serialization — never a live in-memory
/// reference. A fake that skipped this degradation would pass even if
/// `OrganizationSettingsCacheDataSource` never handled it, defeating the
/// point of this regression test.
class _FakeLocalStorage implements LocalStorage {
  final Map<String, Object?> _data = {};

  @override
  Future<void> save({
    required String key,
    required Object? value,
    String? boxName,
  }) async {
    _data[key] = _degrade(value);
  }

  @override
  Future<Object?> load({required String key, String? boxName}) async =>
      _data[key];

  @override
  Future<void> delete({required String key, String? boxName}) async {
    _data.remove(key);
  }

  Object? _degrade(Object? value) {
    if (value is Map) {
      return Map<dynamic, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key, _degrade(e.value))),
      );
    }
    if (value is List) return value.map(_degrade).toList();
    return value;
  }
}

Map<String, dynamic> _businessProfileJson() => {
  'id': 'biz-1',
  'businessName': 'Sanad Cleaning',
  'businessEmail': null,
  'businessPhone': null,
  'ownerEmiratesId': null,
  'tradeLicenseNumber': null,
  'coverImage': {'id': _coverId, 'url': _coverUrl},
  'profileImage': {'id': _profileId, 'url': _profileUrl},
  'description': null,
  'categories': <dynamic>[],
  'socialProfiles': null,
  'status': 'ACTIVE',
  'rejectionReason': null,
  'createdAt': '2024-01-01T00:00:00.000Z',
  'updatedAt': '2024-01-01T00:00:00.000Z',
};

void main() {
  late _FakeLocalStorage storage;
  late OrganizationSettingsCacheDataSourceImpl cache;

  setUp(() {
    storage = _FakeLocalStorage();
    cache = OrganizationSettingsCacheDataSourceImpl(storage);
  });

  group('OrganizationSettingsCacheDataSource profile round-trip', () {
    test(
      'coverImage and profileImage survive a full write → (Hive-shaped) '
      'read round-trip — this is the critical regression test for the '
      'reported "images show as placeholders" bug',
      () async {
        final response = MeSettingsResponse.fromJson({
          'businessProfile': _businessProfileJson(),
        });

        await cache.writeProfile('user-1', response);
        final cached = await cache.readProfile('user-1');

        expect(cached, isNotNull);
        final entity = cached!.toEntity();
        expect(entity.coverImage?.id, _coverId);
        expect(entity.coverImage?.url, _coverUrl);
        expect(entity.profileImage?.id, _profileId);
        expect(entity.profileImage?.url, _profileUrl);
      },
    );

    test('a null coverImage/profileImage round-trips as null', () async {
      final json = _businessProfileJson()
        ..['coverImage'] = null
        ..['profileImage'] = null;
      final response = MeSettingsResponse.fromJson({'businessProfile': json});

      await cache.writeProfile('user-1', response);
      final cached = await cache.readProfile('user-1');

      expect(cached!.toEntity().coverImage, isNull);
      expect(cached.toEntity().profileImage, isNull);
    });

    test('a cache miss (nothing written yet) returns null', () async {
      expect(await cache.readProfile('unknown-user'), isNull);
    });
  });

  group('OrganizationSettingsCacheDataSource working-hours round-trip', () {
    test('availability survives a write → read round-trip', () async {
      final response = WorkingHoursResponse.fromJson({
        'availability': [
          {
            'day': 'Saturday',
            'slots': [
              {'from': '09:00', 'to': '18:00'},
            ],
          },
        ],
      });

      await cache.writeWorkingHours('user-1', response);
      final cached = await cache.readWorkingHours('user-1');

      expect(cached!.toEntity(), const [
        WorkingHoursDayEntity(
          day: 'Saturday',
          slots: [WorkingHoursSlotEntity(from: '09:00', to: '18:00')],
        ),
      ]);
    });
  });
}
