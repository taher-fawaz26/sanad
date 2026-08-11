import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_header.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_navigation.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';
import 'package:shared_ui/shared_ui.dart';

const _kIconSize = 48.0;

/// Step 7 (Organization path only) — trade licence upload.
///
/// Reuses the same [DocumentFlowController] pipeline as Emirates ID.
/// Wraps itself in [AuthScreenShell] so the back / next actions live in the
/// pinned footer — always visible above the scrolling upload card.
class TradeLicencePage extends StatelessWidget {
  const TradeLicencePage({super.key});

  DocumentUploadCardLabels _labels() => DocumentUploadCardLabels(
    chooseUpload: 'registration.choose_upload'.tr(),
    chooseUploadHint: 'registration.choose_upload_hint'.tr(),
    uploading: 'registration.uploading'.tr(),
    uploadFailed: 'registration.upload_failed'.tr(),
    replaceDocument: 'registration.replace_document'.tr(),
    removeDocument: 'registration.remove_document'.tr(),
    upload: 'registration.upload'.tr(),
    retryUpload: 'registration.retry_upload'.tr(),
  );

  Future<void> _capture(BuildContext context) async {
    try {
      final controller = DocumentFlowController(
        context.read<DocumentFlowBloc>(),
      );
      await controller.pick(
        context,
        type: DocumentType.tradeLicense,
        options: kRegistrationDocumentOptions,
        theme: registrationPickerTheme(context),
      );
    } on AssetPickerException {
      if (!context.mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure &&
          current.failure is UploadFailure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure is! UploadFailure) return;
        showAppErrorSnackbar(context: context, title: failure.messageKey.tr());
      },
      child: BlocBuilder<DocumentFlowBloc, DocumentFlowState>(
        builder: (context, state) {
          final tradeLicence = state.documentAt(DocumentType.tradeLicense);
          return AuthScreenShell(
            onBack: () => RegistrationNavigation.popStep(
              context,
              isOrganization: true,
            ),
            title: 'registration.trade_licence_title'.tr(),
            footer: Row(
              children: [
                Expanded(
                  child: AppButtonPresets.secondary(
                    label: 'registration.back'.tr(),
                    onPressed: () => RegistrationNavigation.popStep(
                      context,
                      isOrganization: true,
                    ),
                  ),
                ),
                SizedBox(width: responsiveDimension(AppSpacing.md)),
                Expanded(
                  child: AppButtonPresets.primary(
                    label: 'registration.next'.tr(),
                    onPressed: (tradeLicence?.isUploaded ?? false)
                        ? () => context.push(RegistrationRoutes.extracting)
                        : null,
                    icon: AppSvgPicture.asset(
                      AppSvgs.registrationArrowRight,
                      width: responsiveDimension(ButtonTokens.iconSize),
                      height: responsiveDimension(ButtonTokens.iconSize),
                      colorFilter: ColorFilter.mode(
                        colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    iconPosition: AppButtonIconPosition.right,
                  ),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSvgPicture.asset(
                    AppSvgs.registrationTradeLicence,
                    width: responsiveDimension(_kIconSize),
                    height: responsiveDimension(_kIconSize),
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                  RegistrationHeader(
                    title: 'registration.trade_licence_title'.tr(),
                    subtitle: Text('registration.trade_licence_subtitle'.tr()),
                  ),
                  SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                  DocumentUploadCard(
                    title: 'registration.trade_licence_label'.tr(),
                    labels: _labels(),
                    uploadable: tradeLicence,
                    onUpload: () => _capture(context),
                    onCancel: () => context.read<DocumentFlowBloc>().add(
                      const DocumentUploadCancelled(DocumentType.tradeLicense),
                    ),
                    onReplace: () => _capture(context),
                    onRemove: () => context.read<DocumentFlowBloc>().add(
                      const DocumentRemoved(DocumentType.tradeLicense),
                    ),
                  ),
                  SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
