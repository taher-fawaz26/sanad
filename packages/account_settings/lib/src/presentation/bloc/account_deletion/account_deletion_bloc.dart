import 'package:account_settings/src/domain/entities/account_deletion_eligibility.dart';
import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/entities/deletion_resend_info.dart';
import 'package:account_settings/src/domain/usecases/cancel_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_eligibility_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_status_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/start_account_deletion_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:auth/auth.dart'
    show AuthLogoutUseCase, GetCurrentUserUseCase, SessionManager;
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'account_deletion_event.dart';
part 'account_deletion_state.dart';

/// Owns the self-service account deletion & recovery flow.
///
/// `mutationStatus` is shared by start/cancel — each is read from exactly one
/// screen (confirmation page, scheduled page), so they never overlap. OTP
/// verification has its own `verifyStatus` because the OTP bottom sheet is
/// mounted *over* the confirmation page and the two must not observe each
/// other's transitions. Resend keeps its own `resendStatus`.
class AccountDeletionBloc
    extends Bloc<AccountDeletionEvent, AccountDeletionState> {
  AccountDeletionBloc({
    required GetDeletionEligibilityUseCase getEligibility,
    required StartAccountDeletionUseCase startDeletion,
    required GetDeletionStatusUseCase getStatus,
    required CancelDeletionUseCase cancelDeletion,
    required GetCurrentUserUseCase getCurrentUser,
    required SessionManager sessionManager,
  }) : _getEligibility = getEligibility,
       _startDeletion = startDeletion,
       _getStatus = getStatus,
       _cancelDeletion = cancelDeletion,
       _getCurrentUser = getCurrentUser,
       _sessionManager = sessionManager,
       super(const AccountDeletionState()) {
    on<AccountDeletionEligibilityRequested>(_onEligibilityRequested);
    on<AccountDeletionStatusRequested>(_onStatusRequested);
    on<AccountDeletionStarted>(_onStarted, transformer: droppable());
    on<AccountDeletionCancelled>(_onCancelled, transformer: droppable());
  }

  final GetDeletionEligibilityUseCase _getEligibility;
  final StartAccountDeletionUseCase _startDeletion;
  final GetDeletionStatusUseCase _getStatus;
  final CancelDeletionUseCase _cancelDeletion;
  final GetCurrentUserUseCase _getCurrentUser;
  final SessionManager _sessionManager;

  Future<void> _onEligibilityRequested(
    AccountDeletionEligibilityRequested event,
    Emitter<AccountDeletionState> emit,
  ) async {
    emit(
      state.copyWith(
        eligibilityStatus: RequestStatus.loading,
        clearEligibilityFailure: true,
      ),
    );
    final result = await _getEligibility(const NoParams()).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          eligibilityStatus: RequestStatus.failure,
          eligibilityFailure: failure,
        ),
      ),
      (eligibility) => emit(
        state.copyWith(
          eligibilityStatus: RequestStatus.success,
          eligibility: eligibility,
        ),
      ),
    );
  }

  /// Detects/resumes an already-active request (e.g. app was closed mid-OTP).
  Future<void> _onStatusRequested(
    AccountDeletionStatusRequested event,
    Emitter<AccountDeletionState> emit,
  ) async {
    emit(state.copyWith(activeRequestStatus: RequestStatus.loading));
    final result = await _getStatus(const NoParams()).run();
    result.fold(
      (failure) =>
          emit(state.copyWith(activeRequestStatus: RequestStatus.failure)),
      (request) => emit(
        state.copyWith(
          activeRequestStatus: RequestStatus.success,
          activeRequest: request,
        ),
      ),
    );
  }

  Future<void> _onStarted(
    AccountDeletionStarted event,
    Emitter<AccountDeletionState> emit,
  ) async {
    emit(
      state.copyWith(
        mutationStatus: RequestStatus.loading,
        clearMutationFailure: true,
      ),
    );
    final result = await _startDeletion(const NoParams()).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.failure,
          mutationFailure: failure,
        ),
      ),
      (request) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.success,
          activeRequest: request,
        ),
      ),
    );
  }

  Future<void> _onCancelled(
    AccountDeletionCancelled event,
    Emitter<AccountDeletionState> emit,
  ) async {
    emit(
      state.copyWith(
        mutationStatus: RequestStatus.loading,
        clearMutationFailure: true,
      ),
    );
    final result = await _cancelDeletion(const NoParams()).run();
    await result.match(
      (failure) async => emit(
        state.copyWith(
          mutationStatus: RequestStatus.failure,
          mutationFailure: failure,
        ),
      ),
      (_) async {
        // Owner cancellation restores the organization exactly as the
        // backend describes it — refresh identity from `/me` rather than
        // reconstructing anything locally (same pattern as
        // AuthBloc._checkSignInStatus).
        final identityResult = await _getCurrentUser(const NoParams()).run();
        await identityResult.match(
          (_) async {},
          (identity) async => _sessionManager.hydrateIdentity(identity),
        );
        emit(
          state.copyWith(
            mutationStatus: RequestStatus.success,
            clearActiveRequest: true,
          ),
        );
      },
    );
  }
}
