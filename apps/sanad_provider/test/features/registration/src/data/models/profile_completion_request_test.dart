import 'package:auth/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_request.dart';

/// Locks in the `auth/profile` (`CreateProviderProfileDto`) request body
/// shape after the backend dropped `representativeFullName` from the
/// contract — the field must never be serialized again.
void main() {
  group('ProfileCompletionRequest.toJson', () {
    test('organization payload has businessName and no representativeName', () {
      const request = ProfileCompletionRequest(
        emiratesIdFrontId: 'front-1',
        emiratesIdBackId: 'back-1',
        userType: UserType.organizationProvider,
        tradeLicenseId: 'tl-1',
        businessName: 'Acme LLC',
      );

      final json = request.toJson();

      expect(json, {
        'emiratesIdFrontId': 'front-1',
        'emiratesIdBackId': 'back-1',
        'userType': 'organizationProvider',
        'tradeLicenseId': 'tl-1',
        'businessName': 'Acme LLC',
      });
      expect(json.containsKey('representativeName'), isFalse);
      expect(json.containsKey('representativeFullName'), isFalse);
      expect(json.containsKey('fullName'), isFalse);
    });

    test('individual payload has fullName and no representativeName', () {
      const request = ProfileCompletionRequest(
        emiratesIdFrontId: 'front-1',
        emiratesIdBackId: 'back-1',
        userType: UserType.individualProvider,
        fullName: 'Ahmed Mohammed',
      );

      final json = request.toJson();

      expect(json, {
        'emiratesIdFrontId': 'front-1',
        'emiratesIdBackId': 'back-1',
        'userType': 'individualProvider',
        'fullName': 'Ahmed Mohammed',
      });
      expect(json.containsKey('representativeName'), isFalse);
      expect(json.containsKey('representativeFullName'), isFalse);
      expect(json.containsKey('businessName'), isFalse);
      expect(json.containsKey('tradeLicenseId'), isFalse);
    });
  });
}
