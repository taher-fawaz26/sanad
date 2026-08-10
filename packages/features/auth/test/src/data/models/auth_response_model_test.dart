import 'package:auth/src/data/models/auth_response_model.dart';
import 'package:auth/src/data/models/profiles/auth_profile_model.dart';
import 'package:auth/src/data/models/responses/auth_account_settings_response_dto.dart';
import 'package:auth/src/data/models/responses/auth_session_response_dto.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/enums/auth_session_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every payload below is verbatim (tokens shortened) from the live dev API
/// (`https://dev-api.trysanad.us/api/docs-json`), captured against
/// `AuthSessionResponseDto` / `OnboardingAuthResponseDto` /
/// `BusinessProviderAuthProfileResponseDto` /
/// `ClientAuthProfileResponseDto` / `WorkerAuthProfileResponseDto` /
/// `AuthSessionResponseDto.accountSettings`. This test suite is the contract
/// check against that schema — it must be re-verified whenever the Swagger
/// spec changes.
void main() {
  group('AuthResponseModel.fromJson — dispatch by status', () {
    test('status: authenticated → AuthSessionEntity', () {
      final response = AuthResponseModel.fromJson({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'status': 'authenticated',
        'isEmailVerified': true,
        'isProfileCreated': true,
        'user': {
          'id': 'sub-123',
          'email': 'user@example.com',
          'userType': 'client',
          'isVerified': true,
          'isActive': true,
        },
        'permissions': ['*'],
      });

      expect(response, isA<AuthSessionEntity>());
      expect(
        (response as AuthSessionEntity).status,
        AuthSessionStatus.authenticated,
      );
    });

    test('status: onboarding → OnboardingAuthEntity', () {
      final response = AuthResponseModel.fromJson({
        'status': 'onboarding',
        'onboardingToken': 'onboarding-token',
        'isEmailVerified': true,
        'isProfileCreated': false,
        'user': {
          'id': 'sub-123',
          'email': 'user@example.com',
          'isVerified': true,
        },
      });

      expect(response, isA<OnboardingAuthEntity>());
      final onboarding = response as OnboardingAuthEntity;
      expect(onboarding.status, AuthSessionStatus.onboarding);
      expect(onboarding.onboardingToken, 'onboarding-token');
      expect(onboarding.isProfileCreated, isFalse);
    });

    test('missing status throws FormatException', () {
      expect(
        () => AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'user': {'id': 'x', 'email': 'x@x.com', 'isVerified': true},
        }),
        throwsFormatException,
      );
    });

    test('unknown status value throws FormatException', () {
      expect(
        () => AuthResponseModel.fromJson({
          'status': 'banned',
          'user': {'id': 'x', 'email': 'x@x.com', 'isVerified': true},
        }),
        throwsFormatException,
      );
    });
  });

  group('UserType.fromString — legacy alias', () {
    test('retired "companyProvider" wire/cache value still parses', () {
      // A session cached by a pre-rename build may still have this value on
      // disk — must self-heal rather than crash the splash screen.
      expect(
        UserType.fromString('companyProvider'),
        UserType.organizationProvider,
      );
      expect(
        UserType.fromString('COMPANYPROVIDER'),
        UserType.organizationProvider,
      );
    });

    test('current wire value parses directly', () {
      expect(
        UserType.fromString('organizationProvider'),
        UserType.organizationProvider,
      );
    });

    test('manager is a top-level userType distinct from worker', () {
      expect(UserType.fromString('manager'), UserType.manager);
    });
  });

  group('AuthSessionResponseModel.fromJson — profile oneOf by userType', () {
    test('company provider — live payload, business fields null', () {
      // Verbatim from live POST /auth/profile for
      // seed-company-provider-1@sanad.test.
      final response = AuthResponseModel.fromJson({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'status': 'authenticated',
        'isEmailVerified': true,
        'isProfileCreated': true,
        'user': {
          'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
          'email': 'seed-company-provider-1@sanad.test',
          'userType': 'organizationProvider',
          'isVerified': true,
          'isActive': true,
        },
        'profile': {
          'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
          'businessName': 'Company Provider 1 LLC',
          'businessEmail': null,
          'businessPhone': null,
          'tradeLicenseNumber': null,
          'isReviewed': true,
        },
        'accountSettings': {
          'id': 'e3521ee5-3f43-4af1-819b-8c0f1f164a5f',
          'name': 'Layla Al Mansoori',
          'email': 'seed-company-provider-1@sanad.test',
          'phone': null,
          'preferredLanguage': 'ar',
        },
        'permissions': ['*'],
      });

      final session = response as AuthSessionEntity;
      expect(session.user.type, UserType.organizationProvider);
      expect(session.profile, isA<BusinessProviderProfileModel>());
      final profile = session.profile! as BusinessProviderProfileModel;
      expect(profile.businessName, 'Company Provider 1 LLC');
      expect(profile.businessEmail, isNull);
      expect(profile.businessPhone, isNull);
      expect(profile.tradeLicenseNumber, isNull);
      expect(profile.isReviewed, isTrue);

      expect(session.accountSettings, isA<AuthAccountSettingsModel>());
      final settings = session.accountSettings!;
      expect(settings.name, 'Layla Al Mansoori');
      expect(settings.phone, isNull);
      expect(settings.preferredLanguage, 'ar');
    });

    test(
      'individual provider — dispatches to the same BusinessProvider shape',
      () {
        final response = AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': 'ind-1',
            'email': 'individual@sanad.test',
            'userType': 'individualProvider',
            'isVerified': true,
            'isActive': true,
          },
          'profile': {
            'id': 'ind-1',
            'businessName': 'Handy Fixes',
            'businessEmail': 'handy@sanad.test',
            'businessPhone': '+971500000000',
            'tradeLicenseNumber': null,
            'isReviewed': false,
          },
          'permissions': ['*'],
        });

        final session = response as AuthSessionEntity;
        expect(session.user.type, UserType.individualProvider);
        expect(session.profile, isA<BusinessProviderProfileModel>());
        final profile = session.profile! as BusinessProviderProfileModel;
        expect(profile.businessName, 'Handy Fixes');
        expect(profile.businessEmail, 'handy@sanad.test');
        expect(profile.businessPhone, '+971500000000');
        expect(profile.isReviewed, isFalse);
        // No accountSettings sent this time — must be null, not a crash.
        expect(session.accountSettings, isNull);
      },
    );

    test(
      'business provider — every nullable field absent (fresh onboarding)',
      () {
        final response = AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': 'fresh-1',
            'email': 'fresh@sanad.test',
            'userType': 'organizationProvider',
            'isVerified': true,
            'isActive': true,
          },
          'profile': {'id': 'fresh-1', 'isReviewed': false},
          'permissions': ['*'],
        });

        final session = response as AuthSessionEntity;
        final profile = session.profile! as BusinessProviderProfileModel;
        expect(profile.id, 'fresh-1');
        expect(profile.businessName, isNull);
        expect(profile.businessEmail, isNull);
        expect(profile.businessPhone, isNull);
        expect(profile.tradeLicenseNumber, isNull);
        expect(profile.isReviewed, isFalse);
      },
    );

    test('business provider — missing required isReviewed throws', () {
      expect(
        () => AuthResponseModel.fromJson({
          'accessToken': 'a',
          'refreshToken': 'r',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': 'x',
            'email': 'x@x.com',
            'userType': 'organizationProvider',
            'isVerified': true,
            'isActive': true,
          },
          'profile': {'id': 'x'},
          'permissions': ['*'],
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('client profile', () {
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

      final session = response as AuthSessionEntity;
      expect(session.profile, isA<ClientProfileModel>());
      final profile = session.profile! as ClientProfileModel;
      expect(profile.fullName, 'Test User');
      expect(profile.emiratesId, '784-0000-0000000-0');
      expect(session.permissions.single.name, 'read');
    });

    test('worker profile', () {
      final response = AuthResponseModel.fromJson({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'status': 'authenticated',
        'isEmailVerified': true,
        'isProfileCreated': true,
        'user': {
          'id': 'worker-1',
          'email': 'worker@example.com',
          'isVerified': true,
          'isActive': true,
          'userType': 'worker',
        },
        'profile': {
          'id': 'worker-profile-1',
          'name': 'Worker One',
          'phoneNumber': '+971500000001',
          'jobTitle': 'Technician',
          'type': 'worker',
          'status': 'active',
        },
        'permissions': ['*'],
      });

      final session = response as AuthSessionEntity;
      expect(session.profile, isA<WorkerProfileModel>());
      final profile = session.profile! as WorkerProfileModel;
      expect(profile.name, 'Worker One');
      expect(profile.jobTitle, 'Technician');
    });

    test(
      'profile omitted entirely — tolerated despite isProfileCreated: true',
      () {
        // Real-world behavior: auth/profile sometimes omits `profile` even
        // when isProfileCreated is true. Swagger marks profile as required, but
        // production does not always honor that — this must not throw.
        final response = AuthResponseModel.fromJson({
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': 'sub-123',
            'email': 'user@example.com',
            'userType': 'organizationProvider',
          },
          'permissions': ['*'],
        });

        final session = response as AuthSessionEntity;
        expect(session.profile, isNull);
        expect(session.accountSettings, isNull);
        // Filled from top-level isEmailVerified when user.isVerified is absent.
        expect(session.user.isVerified, isTrue);
      },
    );
  });

  group('AuthAccountSettingsModel.fromJson', () {
    test('invalid preferredLanguage throws FormatException', () {
      expect(
        () => AuthAccountSettingsModel.fromJson(const {
          'id': 'x',
          'name': 'x',
          'email': 'x@x.com',
          'phone': null,
          'preferredLanguage': 'fr',
        }),
        throwsFormatException,
      );
    });

    test('nullable name and phone are tolerated', () {
      final settings = AuthAccountSettingsModel.fromJson(const {
        'id': 'x',
        'name': null,
        'email': 'x@x.com',
        'phone': null,
        'preferredLanguage': 'en',
      });
      expect(settings.name, isNull);
      expect(settings.phone, isNull);
      expect(settings.preferredLanguage, 'en');
    });
  });

  group('AuthProfileModel.fromJson — admin has no profile shape', () {
    test('throws for UserType.admin', () {
      expect(
        () => AuthProfileModel.fromJson(
          userType: UserType.admin,
          json: {'id': 'x'},
        ),
        throwsStateError,
      );
    });
  });

  group('AuthSessionResponseModel — JSON round-trip (Hive persistence)', () {
    test(
      'company provider session with accountSettings round-trips losslessly',
      () {
        final json = {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'status': 'authenticated',
          'isEmailVerified': true,
          'isProfileCreated': true,
          'user': {
            'id': 'e3521ee5',
            'email': 'seed@sanad.test',
            'userType': 'organizationProvider',
            'isVerified': true,
            'isActive': true,
          },
          'profile': {
            'id': 'e3521ee5',
            'businessName': 'Sanad LLC',
            'businessEmail': null,
            'businessPhone': null,
            'tradeLicenseNumber': null,
            'isReviewed': true,
          },
          'accountSettings': {
            'id': 'e3521ee5',
            'name': 'Layla Al Mansoori',
            'email': 'seed@sanad.test',
            'phone': null,
            'preferredLanguage': 'ar',
          },
          'permissions': ['*'],
        };

        final parsed = AuthSessionResponseModel.fromJson(json);
        final reserialised = parsed.toJson();
        final reparsed = AuthSessionResponseModel.fromJson(reserialised);

        // Equatable on the entity gives us a full field-by-field diff.
        expect(reparsed, parsed);
        // And the serialised map matches the original produced form.
        expect(reserialised, parsed.toJson());
      },
    );

    test('worker session without accountSettings round-trips', () {
      final json = {
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'status': 'authenticated',
        'isEmailVerified': true,
        'isProfileCreated': true,
        'user': {
          'id': 'worker-1',
          'email': 'worker@example.com',
          'userType': 'worker',
          'isVerified': true,
          'isActive': true,
        },
        'profile': {
          'id': 'worker-profile-1',
          'name': 'Worker One',
          'phoneNumber': '+971500000001',
          'jobTitle': 'Technician',
          'type': 'worker',
          'status': 'active',
        },
        'permissions': [
          {'name': 'branch:view'},
        ],
      };

      final parsed = AuthSessionResponseModel.fromJson(json);
      final reparsed = AuthSessionResponseModel.fromJson(parsed.toJson());
      expect(reparsed, parsed);
      expect(reparsed.accountSettings, isNull);
    });
  });
}
