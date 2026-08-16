import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_upload/media_upload.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';

part 'service_images_event.dart';
part 'service_images_state.dart';

/// Owns Edit Service's live image lifecycle — add / delete / set-primary,
/// each hitting the backend immediately (no staging, no resubmission
/// through `PATCH /provider-services/{id}`): add via
/// `POST /provider-services/:id/images`, set primary via
/// `PATCH .../images/:imageId/primary`, delete via
/// `DELETE .../images/:imageId`. `:imageId` is always the image row id
/// ([ProviderServiceImageEntity.id]), never the underlying `mediaId`
/// returned by the upload step.
///
/// New images are staged through the sibling `MediaUploadBloc` — this bloc
/// doesn't depend on it directly; `ManageServiceImagesSection` forwards its
/// state via [ServiceImagesUploadStateChanged] (`BlocListener` → `add`), and
/// this bloc alone decides which items are newly-succeeded and kicks off
/// their attach. Upload success and attach success are tracked separately:
/// an uploaded item only leaves `attachStatus` once
/// [AddProviderServiceImageUseCase] confirms the attach. An attach failure
/// never re-triggers the (already-successful) upload; retrying it only
/// re-calls the attach.
class ServiceImagesBloc extends Bloc<ServiceImagesEvent, ServiceImagesState> {
  ServiceImagesBloc({
    required AddProviderServiceImageUseCase addProviderServiceImageUseCase,
    required DeleteProviderServiceImageUseCase
    deleteProviderServiceImageUseCase,
    required SetPrimaryProviderServiceImageUseCase
    setPrimaryProviderServiceImageUseCase,
    required ProviderServiceEntity initialService,
  }) : _addUseCase = addProviderServiceImageUseCase,
       _deleteUseCase = deleteProviderServiceImageUseCase,
       _setPrimaryUseCase = setPrimaryProviderServiceImageUseCase,
       super(ServiceImagesState(service: initialService)) {
    on<ServiceImagesUploadStateChanged>(_onUploadStateChanged);
    on<ServiceImagesAttachRetryRequested>(_onAttachRetry);
    on<ServiceImagesInProgressRemoved>(_onInProgressRemoved);
    on<ServiceImagesSetPrimaryRequested>(
      _onSetPrimary,
      transformer: droppable(),
    );
    on<ServiceImagesDeleteRequested>(_onDelete, transformer: droppable());
  }

  final AddProviderServiceImageUseCase _addUseCase;
  final DeleteProviderServiceImageUseCase _deleteUseCase;
  final SetPrimaryProviderServiceImageUseCase _setPrimaryUseCase;

  Future<void> _onUploadStateChanged(
    ServiceImagesUploadStateChanged event,
    Emitter<ServiceImagesState> emit,
  ) async {
    final newlySucceeded = [
      for (final item in event.items)
        if (item.isSuccess &&
            item.mediaId != null &&
            !state.attachStatus.containsKey(item.localId))
          item,
    ];
    if (newlySucceeded.isEmpty) return;

    emit(
      state.copyWith(
        attachStatus: {
          ...state.attachStatus,
          for (final item in newlySucceeded)
            item.localId: ServiceImagesAttachStatus.attaching,
        },
      ),
    );

    await Future.wait([
      for (final item in newlySucceeded)
        _attachImage(item.localId, item.mediaId!, emit),
    ]);
  }

  Future<void> _onAttachRetry(
    ServiceImagesAttachRetryRequested event,
    Emitter<ServiceImagesState> emit,
  ) async {
    emit(
      state.copyWith(
        attachStatus: {
          ...state.attachStatus,
          event.localId: ServiceImagesAttachStatus.attaching,
        },
      ),
    );
    await _attachImage(event.localId, event.mediaId, emit);
  }

  Future<void> _attachImage(
    String localId,
    String mediaId,
    Emitter<ServiceImagesState> emit,
  ) async {
    final result = await _addUseCase(
      AddProviderServiceImageParams(id: state.service.id, mediaId: mediaId),
    ).run();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          attachStatus: {
            ...state.attachStatus,
            localId: ServiceImagesAttachStatus.failed,
          },
          mutationFailure: failure,
          failureNonce: state.failureNonce + 1,
        ),
      ),
      (updated) {
        final next = Map<String, ServiceImagesAttachStatus>.from(
          state.attachStatus,
        )..remove(localId);
        emit(state.copyWith(service: updated, attachStatus: next));
      },
    );
  }

  void _onInProgressRemoved(
    ServiceImagesInProgressRemoved event,
    Emitter<ServiceImagesState> emit,
  ) {
    if (!state.attachStatus.containsKey(event.localId)) return;
    final next = Map<String, ServiceImagesAttachStatus>.from(
      state.attachStatus,
    )..remove(event.localId);
    emit(state.copyWith(attachStatus: next));
  }

  Future<void> _onSetPrimary(
    ServiceImagesSetPrimaryRequested event,
    Emitter<ServiceImagesState> emit,
  ) async {
    emit(state.copyWith(busyImageId: event.imageId));
    final result = await _setPrimaryUseCase(
      SetPrimaryProviderServiceImageParams(
        id: state.service.id,
        imageId: event.imageId,
      ),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearBusyImageId: true,
          mutationFailure: failure,
          failureNonce: state.failureNonce + 1,
        ),
      ),
      (updated) => emit(
        state.copyWith(service: updated, clearBusyImageId: true),
      ),
    );
  }

  Future<void> _onDelete(
    ServiceImagesDeleteRequested event,
    Emitter<ServiceImagesState> emit,
  ) async {
    emit(state.copyWith(busyImageId: event.imageId));
    final result = await _deleteUseCase(
      DeleteProviderServiceImageParams(
        id: state.service.id,
        imageId: event.imageId,
      ),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          clearBusyImageId: true,
          mutationFailure: failure,
          failureNonce: state.failureNonce + 1,
        ),
      ),
      (updated) => emit(
        state.copyWith(service: updated, clearBusyImageId: true),
      ),
    );
  }
}
