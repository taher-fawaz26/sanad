import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/data/registration_simulation_service.dart';
import 'package:registration/src/domain/usecases/upload_single_media_usecase.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/models/registration_document_slot.dart';

/// Holds all cross-step registration data and drives async sign-up steps.
///
/// Upload networking lives in [UploadSingleMediaUseCase] — this cubit only
/// orchestrates: emit [UploadableAsset] transitions and invoke the use case.
class RegistrationCubit extends Cubit<RegistrationState> {
  RegistrationCubit({
    required UploadSingleMediaUseCase uploadMedia,
    RegistrationSimulationService? service,
  })  : _uploadMedia = uploadMedia,
        _service = service ?? RegistrationSimulationService(),
        super(const RegistrationState());

  final UploadSingleMediaUseCase _uploadMedia;
  final RegistrationSimulationService _service;

  // ── Plain data setters ─────────────────────────────────────────────────────

  void setEmail(String email) => emit(state.copyWith(email: email));

  /// Seeds the verified email + onboarding token handed over by the auth flow.
  void setOnboarding({
    required String email,
    required String onboardingToken,
  }) =>
      emit(state.copyWith(email: email, onboardingToken: onboardingToken));

  void setAccountType(RegistrationAccountType type) =>
      emit(state.copyWith(accountType: type));

  void setOrganizationDetails({
    required String businessName,
    required String representativeName,
  }) =>
      emit(
        state.copyWith(
          businessName: businessName,
          representativeName: representativeName,
        ),
      );

  void setFullName(String fullName) =>
      emit(state.copyWith(fullName: fullName));

  void clearUploadFailure() =>
      emit(state.copyWith(lastUploadFailure: null));

  /// Stores locally captured Emirates ID sides without uploading.
  void setEmiratesIdLocal({PickedAsset? front, PickedAsset? back}) {
    emit(
      state.copyWith(
        emiratesIdFront: front != null
            ? front.toUploadable()
            : state.emiratesIdFront,
        emiratesIdBack:
            back != null ? back.toUploadable() : state.emiratesIdBack,
      ),
    );
  }

  // ── Shared document upload pipeline ────────────────────────────────────────

  /// Picks up [asset] for [slot] and uploads via [UploadSingleMediaUseCase].
  ///
  /// Used by Emirates ID front/back, trade licence, and any future documents.
  Future<void> uploadDocument({
    required RegistrationDocumentSlot slot,
    required PickedAsset asset,
  }) async {
    final token = state.onboardingToken;
    if (token == null || token.isEmpty) {
      emit(
        _withSlot(
          slot,
          asset.toUploadable().markFailed('errors.unauthorized'),
        ).copyWith(lastUploadFailure: 'errors.unauthorized'),
      );
      return;
    }

    emit(
      _withSlot(slot, asset.toUploadable().markUploading()).copyWith(
        lastUploadFailure: null,
      ),
    );

    final result = await _uploadMedia(
      UploadSingleMediaParams(
        filePath: asset.path,
        fileName: asset.name,
        mimeType: asset.mimeType,
        authorizationToken: token,
        uploadKey: slot.name,
        onProgress: (progress) {
          final current = _slotOf(slot);
          if (current == null || !current.isUploading) return;
          emit(_withSlot(slot, current.markUploading(progress)));
        },
      ),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) {
        // User cancelled — clear the slot so they can pick again.
        if (failure is NetworkFailure &&
            failure.message == 'errors.request_cancelled') {
          emit(_withSlot(slot, null));
          return;
        }
        final current = _slotOf(slot);
        final failed = (current ?? asset.toUploadable()).markFailed(
          failure.message,
        );
        emit(
          _withSlot(slot, failed).copyWith(
            lastUploadFailure: failure.message,
          ),
        );
      },
      (media) {
        final current = _slotOf(slot);
        if (current == null) return;
        emit(
          _withSlot(
            slot,
            current.markUploaded(remoteId: media.id, remoteUrl: media.url),
          ),
        );
      },
    );
  }

  /// Cancels the in-flight HTTP upload for [slot] (no-op if idle).
  void cancelDocumentUpload(RegistrationDocumentSlot slot) {
    _uploadMedia.cancel(slot.name);
  }

  /// Clears [slot] and cancels any in-flight upload for it.
  void clearDocument(RegistrationDocumentSlot slot) {
    _uploadMedia.cancel(slot.name);
    emit(_withSlot(slot, null));
  }

  /// Uploads pending Emirates ID sides sequentially (front, then back).
  ///
  /// Skips sides that are already uploaded. Stops if a side fails to upload.
  Future<void> uploadEmiratesIdSequence() async {
    final front = state.emiratesIdFront;
    if (front != null && !front.isUploaded) {
      await uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: front.asset,
      );
      if (isClosed || state.emiratesIdFront?.isUploaded != true) return;
    }

    final back = state.emiratesIdBack;
    if (back != null && !back.isUploaded) {
      await uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdBack,
        asset: back.asset,
      );
    }
  }

  // ── Simulated async steps ──────────────────────────────────────────────

  /// Runs the (simulated) document extraction, storing the result on the state.
  Future<void> extractDocuments({ExtractionScenario? scenario}) async {
    emit(state.copyWith(extractionStatus: ExtractionStatus.extracting));
    final result = await _service.extractDocuments(
      includeTradeLicence: state.isOrganization,
      scenario: scenario,
    );
    emit(
      state.copyWith(
        extraction: result,
        extractionStatus: ExtractionStatus.done,
      ),
    );
  }

  // ── Slot helpers ───────────────────────────────────────────────────────────

  UploadableAsset? _slotOf(RegistrationDocumentSlot slot) => switch (slot) {
        RegistrationDocumentSlot.emiratesIdFront => state.emiratesIdFront,
        RegistrationDocumentSlot.emiratesIdBack => state.emiratesIdBack,
        RegistrationDocumentSlot.tradeLicence => state.tradeLicence,
      };

  RegistrationState _withSlot(
    RegistrationDocumentSlot slot,
    UploadableAsset? value,
  ) =>
      switch (slot) {
        RegistrationDocumentSlot.emiratesIdFront =>
          state.copyWith(emiratesIdFront: value),
        RegistrationDocumentSlot.emiratesIdBack =>
          state.copyWith(emiratesIdBack: value),
        RegistrationDocumentSlot.tradeLicence =>
          state.copyWith(tradeLicence: value),
      };
}
