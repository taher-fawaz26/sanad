import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';
import 'package:invitation/src/domain/usecases/verify_invitation_token_usecase.dart';

sealed class InvitationDetailsState extends Equatable {
  const InvitationDetailsState();

  @override
  List<Object?> get props => [];
}

class InvitationDetailsLoading extends InvitationDetailsState {
  const InvitationDetailsLoading();
}

/// The token resolved (`valid: true`) — [preview] is ready to display.
class InvitationDetailsLoaded extends InvitationDetailsState {
  const InvitationDetailsLoaded(this.preview);

  final InvitationPreview preview;

  @override
  List<Object?> get props => [preview];
}

/// The backend answered 200 with `valid: false` — a well-formed but
/// no-longer-actionable (or unknown) invitation. Not a [Failure]: the call
/// succeeded, the invitation just can't be accepted.
class InvitationDetailsInvalid extends InvitationDetailsState {
  const InvitationDetailsInvalid(this.preview);

  final InvitationPreview preview;

  @override
  List<Object?> get props => [preview];
}

/// The call itself failed (malformed token → 400, network error, etc.).
class InvitationDetailsFailure extends InvitationDetailsState {
  const InvitationDetailsFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Drives `GET /workers/verify-token/{token}` for `InvitationDetailsPage`.
class InvitationDetailsCubit extends Cubit<InvitationDetailsState> {
  InvitationDetailsCubit(this._verifyInvitationToken)
    : super(const InvitationDetailsLoading());

  final VerifyInvitationTokenUseCase _verifyInvitationToken;

  Future<void> loadToken(String token) async {
    emit(const InvitationDetailsLoading());
    final result = await _verifyInvitationToken(
      InvitationTokenParams(token: token),
    ).run();
    result.match(
      (failure) => emit(InvitationDetailsFailure(failure)),
      (preview) => emit(
        preview.valid
            ? InvitationDetailsLoaded(preview)
            : InvitationDetailsInvalid(preview),
      ),
    );
  }
}
