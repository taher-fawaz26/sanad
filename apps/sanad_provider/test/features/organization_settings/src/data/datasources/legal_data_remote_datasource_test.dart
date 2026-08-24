import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/legal_data_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/datasources/media_upload_remote_datasource.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/endpoints/legal_data_api_paths.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/national_id_extraction_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/models/trade_license_extraction_response.dart';

class _MockBaseApiClient extends Mock implements BaseApiClient {}

class _MockMediaUploadRemoteDataSource extends Mock
    implements MediaUploadRemoteDataSource {}

/// Runs the real (synchronous) `parser` this call site passed against
/// [body] and returns the parsed result as a successful [TaskEither], the
/// same way the real client decodes a response — so each test only needs to
/// assert what request was sent. Every parser in [LegalDataRemoteDataSource]
/// is synchronous, so this never needs to await a `Future`.
TaskEither<Failure, T> Function(Invocation) _echoing<T>(dynamic body) =>
    (invocation) {
      final parser = invocation.namedArguments[#parser] as T Function(dynamic);
      return TaskEither.right(parser(body));
    };

void main() {
  late _MockBaseApiClient apiClient;
  late _MockMediaUploadRemoteDataSource mediaUpload;
  late LegalDataRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(RequestMethod.get);
  });

  setUp(() {
    apiClient = _MockBaseApiClient();
    mediaUpload = _MockMediaUploadRemoteDataSource();
    dataSource = LegalDataRemoteDataSourceImpl(apiClient, mediaUpload);
  });

  group('extractEmiratesId', () {
    test(
      'POSTs to the emirates-id extract endpoint with both media ids',
      () async {
        when(
          () => apiClient.request<NationalIdExtractionResponse>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            body: any(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(
          _echoing({'status': 'verified', 'missingFields': <String>[]}),
        );

        final result = await dataSource
            .extractEmiratesId(
              emiratesIdFrontId: 'front-1',
              emiratesIdBackId: 'back-1',
            )
            .run();

        expect(result.isRight(), isTrue);

        verify(
          () => apiClient.request<NationalIdExtractionResponse>(
            path: LegalDataApiPaths.emiratesIdExtract,
            method: RequestMethod.post,
            body: {
              'emiratesIdFrontId': 'front-1',
              'emiratesIdBackId': 'back-1',
            },
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );

    test('parses the bare response — no outer envelope expected', () async {
      when(
        () => apiClient.request<NationalIdExtractionResponse>(
          path: any(named: 'path'),
          method: any(named: 'method'),
          body: any(named: 'body'),
          parser: any(named: 'parser'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        _echoing({
          'fullNameEnglish': 'John Doe',
          'status': 'expiring_soon',
          'missingFields': <String>[],
          'idVerification': {
            'matched': false,
            'reason': 'front_back_id_mismatch',
          },
        }),
      );

      final result = await dataSource
          .extractEmiratesId(emiratesIdFrontId: 'f', emiratesIdBackId: 'b')
          .run();

      final response = result.getOrElse(
        (_) => throw StateError('expected success'),
      );
      expect(response.fullNameEnglish, 'John Doe');
      expect(response.idVerification?.matched, isFalse);
      expect(response.idVerification?.reason, 'front_back_id_mismatch');
    });
  });

  group('confirmEmiratesId', () {
    test(
      'PUTs to the emirates-id confirm endpoint with both media ids',
      () async {
        when(
          () => apiClient.request<Unit>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            body: any(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(_echoing<Unit>(<String, dynamic>{}));

        final result = await dataSource
            .confirmEmiratesId(
              emiratesIdFrontId: 'front-1',
              emiratesIdBackId: 'back-1',
            )
            .run();

        expect(result.isRight(), isTrue);
        verify(
          () => apiClient.request<Unit>(
            path: LegalDataApiPaths.emiratesIdConfirm,
            method: RequestMethod.put,
            body: {
              'emiratesIdFrontId': 'front-1',
              'emiratesIdBackId': 'back-1',
            },
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );
  });

  group('extractTradeLicense', () {
    test(
      'POSTs to the trade-license extract endpoint with only the licence id',
      () async {
        when(
          () => apiClient.request<TradeLicenseExtractionResponse>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            body: any(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(
          _echoing({'status': 'expired', 'missingFields': <String>[]}),
        );

        final result = await dataSource
            .extractTradeLicense(tradeLicenseId: 'licence-1')
            .run();

        expect(result.isRight(), isTrue);

        verify(
          () => apiClient.request<TradeLicenseExtractionResponse>(
            path: LegalDataApiPaths.tradeLicenseExtract,
            method: RequestMethod.post,
            body: {'tradeLicenseId': 'licence-1'},
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );
  });

  group('confirmTradeLicense', () {
    test(
      'PUTs to the trade-license confirm endpoint with only the licence id',
      () async {
        when(
          () => apiClient.request<Unit>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            body: any(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(_echoing<Unit>(<String, dynamic>{}));

        final result = await dataSource
            .confirmTradeLicense(tradeLicenseId: 'licence-1')
            .run();

        expect(result.isRight(), isTrue);
        verify(
          () => apiClient.request<Unit>(
            path: LegalDataApiPaths.tradeLicenseConfirm,
            method: RequestMethod.put,
            body: {'tradeLicenseId': 'licence-1'},
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );
  });

  test('fetchLegalData GETs the unsplit legal-data endpoint', () async {
    when(
      () => apiClient.request<LegalDataResponse>(
        path: any(named: 'path'),
        method: any(named: 'method'),
        body: any(named: 'body'),
        parser: any(named: 'parser'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      _echoing({'personalLegalData': null, 'tradeLicenseLegalData': null}),
    );

    final result = await dataSource.fetchLegalData().run();

    expect(result.isRight(), isTrue);
    verify(
      () => apiClient.request<LegalDataResponse>(
        path: LegalDataApiPaths.legalData,
        method: RequestMethod.get,
        body: any(named: 'body'),
        parser: any(named: 'parser'),
        query: any(named: 'query'),
      ),
    ).called(1);
  });
}
