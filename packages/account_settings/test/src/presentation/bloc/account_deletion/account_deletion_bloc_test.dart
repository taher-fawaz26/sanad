import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/entities/deletion_blocker.dart';
import 'package:account_settings/src/domain/entities/deletion_cascade_preview.dart';
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:account_settings/src/domain/enums/account_deletion_status.dart';
import 'package:account_settings/src/domain/enums/deletion_blocker_code.dart';
import 'package:account_settings/src/domain/enums/deletion_persona.dart';
import 'package:account_settings/src/domain/enums/deletion_warning_code.dart';
import 'package:account_settings/src/domain/usecases/cancel_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_eligibility_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_status_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/start_account_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:account_settings/src/presentation/bloc/account_deletion/account_deletion_bloc.dart';
import 'package:auth/auth.dart'
    show
        AuthIdentity,
        AuthLogoutUseCase,
        GetCurrentUserUseCase,
        SessionManager,
        UserType;
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetDeletionEligibilityUseCase extends Mock
    implements GetDeletionEligibilityUseCase {}

class _MockStartAccountDeletionUseCase extends Mock
    implements StartAccountDeletionUseCase {}

class _MockVerifyDeletionOtpUseCase extends Mock
    implements VerifyDeletionOtpUseCase {}

class _MockResendDeletionOtpUseCase extends Mock
    implements ResendDeletionOtpUseCase {}

class _MockGetDeletionResendInfoUseCase extends Mock
    implements GetDeletionResendInfoUseCase {}

class _MockGetDeletionStatusUseCase extends Mock
    implements GetDeletionStatusUseCase {}

class _MockCancelDeletionUseCase extends Mock
    implements CancelDeletionUseCase {}

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class _MockSessionManager extends Mock implements SessionManager {}

class _MockAuthLogoutUseCase extends Mock implements AuthLogoutUseCase {}

const _tFailure = ServerFailure(message: 'server_error');

const _tCascade = DeletionCascadePreview(
  persona: DeletionPersona.companyProvider,
  branches: 2,
  services: 5,
  teamAccounts: 3,
  invitations: 1,
  documents: 2,
  media: 8,
  branchesUnassigned: 0,
);

const _tEligibleNoBlockers = AccountDeletionEligibility(
  isEligible: true,
  gracePeriodDays: 14,
  blockers: [],
  warnings: [],
  cascadePreview: _tCascade,
);

const _tRequest = AccountDeletionRequest(
  id: 'req-1',
  status: AccountDeletionStatus.pendingVerification,
  initiator: DeletionInitiator.self,
  verificationRequired: true,
  scheduledExecutionDate: null,
  gracePeriodDays: 14,
  message: 'OTP sent',
  createdAt: null,
  updatedAt: null,
);

void main() {
  late _MockGetDeletionEligibilityUseCase getEligibility;
  late _MockStartAccountDeletionUseCase startDeletion;
  late _MockVerifyDeletionOtpUseCase verifyOtp;
  late _MockResendDeletionOtpUseCase resendOtp;
  late _MockGetDeletionResendInfoUseCase getResendInfo;
  late _MockGetDeletionStatusUseCase getStatus;
  late _MockCancelDeletionUseCase cancelDeletion;
  late _MockGetCurrentUserUseCase getCurrentUser;
  late _MockSessionManager sessionManager;
  late _MockAuthLogoutUseCase logout;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const VerifyDeletionOtpParams(otp: '000000'));
    registerFallbackValue(
      const AuthIdentity(
        id: 'fallback',
        email: 'fallback@sanad.test',
        userType: UserType.client,
        permissions: [],
      ),
    );
  });

  setUp(() {
    getEligibility = _MockGetDeletionEligibilityUseCase();
    startDeletion = _MockStartAccountDeletionUseCase();
    verifyOtp = _MockVerifyDeletionOtpUseCase();
    resendOtp = _MockResendDeletionOtpUseCase();
    getResendInfo = _MockGetDeletionResendInfoUseCase();
    getStatus = _MockGetDeletionStatusUseCase();
    cancelDeletion = _MockCancelDeletionUseCase();
    getCurrentUser = _MockGetCurrentUserUseCase();
    sessionManager = _MockSessionManager();
    logout = _MockAuthLogoutUseCase();
    when(() => sessionManager.hydrateIdentity(any())).thenAnswer(
      (_) async => null,
    );
    when(() => sessionManager.clear()).thenAnswer((_) async {});
    when(() => logout(any())).thenAnswer((_) => TaskEither.right(null));
  });

  AccountDeletionBloc build() => AccountDeletionBloc(
    getEligibility: getEligibility,
    startDeletion: startDeletion,
    getStatus: getStatus,
    cancelDeletion: cancelDeletion,
    getCurrentUser: getCurrentUser,
    sessionManager: sessionManager,
  );

  group('eligibility', () {
    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'eligible companyProvider emits success with the full cascade',
      build: () {
        when(
          () => getEligibility(any()),
        ).thenAnswer((_) => TaskEither.right(_tEligibleNoBlockers));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionEligibilityRequested()),
      expect: () => [
        isA<AccountDeletionState>().having(
          (s) => s.eligibilityStatus,
          'eligibilityStatus',
          RequestStatus.loading,
        ),
        isA<AccountDeletionState>()
            .having(
              (s) => s.eligibilityStatus,
              'eligibilityStatus',
              RequestStatus.success,
            )
            .having(
              (s) => s.eligibility?.cascadePreview.persona,
              'persona',
              DeletionPersona.companyProvider,
            ),
      ],
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'blockers present are surfaced without crashing on an unknown code',
      build: () {
        const eligibility = AccountDeletionEligibility(
          isEligible: false,
          gracePeriodDays: 14,
          blockers: [
            DeletionBlocker(
              code: DeletionBlockerCode.unknown,
              rawCode: 'SOME_NEW_BLOCKER',
              message: 'A brand new blocker from the server.',
            ),
          ],
          warnings: [],
          cascadePreview: _tCascade,
        );
        when(
          () => getEligibility(any()),
        ).thenAnswer((_) => TaskEither.right(eligibility));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionEligibilityRequested()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>().having(
          (s) => s.eligibility?.hasBlockers,
          'hasBlockers',
          true,
        ),
      ],
      verify: (bloc) {
        final blocker = bloc.state.eligibility!.blockers.single;
        expect(blocker.code, DeletionBlockerCode.unknown);
        expect(blocker.rawCode, 'SOME_NEW_BLOCKER');
      },
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'warnings present are surfaced, including an unknown code',
      build: () {
        const eligibility = AccountDeletionEligibility(
          isEligible: true,
          gracePeriodDays: 14,
          blockers: [],
          warnings: [
            DeletionWarning(
              code: DeletionWarningCode.teamAccountsDeleted,
              rawCode: 'TEAM_ACCOUNTS_DELETED',
              message: '3 team account(s) will be deleted.',
            ),
            DeletionWarning(
              code: DeletionWarningCode.unknown,
              rawCode: 'SOME_NEW_WARNING',
              message: 'A brand new warning from the server.',
            ),
          ],
          cascadePreview: _tCascade,
        );
        when(
          () => getEligibility(any()),
        ).thenAnswer((_) => TaskEither.right(eligibility));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionEligibilityRequested()),
      verify: (bloc) {
        expect(bloc.state.eligibility!.warnings, hasLength(2));
        expect(
          bloc.state.eligibility!.warnings.last.code,
          DeletionWarningCode.unknown,
        );
      },
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'a failure surfaces without crashing',
      build: () {
        when(
          () => getEligibility(any()),
        ).thenAnswer((_) => TaskEither.left(_tFailure));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionEligibilityRequested()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>()
            .having(
              (s) => s.eligibilityStatus,
              'eligibilityStatus',
              RequestStatus.failure,
            )
            .having((s) => s.eligibilityFailure, 'failure', _tFailure),
      ],
    );
  });

  group('start / verify / resend / cancel', () {
    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'start emits [loading, success] and stores the active request',
      build: () {
        when(
          () => startDeletion(any()),
        ).thenAnswer((_) => TaskEither.right(_tRequest));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionStarted()),
      expect: () => [
        isA<AccountDeletionState>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          RequestStatus.loading,
        ),
        isA<AccountDeletionState>()
            .having(
              (s) => s.mutationStatus,
              'mutationStatus',
              RequestStatus.success,
            )
            .having((s) => s.activeRequest, 'activeRequest', _tRequest),
      ],
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'start is idempotent — a 400-blocked start surfaces the failure',
      build: () {
        when(
          () => startDeletion(any()),
        ).thenAnswer((_) => TaskEither.left(_tFailure));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionStarted()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          RequestStatus.failure,
        ),
      ],
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'a successful cancel refreshes identity and clears the active request',
      build: () {
        when(
          () => cancelDeletion(any()),
        ).thenAnswer((_) => TaskEither.right(unit));
        when(() => getCurrentUser(any())).thenAnswer(
          (_) => TaskEither.right(
            const AuthIdentity(
              id: 'u1',
              email: 'a@a.com',
              userType: UserType.client,
              permissions: [],
            ),
          ),
        );
        return build();
      },
      seed: () => const AccountDeletionState(activeRequest: _tRequest),
      act: (bloc) => bloc.add(const AccountDeletionCancelled()),
      expect: () => [
        isA<AccountDeletionState>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          RequestStatus.loading,
        ),
        isA<AccountDeletionState>()
            .having(
              (s) => s.mutationStatus,
              'mutationStatus',
              RequestStatus.success,
            )
            .having((s) => s.activeRequest, 'activeRequest', isNull),
      ],
      verify: (_) {
        verify(() => sessionManager.hydrateIdentity(any())).called(1);
      },
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      'a 404 cancel (nothing to cancel) still resolves as success',
      build: () {
        when(
          () => cancelDeletion(any()),
        ).thenAnswer((_) => TaskEither.right(unit));
        when(() => getCurrentUser(any())).thenAnswer(
          (_) => TaskEither.left(_tFailure),
        );
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionCancelled()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>().having(
          (s) => s.mutationStatus,
          'mutationStatus',
          RequestStatus.success,
        ),
      ],
    );
  });

  group('status (resume)', () {
    blocTest<AccountDeletionBloc, AccountDeletionState>(
      '200 with an active request resolves it',
      build: () {
        when(
          () => getStatus(any()),
        ).thenAnswer((_) => TaskEither.right(_tRequest));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionStatusRequested()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>()
            .having(
              (s) => s.activeRequestStatus,
              'activeRequestStatus',
              RequestStatus.success,
            )
            .having((s) => s.activeRequest, 'activeRequest', _tRequest),
      ],
    );

    blocTest<AccountDeletionBloc, AccountDeletionState>(
      '404 (no active request) is a quiet null, not an error',
      build: () {
        when(
          () => getStatus(any()),
        ).thenAnswer((_) => TaskEither.right(null));
        return build();
      },
      act: (bloc) => bloc.add(const AccountDeletionStatusRequested()),
      expect: () => [
        isA<AccountDeletionState>(),
        isA<AccountDeletionState>()
            .having(
              (s) => s.activeRequestStatus,
              'activeRequestStatus',
              RequestStatus.success,
            )
            .having((s) => s.activeRequest, 'activeRequest', isNull),
      ],
    );
  });
}
