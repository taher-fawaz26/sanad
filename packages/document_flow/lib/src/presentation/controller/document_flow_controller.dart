import 'package:asset_picker/asset_picker.dart';
import 'package:document_flow/src/domain/entities/document_flow_context.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/presentation/bloc/document_flow_bloc.dart';
import 'package:document_flow/src/presentation/widgets/document_flow_capture.dart';
import 'package:flutter/widgets.dart';

/// Thin UI-facing facade over [DocumentFlowBloc] + `asset_picker`.
///
/// Pages call these methods instead of dispatching bloc events directly, so
/// the capture-sheet orchestration (which needs a [BuildContext]) lives in
/// one place rather than being copy-pasted per screen.
class DocumentFlowController {
  const DocumentFlowController(this._bloc);

  final DocumentFlowBloc _bloc;

  /// Opens the capture sheet for [type] and stores the result.
  ///
  /// What happens next is entirely owned by [DocumentFlowBloc]: when it was
  /// built with a `DocumentTypeValidator`, a passing pre-upload check
  /// auto-triggers the upload; a failing one surfaces a
  /// `DocumentValidationFailure` and uploads nothing. Without a validator
  /// (the legacy contract), the asset is only stored — call [upload]
  /// explicitly afterwards.
  Future<void> pick(
    BuildContext context, {
    required DocumentType type,
    required AssetPickerOptions options,
    required AssetPickerTheme theme,
  }) async {
    final result = await captureDocumentAsset(
      context,
      options: options,
      theme: theme,
    );
    if (result == null || result.assets.isEmpty) return;

    _bloc.add(DocumentPicked(type: type, asset: result.assets.first));
  }

  void upload(DocumentType type) =>
      _bloc.add(DocumentUploadRequested(type));

  void cancelUpload(DocumentType type) =>
      _bloc.add(DocumentUploadCancelled(type));

  void remove(DocumentType type) => _bloc.add(DocumentRemoved(type));

  void extract() => _bloc.add(const ExtractionRequested());

  void startEditing() => _bloc.add(const EditingStarted());

  void submit() => _bloc.add(const SubmitRequested());

  void reset() => _bloc.add(const FlowReset());

  void retry() => _bloc.add(const RetryRequested());

  void start({DocumentFlowContext context = const DocumentFlowContext()}) =>
      _bloc.add(DocumentFlowStarted(context: context));
}
