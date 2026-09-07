import 'package:branches/src/data/datasources/branch_remote_data_source.dart';
import 'package:branches/src/data/endpoints/branch_api_paths.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockBaseApiClient extends Mock implements BaseApiClient {}

/// Runs the real `parser` the call site passed against [body] and returns the
/// parsed result as a successful [TaskEither] — the same way the real client
/// decodes a response — so each test asserts what the parser produces from a
/// realistic payload.
TaskEither<Failure, T> Function(Invocation) _echoing<T>(dynamic body) =>
    (invocation) {
      final parser = invocation.namedArguments[#parser] as T Function(dynamic);
      return TaskEither.right(parser(body));
    };

void main() {
  late _MockBaseApiClient apiClient;
  late BranchRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(RequestMethod.get);
  });

  setUp(() {
    apiClient = _MockBaseApiClient();
    dataSource = BranchRemoteDataSourceImpl(apiClient);
  });

  group('getCompanySchedule', () {
    test(
      'GETs the company working-hours endpoint and normalizes the Title-case '
      'day codes it returns to the all-caps branch schema (SAN-780)',
      () async {
        when(
          () => apiClient.request<List<BranchAvailabilityEntity>>(
            path: any(named: 'path'),
            method: any(named: 'method'),
            body: any<dynamic>(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).thenAnswer(
          // Real `service-provider/working-hours` shape: Title-case day codes.
          _echoing<List<BranchAvailabilityEntity>>({
            'availability': [
              {
                'day': 'Saturday',
                'slots': [
                  {'from': '10:00', 'to': '14:00'},
                ],
              },
              {
                'day': 'Friday',
                'slots': [
                  {'from': '09:00', 'to': '13:00'},
                ],
              },
            ],
          }),
        );

        final result = await dataSource.getCompanySchedule().run();

        final schedule = result.getOrElse(
          (_) => throw StateError('expected success'),
        );

        // Days come back in the canonical all-caps form the details summary
        // keys against (BranchWeekdays.all) — the divergence that made every
        // day render as "Closed".
        expect(
          schedule.map((day) => day.day),
          [BranchWeekdays.saturday, BranchWeekdays.friday],
        );
        expect(schedule.first.slots.single.from, '10:00');
        expect(schedule.first.slots.single.to, '14:00');

        verify(
          () => apiClient.request<List<BranchAvailabilityEntity>>(
            path: BranchApiPaths.companySchedule,
            method: RequestMethod.get,
            body: any<dynamic>(named: 'body'),
            parser: any(named: 'parser'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );

    test('returns an empty schedule when availability is null', () async {
      when(
        () => apiClient.request<List<BranchAvailabilityEntity>>(
          path: any(named: 'path'),
          method: any(named: 'method'),
          body: any<dynamic>(named: 'body'),
          parser: any(named: 'parser'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        _echoing<List<BranchAvailabilityEntity>>({'availability': null}),
      );

      final result = await dataSource.getCompanySchedule().run();

      expect(
        result.getOrElse((_) => throw StateError('expected success')),
        isEmpty,
      );
    });
  });
}
