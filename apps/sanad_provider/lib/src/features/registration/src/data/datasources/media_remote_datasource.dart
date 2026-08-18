import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:document_flow/document_flow.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/registration/src/data/endpoints/media_api_paths.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/extraction_response.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/media_upload_response.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_request.dart';
import 'package:sanad_provider/src/features/registration/src/data/models/profile_completion_response.dart';

/// Remote data source for media uploads and document extraction.
abstract interface class MediaRemoteDataSource {
  TaskEither<Failure, MediaUploadResponse> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  });

  void cancelUpload(String uploadKey);

  /// Calls `POST auth/extract` with the three uploaded media IDs and returns
  /// the structured [ExtractedDocuments].
  TaskEither<Failure, ExtractedDocuments> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  });

  /// Completes provider profile by posting to `MediaApiPaths.profile`
  /// (`POST auth/profile`).
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required ProfileCompletionRequest request,
  });
}

class MediaRemoteDataSourceImpl implements MediaRemoteDataSource {
  MediaRemoteDataSourceImpl(this._client);

  final SecureDioClient _client;

  /// Active cancel tokens keyed by upload slot.
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  TaskEither<Failure, MediaUploadResponse> uploadSingle({
    required String filePath,
    required String fileName,
    required String mimeType,
    required String authorizationToken,
    required String uploadKey,
    void Function(double progress)? onProgress,
  }) => TaskEither.tryCatch(
    () async {
      _cancelTokens[uploadKey]?.cancel();
      final cancelToken = CancelToken();
      _cancelTokens[uploadKey] = cancelToken;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      try {
        final response = await _client.postMultipart<dynamic>(
          MediaApiPaths.onboarding,
          formData: formData,
          cancelToken: cancelToken,
          options: Options(
            headers: {'Authorization': 'Bearer $authorizationToken'},
          ),
          onSendProgress: (sent, total) {
            if (total <= 0 || onProgress == null) return;
            onProgress((sent / total).clamp(0.0, 1.0));
          },
        );

        final raw = response.data;
        final map = _parseResponse(raw);

        return MediaUploadResponse.fromJson(map);
      } finally {
        _cancelTokens.remove(uploadKey);
      }
    },
    (error, stackTrace) => ErrorMapper.mapError(error),
  );

  @override
  void cancelUpload(String uploadKey) {
    final token = _cancelTokens.remove(uploadKey);
    if (token != null && !token.isCancelled) {
      token.cancel();
    }
  }

  @override
  TaskEither<Failure, ExtractedDocuments> extractDocuments({
    required String authorizationToken,
    required String emiratesIdFrontId,
    required String emiratesIdBackId,
    String? tradeLicenseId,
  }) => TaskEither.tryCatch(
    () async {
      final body = <String, dynamic>{
        'emiratesIdFrontId': emiratesIdFrontId,
        'emiratesIdBackId': emiratesIdBackId,
        if (tradeLicenseId != null) 'tradeLicenseId': tradeLicenseId,
      };

      final Response<dynamic> response;
      try {
        response = await _client.post<dynamic>(
          MediaApiPaths.extract,
          data: body,
          options: Options(
            headers: {'Authorization': 'Bearer $authorizationToken'},
          ),
        );
      } on DioException catch (e) {
        // A document-domain rejection (HTTP 400 with a single business
        // message — EXTRACTION_INCOMPLETE, a front/back mismatch, an
        // unreadable/unsupported document, or any future backend code
        // meaning "the uploaded document is the problem") is a per-document
        // outcome, not a flow failure: surface it as flagged sections so the
        // review screen renders it inline (same UX as the image-unclear/
        // expired outcomes) instead of a full-screen error. Classification is
        // structural (400 + a string `message`, not a validation array) —
        // never gated on a specific `code` — so a new backend code is
        // handled automatically without a client change.
        final rejection = _documentDomainRejectionOrNull(
          e,
          includeTradeLicence: tradeLicenseId != null,
        );
        if (rejection != null) return rejection;
        rethrow;
      }

      final raw = response.data;
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return ExtractionResponse.fromJson(
        map,
        includeTradeLicence: tradeLicenseId != null,
      );
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  /// Returns flagged [ExtractedDocuments] when [e] is a **document-domain**
  /// rejection; null otherwise (so the caller rethrows and the failure is
  /// mapped normally as a genuine transport/server failure).
  ///
  /// Classification is structural, not code-based: HTTP 400 with a body
  /// whose `message` is a non-empty string is, for this endpoint, always a
  /// rejection of the *documents themselves* — `auth/extract` has no other
  /// business rule to reject with, and malformed-request validation (an
  /// array-shaped `message`, or a missing required id) is already rejected
  /// client-side before this call is made (see `extract()` in
  /// `RegistrationDocumentRepository`). This is why NO specific `code` value
  /// is checked here: whatever code the backend sends for a new document
  /// problem, this still fires.
  static ExtractedDocuments? _documentDomainRejectionOrNull(
    DioException e, {
    required bool includeTradeLicence,
  }) {
    if (e.response?.statusCode != 400) return null;
    final data = e.response?.data;
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    if (map == null) return null;
    final message = map['message'];
    if (message is! String || message.isEmpty) return null;

    final fields =
        (map['fields'] as List?)?.map((f) => f.toString()).toList() ??
        const <String>[];
    return ExtractionResponse.fromDomainRejection(
      fields: fields,
      code: map['code']?.toString(),
      message: message,
      includeTradeLicence: includeTradeLicence,
    );
  }

  @override
  TaskEither<Failure, AuthSessionEntity> completeProfile({
    required String authorizationToken,
    required ProfileCompletionRequest request,
  }) => TaskEither.tryCatch(
    () async {
      final response = await _client.post<dynamic>(
        MediaApiPaths.profile,
        data: request.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $authorizationToken'},
        ),
      );

      final raw = response.data;
      final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      return ProfileCompletionResponse.fromJson(map);
    },
    (error, _) => ErrorMapper.mapError(error),
  );

  /// Parses the onboarding upload response body.
  static Map<String, dynamic> _parseResponse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) return first;
    }
    return <String, dynamic>{};
  }
}
