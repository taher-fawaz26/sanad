import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media/media.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/organization_media_slot.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/repositories/organization_media_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/remove_organization_media_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/upload_organization_media_usecase.dart';

part 'identity_header_event.dart';
part 'identity_header_state.dart';
part 'identity_media_slot_state.dart';

/// Owns the identity-header upload lifecycle for both the cover and the logo.
///
/// This is feature-level business logic: it calls the organization media
/// repository, tracks per-slot status/progress/failure, updates image URLs
/// optimistically, and owns retry/cancel. The generic `media` package supplies
/// the [EditedMedia] but never uploads.
class IdentityHeaderBloc
    extends Bloc<IdentityHeaderEvent, IdentityHeaderState> {
  IdentityHeaderBloc({
    required UploadOrganizationMediaUseCase uploadUseCase,
    required RemoveOrganizationMediaUseCase removeUseCase,
    required OrganizationMediaRepository repository,
  }) : _uploadUseCase = uploadUseCase,
       _removeUseCase = removeUseCase,
       _repository = repository,
       super(const IdentityHeaderState()) {
    on<IdentityHeaderInitialized>(_onInitialized);
    on<IdentityHeaderMediaSelected>(_onMediaSelected);
    on<IdentityHeaderUploadRetried>(_onRetried);
    on<IdentityHeaderUploadCancelled>(_onCancelled);
    on<IdentityHeaderMediaRemoved>(_onRemoved);
    on<IdentityHeaderFailureAcknowledged>(_onFailureAcknowledged);
  }

  final UploadOrganizationMediaUseCase _uploadUseCase;
  final RemoveOrganizationMediaUseCase _removeUseCase;
  final OrganizationMediaRepository _repository;

  /// Slots whose in-flight upload was cancelled, so the resulting failure is
  /// swallowed instead of shown as an error.
  final Set<OrganizationMediaSlot> _cancelled = {};

  void _onInitialized(
    IdentityHeaderInitialized event,
    Emitter<IdentityHeaderState> emit,
  ) {
    emit(
      IdentityHeaderState(
        cover: IdentityMediaSlotState(imageUrl: event.coverUrl),
        logo: IdentityMediaSlotState(imageUrl: event.logoUrl),
      ),
    );
  }

  Future<void> _onMediaSelected(
    IdentityHeaderMediaSelected event,
    Emitter<IdentityHeaderState> emit,
  ) => _upload(event.slot, event.media, emit);

  Future<void> _onRetried(
    IdentityHeaderUploadRetried event,
    Emitter<IdentityHeaderState> emit,
  ) {
    final media = state.slot(event.slot).lastMedia;
    if (media == null) return Future.value();
    return _upload(event.slot, media, emit);
  }

  Future<void> _upload(
    OrganizationMediaSlot slot,
    EditedMedia media,
    Emitter<IdentityHeaderState> emit,
  ) async {
    _cancelled.remove(slot);
    _emitSlot(
      emit,
      slot,
      state
          .slot(slot)
          .copyWith(
            status: RequestStatus.loading,
            progress: 0,
            lastMedia: media,
            clearFailure: true,
          ),
    );

    final result = await _uploadUseCase(
      UploadOrganizationMediaParams(
        slot: slot,
        media: media,
        onProgress: (progress) {
          if (emit.isDone) return;
          _emitSlot(emit, slot, state.slot(slot).copyWith(progress: progress));
        },
      ),
    ).run();

    if (_cancelled.remove(slot)) {
      // Cancellation is not an error: fall back to the prior image.
      _emitSlot(
        emit,
        slot,
        state.slot(slot).copyWith(status: RequestStatus.initial, progress: 0),
      );
      return;
    }

    result.fold(
      (failure) => _emitSlot(
        emit,
        slot,
        state
            .slot(slot)
            .copyWith(
              status: RequestStatus.failure,
              failure: failure,
            ),
      ),
      (entity) => _emitSlot(
        emit,
        slot,
        state
            .slot(slot)
            .copyWith(
              status: RequestStatus.success,
              imageUrl: entity.url ?? state.slot(slot).imageUrl,
              progress: 1,
              lastMedia: null,
            ),
      ),
    );
  }

  void _onCancelled(
    IdentityHeaderUploadCancelled event,
    Emitter<IdentityHeaderState> emit,
  ) {
    if (!state.slot(event.slot).isBusy) return;
    _cancelled.add(event.slot);
    _repository.cancelUpload(event.slot);
  }

  Future<void> _onRemoved(
    IdentityHeaderMediaRemoved event,
    Emitter<IdentityHeaderState> emit,
  ) async {
    _emitSlot(
      emit,
      event.slot,
      state
          .slot(event.slot)
          .copyWith(
            status: RequestStatus.loading,
            clearFailure: true,
          ),
    );

    final result = await _removeUseCase(
      RemoveOrganizationMediaParams(slot: event.slot),
    ).run();

    result.fold(
      (failure) => _emitSlot(
        emit,
        event.slot,
        state
            .slot(event.slot)
            .copyWith(
              status: RequestStatus.failure,
              failure: failure,
            ),
      ),
      (_) => _emitSlot(
        emit,
        event.slot,
        state
            .slot(event.slot)
            .copyWith(
              status: RequestStatus.success,
              imageUrl: null,
              progress: 0,
              lastMedia: null,
            ),
      ),
    );
  }

  void _onFailureAcknowledged(
    IdentityHeaderFailureAcknowledged event,
    Emitter<IdentityHeaderState> emit,
  ) {
    _emitSlot(
      emit,
      event.slot,
      state
          .slot(event.slot)
          .copyWith(status: RequestStatus.initial, clearFailure: true),
    );
  }

  void _emitSlot(
    Emitter<IdentityHeaderState> emit,
    OrganizationMediaSlot slot,
    IdentityMediaSlotState value,
  ) => emit(state.copyWithSlot(slot, value));
}
