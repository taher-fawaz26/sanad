import 'package:asset_picker/asset_picker.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DocumentFlowRepository {}

class _MockDocumentTypeValidator extends Mock
    implements DocumentTypeValidator {}

void main() {
  late _MockRepository repository;
  late _MockDocumentTypeValidator validator;

  const config = DocumentFlowConfig(
    requiredDocuments: [DocumentType.emiratesIdFront],
  );

  const asset = PickedAsset(
    name: 'front.jpg',
    path: '/tmp/front.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    assetType: AssetType.image,
  );

  const media = DocumentMedia(
    id: 'media-1',
    url: 'https://example.com/media-1',
    fileName: 'front.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    type: DocumentType.emiratesIdFront,
  );

  DocumentFlowBloc buildBloc() => DocumentFlowBloc(
    config: config,
    uploadMedia: UploadMediaUseCase(repository),
    extractDocuments: ExtractDocumentsUseCase(repository),
    submitDocuments: SubmitDocumentsUseCase(repository),
    fetchDocuments: FetchDocumentsUseCase(repository),
  );

  DocumentFlowBloc buildBlocWithValidator() => DocumentFlowBloc(
    config: config,
    uploadMedia: UploadMediaUseCase(repository),
    extractDocuments: ExtractDocumentsUseCase(repository),
    submitDocuments: SubmitDocumentsUseCase(repository),
    fetchDocuments: FetchDocumentsUseCase(repository),
    validator: validator,
  );

  // A trade-licence-only renewal scope (`DocumentScope.tradeLicense` in
  // organization settings) — requires the trade licence and NOT the
  // Emirates ID, unlike every onboarding config.
  const tradeLicenseOnlyConfig = DocumentFlowConfig(
    requiredDocuments: [DocumentType.tradeLicense],
  );

  const tradeLicenseAsset = PickedAsset(
    name: 'licence.jpg',
    path: '/tmp/licence.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    assetType: AssetType.image,
  );

  const tradeLicenseMedia = DocumentMedia(
    id: 'media-tl-1',
    url: 'https://example.com/media-tl-1',
    fileName: 'licence.jpg',
    mimeType: 'image/jpeg',
    size: 1024,
    type: DocumentType.tradeLicense,
  );

  DocumentFlowBloc buildTradeLicenseOnlyBloc() => DocumentFlowBloc(
    config: tradeLicenseOnlyConfig,
    uploadMedia: UploadMediaUseCase(repository),
    extractDocuments: ExtractDocumentsUseCase(repository),
    submitDocuments: SubmitDocumentsUseCase(repository),
    fetchDocuments: FetchDocumentsUseCase(repository),
  );

  setUpAll(() {
    registerFallbackValue(
      const UploadMediaParams(
        type: DocumentType.emiratesIdFront,
        filePath: '',
        fileName: '',
        mimeType: '',
        uploadKey: '',
        context: DocumentFlowContext(),
      ),
    );
    registerFallbackValue(
      const ExtractParams(uploadedIds: {}, context: DocumentFlowContext()),
    );
    registerFallbackValue(
      const SubmitParams(uploadedIds: {}, context: DocumentFlowContext()),
    );
  });

  setUp(() {
    repository = _MockRepository();
    validator = _MockDocumentTypeValidator();
  });

  group('DocumentFlowBloc', () {
    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'DocumentPicked stores the asset without uploading',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const DocumentPicked(type: DocumentType.emiratesIdFront, asset: asset),
      ),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront);
        expect(doc, isNotNull);
        expect(doc!.isUploaded, isFalse);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'upload success marks the document uploaded with its remote id',
      build: buildBloc,
      setUp: () {
        when(() => repository.uploadMedia(any())).thenAnswer(
          (_) => TaskEither.right(media),
        );
      },
      act: (bloc) => bloc
        ..add(
          const DocumentPicked(
            type: DocumentType.emiratesIdFront,
            asset: asset,
          ),
        )
        ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront)!;
        expect(doc.isUploaded, isTrue);
        expect(doc.remoteId, media.id);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'upload failure marks the document failed and sets an UploadFailure',
      build: buildBloc,
      setUp: () {
        when(() => repository.uploadMedia(any())).thenAnswer(
          (_) => TaskEither.left(
            const ServerFailure(message: 'errors.server'),
          ),
        );
      },
      act: (bloc) => bloc
        ..add(
          const DocumentPicked(
            type: DocumentType.emiratesIdFront,
            asset: asset,
          ),
        )
        ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront)!;
        expect(doc.status.isFailed, isTrue);
        expect(bloc.state.failure, isA<UploadFailure>());
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'ExtractionRequested without uploaded documents fails validation',
      build: buildBloc,
      act: (bloc) => bloc.add(const ExtractionRequested()),
      expect: () => [
        isA<DocumentFlowState>().having(
          (s) => s.phase,
          'phase',
          isA<PhaseFailure>().having(
            (p) => p.stage,
            'stage',
            FailedStage.extraction,
          ),
        ),
      ],
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'extraction domain rejection (e.g. EXTRACTION_INCOMPLETE) preserves '
      'the backend code/fields/requestId and classifies as domain, not '
      'network',
      build: buildBloc,
      setUp: () {
        when(() => repository.uploadMedia(any())).thenAnswer(
          (_) => TaskEither.right(media),
        );
        when(() => repository.extract(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'لم نتمكن من قراءة الحقول المطلوبة: license_number.',
              code: '400',
              metadata: {
                'code': 'EXTRACTION_INCOMPLETE',
                'fields': ['license_number'],
                'requestId': 'req-123',
              },
            ),
          ),
        );
      },
      act: (bloc) async {
        bloc
          ..add(
            const DocumentPicked(
              type: DocumentType.emiratesIdFront,
              asset: asset,
            ),
          )
          ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ExtractionRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final failure = bloc.state.failure;
        expect(failure, isA<ExtractionFailure>());
        final extractionFailure = failure! as ExtractionFailure;
        expect(extractionFailure.kind, ExtractionFailureKind.domain);
        expect(extractionFailure.code, 'EXTRACTION_INCOMPLETE');
        expect(extractionFailure.fields, ['license_number']);
        expect(extractionFailure.requestId, 'req-123');
        expect(
          extractionFailure.messageKey,
          'لم نتمكن من قراءة الحقول المطلوبة: license_number.',
        );

        // Media already uploaded before the extraction call must survive a
        // domain rejection so retry doesn't force a re-upload.
        expect(
          bloc.state.uploadedIds[DocumentType.emiratesIdFront],
          media.id,
        );
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'extraction transport failure (no internet) classifies as network',
      build: buildBloc,
      setUp: () {
        when(() => repository.uploadMedia(any())).thenAnswer(
          (_) => TaskEither.right(media),
        );
        when(() => repository.extract(any())).thenAnswer(
          (_) => TaskEither.left(
            const NoInternetFailure(message: 'errors.no_internet'),
          ),
        );
      },
      act: (bloc) async {
        bloc
          ..add(
            const DocumentPicked(
              type: DocumentType.emiratesIdFront,
              asset: asset,
            ),
          )
          ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ExtractionRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final failure = bloc.state.failure! as ExtractionFailure;
        expect(failure.kind, ExtractionFailureKind.network);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'full pipeline: upload → extract → submit reaches PhaseSuccess',
      build: buildBloc,
      setUp: () {
        when(() => repository.uploadMedia(any())).thenAnswer(
          (_) => TaskEither.right(media),
        );
        when(() => repository.extract(any())).thenAnswer(
          (_) => TaskEither.right(
            const ExtractedDocuments(
              sections: [
                ExtractedDocument(
                  type: DocumentType.emiratesIdFront,
                  fields: [],
                ),
              ],
            ),
          ),
        );
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.right(unit),
        );
      },
      act: (bloc) async {
        bloc
          ..add(
            const DocumentPicked(
              type: DocumentType.emiratesIdFront,
              asset: asset,
            ),
          )
          ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ExtractionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseSuccess>());
      },
    );
  });

  group('DocumentFlowBloc — submit-failure routing', () {
    Future<void> uploadThenExtract(
      DocumentFlowBloc bloc, {
      required ExtractedDocuments extracted,
    }) async {
      when(
        () => repository.uploadMedia(any()),
      ).thenAnswer((_) => TaskEither.right(media));
      when(
        () => repository.extract(any()),
      ).thenAnswer((_) => TaskEither.right(extracted));
      bloc
        ..add(
          const DocumentPicked(
            type: DocumentType.emiratesIdFront,
            asset: asset,
          ),
        )
        ..add(const DocumentUploadRequested(DocumentType.emiratesIdFront));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const ExtractionRequested());
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    const cleanExtracted = ExtractedDocuments(
      sections: [
        ExtractedDocument(type: DocumentType.emiratesIdFront, fields: []),
      ],
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'EXTRACTION_INCOMPLETE at submit surfaces a SubmitFailure carrying '
      'the backend code/fields — the feature decides how to flag it inline, '
      'not the shared bloc',
      build: buildBloc,
      setUp: () async {
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'Required identifier could not be read.',
              code: '400',
              metadata: {
                'code': 'EXTRACTION_INCOMPLETE',
                'fields': ['id_number'],
              },
            ),
          ),
        );
      },
      act: (bloc) async {
        await uploadThenExtract(bloc, extracted: cleanExtracted);
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(
          bloc.state.phase,
          isA<PhaseFailure>().having(
            (p) => p.stage,
            'stage',
            FailedStage.submit,
          ),
        );
        final failure = bloc.state.failure! as SubmitFailure;
        expect(failure.code, 'EXTRACTION_INCOMPLETE');
        expect(failure.fields, ['id_number']);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'EXTRACTION_REQUIRED at submit transparently re-runs extraction '
      'instead of failing — the reviewed media drifted, so a fresh preview '
      'is the correct recovery',
      build: buildBloc,
      setUp: () async {
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.left(
            const BusinessRuleFailure(
              message: 'Extract the document first.',
              code: '400',
              metadata: {'code': 'EXTRACTION_REQUIRED'},
            ),
          ),
        );
      },
      act: (bloc) async {
        await uploadThenExtract(bloc, extracted: cleanExtracted);
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseExtracted>());
        expect(bloc.state.failure, isNull);
        expect(bloc.state.extracted, cleanExtracted);
        // Extraction ran twice: once for the initial preview, once as the
        // silent recovery from EXTRACTION_REQUIRED.
        verify(() => repository.extract(any())).called(2);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'EXTRACTION_STALE at submit (409) also re-runs extraction, not '
      'EXTRACTION_REQUIRED-only',
      build: buildBloc,
      setUp: () async {
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.left(
            const ConflictFailure(
              message: 'The document changed since it was extracted.',
              code: '409',
              metadata: {'code': 'EXTRACTION_STALE'},
            ),
          ),
        );
      },
      act: (bloc) async {
        await uploadThenExtract(bloc, extracted: cleanExtracted);
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseExtracted>());
        expect(bloc.state.failure, isNull);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'a 409 that is NOT EXTRACTION_STALE (identifier already registered) '
      'flags the Emirates ID section as alreadyRegistered, mirroring the '
      'extraction-time ConflictFailure treatment',
      build: buildBloc,
      setUp: () async {
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.left(
            const ConflictFailure(
              message: 'This Emirates ID is already registered.',
              code: '409',
            ),
          ),
        );
      },
      act: (bloc) async {
        await uploadThenExtract(bloc, extracted: cleanExtracted);
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseExtracted>());
        expect(bloc.state.failure, isNull);
        final section = bloc.state.extracted!.sectionOf(
          DocumentType.emiratesIdFront,
        )!;
        expect(section.issue, DocumentIssue.alreadyRegistered);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'a 409 during a trade-licence-only renewal scope (no Emirates ID in '
      'this config) flags the trade licence section, not the Emirates ID — '
      'the section a `DocumentScope.tradeLicense` screen actually renders',
      build: buildTradeLicenseOnlyBloc,
      setUp: () {
        when(
          () => repository.uploadMedia(any()),
        ).thenAnswer((_) => TaskEither.right(tradeLicenseMedia));
        when(() => repository.extract(any())).thenAnswer(
          (_) => TaskEither.right(
            const ExtractedDocuments(
              sections: [
                ExtractedDocument(type: DocumentType.tradeLicense, fields: []),
              ],
            ),
          ),
        );
        when(() => repository.submit(any())).thenAnswer(
          (_) => TaskEither.left(
            const ConflictFailure(
              message: 'This licence number is already registered.',
              code: '409',
            ),
          ),
        );
      },
      act: (bloc) async {
        bloc
          ..add(
            const DocumentPicked(
              type: DocumentType.tradeLicense,
              asset: tradeLicenseAsset,
            ),
          )
          ..add(const DocumentUploadRequested(DocumentType.tradeLicense));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ExtractionRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SubmitRequested());
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseExtracted>());
        final section = bloc.state.extracted!.sectionOf(
          DocumentType.tradeLicense,
        )!;
        expect(section.issue, DocumentIssue.alreadyRegistered);
        expect(
          bloc.state.extracted!.sectionOf(DocumentType.emiratesIdFront),
          isNull,
        );
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'ReviewFlagged overwrites extracted, returns to PhaseExtracted, and '
      'clears the failure — the generic primitive a feature uses to apply '
      'its own document-domain-code attribution',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const ReviewFlagged(
          ExtractedDocuments(
            sections: [
              ExtractedDocument(
                type: DocumentType.emiratesIdFront,
                fields: [],
                issue: DocumentIssue.idMismatch,
              ),
            ],
          ),
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.phase, isA<PhaseExtracted>());
        expect(bloc.state.failure, isNull);
        expect(
          bloc.state.extracted!.sectionOf(DocumentType.emiratesIdFront)!.issue,
          DocumentIssue.idMismatch,
        );
      },
    );
  });

  group('DocumentFlowBloc — pre-upload document-type validation', () {
    const asset2 = PickedAsset(
      name: 'bad.jpg',
      path: '/tmp/bad.jpg',
      mimeType: 'image/jpeg',
      size: 1024,
      assetType: AssetType.image,
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'a passing check auto-triggers the upload — no separate '
      'DocumentUploadRequested is needed',
      build: buildBlocWithValidator,
      setUp: () {
        when(
          () => validator.validate(asset, type: DocumentType.emiratesIdFront),
        ).thenAnswer((_) async => const DocumentValidationResult.valid());
        when(
          () => repository.uploadMedia(any()),
        ).thenAnswer((_) => TaskEither.right(media));
      },
      act: (bloc) => bloc.add(
        const DocumentPicked(
          type: DocumentType.emiratesIdFront,
          asset: asset,
        ),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront)!;
        expect(doc.isUploaded, isTrue);
        expect(doc.remoteId, media.id);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'a failing check never overwrites an already-uploaded document and '
      'surfaces a DocumentValidationFailure instead of uploading',
      build: buildBlocWithValidator,
      setUp: () {
        when(
          () => validator.validate(asset, type: DocumentType.emiratesIdFront),
        ).thenAnswer((_) async => const DocumentValidationResult.valid());
        when(
          () => validator.validate(asset2, type: DocumentType.emiratesIdFront),
        ).thenAnswer((_) async => const DocumentValidationResult.invalid());
        when(
          () => repository.uploadMedia(any()),
        ).thenAnswer((_) => TaskEither.right(media));
      },
      act: (bloc) async {
        bloc.add(
          const DocumentPicked(
            type: DocumentType.emiratesIdFront,
            asset: asset,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const DocumentPicked(
            type: DocumentType.emiratesIdFront,
            asset: asset2,
          ),
        );
      },
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront)!;
        // Reverted to the previously uploaded document — never replaced by
        // the rejected re-pick.
        expect(doc.isUploaded, isTrue);
        expect(doc.remoteId, media.id);
        expect(doc.asset, asset);

        final failure = bloc.state.failure! as DocumentValidationFailure;
        expect(failure.kind, DocumentValidationFailureKind.invalidType);
        expect(
          failure.messageKey,
          'errors.document_validation.invalid_emirates_id',
        );
        // Only the first (valid) pick ever reached the upload use case.
        verify(() => repository.uploadMedia(any())).called(1);
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'a validator exception is a VALIDATION_ENGINE_ERROR, not a confident '
      'rejection, and never uploads',
      build: buildBlocWithValidator,
      setUp: () {
        when(
          () => validator.validate(asset, type: DocumentType.emiratesIdFront),
        ).thenThrow(Exception('scanner crashed'));
      },
      act: (bloc) => bloc.add(
        const DocumentPicked(
          type: DocumentType.emiratesIdFront,
          asset: asset,
        ),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.documentAt(DocumentType.emiratesIdFront), isNull);
        final failure = bloc.state.failure! as DocumentValidationFailure;
        expect(failure.kind, DocumentValidationFailureKind.engineError);
        expect(failure.messageKey, 'errors.document_validation.engine_error');
        verifyNever(() => repository.uploadMedia(any()));
      },
    );

    blocTest<DocumentFlowBloc, DocumentFlowState>(
      'without a validator (legacy contract): DocumentPicked only stores '
      'the asset — the caller must dispatch DocumentUploadRequested itself',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const DocumentPicked(
          type: DocumentType.emiratesIdFront,
          asset: asset,
        ),
      ),
      verify: (bloc) {
        final doc = bloc.state.documentAt(DocumentType.emiratesIdFront);
        expect(doc, isNotNull);
        expect(doc!.isUploaded, isFalse);
        expect(doc.isUploading, isFalse);
        verifyNever(() => repository.uploadMedia(any()));
      },
    );
  });
}
