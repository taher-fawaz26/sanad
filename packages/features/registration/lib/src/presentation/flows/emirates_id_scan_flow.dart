import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/models/emirates_id_scan_session.dart';
import 'package:registration/src/routes/registration_routes.dart';

/// Orchestrates the Emirates ID scan flow: capture each side via
/// [AssetPicker.scanDocument], preview in registration UI, then review.
abstract final class EmiratesIdScanFlow {
  EmiratesIdScanFlow._();

  static const _scanOptions = AssetPickerOptions(
    allowedAssetTypes: [AssetType.image],
  );

  /// Starts the scan flow.
  ///
  /// When [retakeSide] is null, captures front then back and navigates to the
  /// review screen. When set, only the given side is recaptured (used from
  /// review or identity replace in later phases).
  static Future<void> start(
    BuildContext context, {
    EmiratesIdScanSide? retakeSide,
    EmiratesIdScanLaunch launch = EmiratesIdScanLaunch.identity,
  }) async {
    final cubit = context.read<RegistrationCubit>();
    var session = EmiratesIdScanSession(
      front: cubit.state.emiratesIdFront?.asset,
      back: cubit.state.emiratesIdBack?.asset,
    );

    final captureFront =
        retakeSide == null || retakeSide == EmiratesIdScanSide.front;
    final captureBack =
        retakeSide == null || retakeSide == EmiratesIdScanSide.back;

    try {
      if (captureFront) {
        final front = await _scanDocument();
        if (front == null || !context.mounted) return;
        session = session.copyWith(front: front);

        final afterFront = await context.push<EmiratesIdScanSession>(
          RegistrationRoutes.emiratesIdScanFrontPreview,
          extra: session,
        );
        if (afterFront == null || !context.mounted) return;
        session = afterFront;
      }

      if (captureBack) {
        final back = await _scanDocument();
        if (back == null || !context.mounted) return;
        session = session.copyWith(back: back);

        final afterBack = await context.push<EmiratesIdScanSession>(
          RegistrationRoutes.emiratesIdScanBackPreview,
          extra: session,
        );
        if (afterBack == null || !context.mounted) return;
        session = afterBack;
      }

      if (!session.isComplete) return;

      cubit.setEmiratesIdLocal(
        front: session.front,
        back: session.back,
      );

      if (!context.mounted) return;

      // Full scan and identity Replace go through review; in-review retake
      // stays on the review screen.
      if (retakeSide == null || launch == EmiratesIdScanLaunch.identity) {
        await context.push(RegistrationRoutes.reviewIdPhotos);
      }
    } on AssetPickerException {
      if (!context.mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  /// Scans a single Emirates ID side via [AssetPicker.scanDocument].
  static Future<PickedAsset?> scanDocumentSide() => _scanDocument();

  static Future<PickedAsset?> _scanDocument() async {
    final result = await AssetPicker.scanDocument(options: _scanOptions);
    if (result.cancelled || result.isEmpty) return null;
    return result.single;
  }
}
