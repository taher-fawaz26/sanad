import 'package:app_assets/app_assets.dart';
import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/flows/emirates_id_scan_flow.dart';
import 'package:registration/src/presentation/models/emirates_id_scan_session.dart';
import 'package:registration/src/presentation/widgets/captured_image.dart';
import 'package:registration/src/presentation/widgets/registration_scan_chrome.dart';

const double _kCardAspect = 254.76 / 156.49;

/// Full-screen preview after scanning one Emirates ID side.
///
/// Figma: `2897:13610` (front), `2897:13635` (back). Confirms the capture
/// before continuing the multi-step scan flow.
class EmiratesIdScanPreviewPage extends StatefulWidget {
  const EmiratesIdScanPreviewPage({
    required this.side,
    required this.initialSession,
    super.key,
  });

  final EmiratesIdScanSide side;
  final EmiratesIdScanSession initialSession;

  @override
  State<EmiratesIdScanPreviewPage> createState() =>
      _EmiratesIdScanPreviewPageState();
}

class _EmiratesIdScanPreviewPageState extends State<EmiratesIdScanPreviewPage> {
  late EmiratesIdScanSession _session;
  bool _isRetaking = false;

  bool get _isFront => widget.side == EmiratesIdScanSide.front;

  PickedAsset? get _currentAsset =>
      _isFront ? _session.front : _session.back;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
  }

  Future<void> _retakeSide() async {
    setState(() => _isRetaking = true);
    try {
      final asset = await EmiratesIdScanFlow.scanDocumentSide();
      if (!mounted || asset == null) return;
      setState(() {
        _session = _isFront
            ? _session.copyWith(front: asset)
            : _session.copyWith(back: asset);
      });
    } on AssetPickerException {
      if (!mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    } finally {
      if (mounted) setState(() => _isRetaking = false);
    }
  }

  void _continueFlow() {
    if (_currentAsset == null) return;
    context.pop(_session);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final asset = _currentAsset;

    return RegistrationGradientScaffold(
      child: Column(
        children: [
          RegistrationScanBackButton(onBack: () => context.pop()),
          RegistrationScanTitle(
            title: 'registration.review_photos_title'.tr(),
            subtitle: _isFront
                ? 'registration.scan_front_preview_subtitle'.tr()
                : 'registration.scan_back_preview_subtitle'.tr(),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.md)),
          ScanStepIndicator(
            activeStep: _isFront ? 1 : 2,
            frontLabel: 'registration.front_side'.tr(),
            backLabel: 'registration.back_side'.tr(),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsiveDimension(AppSpacing.xl),
                vertical: responsiveDimension(AppSpacing.xl),
              ),
              child: asset == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Row(
                          children: [
                            AppSvgPicture.asset(
                              AppSvgs.registrationCheckCircle,
                              width: responsiveDimension(18),
                              height: responsiveDimension(18),
                              colorFilter: ColorFilter.mode(
                                colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: responsiveDimension(AppSpacing.sm)),
                            Text(
                              _isFront
                                  ? 'registration.front_side'.tr()
                                  : 'registration.back_side'.tr(),
                              style: typography.smallNormal.copyWith(
                                color: colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsiveDimension(AppSpacing.sm)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppRadius.circularMd,
                            child: AspectRatio(
                              aspectRatio: _kCardAspect,
                              child: CapturedImage(asset: asset),
                            ),
                          ),
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
              responsiveDimension(AppSpacing.md),
            ),
            child: AppButtonPresets.secondary(
              label: _isFront
                  ? 'registration.retake_front_side'.tr()
                  : 'registration.retake_back_side'.tr(),
              onPressed: _isRetaking ? null : _retakeSide,
              isLoading: _isRetaking,
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
              label: _isFront
                  ? 'registration.scan_back_side'.tr()
                  : 'registration.confirm_photos'.tr(),
              onPressed: asset == null || _isRetaking ? null : _continueFlow,
            ),
          ),
        ],
      ),
    );
  }
}
