import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/widgets/captured_image.dart';
import 'package:registration/src/presentation/widgets/registration_scan_chrome.dart';
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:registration/src/routes/registration_routes.dart';

const double _kCardAspect = 254.76 / 156.49;

/// Step 6 — full-screen review of the captured Emirates ID photos.
///
/// Figma: `Review Both Sides` (`2897:13666`). Shows the real captured front and
/// back images with a per-side retake option before continuing.
class ReviewIdPhotosPage extends StatelessWidget {
  const ReviewIdPhotosPage({super.key});

  Future<void> _retake(BuildContext context, {required bool front}) async {
    try {
      final asset = await captureRegistrationDocument(context);
      if (asset == null || !context.mounted) return;
      final cubit = context.read<RegistrationCubit>();
      front ? cubit.setEmiratesIdFront(asset) : cubit.setEmiratesIdBack(asset);
    } on AssetPickerException {
      if (!context.mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  void _confirm(BuildContext context) {
    final isOrg = context.read<RegistrationCubit>().state.isOrganization;
    context.push(
      isOrg
          ? RegistrationRoutes.tradeLicence
          : RegistrationRoutes.extracting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RegistrationCubit>().state;

    return RegistrationGradientScaffold(
      child: Column(
        children: [
          RegistrationScanBackButton(onBack: () => context.pop()),
          RegistrationScanTitle(
            title: 'registration.review_photos_title'.tr(),
            subtitle: 'registration.review_photos_subtitle'.tr(),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.md)),
          ScanStepIndicator(
            activeStep: 2,
            frontLabel: 'registration.front_side'.tr(),
            backLabel: 'registration.back_side'.tr(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(AppSpacing.xl),
                vertical: responsiveDimension(AppSpacing.xl),
              ),
              child: Column(
                children: [
                  if (state.emiratesIdFront != null)
                    _PhotoTile(
                      label: 'registration.front_side'.tr(),
                      asset: state.emiratesIdFront!,
                      onRetake: () => _retake(context, front: true),
                    ),
                  SizedBox(height: responsiveDimension(AppSpacing.lg)),
                  if (state.emiratesIdBack != null)
                    _PhotoTile(
                      label: 'registration.back_side'.tr(),
                      asset: state.emiratesIdBack!,
                      onRetake: () => _retake(context, front: false),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsiveDimension(AppSpacing.xl),
              0,
              responsiveDimension(AppSpacing.xl),
              responsiveDimension(AppSpacing.xl),
            ),
            child: AppButtonPresets.primary(
              label: 'registration.confirm_photos'.tr(),
              onPressed: () => _confirm(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.label,
    required this.asset,
    required this.onRetake,
  });

  final String label;
  final PickedAsset asset;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppSvgPicture.asset(
              AppSvgs.registrationCheckCircle,
              width: responsiveDimension(18),
              height: responsiveDimension(18),
              colorFilter: ColorFilter.mode(colors.white, BlendMode.srcIn),
            ),
            SizedBox(width: responsiveDimension(AppSpacing.sm)),
            Text(
              label,
              style: typography.smallNormal.copyWith(color: colors.white),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRetake,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AppSvgPicture.asset(
                    AppSvgs.registrationRetake,
                    width: responsiveDimension(16),
                    height: responsiveDimension(16),
                    colorFilter:
                        ColorFilter.mode(colors.primary300, BlendMode.srcIn),
                  ),
                  SizedBox(width: responsiveDimension(AppSpacing.xs)),
                  Text(
                    'registration.retake'.tr(),
                    style: typography.smallNormal.copyWith(
                      color: colors.primary300,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsiveDimension(AppSpacing.sm)),
        ClipRRect(
          borderRadius: AppRadius.circularMd,
          child: AspectRatio(
            aspectRatio: _kCardAspect,
            child: CapturedImage(asset: asset),
          ),
        ),
      ],
    );
  }
}
