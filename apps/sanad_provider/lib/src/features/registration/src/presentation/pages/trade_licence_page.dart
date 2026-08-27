import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_header.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_logo.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_sliver_shell.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_navigation.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;

/// Step 7 (Organization path only) — trade licence upload.
///
/// Reuses the same [DocumentFlowController] pipeline as Emirates ID.
/// Self-wraps in [RegistrationSliverShell] so the back / next actions live in
/// the pinned footer — always visible above the scrolling upload card.
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
    retryUpload: 'common.retry'.tr(),
    checkingDocument: 'registration.checking_document'.tr(),
  );

  Future<void> _capture(BuildContext context) async {
    try {
      final controller = DocumentFlowController(
        context.read<DocumentFlowBloc>(),
      );
      await controller.pick(
        context,
        type: DocumentType.tradeLicense,
        options: registrationDocumentOptions(context),
        theme: registrationPickerTheme(context),
      );
    } on AssetPickerException catch (e) {
      if (kDebugMode) debugPrint('[TradeLicence] capture failed: $e');
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
    final title = 'registration.trade_licence_title'.tr();

    return BlocListener<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure &&
          (current.failure is UploadFailure ||
              current.failure is DocumentValidationFailure),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        if (failure is! UploadFailure &&
            failure is! DocumentValidationFailure) {
          return;
        }
        showAppErrorSnackbar(context: context, title: failure.messageKey.tr());
      },
      child: BlocBuilder<DocumentFlowBloc, DocumentFlowState>(
        builder: (context, state) {
          final tradeLicence = state.documentAt(DocumentType.tradeLicense);
          return RegistrationSliverShell(
            onBack: () => RegistrationNavigation.popStep(
              context,
              isOrganization: true,
            ),
            headerBuilder: (context, t) => RegistrationLogo(
              collapseProgress: t,
              collapsedTitle: title,
              reserveLeadingSpace: true,
            ),
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
                    label: 'common.next'.tr(),
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
                  title: title,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
