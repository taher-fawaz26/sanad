import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
);

const _kCaptureOptions = AssetPickerOptions(
  allowCamera: false,
  allowScanner: true,
  allowedAssetTypes: [AssetType.image, AssetType.pdf],
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  loadBytes: true,
  maxFileSize: 10 * 1024 * 1024,
);

/// Update flow for the organization's Emirates ID + trade licence documents.
///
/// Prefills from whatever is already on file (`DocumentFlowConfig
/// .enablePrefetch`), lets the user replace any document, re-runs OCR
/// verification, then saves via `PUT service-provider/legal-data/documents`.
/// Pops with `true` on a successful save so the caller can refresh
/// `OrganizationSettingsBloc`.
class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({super.key});

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  late final DocumentFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DocumentFlowController(context.read<DocumentFlowBloc>());
    _controller.start();
  }

  Future<void> _pick(DocumentType type) => _controller.pick(
    context,
    type: type,
    options: _kCaptureOptions,
    theme: AssetPickerTheme.of(context),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (prev, curr) => prev.phase != curr.phase,
      listener: (context, state) {
        if (state.phase is PhaseSuccess) {
          context.pop(true);
          return;
        }
        final failure = state.failure;
        if (failure != null && state.phase is PhaseFailure) {
          showAppErrorSnackbar(
            context: context,
            title: failure.messageKey.tr(),
          );
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
                title: 'settings.legal_documents.title'.tr(),
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
                      uploadable: state.documentAt(DocumentType.emiratesIdBack),
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
                  AppSliverGap(AppSpacing.lg),
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
                  if (extracted != null) ...[
                    for (final section in extracted.sections) ...[
                      AppSliverGap(AppSpacing.lg),
                      AppSliverBox(
                        child: ExtractedFieldsView(
                          title: section.type == DocumentType.tradeLicense
                              ? 'settings.legal_documents.trade_license'.tr()
                              : 'settings.legal_documents.emirates_id'.tr(),
                          issue: section.issue,
                          fields: section.fields,
                          replaceLabel:
                              'settings.legal_documents.replace_document'.tr(),
                          resolveIssueLabels: _resolveIssueLabels,
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

  DocumentIssueLabels _resolveIssueLabels(DocumentIssue issue) =>
      switch (issue) {
        DocumentIssue.none => DocumentIssueLabels(
          badgeLabel: 'settings.legal_documents.verified'.tr(),
          badgeType: AppStatusBadgeType.success,
        ),
        DocumentIssue.expired => DocumentIssueLabels(
          badgeLabel: 'settings.legal_documents.expired'.tr(),
          badgeType: AppStatusBadgeType.alert,
        ),
        DocumentIssue.imageUnclear => DocumentIssueLabels(
          badgeLabel: 'settings.legal_documents.image_unclear'.tr(),
          badgeType: AppStatusBadgeType.warning,
        ),
        DocumentIssue.alreadyRegistered => DocumentIssueLabels(
          badgeLabel: 'settings.legal_documents.already_registered'.tr(),
          badgeType: AppStatusBadgeType.alert,
        ),
      };
}
