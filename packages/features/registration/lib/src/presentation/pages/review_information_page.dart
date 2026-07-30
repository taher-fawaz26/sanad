import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/presentation/cubit/registration_cubit.dart';
import 'package:registration/src/presentation/cubit/registration_state.dart';
import 'package:registration/src/presentation/models/registration_document_slot.dart';
import 'package:registration/src/presentation/widgets/registration_header.dart';
import 'package:registration/src/presentation/widgets/review_section_card.dart';
import 'package:registration/src/presentation/widgets/select_capture_method_sheet.dart';

/// Step 9 — review the extracted document information.
///
/// Figma: `Review Information` (`3001:19131`) + error variant
/// (`3001:19276`). Renders each document as a [ReviewSectionCard] whose tone
/// reflects its extraction outcome. "Continue to Dashboard" unlocks only when
/// every document extracted cleanly.
class ReviewInformationPage extends StatelessWidget {
  const ReviewInformationPage({required this.homeRoute, super.key});

  /// Post-registration landing route (injected from the app via the module).
  final String homeRoute;

  Future<void> _replaceEmiratesId(BuildContext context) async {
    try {
      final asset = await captureRegistrationDocument(context);
      if (asset == null || !context.mounted) return;
      final cubit = context.read<RegistrationCubit>();
      await cubit.uploadDocument(
        slot: RegistrationDocumentSlot.emiratesIdFront,
        asset: asset,
      );
      if (!context.mounted) return;
      await cubit.extractDocuments();
    } on AssetPickerException {
      if (!context.mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  Future<void> _replaceTradeLicence(BuildContext context) async {
    try {
      final asset = await captureRegistrationDocument(context);
      if (asset == null || !context.mounted) return;
      final cubit = context.read<RegistrationCubit>();
      await cubit.uploadDocument(
        slot: RegistrationDocumentSlot.tradeLicence,
        asset: asset,
      );
      if (!context.mounted) return;
      await cubit.extractDocuments();
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
    final state = context.watch<RegistrationCubit>().state;
    final extraction = state.extraction;

    if (extraction == null ||
        state.extractionStatus == ExtractionStatus.extracting) {
      return const Center(child: AppLoadingIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationHeader(
          title: 'registration.review_title'.tr(),
          subtitle: Text('registration.review_subtitle'.tr()),
        ),
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        ReviewSectionCard(
          title: 'registration.emirates_id_details'.tr(),
          issue: extraction.emiratesId.issue,
          fields: _emiratesIdFields(extraction.emiratesId),
          thumbnail: state.emiratesIdFront?.asset,
          onReplace: () => _replaceEmiratesId(context),
        ),
        if (extraction.tradeLicence != null) ...[
          SizedBox(height: responsiveDimension(AppSpacing.xl)),
          ReviewSectionCard(
            title: 'registration.trade_licence_details'.tr(),
            issue: extraction.tradeLicence!.issue,
            fields: _tradeLicenceFields(extraction.tradeLicence!),
            thumbnail: state.tradeLicence?.asset,
            onReplace: () => _replaceTradeLicence(context),
          ),
        ],
        SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
        AppButtonPresets.primary(
          label: 'registration.continue_to_dashboard'.tr(),
          onPressed: extraction.allOk ? () => context.go(homeRoute) : null,
        ),
      ],
    );
  }

  List<ExtractedField> _emiratesIdFields(EmiratesIdResult r) => [
        ExtractedField(
          'registration.full_name_en'.tr(),
          r.fullNameEn,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.full_name_ar'.tr(),
          r.fullNameAr,
          fullWidth: true,
          rtl: true,
        ),
        ExtractedField(
          'registration.id_number'.tr(),
          r.idNumber,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.nationality'.tr(),
          r.nationality,
          fullWidth: true,
        ),
        ExtractedField('registration.date_of_birth'.tr(), r.dateOfBirth),
        ExtractedField(
          'registration.expiry_date'.tr(),
          r.expiryDate,
          highlight: true,
        ),
        ExtractedField('registration.gender'.tr(), r.gender),
      ];

  List<ExtractedField> _tradeLicenceFields(TradeLicenceResult r) => [
        ExtractedField(
          'registration.trade_name_en'.tr(),
          r.tradeNameEn,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.trade_name_ar'.tr(),
          r.tradeNameAr,
          fullWidth: true,
          rtl: true,
        ),
        ExtractedField(
          'registration.licence_no'.tr(),
          r.licenceNo,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.licence_type'.tr(),
          r.licenceType,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.establishment_date'.tr(),
          r.establishmentDate,
        ),
        ExtractedField(
          'registration.issuance_date'.tr(),
          r.issuanceDate,
          highlight: true,
        ),
        ExtractedField('registration.legal_form'.tr(), r.legalForm),
        ExtractedField(
          'registration.unified_reg_no'.tr(),
          r.unifiedRegNo,
          fullWidth: true,
        ),
        ExtractedField(
          'registration.unified_licence_no'.tr(),
          r.unifiedLicenceNo,
          fullWidth: true,
        ),
      ];
}
