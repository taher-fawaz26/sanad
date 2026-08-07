import 'package:asset_picker/asset_picker.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements DocumentFlowRepository {}

void main() {
  late _MockRepository repository;

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
}
