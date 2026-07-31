import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/models/registration_document_slot.dart';
import 'package:registration/src/presentation/widgets/document_upload_card.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:registration/src/routes/registration_routes.dart';

const _kIconSize = 48.0;

/// Step 7 (Organization path only) — trade licence upload.
///
/// Reuses the same [RegistrationCubit.uploadDocument] pipeline as Emirates ID.
/// Wraps itself in [AuthScreenShell] so the back / next actions live in the
/// pinned footer — always visible above the scrolling upload card.
class TradeLicencePage extends StatelessWidget {
  const TradeLicencePage({super.key});

  Future<void> _capture(BuildContext context) async {
    try {
      final result = await captureRegistrationDocument(context);
      if (result == null || result.isEmpty || !context.mounted) return;
      await context.read<RegistrationCubit>().uploadDocument(
            slot: RegistrationDocumentSlot.tradeLicence,
            asset: result.assets.first,
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
          return AuthScreenShell(
            onBack: () => context.pop(),
            title: 'registration.trade_licence_title'.tr(),
            footer: Row(
              children: [
                Expanded(
                  child: AppButtonPresets.secondary(
                    label: 'registration.back'.tr(),
                    onPressed: () => context.pop(),
                  ),
                ),
                SizedBox(width: responsiveDimension(AppSpacing.md)),
                Expanded(
                  child: AppButtonPresets.primary(
                    label: 'registration.next'.tr(),
                    onPressed: state.hasTradeLicenceUploaded
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
                    uploadable: state.tradeLicence,
                    onUpload: () => _capture(context),
                    onCancel: () => context
                        .read<RegistrationCubit>()
                        .cancelDocumentUpload(
                          RegistrationDocumentSlot.tradeLicence,
                        ),
                    onReplace: () => _capture(context),
                    onRemove: () => context
                        .read<RegistrationCubit>()
                        .clearDocument(RegistrationDocumentSlot.tradeLicence),
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
