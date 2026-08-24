import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_submit_rejection.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/legal_documents/document_scope.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/mappers/document_field_name_resolver.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:shared_ui/shared_ui.dart';

DocumentUploadCardLabels _labels() => DocumentUploadCardLabels(
  chooseUpload: 'settings.legal_documents.choose_upload'.tr(),
  chooseUploadHint: 'settings.legal_documents.choose_upload_hint'.tr(),
  uploading: 'settings.legal_documents.uploading'.tr(),
  uploadFailed: 'settings.legal_documents.upload_failed'.tr(),
  replaceDocument: 'settings.legal_documents.replace_document'.tr(),
  removeDocument: 'settings.legal_documents.remove_document'.tr(),
  upload: 'settings.legal_documents.upload'.tr(),
  retryUpload: 'common.retry'.tr(),
  checkingDocument: 'settings.legal_documents.checking_document'.tr(),
);

/// Emirates ID capture options — reuses the shared scanner config factory
/// from the registration flow so scanner titles/labels stay consistent.
AssetPickerOptions get _kEmiratesIdCaptureOptions => const AssetPickerOptions(
  allowCamera: false,
  allowGallery: false,
  allowFiles: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  loadBytes: true,
  maxFileSize: FileSizePolicy.maxBytes,
).copyWith(scannerConfig: emiratesIdScannerConfig());

/// Trade Licence capture options — reuses the shared scanner config factory.
AssetPickerOptions get _kTradeLicenseCaptureOptions => const AssetPickerOptions(
  allowCamera: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  loadBytes: true,
  maxFileSize: FileSizePolicy.maxBytes,
).copyWith(scannerConfig: tradeLicenseScannerConfig());

/// Update flow for a single organization legal document (Emirates ID, or
/// Trade Licence) — never both at once.
///
/// Prefills from whatever is already on file (`DocumentFlowConfig
/// .enablePrefetch`), lets the user replace the document(s) in [scope],
/// re-runs OCR verification, then confirms via the scope's own
/// `PUT service-provider/legal-data/{emirates-id,trade-license}` endpoint.
/// Pops with `true` on a successful save so the caller can refresh
/// `OrganizationSettingsBloc`.
class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({required this.scope, super.key});

  final DocumentScope scope;

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  late final DocumentFlowController _controller;

  /// Confirm-time codes meaning the *document itself* is the problem —
  /// routed back to review with the section flagged inline instead of a
  /// generic error snackbar (mirrors registration's equivalent submit-time
  /// treatment).
  static const _inlineFlagCodes = {
    'EXTRACTION_INCOMPLETE',
    'EXTRACTION_EXPIRED',
    'EXTRACTION_ID_MISMATCH',
  };

  DocumentType get _documentType => widget.scope == DocumentScope.tradeLicense
      ? DocumentType.tradeLicense
      : DocumentType.emiratesIdFront;

  @override
  void initState() {
    super.initState();
    _controller = DocumentFlowController(context.read<DocumentFlowBloc>());
    _controller.start();
  }

  void _onPhaseFailure(BuildContext context, DocumentFlowState state) {
    final failure = state.failure;
    if (failure is SubmitFailure && _inlineFlagCodes.contains(failure.code)) {
      final type = _documentType;
      context.read<DocumentFlowBloc>().add(
        ReviewFlagged(
          LegalDataSubmitRejection.flag(
            type: type,
            previous: state.extracted?.sectionOf(type),
            fields: failure.fields,
            message: failure.messageKey,
            code: failure.code,
          ),
        ),
      );
      return;
    }
    if (failure != null) {
      showAppErrorSnackbar(context: context, title: failure.messageKey.tr());
    }
  }

  Future<void> _pick(DocumentType type) async {
    try {
      await _controller.pick(
        context,
        type: type,
        options: type == DocumentType.tradeLicense
            ? _kTradeLicenseCaptureOptions
            : _kEmiratesIdCaptureOptions,
        theme: AssetPickerTheme.of(context),
      );
    } on AssetValidationException catch (e) {
      if (!mounted) return;
      final isTooLarge = e.errors.any(
        (error) => error.type == AssetValidationErrorType.fileTooLarge,
      );
      showAppErrorSnackbar(
        context: context,
        title: isTooLarge
            ? 'errors.media_upload.file_too_large'.tr()
            : 'errors.media_upload.unsupported_type'.tr(),
      );
    } on AssetPickerException {
      if (!mounted) return;
      showAppErrorSnackbar(
        context: context,
        title: 'registration.capture_failed'.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentFlowBloc, DocumentFlowState>(
      // A `DocumentValidationFailure` never changes `phase` (the document-level
      // check runs and reverts within `DocumentPicked` handling), so it is
      // watched separately from the phase-driven upload/extraction/submit
      // failures below.
      listenWhen: (prev, curr) =>
          prev.phase != curr.phase ||
          (prev.failure != curr.failure &&
              curr.failure is DocumentValidationFailure),
      listener: (context, state) {
        if (state.phase is PhaseSuccess) {
          context.pop(true);
          return;
        }
        final failure = state.failure;
        if (failure is DocumentValidationFailure) {
          showAppErrorSnackbar(
            context: context,
            title: failure.messageKey.tr(),
          );
          return;
        }
        if (state.phase is PhaseFailure) {
          _onPhaseFailure(context, state);
        }
      },
      builder: (context, state) {
        final extracted = state.extracted;
        final isBusy =
            state.phase is PhaseExtracting || state.phase is PhaseSubmitting;

        return AppScrollPage(
          backgroundColor: context.appColors.surface,
          slivers: [
            AppSliverAppBar(
              navBar: AppNavBar(
                title: widget.scope.titleKey.tr(),
                showBackButton: true,
                onLeadingTap: () => context.pop(),
              ),
            ),
            AppSliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  if (widget.scope == DocumentScope.emiratesId) ...[
                    AppSliverBox(
                      child: DocumentUploadCard(
                        title: 'settings.legal_documents.id_front'.tr(),
                        labels: _labels(),
                        uploadable: state.documentAt(
                          DocumentType.emiratesIdFront,
                        ),
                        onUpload: () => _pick(DocumentType.emiratesIdFront),
                        onReplace: () => _pick(DocumentType.emiratesIdFront),
                        onCancel: () => context.read<DocumentFlowBloc>().add(
                          const DocumentUploadCancelled(
                            DocumentType.emiratesIdFront,
                          ),
                        ),
                        onRemove: () => context.read<DocumentFlowBloc>().add(
                          const DocumentRemoved(DocumentType.emiratesIdFront),
                        ),
                      ),
                    ),
                    AppSliverGap(AppSpacing.lg),
                    AppSliverBox(
                      child: DocumentUploadCard(
                        title: 'settings.legal_documents.id_back'.tr(),
                        labels: _labels(),
                        uploadable: state.documentAt(
                          DocumentType.emiratesIdBack,
                        ),
                        onUpload: () => _pick(DocumentType.emiratesIdBack),
                        onReplace: () => _pick(DocumentType.emiratesIdBack),
                        onCancel: () => context.read<DocumentFlowBloc>().add(
                          const DocumentUploadCancelled(
                            DocumentType.emiratesIdBack,
                          ),
                        ),
                        onRemove: () => context.read<DocumentFlowBloc>().add(
                          const DocumentRemoved(DocumentType.emiratesIdBack),
                        ),
                      ),
                    ),
                  ] else ...[
                    AppSliverBox(
                      child: DocumentUploadCard(
                        title: 'settings.legal_documents.trade_license'.tr(),
                        labels: _labels(),
                        uploadable: state.documentAt(DocumentType.tradeLicense),
                        onUpload: () => _pick(DocumentType.tradeLicense),
                        onReplace: () => _pick(DocumentType.tradeLicense),
                        onCancel: () => context.read<DocumentFlowBloc>().add(
                          const DocumentUploadCancelled(
                            DocumentType.tradeLicense,
                          ),
                        ),
                        onRemove: () => context.read<DocumentFlowBloc>().add(
                          const DocumentRemoved(DocumentType.tradeLicense),
                        ),
                      ),
                    ),
                  ],
                  if (extracted != null) ...[
                    for (final section in extracted.sections.where(
                      (section) => widget.scope == DocumentScope.tradeLicense
                          ? section.type == DocumentType.tradeLicense
                          : section.type != DocumentType.tradeLicense,
                    )) ...[
                      AppSliverGap(AppSpacing.lg),
                      AppSliverBox(
                        child: ExtractedFieldsView(
                          title: widget.scope.titleKey.tr(),
                          issue: section.issue,
                          fields: section.fields,
                          replaceLabel:
                              'settings.legal_documents.replace_document'.tr(),
                          resolveIssueLabels: (issue) => _resolveIssueLabels(
                            issue,
                            detail: section.issueDetail,
                            missingFields: section.missingFields,
                            status: section.status,
                          ),
                          onReplace: () {},
                        ),
                      ),
                    ],
                  ],
                  AppSliverGap(AppSpacing.xxl),
                  AppSliverBox(
                    child: AppButton(
                      label: 'common.save'.tr(),
                      onPressed: (isBusy || !state.isComplete)
                          ? null
                          : () => extracted == null
                                ? _controller.extract()
                                : _controller.submit(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// [detail] is the affected section's [ExtractedDocument.issueDetail] — a
  /// dynamic, already-localized backend message (e.g. from a confirm-time
  /// `EXTRACTION_INCOMPLETE` rejection). [missingFields] are the raw backend
  /// field identifiers that message concerns — never rendered as-is; always
  /// resolved through [describeMissingFields] first, mirroring registration's
  /// review screen so raw backend identifiers never reach the UI here either.
  ///
  /// [status] is checked only for [DocumentIssue.none]:
  /// [DocumentStatus.expiringSoon] is a non-blocking warning (the document is
  /// still submittable), so it renders as a warning badge instead of the
  /// success badge.
  DocumentIssueLabels _resolveIssueLabels(
    DocumentIssue issue, {
    String? detail,
    List<String> missingFields = const [],
    DocumentStatus? status,
  }) => switch (issue) {
    DocumentIssue.none when status == DocumentStatus.expiringSoon =>
      DocumentIssueLabels(
        badgeLabel:
            'settings.legal_documents.compliance_card.status_expiring_soon'
                .tr(),
        badgeType: AppStatusBadgeType.warning,
      ),
    DocumentIssue.none => DocumentIssueLabels(
      badgeLabel: 'settings.legal_documents.verified'.tr(),
      badgeType: AppStatusBadgeType.success,
    ),
    DocumentIssue.expired => DocumentIssueLabels(
      badgeLabel: 'settings.legal_documents.expired'.tr(),
      badgeType: AppStatusBadgeType.alert,
      bannerTitle: 'settings.legal_documents.expired'.tr(),
      bannerMessage: 'settings.legal_documents.expired_message'.tr(),
    ),
    DocumentIssue.imageUnclear => DocumentIssueLabels(
      badgeLabel: 'settings.legal_documents.image_unclear'.tr(),
      badgeType: AppStatusBadgeType.warning,
      bannerTitle: 'settings.legal_documents.image_unclear'.tr(),
      bannerMessage: missingFields.isNotEmpty
          ? 'registration.missing_fields_message'.tr(
              namedArgs: {'fields': describeMissingFields(missingFields)},
            )
          : (detail != null && detail.isNotEmpty)
          ? detail
          : 'registration.image_unclear_message'.tr(),
    ),
    DocumentIssue.alreadyRegistered => DocumentIssueLabels(
      badgeLabel: 'settings.legal_documents.already_registered'.tr(),
      badgeType: AppStatusBadgeType.alert,
      bannerTitle: 'settings.legal_documents.already_registered'.tr(),
      bannerMessage: 'settings.legal_documents.already_registered_message'.tr(),
    ),
    DocumentIssue.idMismatch => DocumentIssueLabels(
      badgeLabel: 'registration.id_mismatch'.tr(),
      badgeType: AppStatusBadgeType.alert,
      bannerTitle: 'registration.id_mismatch'.tr(),
      bannerMessage: 'registration.id_mismatch_message'.tr(),
    ),
  };
}
