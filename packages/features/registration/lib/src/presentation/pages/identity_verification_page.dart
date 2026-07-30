import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/flows/emirates_id_scan_flow.dart';
import 'package:registration/src/presentation/models/emirates_id_scan_session.dart';
import 'package:registration/src/presentation/models/registration_document_slot.dart';
import 'package:registration/src/presentation/widgets/document_upload_card.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;

/// Step 5 — Emirates ID front/back upload.
///
/// Figma: `Identity Verification` (`2794:34425` empty, `2982:16039` filled).
/// Scan flow stores captures locally; camera/gallery/files upload immediately.
/// Continue runs sequential upload then advances the sign-up flow.
class IdentityVerificationPage extends StatelessWidget {
  const IdentityVerificationPage({super.key});

  EmiratesIdScanSide _scanSideFor(RegistrationDocumentSlot slot) =>
      switch (slot) {
        RegistrationDocumentSlot.emiratesIdFront => EmiratesIdScanSide.front,
        RegistrationDocumentSlot.emiratesIdBack => EmiratesIdScanSide.back,
        RegistrationDocumentSlot.tradeLicence =>
          throw ArgumentError('not an Emirates ID slot'),
      };

  bool _isUploading(RegistrationState state) =>
      (state.emiratesIdFront?.isUploading ?? false) ||
      (state.emiratesIdBack?.isUploading ?? false);

  Future<void> _capture(
    BuildContext context,
    RegistrationDocumentSlot slot,
  ) async {
    final theme = AssetPickerTheme.of(context);
    final options = kRegistrationDocumentOptions.copyWith(
      sheetTitle: 'registration.select_action'.tr(),
    );

    final source = await showAssetSourceSheet(
      context: context,
      options: options,
      theme: theme,
    );
    if (source == null || !context.mounted) return;

    if (source == AssetSource.scanner) {
      await EmiratesIdScanFlow.start(context);
      return;
    }

    try {
      final asset = await pickRegistrationAsset(source);
      if (asset == null || !context.mounted) return;

      await context.read<RegistrationCubit>().uploadDocument(
            slot: slot,
            asset: asset,
          );
    } on AssetPickerException {
      if (!context.mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  Future<void> _replaceScanSide(
    BuildContext context,
    RegistrationDocumentSlot slot,
  ) async {
    await EmiratesIdScanFlow.start(
      context,
      retakeSide: _scanSideFor(slot),
    );
  }

  Future<void> _continue(BuildContext context) async {
    final cubit = context.read<RegistrationCubit>();
    await cubit.uploadEmiratesIdSequence();
    if (!context.mounted || !cubit.state.hasBothIdSides) return;

    final isOrg = cubit.state.isOrganization;
    await context.push(
      isOrg ? RegistrationRoutes.tradeLicence : RegistrationRoutes.extracting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<RegistrationCubit, RegistrationState>(
      listenWhen: (previous, current) =>
          previous.lastUploadFailure != current.lastUploadFailure &&
          current.lastUploadFailure != null,
      listener: (context, state) {
        final failure = state.lastUploadFailure;
        if (failure == null) return;
        showAppErrorSnackbar(
          context: context,
          title: failure.tr(),
        );
        context.read<RegistrationCubit>().clearUploadFailure();
      },
      child: BlocBuilder<RegistrationCubit, RegistrationState>(
        builder: (context, state) {
          final isUploading = _isUploading(state);

          return AuthScreenShell(
            onBack: () => context.pop(),
            title: 'registration.identity_title'.tr(),
            footer: AppButton(
              label: 'registration.continue'.tr(),
              isLoading: isUploading,
              onPressed: state.hasBothIdSidesCaptured && !isUploading
                  ? () => _continue(context)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSvgPicture.asset(
                  AppSvgs.registrationIdentityScan,
                  width: responsiveDimension(_kIconSize),
                  height: responsiveDimension(_kIconSize),
                  colorFilter: ColorFilter.mode(
                    colors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                RegistrationHeader(
                  title: 'registration.identity_title'.tr(),
                  subtitle: Text('registration.identity_subtitle'.tr()),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                DocumentUploadCard(
                  title: 'registration.id_front'.tr(),
                  uploadable: state.emiratesIdFront,
                  onUpload: () => _capture(
                    context,
                    RegistrationDocumentSlot.emiratesIdFront,
                  ),
                  onReplace: () => _replaceScanSide(
                    context,
                    RegistrationDocumentSlot.emiratesIdFront,
                  ),
                  onRemove: () => context
                      .read<RegistrationCubit>()
                      .clearDocument(
                        RegistrationDocumentSlot.emiratesIdFront,
                      ),
                  onCancel: () => context
                      .read<RegistrationCubit>()
                      .cancelDocumentUpload(
                        RegistrationDocumentSlot.emiratesIdFront,
                      ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                DocumentUploadCard(
                  title: 'registration.id_back'.tr(),
                  uploadable: state.emiratesIdBack,
                  onUpload: () => _capture(
                    context,
                    RegistrationDocumentSlot.emiratesIdBack,
                  ),
                  onReplace: () => _replaceScanSide(
                    context,
                    RegistrationDocumentSlot.emiratesIdBack,
                  ),
                  onRemove: () => context
                      .read<RegistrationCubit>()
                      .clearDocument(
                        RegistrationDocumentSlot.emiratesIdBack,
                      ),
                  onCancel: () => context
                      .read<RegistrationCubit>()
                      .cancelDocumentUpload(
                        RegistrationDocumentSlot.emiratesIdBack,
                      ),
                ),
                SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
              ],
            ),
          );
        },
      ),
    );
  }
}
