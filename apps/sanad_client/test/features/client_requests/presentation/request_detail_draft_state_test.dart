// Regression for C-03: opening a *draft* showed the submitted-request empty
// state, whose copy reads "Matched providers have been notified." That is
// false — a draft has never left the device — and alarming, because it tells
// the user their unfinished request was broadcast to businesses.
//
// The old condition was `request.threads.isEmpty`, which is equally true for a
// draft and for a submitted request nobody has bid on yet, so it could only
// tell them apart by accident.
//
// No EasyLocalization bootstrap — `.tr()` falls back to the raw key, which is
// exactly what these assertions want to match on (same convention as
// `oauth_otp_page_test.dart`).

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/datasources/client_requests_remote_data_source.dart';
import 'package:sanad_client/src/features/client_requests/src/data/repositories/client_requests_repository_impl.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_request_detail/client_request_detail_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_request_detail_page.dart';

import '../support/client_requests_fakes.dart';

/// The request fixture with every timestamp the header would format stripped.
///
/// `_Header` renders dates through `formatRequestDateTime`, which reads
/// `context.locale` from EasyLocalization — and this harness deliberately does
/// not bootstrap it (so `.tr()` yields raw keys to assert on). Dates are not
/// what these tests are about; the empty-state branch is.
Map<String, dynamic> requestWithoutDates({
  String status = 'SUBMITTED',
}) => {
  ...clientRequestJson(
    status: status,
    threads: const [],
    matchedBranches: const [],
    offerCount: 0,
  ),
  'preferredAt': null,
  'expiresAt': null,
  'scheduledAt': null,
  'submittedAt': null,
};

void main() {
  late RecordingApiClient client;

  ClientRequestDetailBloc buildBloc() {
    final ClientRequestsRepository repository = ClientRequestsRepositoryImpl(
      ClientRequestsRemoteDataSourceImpl(client),
    );
    return ClientRequestDetailBloc(
      requestId: 'req-1',
      getRequest: GetClientRequestUseCase(repository),
      cancelRequest: CancelClientRequestUseCase(repository),
      confirmRequest: ConfirmClientRequestUseCase(repository),
      disputeRequest: DisputeClientRequestUseCase(repository),
      acceptOffer: AcceptOfferUseCase(repository),
      rejectOffer: RejectOfferUseCase(repository),
      counterOffer: CounterOfferUseCase(repository),
    );
  }

  Future<void> pumpDetail(WidgetTester tester) async {
    // A wide surface: with no EasyLocalization bootstrap the UI renders raw
    // i18n *keys*, which are far longer than the real copy and overflow the
    // default 800x600 test window. Widening keeps the harness's own artefact
    // out of the assertions.
    tester.view
      ..physicalSize = const Size(1400, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: ClientRequestDetailPage(buildBloc: buildBloc),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() => client = RecordingApiClient());

  group('a draft with no offers', () {
    setUp(() {
      client.defaultResponse = TaskEither.right(
        requestWithoutDates(status: 'DRAFT'),
      );
    });

    testWidgets('never claims providers were notified', (tester) async {
      await pumpDetail(tester);

      expect(
        find.text('client_requests.no_offers_description'),
        findsNothing,
        reason: 'a draft has not been submitted, so nobody was notified',
      );
      expect(find.text('client_requests.no_offers_title'), findsNothing);
    });

    testWidgets('says it has not been submitted', (tester) async {
      await pumpDetail(tester);

      expect(
        find.text('client_requests.draft_not_submitted_title'),
        findsOneWidget,
      );
      expect(
        find.text('client_requests.draft_not_submitted_description'),
        findsOneWidget,
      );
    });

    testWidgets('offers no way to edit it — creation lives in Chat', (
      tester,
    ) async {
      // Product rule: a request is created and changed by asking the agent,
      // never through a form in the client. The draft state says what it is
      // and stops there.
      await pumpDetail(tester);

      expect(find.text('client_requests.continue_editing'), findsNothing);
      expect(find.text('client_requests.new_request'), findsNothing);
    });
  });

  group('a submitted request with no offers', () {
    setUp(() {
      client.defaultResponse = TaskEither.right(requestWithoutDates());
    });

    testWidgets('still says providers were notified — that copy is correct '
        'here and must survive', (tester) async {
      await pumpDetail(tester);

      expect(find.text('client_requests.no_offers_title'), findsOneWidget);
      expect(
        find.text('client_requests.no_offers_description'),
        findsOneWidget,
      );
    });

    testWidgets('offers no edit action either', (tester) async {
      await pumpDetail(tester);

      expect(find.text('client_requests.continue_editing'), findsNothing);
    });
  });

  test('the draft status is what the branch keys off', () {
    // Guards the condition itself: `threads.isEmpty` is true for both cases
    // above, so only the status can separate them.
    expect(ClientRequestStatus.draft.isDraft, isTrue);
    expect(ClientRequestStatus.submitted.isDraft, isFalse);
  });
}
