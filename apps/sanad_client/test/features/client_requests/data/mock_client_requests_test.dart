import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/mocks/mock_client_requests.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

/// The fixture set behind the **normal** Requests screen in a mock build.
///
/// What matters here is not that the rows exist but that they are ordinary
/// `ClientRequest`s: every state the card shows — the attention section, the
/// offer stack, the missing-address pill, Rebook — has to fall out of fields on
/// the entity, exactly as it does against the API. A fixture that set those by
/// some other route would be demonstrating a screen the product does not have.
void main() {
  group('the fixture is one coherent data set', () {
    test('it covers all three tabs', () {
      final all = MockClientRequests.all();

      for (final tab in ClientRequestsTab.values) {
        expect(
          all.where(
            (r) => tab.serverStatus == null || r.status == tab.serverStatus,
          ),
          isNotEmpty,
          reason: '${tab.name} would render empty',
        );
      }
    });

    test('the attention row earns it through missingForSubmit', () {
      final attention = MockClientRequests.all().where((r) => r.needsAttention);

      expect(attention, isNotEmpty);
      // Not a flag the fixture set: the card reads `missingForSubmit`, and a
      // draft with no coordinates is what puts it there.
      expect(attention.first.missingForSubmit, contains('location'));
      expect(attention.first.lat, isNull);
    });

    test('the in-progress row carries offers and matched branches', () {
      final active = MockClientRequests.all().firstWhere(
        (r) => r.status == ClientRequestStatus.inProgress,
      );

      expect(active.serviceName, 'Home Cleaning');
      expect(active.offerCount, 18);
      expect(active.matchedBranches, hasLength(3));
    });

    test('the cancelled row can be rebooked and not cancelled again', () {
      final cancelled = MockClientRequests.all().firstWhere(
        (r) => r.status == ClientRequestStatus.cancelled,
      );

      expect(cancelled.status.isClosed, isTrue);
      expect(cancelled.canCancel, isFalse);
    });

    test('dates are fixed, so the same screen renders next week', () {
      expect(MockClientRequests.scheduledDay.year, greaterThan(2027));
      expect(MockClientRequests.scheduledDay.weekday, DateTime.monday);
    });
  });

  group('the repository behaves like the API it stands in for', () {
    late ClientRequestsRepository repository;

    setUp(() => repository = MockClientRequestsRepository());

    test('list filters by the tab status the bloc sends', () async {
      for (final tab in [
        ClientRequestsTab.scheduled,
        ClientRequestsTab.cancelled,
      ]) {
        final page = await repository
            .list(ClientRequestsQuery(status: tab.serverStatus))
            .run();

        expect(
          page.getRight().toNullable()!.items.every(
            (r) => r.status == tab.serverStatus,
          ),
          isTrue,
        );
      }
    });

    test('list returns a terminating page so pagination stops', () async {
      final page = await repository.list(const ClientRequestsQuery()).run();
      final value = page.getRight().toNullable()!;

      expect(value.meta.totalPages, 1);
      expect(value.meta.currentPage, 1);
    });

    test('cancel really moves the row between tabs', () async {
      final scheduled = MockClientRequests.all().firstWhere(
        (r) => r.status == ClientRequestStatus.scheduled,
      );

      await repository.cancel(scheduled.id, 'changed my mind').run();

      final after = await repository.getById(scheduled.id).run();
      expect(
        after.getRight().toNullable()!.status,
        ClientRequestStatus.cancelled,
      );
    });

    test(
      'an unsupported mutation fails honestly rather than pretending',
      () async {
        final result = await repository
            .submit(MockClientRequests.all().first.id)
            .run();

        // A stand-in that silently accepted a submission would be demonstrating
        // something the product does not do.
        expect(result.isLeft(), isTrue);
      },
    );

    test('an unknown id is a not-found, not a crash', () async {
      final result = await repository.getById('nope').run();

      expect(result.isLeft(), isTrue);
    });
  });
}
