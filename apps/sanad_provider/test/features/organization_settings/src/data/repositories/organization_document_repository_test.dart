import 'package:core/core.dart';
import 'package:document_flow/document_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/trade_license_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/repositories/organization_document_repository.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';

class _MockRemote extends Mock implements LegalDataRemoteDataSource {}

/// Real pass-through: mocktail can't reliably stub the generic `execute<T>`
/// across differing type arguments, so a Fake mirrors NetworkGuard's
/// connected → run-the-action behaviour (see
/// `organization_media_repository_impl_test.dart` for the same pattern).
class _FakeNetworkGuard extends Fake implements NetworkGuard {
  @override
  TaskEither<Failure, T> execute<T>({required TaskEither<Failure, T> action}) =>
      action;
}

void main() {
  late _MockRemote remote;
  late OrganizationDocumentRepository repository;

  setUp(() {
    remote = _MockRemote();
    repository = OrganizationDocumentRepository(remote, _FakeNetworkGuard());
  });

  group('extract — scope derivation', () {
    test(
      'a trade licence id in uploadedIds calls extractTradeLicense, never '
      'extractEmiratesId',
      () async {
        when(
          () => remote.extractTradeLicense(tradeLicenseId: 'tl-1'),
        ).thenAnswer(
          (_) => TaskEither.right(
            const TradeLicenseExtractionResponse(
              status: LegalDataStatus.verified,
              missingFields: [],
            ),
          ),
        );

        final result = await repository
            .extract(
              const ExtractParams(
                uploadedIds: {DocumentType.tradeLicense: 'tl-1'},
                context: DocumentFlowContext(),
              ),
            )
            .run();

        expect(result.isRight(), isTrue);
        verifyNever(
          () => remote.extractEmiratesId(
            emiratesIdFrontId: any(named: 'emiratesIdFrontId'),
            emiratesIdBackId: any(named: 'emiratesIdBackId'),
          ),
        );
      },
    );

    test(
      'Emirates ID ids in uploadedIds (no trade licence id) call '
      'extractEmiratesId, never extractTradeLicense',
      () async {
        when(
          () => remote.extractEmiratesId(
            emiratesIdFrontId: 'front-1',
            emiratesIdBackId: 'back-1',
          ),
        ).thenAnswer(
          (_) => TaskEither.right(
            const NationalIdExtractionResponse(
              status: LegalDataStatus.verified,
              missingFields: [],
            ),
          ),
        );

        final result = await repository
            .extract(
              const ExtractParams(
                uploadedIds: {
                  DocumentType.emiratesIdFront: 'front-1',
                  DocumentType.emiratesIdBack: 'back-1',
                },
                context: DocumentFlowContext(),
              ),
            )
            .run();

        expect(result.isRight(), isTrue);
        verifyNever(
          () => remote.extractTradeLicense(
            tradeLicenseId: any(named: 'tradeLicenseId'),
          ),
        );
      },
    );

    test(
      'neither a complete Emirates ID pair nor a trade licence id fails '
      'validation without calling the remote at all',
      () async {
        final result = await repository
            .extract(
              const ExtractParams(
                uploadedIds: {DocumentType.emiratesIdFront: 'front-1'},
                context: DocumentFlowContext(),
              ),
            )
            .run();

        expect(result.isLeft(), isTrue);
        result.match(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('expected a failure'),
        );
        verifyZeroInteractions(remote);
      },
    );
  });

  group('extract — Emirates ID issue derivation', () {
    Future<ExtractedDocument> runExtract(
      NationalIdExtractionResponse stub,
    ) async {
      when(
        () => remote.extractEmiratesId(
          emiratesIdFrontId: any(named: 'emiratesIdFrontId'),
          emiratesIdBackId: any(named: 'emiratesIdBackId'),
        ),
      ).thenAnswer((_) => TaskEither.right(stub));

      final result = await repository
          .extract(
            const ExtractParams(
              uploadedIds: {
                DocumentType.emiratesIdFront: 'front-1',
                DocumentType.emiratesIdBack: 'back-1',
              },
              context: DocumentFlowContext(),
            ),
          )
          .run();

      final documents = result.getOrElse(
        (_) => throw StateError('expected success'),
      );
      return documents.sectionOf(DocumentType.emiratesIdFront)!;
    }

    test(
      'status verified, no missingFields, no idVerification → none',
      () async {
        final section = await runExtract(
          const NationalIdExtractionResponse(
            status: LegalDataStatus.verified,
            missingFields: [],
          ),
        );
        expect(section.issue, DocumentIssue.none);
        expect(section.status, DocumentStatus.verified);
      },
    );

    test(
      'status expiring_soon is non-blocking — issue stays none',
      () async {
        final section = await runExtract(
          const NationalIdExtractionResponse(
            status: LegalDataStatus.expiringSoon,
            missingFields: [],
          ),
        );
        expect(section.status, DocumentStatus.expiringSoon);
        expect(section.issue, DocumentIssue.none);
      },
    );

    test('status expired → DocumentIssue.expired', () async {
      final section = await runExtract(
        const NationalIdExtractionResponse(
          status: LegalDataStatus.expired,
          missingFields: [],
        ),
      );
      expect(section.issue, DocumentIssue.expired);
    });

    test('non-empty missingFields → DocumentIssue.imageUnclear', () async {
      final section = await runExtract(
        const NationalIdExtractionResponse(
          status: LegalDataStatus.verified,
          missingFields: ['id_number'],
        ),
      );
      expect(section.issue, DocumentIssue.imageUnclear);
      expect(section.missingFields, ['id_number']);
    });

    test(
      'idVerification.matched == false → DocumentIssue.idMismatch with a '
      'whole-document repair target',
      () async {
        final section = await runExtract(
          const NationalIdExtractionResponse(
            status: LegalDataStatus.verified,
            missingFields: [],
            idVerification: IdVerification(matched: false),
          ),
        );
        expect(section.issue, DocumentIssue.idMismatch);
        expect(section.repair?.scope, DocumentRepairScope.wholeDocument);
        expect(section.repair?.parts, [
          DocumentType.emiratesIdFront,
          DocumentType.emiratesIdBack,
        ]);
      },
    );

    test(
      'idVerification.matched == true never triggers idMismatch',
      () async {
        final section = await runExtract(
          const NationalIdExtractionResponse(
            status: LegalDataStatus.verified,
            missingFields: [],
            idVerification: IdVerification(matched: true),
          ),
        );
        expect(section.issue, DocumentIssue.none);
        expect(section.repair, isNull);
      },
    );
  });

  group('extract — trade licence has no idVerification concept', () {
    test('a trade licence section never carries idVerification', () async {
      when(
        () => remote.extractTradeLicense(tradeLicenseId: 'tl-1'),
      ).thenAnswer(
        (_) => TaskEither.right(
          const TradeLicenseExtractionResponse(
            status: LegalDataStatus.expired,
            missingFields: [],
          ),
        ),
      );

      final result = await repository
          .extract(
            const ExtractParams(
              uploadedIds: {DocumentType.tradeLicense: 'tl-1'},
              context: DocumentFlowContext(),
            ),
          )
          .run();

      final documents = result.getOrElse(
        (_) => throw StateError('expected success'),
      );
      final section = documents.sectionOf(DocumentType.tradeLicense)!;
      expect(section.idVerification, isNull);
      expect(section.issue, DocumentIssue.expired);
    });
  });

  group('submit — scope derivation', () {
    test('a trade licence id calls confirmTradeLicense', () async {
      when(
        () => remote.confirmTradeLicense(tradeLicenseId: 'tl-1'),
      ).thenAnswer((_) => TaskEither.right(unit));

      final result = await repository
          .submit(
            const SubmitParams(
              uploadedIds: {DocumentType.tradeLicense: 'tl-1'},
              context: DocumentFlowContext(),
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      verifyNever(
        () => remote.confirmEmiratesId(
          emiratesIdFrontId: any(named: 'emiratesIdFrontId'),
          emiratesIdBackId: any(named: 'emiratesIdBackId'),
        ),
      );
    });

    test('Emirates ID ids call confirmEmiratesId', () async {
      when(
        () => remote.confirmEmiratesId(
          emiratesIdFrontId: 'front-1',
          emiratesIdBackId: 'back-1',
        ),
      ).thenAnswer((_) => TaskEither.right(unit));

      final result = await repository
          .submit(
            const SubmitParams(
              uploadedIds: {
                DocumentType.emiratesIdFront: 'front-1',
                DocumentType.emiratesIdBack: 'back-1',
              },
              context: DocumentFlowContext(),
            ),
          )
          .run();

      expect(result.isRight(), isTrue);
      verifyNever(
        () => remote.confirmTradeLicense(
          tradeLicenseId: any(named: 'tradeLicenseId'),
        ),
      );
    });

    test(
      'an incomplete Emirates ID pair fails validation without calling the '
      'remote',
      () async {
        final result = await repository
            .submit(
              const SubmitParams(
                uploadedIds: {DocumentType.emiratesIdFront: 'front-1'},
                context: DocumentFlowContext(),
              ),
            )
            .run();

        expect(result.isLeft(), isTrue);
        result.match(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (_) => fail('expected a failure'),
        );
        verifyZeroInteractions(remote);
      },
    );
  });

  group('fetch — stored record (unchanged combined mapping)', () {
    test('builds a section per present stored document', () async {
      when(() => remote.fetchLegalData()).thenAnswer(
        (_) => TaskEither.right(
          LegalDataResponse(
            personalLegalData: NationalIdResponse(
              id: 'p1',
              status: LegalDataStatus.verified,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
        ),
      );

      final result = await repository
          .fetch(const FetchParams(context: DocumentFlowContext()))
          .run();

      final documents = result.getOrElse(
        (_) => throw StateError('expected success'),
      );
      expect(documents.sectionOf(DocumentType.emiratesIdFront), isNotNull);
      expect(documents.sectionOf(DocumentType.tradeLicense), isNull);
    });
  });
}
