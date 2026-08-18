import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/profile_completion_error_dialog.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_header.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_logo.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_sliver_shell.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Step 9 — review the extracted document information.
///
/// Figma: `Review Information` (`3001:19131`) + error variant
/// (`3001:19276`). Renders each document as an [ExtractedFieldsView] whose
/// tone reflects its extraction outcome. "Continue to Dashboard" unlocks only
/// when every document extracted cleanly and submits via the shared pipeline
/// (which internally posts profile completion and persists the session).
class ReviewInformationPage extends StatefulWidget {
  const ReviewInformationPage({required this.homeRoute, super.key});

  /// Post-registration landing route (injected from the app via the module).
  final String homeRoute;

  @override
  State<ReviewInformationPage> createState() => _ReviewInformationPageState();
}

class _ReviewInformationPageState extends State<ReviewInformationPage> {
  /// Maps the flow's submit-related phases onto [RequestStatus] for
  /// [MutationListener]. Extraction failures use the same [PhaseFailure]
  /// type with a different [FailedStage] — those are not a submit mutation
  /// and must not surface the submit dialog/retry sheet, so they map to
  /// [RequestStatus.initial] (handled elsewhere on this page).
  RequestStatus _submitStatus(DocumentFlowState state) => switch (state.phase) {
    PhaseSubmitting() => RequestStatus.loading,
    PhaseSuccess() => RequestStatus.success,
    PhaseFailure(stage: FailedStage.submit) => RequestStatus.failure,
    _ => RequestStatus.initial,
  };

  void _onSubmitSuccess(BuildContext context) => context.go(widget.homeRoute);

  Future<void> _onSubmitFailure(
    BuildContext context,
    DocumentFlowState state,
  ) async {
    final failure = state.failure;
    final errorMessage = failure is SubmitFailure ? failure.messageKey : null;

    final retry = await showProfileCompletionErrorDialog(
      context: context,
      errorMessage: errorMessage,
    );

    if ((retry ?? false) && context.mounted) {
      context.read<DocumentFlowBloc>().add(const SubmitRequested());
    }
  }

  /// Routes "Replace Document" for the Emirates ID section: a
  /// [DocumentRepairScope.wholeDocument] issue (e.g. a front/back mismatch)
  /// needs both sides replaced together, so it opens the dedicated two-sided
  /// repair page; every other case (including the default `repair == null`)
  /// keeps the existing single-file replace.
  void _onReplaceRequested(BuildContext context, ExtractedDocument section) {
    final repair = section.repair;
    if (repair != null && repair.scope == DocumentRepairScope.wholeDocument) {
      context.push(RegistrationRoutes.repairEmiratesId, extra: repair);
      return;
    }
    _replace(context, DocumentType.emiratesIdFront);
  }

  Future<void> _replace(BuildContext context, DocumentType type) async {
    try {
      final result = await captureRegistrationDocument(context);
      if (result == null || result.isEmpty || !context.mounted) return;
      final bloc = context.read<DocumentFlowBloc>()
        ..add(DocumentPicked(type: type, asset: result.assets.first))
        ..add(DocumentUploadRequested(type));
      await bloc.stream.firstWhere(
        (state) =>
            (state.documentAt(type)?.isUploaded ?? false) ||
            (state.documentAt(type)?.status.isFailed ?? false),
      );
      if (!context.mounted) return;
      bloc.add(const ExtractionRequested());
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
    final state = context.watch<DocumentFlowBloc>().state;
    final extracted = state.extracted;

    if (extracted == null && state.phase is PhaseIdle) {
      // User arrived here without going through extraction — redirect to start.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RegistrationRoutes.selectAccountType);
      });
      return const SizedBox.shrink();
    }

    if (extracted == null || state.phase is PhaseExtracting) {
      return const Center(child: AppLoadingIndicator());
    }

    final emiratesId = extracted.sectionOf(DocumentType.emiratesIdFront);
    final tradeLicence = extracted.sectionOf(DocumentType.tradeLicense);

    return MutationListener<DocumentFlowBloc, DocumentFlowState>(
      status: _submitStatus,
      title: (context) => 'registration.completing_profile'.tr(),
      onSuccess: (context, state) => _onSubmitSuccess(context),
      onFailure: _onSubmitFailure,
      child: _buildReview(context, state, extracted, emiratesId, tradeLicence),
    );
  }

  Widget _buildReview(
    BuildContext context,
    DocumentFlowState state,
    ExtractedDocuments extracted,
    ExtractedDocument? emiratesId,
    ExtractedDocument? tradeLicence,
  ) {
    final title = 'registration.review_title'.tr();
    return RegistrationSliverShell(
      headerBuilder: (context, t) =>
          RegistrationLogo(collapseProgress: t, collapsedTitle: title),
      footer: AppButtonPresets.primary(
        label: 'registration.continue_to_dashboard'.tr(),
        onPressed: extracted.allOk
            ? () => context.read<DocumentFlowBloc>().add(
                const SubmitRequested(),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RegistrationHeader(
            title: title,
            subtitle: Text('registration.review_subtitle'.tr()),
          ),
          SizedBox(height: responsiveDimension(AppSpacing.xxxl)),
          if (emiratesId != null)
            ExtractedFieldsView(
              title: 'registration.emirates_id_details'.tr(),
              issue: emiratesId.issue,
              fields: _emiratesIdFields(emiratesId.raw),
              replaceLabel: 'registration.replace_document'.tr(),
              resolveIssueLabels: (issue) =>
                  _resolveIssueLabels(issue, detail: emiratesId.issueDetail),
              thumbnail: state.documentAt(DocumentType.emiratesIdFront)?.asset,
              onReplace: () => _onReplaceRequested(context, emiratesId),
            ),
          if (tradeLicence != null) ...[
            SizedBox(height: responsiveDimension(AppSpacing.xl)),
            ExtractedFieldsView(
              title: 'registration.trade_licence_details'.tr(),
              issue: tradeLicence.issue,
              fields: _tradeLicenceFields(tradeLicence.raw),
              replaceLabel: 'registration.replace_document'.tr(),
              resolveIssueLabels: (issue) =>
                  _resolveIssueLabels(issue, detail: tradeLicence.issueDetail),
              thumbnail: state.documentAt(DocumentType.tradeLicense)?.asset,
              onReplace: () => _replace(context, DocumentType.tradeLicense),
            ),
          ],
        ],
      ),
    );
  }

  /// [detail] is the affected document's [ExtractedDocument.issueDetail] — a
  /// dynamic, already-localized backend message (e.g. from an
  /// `EXTRACTION_INCOMPLETE` rejection). When present it replaces the static
  /// banner copy; when null the issue-generic message is used, so all existing
  /// states render exactly as before.
  DocumentIssueLabels _resolveIssueLabels(
    DocumentIssue issue, {
    String? detail,
  }) => switch (issue) {
    DocumentIssue.none => DocumentIssueLabels(
      badgeLabel: 'registration.extracted_success'.tr(),
      badgeType: AppStatusBadgeType.success,
    ),
    DocumentIssue.imageUnclear => DocumentIssueLabels(
      badgeLabel: 'registration.image_unclear'.tr(),
      badgeType: AppStatusBadgeType.warning,
      bannerTitle: 'registration.image_unclear'.tr(),
      bannerMessage: (detail != null && detail.isNotEmpty)
          ? detail
          : 'registration.image_unclear_message'.tr(),
    ),
    DocumentIssue.alreadyRegistered => DocumentIssueLabels(
      badgeLabel: 'registration.emirates_id_already_registered'.tr(),
      badgeType: AppStatusBadgeType.alert,
      bannerTitle: 'registration.emirates_id_already_registered'.tr(),
      bannerMessage: 'registration.emirates_id_already_registered_message'.tr(),
    ),
    DocumentIssue.expired => DocumentIssueLabels(
      badgeLabel: 'registration.expired'.tr(),
      badgeType: AppStatusBadgeType.alert,
      bannerTitle: 'registration.expired'.tr(),
      bannerMessage: 'registration.expired_message'.tr(),
    ),
  };

  List<ExtractedField> _emiratesIdFields(Map<String, String> r) => [
    ExtractedField(
      'registration.full_name_en'.tr(),
      r['fullNameEn'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.full_name_ar'.tr(),
      r['fullNameAr'] ?? '',
      fullWidth: true,
      rtl: true,
    ),
    ExtractedField(
      'registration.id_number'.tr(),
      r['idNumber'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.nationality'.tr(),
      r['nationality'] ?? '',
      fullWidth: true,
    ),
    ExtractedField('registration.date_of_birth'.tr(), r['dateOfBirth'] ?? ''),
    ExtractedField(
      'registration.expiry_date'.tr(),
      r['expiryDate'] ?? '',
      highlight: true,
    ),
    ExtractedField('registration.gender'.tr(), r['gender'] ?? ''),
  ];

  List<ExtractedField> _tradeLicenceFields(Map<String, String> r) => [
    ExtractedField(
      'registration.trade_name_en'.tr(),
      r['tradeNameEn'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.trade_name_ar'.tr(),
      r['tradeNameAr'] ?? '',
      fullWidth: true,
      rtl: true,
    ),
    ExtractedField(
      'registration.licence_no'.tr(),
      r['licenceNo'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.licence_type'.tr(),
      r['licenceType'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.establishment_date'.tr(),
      r['establishmentDate'] ?? '',
    ),
    ExtractedField(
      'registration.issuance_date'.tr(),
      r['issuanceDate'] ?? '',
      highlight: true,
    ),
    ExtractedField('registration.legal_form'.tr(), r['legalForm'] ?? ''),
    ExtractedField(
      'registration.unified_reg_no'.tr(),
      r['unifiedRegNo'] ?? '',
      fullWidth: true,
    ),
    ExtractedField(
      'registration.unified_licence_no'.tr(),
      r['unifiedLicenceNo'] ?? '',
      fullWidth: true,
    ),
  ];
}
