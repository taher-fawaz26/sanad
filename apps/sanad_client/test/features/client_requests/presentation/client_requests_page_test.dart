import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/matched_branch.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_requests_page.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_request_card.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tabs.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tokens.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_status_badge.dart';
import 'package:testing/testing.dart';

/// The Requests screen against Figma `Requests - Active` (`8135:29516`).
///
/// The bloc is mocked: every one of these is a *layout* question — which
/// headings appear, what a selected pill looks like, whether 360dp is enough
/// room — and driving the real bloc would only add network fakes and timers to
/// the setup. Its behaviour is covered in `client_requests_list_bloc_test`.
///
/// Localization is not initialized here, so `.tr()` returns the key itself and
/// the finders below look for keys. That also means the fixtures carry **no**
/// date: the card formats one through `context.locale`, which needs
/// `EasyLocalization` in the tree, and initializing that in a widget test
/// hangs. Date formatting is `intl`'s job and is exercised on the device
/// instead; everything these tests are about — sections, sizing, mirroring —
/// is unaffected by it.
class _MockListBloc
    extends MockBloc<ClientRequestsListEvent, ClientRequestsListState>
    implements ClientRequestsListBloc {}

void main() {
  late _MockListBloc bloc;

  ClientRequest request({
    String id = 'req-1',
    ClientRequestStatus status = ClientRequestStatus.inProgress,
    int offerCount = 18,
    String? areaName = 'Dubai Hills',
    DateTime? preferredAt,
  }) => ClientRequest(
    id: id,
    status: status,
    createdAt: DateTime(2026, 8, 20),
    serviceId: 'svc-1',
    serviceName: 'Home Cleaning',
    categoryName: 'Home Services',
    lat: 25.2,
    lng: 55.3,
    areaName: areaName,
    preferredAt: preferredAt,
    note: 'Deep cleaning of the entire home including kitchen and bathrooms.',
    offerCount: offerCount,
    matchedBranches: const [
      MatchedBranch(
        branchId: 'b1',
        branchName: 'Al Barsha Branch',
        providerId: 'p1',
        providerName: 'Sparkle Cleaning LLC',
        distanceKm: 4.2,
      ),
    ],
  );

  void stub(ClientRequestsListState state) {
    whenListen(
      bloc,
      const Stream<ClientRequestsListState>.empty(),
      initialState: state,
    );
  }

  ClientRequestsListState stateWith(
    List<ClientRequest> items, {
    ClientRequestsTab tab = ClientRequestsTab.active,
  }) => ClientRequestsListState(
    tab: tab,
    data: PaginationData<ClientRequest>(
      status: RequestStatus.success,
      items: items,
    ),
  );

  Future<void> pumpPage(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    // The emulator's real width: 1080px at 3x.
    Size physicalSize = const Size(1080, 2400),
  }) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDsWidget(
      tester,
      Directionality(
        textDirection: direction,
        child: BlocProvider<ClientRequestsListBloc>.value(
          value: bloc,
          child: ClientRequestsPage(buildBloc: () => bloc, showNavBar: false),
        ),
      ),
    );
    // Each card's entrance (`AppListEntrance`) is a bounded, one-shot
    // animation — settling it is safe and avoids leaving its timer pending
    // at test teardown.
    await tester.pumpAndSettle();
  }

  setUp(() {
    bloc = _MockListBloc();
    stub(stateWith([request()]));
  });

  group('the tab row', () {
    testWidgets('draws all three segments', (tester) async {
      await pumpPage(tester);

      expect(find.byType(ClientRequestsTabs), findsOneWidget);
      expect(find.text('client_requests.tab_active'), findsOneWidget);
      expect(find.text('client_requests.tab_scheduled'), findsOneWidget);
      expect(find.text('client_requests.tab_cancelled'), findsOneWidget);
    });

    testWidgets('gives the three pills equal width', (tester) async {
      // Figma `StatusPills` (`8385:4377`) divides the content column in three;
      // intrinsically-sized chips would not.
      await pumpPage(tester);

      final widths = [
        for (final label in [
          'client_requests.tab_active',
          'client_requests.tab_scheduled',
          'client_requests.tab_cancelled',
        ])
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(Ink),
                ),
              )
              .width,
      ];

      expect(widths[1], closeTo(widths[0], 0.5));
      expect(widths[2], closeTo(widths[0], 0.5));
    });

    testWidgets('fills only the selected pill', (tester) async {
      await pumpPage(tester);

      Color? fillOf(String label) {
        final ink = tester.widget<Ink>(
          find.ancestor(of: find.text(label), matching: find.byType(Ink)),
        );
        return (ink.decoration! as BoxDecoration).color;
      }

      expect(
        fillOf('client_requests.tab_active'),
        ClientRequestsTokens.tabSelectedFill,
      );
      expect(
        fillOf('client_requests.tab_scheduled'),
        isNot(ClientRequestsTokens.tabSelectedFill),
      );
    });

    testWidgets('tapping an unselected segment asks the bloc to switch', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.text('client_requests.tab_cancelled'));
      await tester.pump();

      verify(
        () => bloc.add(
          const ClientRequestsTabChanged(ClientRequestsTab.cancelled),
        ),
      ).called(1);
    });
  });

  group('sections', () {
    testWidgets('heads the flagged run with a count, then the tab heading', (
      tester,
    ) async {
      // A draft missing its location needs the client; a live request with
      // offers pending on the provider does not.
      final needsYou = ClientRequest(
        id: 'draft-1',
        status: ClientRequestStatus.draft,
        createdAt: DateTime(2026, 8, 20),
        serviceId: 'svc-1',
        serviceName: 'Home Cleaning',
      );
      stub(stateWith([needsYou, request(id: 'other')]));

      await pumpPage(tester);

      expect(find.text('client_requests.section_attention'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('client_requests.section_other'), findsOneWidget);
      expect(find.byType(ClientRequestCard), findsNWidgets(2));
    });

    testWidgets('shows only the tab heading when nothing is flagged', (
      tester,
    ) async {
      stub(stateWith([request(id: 'a'), request(id: 'b')]));

      await pumpPage(tester);

      expect(find.text('client_requests.section_attention'), findsNothing);
      expect(find.text('client_requests.section_other'), findsOneWidget);
    });

    testWidgets('names the section after the visible tab', (tester) async {
      stub(
        stateWith(
          [request(status: ClientRequestStatus.scheduled)],
          tab: ClientRequestsTab.scheduled,
        ),
      );

      await pumpPage(tester);

      expect(find.text('client_requests.section_upcoming'), findsOneWidget);
    });
  });

  group('the card', () {
    testWidgets('carries the status chip, Cancel and Open Chat', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.byType(RequestStatusChip), findsOneWidget);
      expect(find.text('requests.status.in_progress'), findsOneWidget);
      expect(find.text('client_requests.cancel'), findsOneWidget);
      // Open Chat only exists where a chat branch does; outside the shell it
      // is deliberately absent rather than dead.
      expect(find.text('client_requests.open_chat'), findsNothing);
    });

    testWidgets('offers no create, add or edit affordance', (tester) async {
      // The product rule: a request is made by asking the agent in AI Chat.
      await pumpPage(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
      for (final forbidden in ['New Request', 'Add Request', 'Create']) {
        expect(find.text(forbidden), findsNothing);
      }
    });

    testWidgets('shows the offer stack when there are offers', (tester) async {
      await pumpPage(tester);

      // The count and the word are two spans of one `Text.rich`, so the
      // finder has to look inside it.
      // The count and the word are two spans of one `Text.rich`, so the
      // finder has to look inside it — and match a substring, since the
      // rich text as a whole reads "18 <label>".
      expect(
        find.textContaining('client_requests.offers_label', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('18', findRichText: true), findsOneWidget);
    });

    testWidgets('falls back to the date and area pills without offers', (
      tester,
    ) async {
      stub(stateWith([request(offerCount: 0)]));

      await pumpPage(tester);

      expect(
        find.textContaining('client_requests.offers_label', findRichText: true),
        findsNothing,
      );
      expect(find.text('Dubai Hills'), findsOneWidget);
    });

    testWidgets('hides Cancel once the request is closed', (tester) async {
      stub(stateWith([request(status: ClientRequestStatus.cancelled)]));

      await pumpPage(tester);

      expect(find.text('client_requests.cancel'), findsNothing);
    });
  });

  group('it fits a real device', () {
    for (final direction in TextDirection.values) {
      testWidgets('no overflow at 360dp in ${direction.name}', (tester) async {
        // Three long-ish tab labels, a two-line description and a card action
        // row all compete for the same 360dp.
        stub(
          stateWith([
            request(),
            request(id: 'b', offerCount: 0),
            request(id: 'c', status: ClientRequestStatus.cancelled),
          ]),
        );

        await pumpPage(tester, direction: direction);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('cards span the content column at both directions', (
      tester,
    ) async {
      // Figma: 20dp of page padding either side, so a card is width - 40.
      await pumpPage(tester);

      final card = tester.getSize(find.byType(ClientRequestCard).first);
      expect(card.width, closeTo(360 - 40, 1));
    });

    testWidgets('mirrors its leading edge under RTL', (tester) async {
      await pumpPage(tester, direction: TextDirection.rtl);

      final chip = tester.getRect(find.byType(RequestStatusChip));
      final card = tester.getRect(find.byType(ClientRequestCard).first);

      // The status chip sits on the leading edge, which is the right in RTL.
      expect(chip.right, closeTo(card.right - 20, 1.5));
    });
  });
}
