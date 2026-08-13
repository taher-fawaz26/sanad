import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/business_profile_me_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/me_settings_response.dart';

// Verbatim `GET /settings` response fields reported against a live account.
const _coverId = 'ba3c3c36-1460-4c73-b65a-b1b3c3f0dc1d';
const _coverUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    '916d86ee-4c74-476d-b89a-31c7222ba752.jpg';
const _profileId = '93804ece-8166-4b6e-b1bf-371f9d067517';
const _profileUrl =
    'https://sanad-dev-bucket.s3.eu-central-1.amazonaws.com/media/'
    'e53d2bf5-3b96-48ce-ba3b-da6aa7da9d28.jpg';

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
  group('BusinessProfileMeResponse image mapping', () {
    test('fromJson.toEntity preserves both coverImage and profileImage', () {
      final response = BusinessProfileMeResponse.fromJson(
        _businessProfileJson(),
      );
      final entity = response.toEntity();

      expect(entity.coverImage?.id, _coverId);
      expect(entity.coverImage?.url, _coverUrl);
      expect(entity.profileImage?.id, _profileId);
      expect(entity.profileImage?.url, _profileUrl);
    });

    test(
      'MeSettingsResponse (the actual GET /settings envelope) preserves '
      'both images through to the entity',
      () {
        final response = MeSettingsResponse.fromJson({
          'businessProfile': _businessProfileJson(),
        });
        final entity = response.toEntity();

        expect(entity.coverImage?.url, _coverUrl);
        expect(entity.profileImage?.url, _profileUrl);
      },
    );
  });
}
