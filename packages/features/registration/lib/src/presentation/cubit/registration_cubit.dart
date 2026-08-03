import 'package:asset_picker/asset_picker.dart';
import 'package:auth/auth.dart' show AuthSessionEntity;
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/domain/failures/registration_failure.dart';
import 'package:registration/src/domain/provider_type/provider_type_spec.dart';
import 'package:registration/src/domain/usecases/complete_profile_usecase.dart';
import 'package:registration/src/domain/usecases/extract_documents_usecase.dart';
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
    required ExtractDocumentsUseCase extractDocuments,
    required CompleteProfileUseCase completeProfile,
  })  : _uploadMedia = uploadMedia,
        _extractDocuments = extractDocuments,
        _completeProfile = completeProfile,
        super(const RegistrationState());

  final UploadSingleMediaUseCase _uploadMedia;
  final ExtractDocumentsUseCase _extractDocuments;
  final CompleteProfileUseCase _completeProfile;

  // ── Plain data setters ─────────────────────────────────────────────────────

  void setEmail(String email) => emit(state.copyWith(email: email));

  /// Seeds the verified email + onboarding token handed over by the auth flow.
  void setOnboarding({
    required String email,
    required String onboardingToken,
  }) =>
      emit(state.copyWith(email: email, onboardingToken: onboardingToken));

  void setProviderType(ProviderTypeSpec type) =>
      emit(state.copyWith(providerType: type));

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

  void clearFailure() => emit(state.copyWith(failure: null));

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
        ).copyWith(
          failure: const UploadFailure(messageKey: 'errors.unauthorized'),
        ),
      );
      return;
    }

    emit(
      _withSlot(slot, asset.toUploadable().markUploading()).copyWith(
        failure: null,
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
            failure: UploadFailure(messageKey: failure.message),
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

  // ── Document extraction ────────────────────────────────────────────────────

  /// Calls `POST auth/extract` with the uploaded document IDs.
  Future<void> extractDocuments() async {
    final token = state.onboardingToken;
    final frontId = state.emiratesIdFront?.remoteId;
    final backId = state.emiratesIdBack?.remoteId;

    if (token == null || frontId == null || backId == null) {
      emit(
        state.copyWith(
          phase: const PhaseExtractionFailed(),
          failure: const ExtractionFailure(
            messageKey: 'errors.required_fields_missing',
            kind: ExtractionFailureKind.missingToken,
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        phase: const PhaseExtracting(),
        failure: null,
      ),
    );

    final result = await _extractDocuments(
      ExtractDocumentsParams(
        authorizationToken: token,
        emiratesIdFrontId: frontId,
        emiratesIdBackId: backId,
        tradeLicenseId: state.isOrganization
            ? state.tradeLicence?.remoteId
            : null,
      ),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is ConflictFailure) {
          // 409: this Emirates ID is already linked to another account.
          emit(
            state.copyWith(
              extraction: const ExtractionResult(
                emiratesId: EmiratesIdResult.alreadyRegistered(),
              ),
              phase: const PhaseExtractionDone(),
              failure: null,
            ),
          );
        } else {
          // Network/server error — not an OCR issue. Show retry, not "blurry image".
          emit(
            state.copyWith(
              phase: const PhaseExtractionFailed(),
              failure: ExtractionFailure(
                messageKey: failure.message,
                kind: failure is NetworkFailure
                    ? ExtractionFailureKind.network
                    : ExtractionFailureKind.server,
              ),
            ),
          );
        }
      },
      (extraction) => emit(
        state.copyWith(
          extraction: extraction,
          phase: const PhaseExtractionDone(),
          failure: null,
        ),
      ),
    );
  }

  // ── Profile completion ─────────────────────────────────────────────────────

  /// Completes provider profile by posting to the backend.
  ///
  /// Returns [AuthSessionEntity] on success which contains session tokens
  /// that the auth layer can persist. On failure, emits [PhaseSubmissionFailed]
  /// and sets [RegistrationState.failure] to a [ProfileFailure].
  Future<AuthSessionEntity?> completeProfile() async {
    final token = state.onboardingToken;
    final frontId = state.emiratesIdFront?.remoteId;
    final backId = state.emiratesIdBack?.remoteId;
    final providerType = state.providerType;

    if (token == null || frontId == null || backId == null ||
        providerType == null) {
      emit(
        state.copyWith(
          phase: const PhaseSubmissionFailed(),
          failure: const ProfileFailure(
            messageKey: 'errors.required_fields_missing',
          ),
        ),
      );
      return null;
    }

    // Use extracted name as fallback if manual entry is empty.
    final fullName = state.fullName.isNotEmpty
        ? state.fullName
        : (state.extraction?.emiratesId.fullNameEn ?? '');
    
    // Use extracted business name as fallback.
    final businessName = state.businessName.isNotEmpty
        ? state.businessName
        : (state.extraction?.tradeLicence?.tradeNameEn ?? '');

    emit(
      state.copyWith(
        phase: const PhaseSubmitting(),
        failure: null,
      ),
    );

    final result = await _completeProfile(
      CompleteProfileParams(
        authorizationToken: token,
        emiratesIdFrontId: frontId,
        emiratesIdBackId: backId,
        providerType: providerType,
        tradeLicenseId:
            state.isOrganization ? state.tradeLicence?.remoteId : null,
        fullName: state.isOrganization
            ? null
            : (fullName.isNotEmpty ? fullName : null),
        businessName: state.isOrganization
            ? (businessName.isNotEmpty ? businessName : null)
            : null,
        representativeFullName: state.isOrganization
            ? (state.representativeName.isNotEmpty
                ? state.representativeName
                : null)
            : null,
        representativeEmail: state.isOrganization
            ? (state.email.isNotEmpty ? state.email : null)
            : null,
      ),
    ).run();

    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            phase: const PhaseSubmissionFailed(),
            failure: ProfileFailure(messageKey: failure.message),
          ),
        );
        return null;
      },
      (authResult) {
        emit(state.copyWith(phase: const PhaseSubmissionDone()));
        return authResult;
      },
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
