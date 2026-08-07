import 'package:core/core.dart';
import 'package:document_flow/src/domain/entities/document_media.dart';
import 'package:document_flow/src/domain/entities/extracted_document.dart';
import 'package:document_flow/src/domain/usecases/document_flow_params.dart';
import 'package:fpdart/fpdart.dart';

/// Contract every feature implements to back the shared document-flow
/// pipeline with its own endpoints, request/response mapping, and side
/// effects.
///
/// `document_flow` never implements this itself and never knows about HTTP
/// paths — each feature (registration, organization settings, ...) owns its
/// datasource and wraps it behind this interface.
abstract interface class DocumentFlowRepository {
  /// Uploads a single file and returns the backend-assigned [DocumentMedia].
  TaskEither<Failure, DocumentMedia> uploadMedia(UploadMediaParams params);

  /// Cancels the in-flight upload registered under `uploadKey`, if any.
  void cancelUpload(String uploadKey);

  /// Runs OCR/verification against the previously uploaded documents.
  TaskEither<Failure, ExtractedDocuments> extract(ExtractParams params);

  /// Submits the final documents. Any feature-specific side effect (e.g.
  /// persisting a session, refreshing another bloc) happens inside the
  /// implementation — this stays a plain `Unit` so the package never needs
  /// to know what "success" means for a given feature.
  TaskEither<Failure, Unit> submit(SubmitParams params);

  /// Fetches previously submitted documents to prefill the flow. Features
  /// that have no prefill (e.g. onboarding) can return an empty
  /// [ExtractedDocuments] and set `DocumentFlowConfig.enablePrefetch: false`.
  TaskEither<Failure, ExtractedDocuments> fetch(FetchParams params);
}
