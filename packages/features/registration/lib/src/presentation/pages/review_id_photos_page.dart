import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/flows/emirates_id_scan_flow.dart';
import 'package:registration/src/presentation/models/emirates_id_scan_session.dart';
import 'package:registration/src/presentation/widgets/captured_image.dart';
import 'package:registration/src/presentation/widgets/registration_scan_chrome.dart';

const double _kCardAspect = 254.76 / 156.49;

/// Step 6 — full-screen review of the captured Emirates ID photos.
///
/// Figma: `Review Both Sides` (`2897:13666`). Shows locally captured front and
/// back images with a per-side retake option before returning to Identity
/// Verification.
class ReviewIdPhotosPage extends StatelessWidget {
  const ReviewIdPhotosPage({super.key});

  Future<void> _retake(BuildContext context, {required bool front}) async {
    await EmiratesIdScanFlow.start(
      context,
      retakeSide:
          front ? EmiratesIdScanSide.front : EmiratesIdScanSide.back,
      launch: EmiratesIdScanLaunch.review,
    );
  }

  void _confirm(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final state = cubit.state;
    final front = state.emiratesIdFront?.asset;
    final back = state.emiratesIdBack?.asset;
    if (front == null || back == null) return;

    cubit.setEmiratesIdLocal(front: front, back: back);
    context.pop();
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
                  if (state.emiratesIdFront?.asset != null)
                    _PhotoTile(
                      label: 'registration.front_side'.tr(),
                      asset: state.emiratesIdFront!.asset,
                      onRetake: () => _retake(context, front: true),
                    ),
                  SizedBox(height: responsiveDimension(AppSpacing.lg)),
                  if (state.emiratesIdBack?.asset != null)
                    _PhotoTile(
                      label: 'registration.back_side'.tr(),
                      asset: state.emiratesIdBack!.asset,
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
              onPressed: state.hasBothIdSidesCaptured
                  ? () => _confirm(context)
                  : null,
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
