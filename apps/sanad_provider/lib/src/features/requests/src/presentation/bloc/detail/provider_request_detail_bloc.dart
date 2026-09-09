import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/repositories/provider_requests_repository.dart';
import 'package:sanad_provider/src/features/requests/src/domain/usecases/provider_request_usecases.dart';

part 'provider_request_detail_event.dart';
part 'provider_request_detail_state.dart';

/// One request in the provider view, with every action available on it.
///
/// Like its client counterpart, this bloc never predicts a status and never
/// re-derives whose turn it is. Two provider-specific rules on top:
///
/// * **Contact visibility comes only from `contact.unlocked`.** Accepting a
///   client's counter is what flips it, and the repository re-reads the request
///   afterwards so the screen shows the server's answer rather than a local
///   guess about what winning implies.
/// * **The re-bid budget is server-owned.** `remainingRebids` gates the button,
///   but an exhausted budget still surfaces as a `409` from the server.
class ProviderRequestDetailBloc
    extends Bloc<ProviderRequestDetailEvent, ProviderRequestDetailState> {
  /// Creates the detail bloc for [requestId].
  ProviderRequestDetailBloc({
    required String requestId,
    required GetProviderRequestUseCase getRequest,
    required CreateProviderOfferUseCase createOffer,
    required WithdrawProviderOfferUseCase withdrawOffer,
    required AcceptClientCounterUseCase acceptCounter,
    required DeclineClientCounterUseCase declineCounter,
    required CounterClientOfferUseCase counterOffer,
    required CompleteProviderJobUseCase completeJob,
    required CancelProviderJobUseCase cancelJob,
  }) : _requestId = requestId,
       _getRequest = getRequest,
       _createOffer = createOffer,
       _withdrawOffer = withdrawOffer,
       _acceptCounter = acceptCounter,
       _declineCounter = declineCounter,
       _counterOffer = counterOffer,
       _completeJob = completeJob,
       _cancelJob = cancelJob,
       super(const ProviderRequestDetailState()) {
    on<ProviderRequestDetailStarted>(_onLoad, transformer: restartable());
    on<ProviderRequestDetailRefreshed>(_onLoad, transformer: restartable());
    // Every mutation is droppable: a double-tapped Send must not create two
    // offers, and a double-tapped Withdraw must not consume two re-bids.
    on<ProviderOfferCreated>(_onOfferCreated, transformer: droppable());
    on<ProviderOfferWithdrawn>(_onOfferWithdrawn, transformer: droppable());
    on<ProviderCounterAccepted>(_onCounterAccepted, transformer: droppable());
    on<ProviderCounterDeclined>(_onCounterDeclined, transformer: droppable());
    on<ProviderCounterSent>(_onCounterSent, transformer: droppable());
    on<ProviderJobCompleted>(_onJobCompleted, transformer: droppable());
    on<ProviderJobCancelled>(_onJobCancelled, transformer: droppable());
    on<ProviderRequestMutationAcknowledged>(
      (_, emit) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.initial,
          clearMutationFailure: true,
        ),
      ),
    );
  }

  final String _requestId;
  final GetProviderRequestUseCase _getRequest;
  final CreateProviderOfferUseCase _createOffer;
  final WithdrawProviderOfferUseCase _withdrawOffer;
  final AcceptClientCounterUseCase _acceptCounter;
  final DeclineClientCounterUseCase _declineCounter;
  final CounterClientOfferUseCase _counterOffer;
  final CompleteProviderJobUseCase _completeJob;
  final CancelProviderJobUseCase _cancelJob;

  Future<void> _onLoad(
    ProviderRequestDetailEvent event,
    Emitter<ProviderRequestDetailState> emit,
  ) async {
    emit(state.copyWith(loadStatus: RequestStatus.loading));
    final result = await _getRequest(_requestId).run();
    result.match(
      (failure) => emit(
        state.copyWith(loadStatus: RequestStatus.failure, loadFailure: failure),
      ),
      (request) => emit(
        state.copyWith(loadStatus: RequestStatus.success, request: request),
      ),
    );
  }

  Future<void> _onOfferCreated(
    ProviderOfferCreated event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _createOffer(
      CreateOfferParams(
        requestId: _requestId,
        branchId: event.branchId,
        proposedAt: event.proposedAt,
        note: event.note,
      ),
    ),
  );

  Future<void> _onOfferWithdrawn(
    ProviderOfferWithdrawn event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _withdrawOffer(
      ProviderOfferActionParams(
        requestId: _requestId,
        offerId: event.offerId,
      ),
    ),
  );

  Future<void> _onCounterAccepted(
    ProviderCounterAccepted event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _acceptCounter(
      ProviderOfferActionParams(
        requestId: _requestId,
        offerId: event.offerId,
      ),
    ),
  );

  Future<void> _onCounterDeclined(
    ProviderCounterDeclined event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _declineCounter(
      ProviderOfferActionParams(
        requestId: _requestId,
        offerId: event.offerId,
      ),
    ),
  );

  Future<void> _onCounterSent(
    ProviderCounterSent event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _counterOffer(
      ProviderCounterParams(
        requestId: _requestId,
        offerId: event.offerId,
        proposedAt: event.proposedAt,
        note: event.note,
      ),
    ),
  );

  Future<void> _onJobCompleted(
    ProviderJobCompleted event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(emit, () => _completeJob(_requestId));

  Future<void> _onJobCancelled(
    ProviderJobCancelled event,
    Emitter<ProviderRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _cancelJob(
      CancelProviderJobParams(requestId: _requestId, reason: event.reason),
    ),
  );

  /// Runs a mutation and adopts the request the server returns afterwards.
  ///
  /// On failure the loaded request stays put — the action did not happen — and
  /// a `409` additionally forces a re-read, because it almost always means the
  /// server state moved underneath this view: the client accepted a rival, a
  /// timer fired, or the re-bid budget ran out.
  Future<void> _mutate(
    Emitter<ProviderRequestDetailState> emit,
    TaskEither<Failure, ProviderRequest> Function() action,
  ) async {
    emit(
      state.copyWith(
        mutationStatus: RequestStatus.loading,
        clearMutationFailure: true,
      ),
    );
    final result = await action().run();
    result.match(
      (failure) {
        emit(
          state.copyWith(
            mutationStatus: RequestStatus.failure,
            mutationFailure: failure,
          ),
        );
        if (failure.isConflict) add(const ProviderRequestDetailRefreshed());
      },
      (request) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.success,
          request: request,
        ),
      ),
    );
  }
}
