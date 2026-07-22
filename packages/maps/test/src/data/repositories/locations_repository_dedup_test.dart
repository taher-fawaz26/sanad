import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/src/data/repositories/locations_repository_impl.dart';
import 'package:network/network.dart';

/// Fake client that serves a 3-page `locations/areas` response and counts how
/// many page-1 requests were issued, so we can assert the repo paginates the
/// city exactly once regardless of concurrent/subsequent callers.
class _CountingApiClient implements BaseApiClient {
  int page1Requests = 0;
  int totalRequests = 0;

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required T Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
  }) {
    return TaskEither(() async {
      totalRequests++;
      final page = int.parse(query!['page'] as String);
      if (page == 1) page1Requests++;
      // Yield so concurrent callers interleave before the first run completes.
      await Future<void>.delayed(Duration.zero);
      final data = {
        'data': [
          {
            'id': 'a$page',
            'placeId': 'ChIJ_$page',
            'nameEn': 'Area $page',
            'nameAr': 'منطقة $page',
            'latitude': 25.0,
            'longitude': 55.0,
            'cityId': query['cityId'],
            'countryId': 'country-1',
          },
        ],
        'meta': {'currentPage': page, 'totalPages': 3},
      };
      return Either.right(parser(data));
    });
  }
}

void main() {
  group('LocationsRepositoryImpl.getAreasByCity dedup + cache', () {
    test('concurrent callers share a single pagination', () async {
      final client = _CountingApiClient();
      final repo = LocationsRepositoryImpl(client);

      final results = await Future.wait([
        repo.getAreasByCity(cityId: 'city-1').run(),
        repo.getAreasByCity(cityId: 'city-1').run(),
      ]);

      for (final r in results) {
        expect(r.isRight(), isTrue);
        r.map((areas) => expect(areas.length, 3));
      }
      // 3 pages fetched once total, not 6 across two concurrent callers.
      expect(client.page1Requests, 1);
      expect(client.totalRequests, 3);
    });

    test('subsequent calls hit the cache and issue no new requests', () async {
      final client = _CountingApiClient();
      final repo = LocationsRepositoryImpl(client);

      await repo.getAreasByCity(cityId: 'city-1').run();
      expect(client.totalRequests, 3);

      await repo.getAreasByCity(cityId: 'city-1').run();
      // Still 3 — the second call served entirely from cache.
      expect(client.totalRequests, 3);
    });
  });
}
