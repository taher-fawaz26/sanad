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
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:registration/src/routes/registration_navigation.dart';
import 'package:registration/src/routes/registration_routes.dart';

// Figma: Identity Verification — node 2794:34425 (page layout).
// Uses DocumentUploadCard for all states (empty, uploading, success, failed).

class IdentityVerificationPage extends StatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  State<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState extends State<IdentityVerificationPage> {
  bool _isPickingFront = false;
  bool _isPickingBack = false;

  Future<void> _upload(RegistrationDocumentSlot slot) async {
    if (_isPickingFront || _isPickingBack) return;

    final source = await showAssetSourceSheet(
      context: context,
      options: kRegistrationEmiratesIdOptions,
      theme: registrationPickerTheme(context),
    );
    if (source == null || !mounted) return;

    setState(() {
      if (slot == RegistrationDocumentSlot.emiratesIdFront) {
        _isPickingFront = true;
      } else {
        _isPickingBack = true;
      }
    });

    try {
      final result = await pickRegistrationAsset(
        source,
        kRegistrationEmiratesIdOptions,
      );
      if (!mounted) return;
      if (result == null || result.isEmpty) return;

      final cubit = context.read<RegistrationCubit>();
      final assets = result.assets;

      if (assets.length > 1) {
        cubit.setEmiratesIdLocal(front: assets[0], back: assets[1]);
        await cubit.uploadEmiratesIdSequence();
      } else if (slot == RegistrationDocumentSlot.emiratesIdFront) {
        cubit.setEmiratesIdLocal(front: assets.first);
        await cubit.uploadDocument(slot: slot, asset: assets.first);
      } else {
        cubit.setEmiratesIdLocal(back: assets.first);
        await cubit.uploadDocument(slot: slot, asset: assets.first);
      }
    } on AssetPickerException {
      if (mounted) {
        showAppErrorSnackbar(
          context: context,
          title: 'registration.capture_failed'.tr(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFront = false;
          _isPickingBack = false;
        });
      }
    }
  }

  void _clearSlot(RegistrationDocumentSlot slot) =>
      context.read<RegistrationCubit>().clearDocument(slot);

  void _continue() {
    final state = context.read<RegistrationCubit>().state;
    context.go(
      state.isOrganization
          ? RegistrationRoutes.tradeLicence
          : RegistrationRoutes.extracting,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationCubit, RegistrationState>(
      listenWhen: (prev, curr) =>
          prev.lastUploadFailure != curr.lastUploadFailure &&
          curr.lastUploadFailure != null,
      listener: (context, state) {
        final failure = state.lastUploadFailure;
        if (failure == null) return;
        showAppErrorSnackbar(context: context, title: failure.tr());
        context.read<RegistrationCubit>().clearUploadFailure();
      },
      builder: (context, state) {
        final canContinue = state.hasBothIdSides;

        return AuthScreenShell(
          onBack: () => RegistrationNavigation.popStep(
            context,
            registrationState: context.read<RegistrationCubit>().state,
          ),
          title: 'registration.identity_title'.tr(),
          footer: AppButton(
            label: 'registration.continue'.tr(),
            onPressed: canContinue ? _continue : null,
          ),
          child: SingleChildScrollView(
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
                'registration.identity_title'.tr(),
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
                uploadable: state.emiratesIdFront,
                onUpload: _isPickingFront
                    ? () {}
                    : () => _upload(RegistrationDocumentSlot.emiratesIdFront),
                onCancel: () => context
                    .read<RegistrationCubit>()
                    .cancelDocumentUpload(
                      RegistrationDocumentSlot.emiratesIdFront,
                    ),
                onReplace: () =>
                    _upload(RegistrationDocumentSlot.emiratesIdFront),
                onRemove: () =>
                    _clearSlot(RegistrationDocumentSlot.emiratesIdFront),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
              DocumentUploadCard(
                title: 'registration.id_back'.tr(),
                uploadable: state.emiratesIdBack,
                onUpload: _isPickingBack
                    ? () {}
                    : () => _upload(RegistrationDocumentSlot.emiratesIdBack),
                onCancel: () => context
                    .read<RegistrationCubit>()
                    .cancelDocumentUpload(
                      RegistrationDocumentSlot.emiratesIdBack,
                    ),
                onReplace: () =>
                    _upload(RegistrationDocumentSlot.emiratesIdBack),
                onRemove: () =>
                    _clearSlot(RegistrationDocumentSlot.emiratesIdBack),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xl)),
            ],
          ),
        ),
      );
      },
    );
  }
}
