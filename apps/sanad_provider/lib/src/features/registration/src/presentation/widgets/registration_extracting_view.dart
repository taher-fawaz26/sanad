import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_scan_chrome.dart';
import 'package:shared_ui/shared_ui.dart';

/// The "AI extracting document information" loading visual — Sanad logo,
/// [AppDocumentExtractionLoader] orb, and the `registration.extracting`
/// caption over [RegistrationGradientScaffold].
///
/// Shared by `ExtractingDocumentsPage` (first extraction) and
/// `ReviewInformationPage` (re-extraction while replacing a document) so
/// every extraction wait shows the same mounted, animated visual instead of
/// a bare, background-less loading indicator (SAN-575: the latter painted as
/// a black screen during document replacement).
class RegistrationExtractingView extends StatelessWidget {
  const RegistrationExtractingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return RegistrationGradientScaffold(
      child: Column(
        children: [
          SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
          AppSvgPicture.asset(
            AppSvgs.sanadLogo,
            width: responsiveDimension(160),
            height: responsiveDimension(52),
          ),
          const Spacer(),
          const AppDocumentExtractionLoader(),
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsiveDimension(AppSpacing.xl),
            ),
            child: Text(
              'registration.extracting'.tr(),
              textAlign: TextAlign.center,
              style: typography.regularNormal.copyWith(
                color: colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxxl)),
        ],
      ),
    );
  }
}
