import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/cubit/registration_details_cubit.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_logo.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_sliver_shell.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_navigation.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';

// Figma: Identity Verification — node 2794:34425 (page layout).
// Uses DocumentUploadCard for all states (empty, uploading, success, failed).

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  bool _isPicking = false;

  DocumentUploadCardLabels get _labels => DocumentUploadCardLabels(
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

  Future<void> _upload(DocumentType slot) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final controller = DocumentFlowController(
        context.read<DocumentFlowBloc>(),
      );
      await controller.pick(
        context,
        type: slot,
        options: registrationEmiratesIdOptions(context),
        theme: registrationPickerTheme(context),
      );
    } on AssetPickerException catch (e) {
      // Keep the user-facing copy generic, but preserve the concrete
      // exception (e.g. an AssetValidationException's per-rule messages) in
      // debug so a capture that succeeds natively but fails validation is
      // never again invisible.
      if (kDebugMode) debugPrint('[IdentityVerification] capture failed: $e');
      if (mounted) {
        showAppErrorSnackbar(
          context: context,
          title: 'registration.capture_failed'.tr(),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _clearSlot(DocumentType slot) =>
      context.read<DocumentFlowBloc>().add(DocumentRemoved(slot));

  void _continue() {
    final isOrganization = context
        .read<RegistrationDetailsCubit>()
        .state
        .isOrganization;
    context.go(
      isOrganization
          ? RegistrationRoutes.tradeLicence
          : RegistrationRoutes.extracting,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (prev, curr) =>
          prev.failure != curr.failure &&
          (curr.failure is UploadFailure ||
              curr.failure is DocumentValidationFailure),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        if (failure is! UploadFailure &&
            failure is! DocumentValidationFailure) {
          return;
        }
        showAppErrorSnackbar(context: context, title: failure.messageKey.tr());
      },
      builder: (context, state) {
        final front = state.documentAt(DocumentType.emiratesIdFront);
        final back = state.documentAt(DocumentType.emiratesIdBack);
        final canContinue =
            (front?.isUploaded ?? false) && (back?.isUploaded ?? false);
        final title = 'registration.identity_title'.tr();

        return RegistrationSliverShell(
          onBack: () => RegistrationNavigation.popStep(
            context,
            isOrganization: context
                .read<RegistrationDetailsCubit>()
                .state
                .isOrganization,
          ),
          headerBuilder: (context, t) => RegistrationLogo(
            collapseProgress: t,
            collapsedTitle: title,
            reserveLeadingSpace: true,
          ),
          footer: AppButton(
            label: 'common.continue'.tr(),
            onPressed: canContinue ? _continue : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AppSvgPicture.asset(
                  AppSvgs.registrationIdentityScan,
                  width: responsiveDimension(48),
                  height: responsiveDimension(48),
                  colorFilter: ColorFilter.mode(
                    context.appColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xxl)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.appTypography.title2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.sm)),
              Text(
                'registration.identity_subtitle'.tr(),
                textAlign: TextAlign.center,
                style: context.appTypography.regularNormal.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xxl)),
              DocumentUploadCard(
                title: 'registration.id_front'.tr(),
                labels: _labels,
                uploadable: front,
                onUpload: () => _upload(DocumentType.emiratesIdFront),
                onCancel: () => context.read<DocumentFlowBloc>().add(
                  const DocumentUploadCancelled(DocumentType.emiratesIdFront),
                ),
                onReplace: () => _upload(DocumentType.emiratesIdFront),
                onRemove: () => _clearSlot(DocumentType.emiratesIdFront),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
              DocumentUploadCard(
                title: 'registration.id_back'.tr(),
                labels: _labels,
                uploadable: back,
                onUpload: () => _upload(DocumentType.emiratesIdBack),
                onCancel: () => context.read<DocumentFlowBloc>().add(
                  const DocumentUploadCancelled(DocumentType.emiratesIdBack),
                ),
                onReplace: () => _upload(DocumentType.emiratesIdBack),
                onRemove: () => _clearSlot(DocumentType.emiratesIdBack),
              ),
            ],
          ),
        );
      },
    );
  }
}
