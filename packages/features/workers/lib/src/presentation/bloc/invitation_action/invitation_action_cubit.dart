import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';

enum InvitationActionType { resend, cancel, delete }

sealed class InvitationActionEffect extends Equatable {
  const InvitationActionEffect();

  @override
  List<Object?> get props => [];
}

final class InvitationActionStarted extends InvitationActionEffect {
  const InvitationActionStarted(this.type);
  final InvitationActionType type;

  @override
  List<Object?> get props => [type];
}

final class InvitationActionSucceeded extends InvitationActionEffect {
  const InvitationActionSucceeded({
    required this.type,
    required this.invitationId,
  });
  final InvitationActionType type;
  final String invitationId;

  @override
  List<Object?> get props => [type, invitationId];
}

final class InvitationActionFailed extends InvitationActionEffect {
  const InvitationActionFailed({required this.type, required this.failure});
  final InvitationActionType type;
  final Failure failure;

  @override
  List<Object?> get props => [type, failure];
}

class InvitationActionState extends Equatable {
  const InvitationActionState({this.inFlight});
  final InvitationActionType? inFlight;

  bool get isBusy => inFlight != null;

  @override
  List<Object?> get props => [inFlight];
}

class InvitationActionCubit extends Cubit<InvitationActionState> {
  InvitationActionCubit({
    required ResendInvitationUseCase resendInvitationUseCase,
    required CancelInvitationUseCase cancelInvitationUseCase,
    required DeleteInvitationUseCase deleteInvitationUseCase,
  }) : _resendInvitationUseCase = resendInvitationUseCase,
       _cancelInvitationUseCase = cancelInvitationUseCase,
       _deleteInvitationUseCase = deleteInvitationUseCase,
       super(const InvitationActionState());

  final ResendInvitationUseCase _resendInvitationUseCase;
  final CancelInvitationUseCase _cancelInvitationUseCase;
  final DeleteInvitationUseCase _deleteInvitationUseCase;

  final _effects = StreamController<InvitationActionEffect>.broadcast();

  Stream<InvitationActionEffect> get effects => _effects.stream;

  @override
  Future<void> close() async {
    await _effects.close();
    await super.close();
  }

  Future<void> resend(String invitationId) => _run(
    invitationId,
    InvitationActionType.resend,
    () => _resendInvitationUseCase(
      ResendInvitationParams(id: invitationId),
    ).run(),
  );

  Future<void> cancel(String invitationId) => _run(
    invitationId,
    InvitationActionType.cancel,
    () => _cancelInvitationUseCase(
      CancelInvitationParams(id: invitationId),
    ).run(),
  );

  Future<void> delete(String invitationId) => _run(
    invitationId,
    InvitationActionType.delete,
    () => _deleteInvitationUseCase(
      DeleteInvitationParams(id: invitationId),
    ).run(),
  );

  Future<void> _run(
    String invitationId,
    InvitationActionType type,
    Future<Either<Failure, Unit>> Function() invoke,
  ) async {
    if (state.isBusy) return;
    emit(InvitationActionState(inFlight: type));
    _effects.add(InvitationActionStarted(type));

    final result = await invoke();

    result.fold(
      (failure) => _effects.add(
        InvitationActionFailed(type: type, failure: failure),
      ),
      (_) => _effects.add(
        InvitationActionSucceeded(type: type, invitationId: invitationId),
      ),
    );

    emit(const InvitationActionState());
  }
}
