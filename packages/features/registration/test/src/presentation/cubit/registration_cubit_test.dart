// ignore_for_file: prefer_const_constructors // bloc_test act lambdas prevent const inference

import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart'
    show AuthSessionEntity, UserEntity, UserType, PermissionEntity;
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/domain/entities/media_file_entity.dart';
import 'package:registration/src/domain/failures/registration_failure.dart';
import 'package:registration/src/domain/provider_type/provider_type_registry.dart';
import 'package:registration/src/domain/usecases/complete_profile_usecase.dart';
import 'package:registration/src/domain/usecases/extract_documents_usecase.dart';
import 'package:registration/src/domain/usecases/upload_single_media_usecase.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/models/registration_document_slot.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

class _MockUploadUseCase extends Mock implements UploadSingleMediaUseCase {}

class _MockExtractUseCase extends Mock implements ExtractDocumentsUseCase {}

class _MockCompleteProfileUseCase extends Mock
    implements CompleteProfileUseCase {}

// ── Fixtures ───────────────────────────────────────────────────────────────

const _kToken = 'onboarding-token-123';
const _kEmail = 'user@example.com';
const _kFrontId = 'front-media-id';
const _kBackId = 'back-media-id';

final _tAsset = PickedAsset(
  name: 'id_front.jpg',
  path: '/tmp/id_front.jpg',
  mimeType: 'image/jpeg',
  size: 512 * 1024,
  assetType: AssetType.image,
);

final _tUploadable = _tAsset.toUploadable();

final _tMediaFile = MediaFileEntity(
  id: _kFrontId,
  originalName: 'id_front.jpg',
  fileName: 'id_front.jpg',
  mimeType: 'image/jpeg',
  size: 512 * 1024,
  type: 'image',
  url: 'https://example.com/front.jpg',
  createdAt: DateTime(2025),
);

const _tExtractionResult = ExtractionResult(
  emiratesId: EmiratesIdResult(
    fullNameEn: 'John Doe',
    fullNameAr: 'جون دو',
    idNumber: '784-1990-0000001-1',
    nationality: 'UAE',
    dateOfBirth: '01/01/1990',
    expiryDate: '01/01/2030',
    gender: 'Male',
  ),
);

final _tAuthSession = AuthSessionEntity(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  status: 'authenticated',
  isEmailVerified: true,
  isProfileCreated: false,
  user: UserEntity(
    id: 'user-1',
    email: _kEmail,
    isVerified: true,
    isActive: true,
    type: UserType.individualProvider,
  ),
  permissions: const <PermissionEntity>[],
);

// ── Cubit factory ──────────────────────────────────────────────────────────

RegistrationCubit _makeCubit({
  _MockUploadUseCase? upload,
  _MockExtractUseCase? extract,
  _MockCompleteProfileUseCase? complete,
}) =>
    RegistrationCubit(
      uploadMedia: upload ?? _MockUploadUseCase(),
      extractDocuments: extract ?? _MockExtractUseCase(),
      completeProfile: complete ?? _MockCompleteProfileUseCase(),
    );

// ── Seeded state helpers ───────────────────────────────────────────────────

RegistrationState _uploadedIdsState() => RegistrationState(
      onboardingToken: _kToken,
      email: _kEmail,
      emiratesIdFront: _tUploadable.markUploaded(
        remoteId: _kFrontId,
        remoteUrl: 'https://example.com/front.jpg',
      ),
      emiratesIdBack: _tUploadable.markUploaded(
        remoteId: _kBackId,
        remoteUrl: 'https://example.com/back.jpg',
      ),
    );

RegistrationState _individualSeedState() => _uploadedIdsState().copyWith(
      providerType: ProviderTypeRegistry.individual,
      fullName: 'John Doe',
    );

RegistrationState _orgSeedState() => _uploadedIdsState().copyWith(
      providerType: ProviderTypeRegistry.company,
      businessName: 'Test LLC',
      representativeName: 'Jane Smith',
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(
      UploadSingleMediaParams(
        filePath: '',
        fileName: '',
        mimeType: '',
        authorizationToken: '',
        uploadKey: '',
      ),
    );
    registerFallbackValue(
      const ExtractDocumentsParams(
        authorizationToken: '',
        emiratesIdFrontId: '',
        emiratesIdBackId: '',
      ),
    );
    registerFallbackValue(
      CompleteProfileParams(
        authorizationToken: '',
        emiratesIdFrontId: '',
        emiratesIdBackId: '',
        providerType: ProviderTypeRegistry.individual,
      ),
    );
  });

  // ── Plain setters ─────────────────────────────────────────────────────────

  group('setOnboarding', () {
    test('populates email and onboardingToken', () {
      final cubit = _makeCubit();
      cubit.setOnboarding(email: _kEmail, onboardingToken: _kToken);
      expect(cubit.state.email, _kEmail);
      expect(cubit.state.onboardingToken, _kToken);
    });
  });

  group('setProviderType', () {
    test('stores provider type and reflects isOrganization', () {
      final cubit = _makeCubit();
      cubit.setProviderType(ProviderTypeRegistry.company);
      expect(cubit.state.providerType, ProviderTypeRegistry.company);
      expect(cubit.state.isOrganization, isTrue);
    });

    test('individual type — isOrganization is false', () {
      final cubit = _makeCubit();
      cubit.setProviderType(ProviderTypeRegistry.individual);
      expect(cubit.state.isOrganization, isFalse);
    });
  });

  // ── uploadDocument ────────────────────────────────────────────────────────

  group('uploadDocument', () {
    blocTest<RegistrationCubit, RegistrationState>(
      'emits uploading then uploaded on success',
      build: () {
        final upload = _MockUploadUseCase();
        when(() => upload(any())).thenReturn(TaskEither.right(_tMediaFile));
        final cubit = _makeCubit(upload: upload);
        cubit.setOnboarding(email: _kEmail, onboardingToken: _kToken);
        return cubit;
      },
      act: (cubit) => cubit.uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: _tAsset,
      ),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.emiratesIdFront?.isUploading,
          'uploading',
          isTrue,
        ),
        isA<RegistrationState>().having(
          (s) => s.emiratesIdFront?.isUploaded,
          'uploaded',
          isTrue,
        ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits failed and sets UploadFailure on network error',
      build: () {
        final upload = _MockUploadUseCase();
        when(() => upload(any())).thenReturn(
          TaskEither.left(
            const NetworkFailure(message: 'errors.no_internet'),
          ),
        );
        final cubit = _makeCubit(upload: upload);
        cubit.setOnboarding(email: _kEmail, onboardingToken: _kToken);
        return cubit;
      },
      act: (cubit) => cubit.uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: _tAsset,
      ),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.emiratesIdFront?.isUploading,
          'uploading',
          isTrue,
        ),
        isA<RegistrationState>()
            .having(
              (s) => s.emiratesIdFront?.status,
              'failed status',
              UploadStatus.failed,
            )
            .having(
              (s) => s.failure,
              'upload failure',
              isA<UploadFailure>().having(
                (f) => f.messageKey,
                'key',
                'errors.no_internet',
              ),
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'clears slot silently on request_cancelled',
      build: () {
        final upload = _MockUploadUseCase();
        when(() => upload(any())).thenReturn(
          TaskEither.left(
            const NetworkFailure(message: 'errors.request_cancelled'),
          ),
        );
        final cubit = _makeCubit(upload: upload);
        cubit.setOnboarding(email: _kEmail, onboardingToken: _kToken);
        return cubit;
      },
      act: (cubit) => cubit.uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: _tAsset,
      ),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.emiratesIdFront?.isUploading,
          'uploading',
          isTrue,
        ),
        isA<RegistrationState>()
            .having((s) => s.emiratesIdFront, 'slot cleared', isNull)
            .having((s) => s.failure, 'no failure', isNull),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits unauthorized failure when onboardingToken is missing',
      build: _makeCubit,
      act: (cubit) => cubit.uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: _tAsset,
      ),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.failure,
          'unauthorized failure',
          isA<UploadFailure>().having(
            (f) => f.messageKey,
            'key',
            'errors.unauthorized',
          ),
        ),
      ],
    );
  });

  // ── extractDocuments ──────────────────────────────────────────────────────

  group('extractDocuments', () {
    blocTest<RegistrationCubit, RegistrationState>(
      'emits extracting → done with result on success',
      build: () {
        final extract = _MockExtractUseCase();
        when(() => extract(any())).thenReturn(
          TaskEither.right(_tExtractionResult),
        );
        return _makeCubit(extract: extract);
      },
      seed: _uploadedIdsState,
      act: (cubit) => cubit.extractDocuments(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'extracting',
          isA<PhaseExtracting>(),
        ),
        isA<RegistrationState>()
            .having((s) => s.phase, 'done', isA<PhaseExtractionDone>())
            .having((s) => s.extraction, 'result set', isNotNull)
            .having((s) => s.failure, 'no failure', isNull),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits failed (NOT unclear) for network / server errors',
      build: () {
        final extract = _MockExtractUseCase();
        when(() => extract(any())).thenReturn(
          TaskEither.left(
            const NoInternetFailure(message: 'errors.no_internet'),
          ),
        );
        return _makeCubit(extract: extract);
      },
      seed: _uploadedIdsState,
      act: (cubit) => cubit.extractDocuments(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'extracting',
          isA<PhaseExtracting>(),
        ),
        isA<RegistrationState>()
            .having((s) => s.phase, 'failed — not done', isA<PhaseExtractionFailed>())
            .having((s) => s.extraction, 'no extraction result', isNull)
            .having(
              (s) => s.failure,
              'extraction failure set',
              isA<ExtractionFailure>(),
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits done with alreadyRegistered issue for 409 ConflictFailure',
      build: () {
        final extract = _MockExtractUseCase();
        when(() => extract(any())).thenReturn(
          TaskEither.left(
            const ConflictFailure(message: 'errors.conflict'),
          ),
        );
        return _makeCubit(extract: extract);
      },
      seed: _uploadedIdsState,
      act: (cubit) => cubit.extractDocuments(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'extracting',
          isA<PhaseExtracting>(),
        ),
        isA<RegistrationState>()
            .having((s) => s.phase, 'done — not failed', isA<PhaseExtractionDone>())
            .having(
              (s) => s.extraction?.emiratesId.issue,
              'alreadyRegistered',
              DocumentIssue.alreadyRegistered,
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits failed with required_fields_missing when token/IDs are absent',
      build: _makeCubit,
      act: (cubit) => cubit.extractDocuments(),
      expect: () => [
        isA<RegistrationState>()
            .having((s) => s.phase, 'failed', isA<PhaseExtractionFailed>())
            .having(
              (s) => s.failure,
              'extraction failure',
              isA<ExtractionFailure>()
                  .having((f) => f.messageKey, 'key', 'errors.required_fields_missing')
                  .having((f) => f.kind, 'kind', ExtractionFailureKind.missingToken),
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'transitions back to extracting → done on retry after failure',
      build: () {
        final extract = _MockExtractUseCase();
        when(() => extract(any())).thenReturn(
          TaskEither.right(_tExtractionResult),
        );
        return _makeCubit(extract: extract);
      },
      seed: () => _uploadedIdsState().copyWith(
        phase: const PhaseExtractionFailed(),
        failure: const ExtractionFailure(
          messageKey: 'errors.timeout',
          kind: ExtractionFailureKind.server,
        ),
      ),
      act: (cubit) => cubit.extractDocuments(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'back to extracting',
          isA<PhaseExtracting>(),
        ),
        isA<RegistrationState>().having(
          (s) => s.phase,
          'done after retry',
          isA<PhaseExtractionDone>(),
        ),
      ],
    );
  });

  // ── completeProfile ───────────────────────────────────────────────────────

  group('completeProfile', () {
    blocTest<RegistrationCubit, RegistrationState>(
      'emits submitting → done and returns AuthSessionEntity on success',
      build: () {
        final complete = _MockCompleteProfileUseCase();
        when(() => complete(any())).thenReturn(
          TaskEither.right(_tAuthSession),
        );
        return _makeCubit(complete: complete);
      },
      seed: _individualSeedState,
      act: (cubit) => cubit.completeProfile(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'submitting',
          isA<PhaseSubmitting>(),
        ),
        isA<RegistrationState>().having(
          (s) => s.phase,
          'done',
          isA<PhaseSubmissionDone>(),
        ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits submitting → failed and sets ProfileFailure on API error',
      build: () {
        final complete = _MockCompleteProfileUseCase();
        when(() => complete(any())).thenReturn(
          TaskEither.left(
            const ServerFailure(message: 'errors.server_error'),
          ),
        );
        return _makeCubit(complete: complete);
      },
      seed: _individualSeedState,
      act: (cubit) => cubit.completeProfile(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'submitting',
          isA<PhaseSubmitting>(),
        ),
        isA<RegistrationState>()
            .having((s) => s.phase, 'failed', isA<PhaseSubmissionFailed>())
            .having(
              (s) => s.failure,
              'profile failure',
              isA<ProfileFailure>().having(
                (f) => f.messageKey,
                'key',
                'errors.server_error',
              ),
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'emits failed immediately when required fields (token/IDs) are missing',
      build: _makeCubit,
      act: (cubit) => cubit.completeProfile(),
      expect: () => [
        isA<RegistrationState>()
            .having((s) => s.phase, 'failed', isA<PhaseSubmissionFailed>())
            .having(
              (s) => s.failure,
              'profile failure',
              isA<ProfileFailure>().having(
                (f) => f.messageKey,
                'key',
                'errors.required_fields_missing',
              ),
            ),
      ],
    );

    blocTest<RegistrationCubit, RegistrationState>(
      'org path: emits done and completes without error',
      build: () {
        final complete = _MockCompleteProfileUseCase();
        when(() => complete(any())).thenReturn(
          TaskEither.right(_tAuthSession),
        );
        return _makeCubit(complete: complete);
      },
      seed: _orgSeedState,
      act: (cubit) => cubit.completeProfile(),
      expect: () => [
        isA<RegistrationState>().having(
          (s) => s.phase,
          'submitting',
          isA<PhaseSubmitting>(),
        ),
        isA<RegistrationState>().having(
          (s) => s.phase,
          'done',
          isA<PhaseSubmissionDone>(),
        ),
      ],
    );
  });

  // ── RegistrationState helpers ─────────────────────────────────────────────

  group('RegistrationState', () {
    test('hasBothIdSides is false when slots are null', () {
      expect(const RegistrationState().hasBothIdSides, isFalse);
    });

    test('hasBothIdSides is true when both are uploaded', () {
      final state = RegistrationState(
        emiratesIdFront: _tUploadable.markUploaded(remoteId: 'a', remoteUrl: ''),
        emiratesIdBack: _tUploadable.markUploaded(remoteId: 'b', remoteUrl: ''),
      );
      expect(state.hasBothIdSides, isTrue);
    });

    test('isOrganization reflects providerType.requiresTradeLicence', () {
      final org = RegistrationState(providerType: ProviderTypeRegistry.company);
      final ind =
          RegistrationState(providerType: ProviderTypeRegistry.individual);
      expect(org.isOrganization, isTrue);
      expect(ind.isOrganization, isFalse);
    });

    test('copyWith sentinel allows clearing nullable slots to null', () {
      final withFront = RegistrationState(emiratesIdFront: _tUploadable);
      final cleared = withFront.copyWith(emiratesIdFront: null);
      expect(cleared.emiratesIdFront, isNull);
    });

    test('copyWith preserves slot when parameter is omitted', () {
      final withFront = RegistrationState(emiratesIdFront: _tUploadable);
      final updated = withFront.copyWith(email: 'x@example.com');
      expect(updated.emiratesIdFront, isNotNull);
    });

    test('copyWith sentinel allows clearing failure to null', () {
      final withFailure = const RegistrationState(
        phase: PhaseExtractionFailed(),
      ).copyWith(
        failure: const ExtractionFailure(
          messageKey: 'errors.timeout',
          kind: ExtractionFailureKind.server,
        ),
      );
      final cleared = withFailure.copyWith(failure: null);
      expect(cleared.failure, isNull);
    });
  });
}
