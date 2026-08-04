import 'package:auth/src/data/models/auth_response_model.dart';
import 'package:auth/src/data/models/profiles/client_profile_model.dart';
import 'package:auth/src/data/models/profiles/company_provider_profile_model.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthResponseModel.fromJson', () {
    test(
      'parses seed company-provider verify payload with null profile fields',
      () {
        // Shape from live POST /auth/email/verify for
        // seed-company-provider-1@sanad.test (tokens omitted).
        // Document media IDs and trade/emirates numbers may be null/omitted.
        final response = AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': '50474af3-7579-4f1c-9372-103de77c0754',
            'email': 'seed-company-provider-1@sanad.test',
            'userType': 'companyProvider',
            'isVerified': true,
            'isActive': true,
          },
          'profile': {
            'id': '50474af3-7579-4f1c-9372-103de77c0754',
            'businessName': 'Company Provider 1 LLC',
            'businessEmail': 'seed-company-provider-1@sanad.test',
            'tradeLicenseNumber': null,
            'representativeFullName': 'Company Representative 1',
            'representativeEmail': 'seed-company-rep-1@sanad.test',
            'representativeEmiratesId': null,
            'isReviewed': true,
            'preferredLanguage': 'en',
          },
          'permissions': ['*'],
        });

        expect(response, isA<AuthSessionEntity>());
        final session = response as AuthSessionEntity;
        expect(session.status, 'authenticated');
        expect(session.user.type, UserType.companyProvider);
        expect(session.user.isVerified, isTrue);
        expect(session.profile, isA<CompanyProviderProfileModel>());
        final profile = session.profile! as CompanyProviderProfileModel;
        expect(profile.tradeLicenseNumber, isNull);
        expect(profile.representativeEmiratesId, isNull);
        expect(profile.emiratesIdFrontId, isNull);
        expect(profile.emiratesIdBackId, isNull);
        expect(profile.tradeLicenseId, isNull);
        expect(profile.businessName, 'Company Provider 1 LLC');
        expect(session.permissions.single.name, '*');
      },
    );

    test(
      'parses minimal authenticated verify payload without profile or '
      'user.isVerified',
      () {
        final response = AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': '50474af3-7579-4f1c-9372-103de77c0754',
            'email': 'seed-company-provider-1@sanad.test',
            'userType': 'companyProvider',
          },
          'permissions': ['*'],
        });

        expect(response, isA<AuthSessionEntity>());
        final session = response as AuthSessionEntity;
        expect(session.accessToken, 'access-token');
        expect(session.refreshToken, 'refresh-token');
        expect(session.status, 'authenticated');
        expect(session.isEmailVerified, isTrue);
        expect(session.isProfileCreated, isTrue);
        expect(session.profile, isNull);
        expect(session.user.id, '50474af3-7579-4f1c-9372-103de77c0754');
        expect(session.user.email, 'seed-company-provider-1@sanad.test');
        expect(session.user.type, UserType.companyProvider);
        // Filled from top-level isEmailVerified when user.isVerified is absent.
        expect(session.user.isVerified, isTrue);
        expect(session.permissions, hasLength(1));
        expect(session.permissions.single.name, '*');
      },
    );

    test('parses full authenticated session with profile', () {
      final response = AuthResponseModel.fromJson({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'status': 'authenticated',
        'isEmailVerified': true,
        'isProfileCreated': true,
        'user': {
          'id': 'sub-123',
          'email': 'user@example.com',
          'isVerified': true,
          'isActive': true,
          'userType': 'client',
        },
        'profile': {
          'id': 'profile-1',
          'fullName': 'Test User',
          'email': 'user@example.com',
          'emiratesId': '784-0000-0000000-0',
        },
        'permissions': [
          {'name': 'read'},
        ],
      });

      expect(response, isA<AuthSessionEntity>());
      final session = response as AuthSessionEntity;
      expect(session.profile, isA<ClientProfileModel>());
      expect(session.user.isVerified, isTrue);
      expect(session.user.type, UserType.client);
      expect(session.permissions.single.name, 'read');
    });

    test('parses onboarding response when accessToken is absent', () {
      final response = AuthResponseModel.fromJson({
        'status': 'onboarding',
        'onboardingToken': 'onboarding-token',
        'isEmailVerified': true,
        'isProfileCreated': false,
        'user': {
          'id': 'sub-123',
          'email': 'user@example.com',
          'isVerified': true,
          'userType': 'client',
        },
      });

      expect(response, isA<OnboardingAuthEntity>());
      final onboarding = response as OnboardingAuthEntity;
      expect(onboarding.onboardingToken, 'onboarding-token');
      expect(onboarding.isProfileCreated, isFalse);
    });
  });
}
