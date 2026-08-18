import 'package:asset_picker/asset_picker.dart';
import 'package:design_system/design_system.dart';
import 'package:document_flow/document_flow.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_logo.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/registration_sliver_shell.dart';
import 'package:sanad_provider/src/features/registration/src/presentation/widgets/select_capture_method_sheet.dart';
import 'package:sanad_provider/src/features/registration/src/routes/registration_navigation.dart';

/// Repairs a [DocumentRepairTarget] whose [DocumentRepairScope] is
/// [DocumentRepairScope.wholeDocument] — every part must be replaced
/// together before re-extraction (e.g. an Emirates ID front/back mismatch,
/// where replacing only one side can still leave two sides that don't
/// belong to the same physical card).
///
/// Reuses the exact two-slot pattern from `IdentityVerificationPage`
/// ([DocumentUploadCard] per part, the same capture options/theme) rather
/// than inventing new visual treatment. "Satisfied" is derived from the
/// existing per-slot bloc state — a part counts as replaced once its
/// `remoteId` differs from the snapshot taken when this page opened — so no
/// second state machine is introduced.
class DocumentRepairPage extends StatefulWidget {
  const DocumentRepairPage({required this.target, super.key});

  final DocumentRepairTarget target;

  @override
  State<DocumentRepairPage> createState() => _DocumentRepairPageState();
}

class _DocumentRepairPageState extends State<DocumentRepairPage> {
  bool _isPicking = false;
  bool _isReextracting = false;
  late final Map<DocumentType, String?> _initialRemoteIds;

  @override
  void initState() {
    super.initState();
    final state = context.read<DocumentFlowBloc>().state;
    _initialRemoteIds = {
      for (final part in widget.target.parts)
        part: state.documentAt(part)?.remoteId,
    };
  }

  DocumentUploadCardLabels get _labels => DocumentUploadCardLabels(
    chooseUpload: 'registration.choose_upload'.tr(),
    chooseUploadHint: 'registration.choose_upload_hint'.tr(),
    uploading: 'registration.uploading'.tr(),
    uploadFailed: 'registration.upload_failed'.tr(),
    replaceDocument: 'registration.replace_document'.tr(),
    removeDocument: 'registration.remove_document'.tr(),
    upload: 'registration.upload'.tr(),
    retryUpload: 'common.retry'.tr(),
  );

  String _titleFor(DocumentType type) => switch (type) {
    DocumentType.emiratesIdFront => 'registration.id_front'.tr(),
    DocumentType.emiratesIdBack => 'registration.id_back'.tr(),
    _ => type.name,
  };

  bool _isSatisfied(DocumentFlowState state, DocumentType type) {
    final uploadable = state.documentAt(type);
    return (uploadable?.isUploaded ?? false) &&
        uploadable!.remoteId != _initialRemoteIds[type];
  }

  Future<void> _upload(DocumentType slot) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final controller = DocumentFlowController(
        context.read<DocumentFlowBloc>(),
      );
      await controller.pick(
        context,
        type: slot,
        options: kRegistrationEmiratesIdOptions,
        theme: registrationPickerTheme(context),
      );
    } on AssetPickerException {
      if (mounted) {
        showAppErrorSnackbar(
          context: context,
          title: 'registration.capture_failed'.tr(),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _clearSlot(DocumentType slot) =>
      context.read<DocumentFlowBloc>().add(DocumentRemoved(slot));

  Future<void> _reextract() async {
    if (_isReextracting) return;
    setState(() => _isReextracting = true);

    final bloc = context.read<DocumentFlowBloc>()
      ..add(const ExtractionRequested());
    final state = await bloc.stream.firstWhere(
      (s) => s.phase is! PhaseExtracting,
    );
    if (!mounted) return;

    if (state.phase is PhaseExtracted) {
      Navigator.of(context).pop();
      return;
    }
    // A genuine transport/server failure (never a document-domain rejection —
    // those always resolve to PhaseExtracted, flagged or not). Stay here so
    // the user doesn't lose the two-sided repair context; the failure
    // snackbar listener below surfaces the reason.
    setState(() => _isReextracting = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DocumentFlowBloc, DocumentFlowState>(
      listenWhen: (prev, curr) =>
          prev.failure != curr.failure &&
          (curr.failure is UploadFailure || curr.failure is ExtractionFailure),
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppErrorSnackbar(context: context, title: failure.messageKey.tr());
      },
      builder: (context, state) {
        final allSatisfied = widget.target.parts.every(
          (part) => _isSatisfied(state, part),
        );
        final title = 'registration.repair_emirates_id_title'.tr();

        return RegistrationSliverShell(
          onBack: () => RegistrationNavigation.popStep(context),
          headerBuilder: (context, t) => RegistrationLogo(
            collapseProgress: t,
            collapsedTitle: title,
            reserveLeadingSpace: true,
          ),
          footer: AppButton(
            label: 'registration.repair_reextract'.tr(),
            isLoading: _isReextracting,
            onPressed: allSatisfied && !_isReextracting ? _reextract : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.appTypography.title2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              SizedBox(height: responsiveDimension(AppSpacing.lg)),
              AppAlert(
                message: 'registration.repair_emirates_id_hint'.tr(),
                type: AppAlertType.info,
              ),
              SizedBox(height: responsiveDimension(AppSpacing.xxl)),
              for (final part in widget.target.parts) ...[
                DocumentUploadCard(
                  title: _titleFor(part),
                  labels: _labels,
                  uploadable: state.documentAt(part),
                  onUpload: () => _upload(part),
                  onCancel: () => context.read<DocumentFlowBloc>().add(
                    DocumentUploadCancelled(part),
                  ),
                  onReplace: () => _upload(part),
                  onRemove: () => _clearSlot(part),
                ),
                if (part != widget.target.parts.last)
                  SizedBox(height: responsiveDimension(AppSpacing.xl)),
              ],
            ],
          ),
        );
      },
    );
  }
}
