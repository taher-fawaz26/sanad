import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';

part 'client_request_detail_event.dart';
part 'client_request_detail_state.dart';

/// One request, with its negotiation threads and every action the client can
/// take on it.
///
/// Two things this bloc deliberately does not do:
///
/// * **It never predicts a status.** Every mutation returns the full request,
///   and that response replaces the state. A request can also move on a server
///   timer — SUBMITTED to EXPIRED, SCHEDULED to IN_PROGRESS,
///   AWAITING_CONFIRMATION to COMPLETED — with no user action at all, so a
///   locally-assumed transition would simply be wrong.
/// * **It never re-derives whose turn it is.** That comes from the pending
///   offer's `actorType` in the payload.
class ClientRequestDetailBloc
    extends Bloc<ClientRequestDetailEvent, ClientRequestDetailState> {
  /// Creates the detail bloc for [requestId].
  ClientRequestDetailBloc({
    required String requestId,
    required GetClientRequestUseCase getRequest,
    required CancelClientRequestUseCase cancelRequest,
    required ConfirmClientRequestUseCase confirmRequest,
    required DisputeClientRequestUseCase disputeRequest,
    required AcceptOfferUseCase acceptOffer,
    required RejectOfferUseCase rejectOffer,
    required CounterOfferUseCase counterOffer,
  }) : _requestId = requestId,
       _getRequest = getRequest,
       _cancelRequest = cancelRequest,
       _confirmRequest = confirmRequest,
       _disputeRequest = disputeRequest,
       _acceptOffer = acceptOffer,
       _rejectOffer = rejectOffer,
       _counterOffer = counterOffer,
       super(const ClientRequestDetailState()) {
    on<ClientRequestDetailStarted>(_onLoad, transformer: restartable());
    on<ClientRequestDetailRefreshed>(_onLoad, transformer: restartable());
    // Every mutation is droppable: a double-tapped Accept must not race a
    // second accept against the same offer.
    on<ClientRequestCancelled>(_onCancelled, transformer: droppable());
    on<ClientRequestConfirmed>(_onConfirmed, transformer: droppable());
    on<ClientRequestDisputed>(_onDisputed, transformer: droppable());
    on<ClientRequestOfferAccepted>(_onOfferAccepted, transformer: droppable());
    on<ClientRequestOfferRejected>(_onOfferRejected, transformer: droppable());
    on<ClientRequestOfferCountered>(
      _onOfferCountered,
      transformer: droppable(),
    );
    on<ClientRequestMutationAcknowledged>(
      (_, emit) => emit(
        state.copyWith(
          mutationStatus: RequestStatus.initial,
          clearMutationFailure: true,
        ),
      ),
    );
  }

  final String _requestId;
  final GetClientRequestUseCase _getRequest;
  final CancelClientRequestUseCase _cancelRequest;
  final ConfirmClientRequestUseCase _confirmRequest;
  final DisputeClientRequestUseCase _disputeRequest;
  final AcceptOfferUseCase _acceptOffer;
  final RejectOfferUseCase _rejectOffer;
  final CounterOfferUseCase _counterOffer;

  Future<void> _onLoad(
    ClientRequestDetailEvent event,
    Emitter<ClientRequestDetailState> emit,
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

  Future<void> _onCancelled(
    ClientRequestCancelled event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _cancelRequest(
      ReasonedRequestParams(id: _requestId, reason: event.reason),
    ),
  );

  Future<void> _onConfirmed(
    ClientRequestConfirmed event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(emit, () => _confirmRequest(_requestId));

  Future<void> _onDisputed(
    ClientRequestDisputed event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _disputeRequest(
      ReasonedRequestParams(id: _requestId, reason: event.reason),
    ),
  );

  Future<void> _onOfferAccepted(
    ClientRequestOfferAccepted event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _acceptOffer(
      OfferActionParams(requestId: _requestId, offerId: event.offerId),
    ),
  );

  Future<void> _onOfferRejected(
    ClientRequestOfferRejected event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _rejectOffer(
      OfferActionParams(requestId: _requestId, offerId: event.offerId),
    ),
  );

  Future<void> _onOfferCountered(
    ClientRequestOfferCountered event,
    Emitter<ClientRequestDetailState> emit,
  ) => _mutate(
    emit,
    () => _counterOffer(
      CounterOfferParams(
        requestId: _requestId,
        offerId: event.offerId,
        proposedAt: event.proposedAt,
        note: event.note,
      ),
    ),
  );

  /// Runs a mutation and adopts the server's returned request wholesale.
  ///
  /// On failure the previously loaded request is left in place — the action did
  /// not happen, so the screen must keep showing what is actually true — and a
  /// refresh is triggered, because a `409` usually means the server state
  /// moved underneath this view — a rival accepted, a timer fired, or the
  /// request closed.
  Future<void> _mutate(
    Emitter<ClientRequestDetailState> emit,
    TaskEither<Failure, ClientRequest> Function() action,
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
        if (failure.isConflict) add(const ClientRequestDetailRefreshed());
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
