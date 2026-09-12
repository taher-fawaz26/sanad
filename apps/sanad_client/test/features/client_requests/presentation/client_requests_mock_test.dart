import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/mocks/mock_client_requests.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_requests_page.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_request_card.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tabs.dart';
import 'package:testing/testing.dart';

/// The **normal** Requests screen, against the mock repository.
///
/// Nothing here is a demo page: this is `ClientRequestsPage` over the real
/// `ClientRequestsListBloc` over the real `ListClientRequestsUseCase`, with
/// only the repository swapped — which is exactly what `ClientRequestsDI` does
/// when `AppConfig.useMockBackend` is set. If the screen renders here, it
/// renders in the app for the same reason.
///
/// Localization is not initialized (see `client_requests_page_test` for why
/// initializing it hangs), so `.tr()` returns keys and the finders look for
/// keys. The same constraint is why the tab assertions below run against the
/// bloc rather than the rendered rows: the Scheduled and Cancelled fixtures
/// carry dates, and the card formats those through `context.locale`.
void main() {
  ClientRequestsListBloc buildBloc() {
    final repository = MockClientRequestsRepository();
    return ClientRequestsListBloc(
      listRequests: ListClientRequestsUseCase(repository),
      cancelRequest: CancelClientRequestUseCase(repository),
    );
  }

  group('the screen renders fixture data through the shipped widgets', () {
    testWidgets('the Active tab fills with the existing request card', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpDsWidget(tester, ClientRequestsPage(buildBloc: buildBloc));
      await tester.pumpAndSettle();

      // The same card the API path renders. A second Requests UI would show up
      // here as this finder returning nothing.
      expect(find.byType(ClientRequestCard), findsWidgets);
      expect(find.byType(ClientRequestsTabs), findsOne);
      expect(find.textContaining('Home Cleaning'), findsWidgets);
    });

    testWidgets('the attention section is reached through request data', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpDsWidget(tester, ClientRequestsPage(buildBloc: buildBloc));
      await tester.pumpAndSettle();

      // The heading exists because a fixture row has `missingForSubmit`, not
      // because anything told the page to draw it.
      expect(find.text('client_requests.section_attention'), findsOne);
    });

    testWidgets('it reaches no network', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // No `BaseApiClient` is registered in this test's locator at all, so a
      // repository that tried to resolve one would throw rather than quietly
      // fall back.
      await pumpDsWidget(tester, ClientRequestsPage(buildBloc: buildBloc));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('the tabs map to the statuses the shipped bloc expects', () {
    for (final (tab, expected) in <(ClientRequestsTab, ClientRequestStatus)>[
      (ClientRequestsTab.scheduled, ClientRequestStatus.scheduled),
      (ClientRequestsTab.cancelled, ClientRequestStatus.cancelled),
    ]) {
      test('${tab.name} lists only ${expected.name} rows', () async {
        final bloc = buildBloc()
          ..add(const ClientRequestsStarted())
          ..add(ClientRequestsTabChanged(tab));
        addTearDown(bloc.close);

        await expectLater(
          bloc.stream.firstWhere(
            (s) => s.tab == tab && s.data.items.isNotEmpty,
          ),
          completes,
        );
        expect(
          bloc.state.data.items.map((r) => r.status).toSet(),
          {expected},
        );
      });
    }

    test('Active spans every other status', () async {
      final bloc = buildBloc()..add(const ClientRequestsStarted());
      addTearDown(bloc.close);

      await bloc.stream.firstWhere((s) => s.data.items.isNotEmpty);

      final statuses = bloc.state.data.items.map((r) => r.status).toSet();
      expect(statuses, isNot(contains(ClientRequestStatus.scheduled)));
      expect(statuses, isNot(contains(ClientRequestStatus.cancelled)));
      expect(statuses, contains(ClientRequestStatus.inProgress));
    });
  });
}
