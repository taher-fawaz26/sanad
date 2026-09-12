import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/matched_branch.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';

/// Deterministic Requests fixtures — Figma `Requests - Active` (`8135:29516`)
/// and the card variants beside it.
///
/// ## What this is not
///
/// It is not a second Requests feature, and not a second data layer. It is one
/// implementation of the **existing** [ClientRequestsRepository] behind the
/// **existing** use cases, bloc, page and card: swapping it in changes where
/// the rows come from and nothing else, so what a presenter demonstrates is
/// the shipped screen rather than a replica of it. Every state the cards show
/// — the attention section, the offer stack, the missing-address pill, Rebook
/// — is produced the way production produces it, by fields on a
/// [ClientRequest].
///
/// ## Isolation
///
/// Nothing here reaches the network stack. It is selected in exactly one place
/// (`ClientRequestsDI.init`, on `AppConfig.useMockBackend`) so a build that
/// does not opt in has no path to a fixture, and there is no flag inside the
/// feature that could be flipped by accident. There is deliberately no route,
/// query parameter or UI control that swaps it: the normal Requests screen
/// simply renders whatever the repository it was given returns.
///
/// ## Dates
///
/// Fixed, not relative to `DateTime.now()`: a fixture set that renders
/// "Mon, 28 Aug"
/// today and something else next week is not a demonstration of a design.
/// 28 Aug 2028
/// is a Monday, which is what Figma's date pill reads.
abstract final class MockClientRequests {
  MockClientRequests._();

  /// Figma's scheduled date — `Mon, 28 Aug`.
  static final DateTime scheduledDay = DateTime(2028, 8, 28, 10);

  /// The whole fixture set, in the order the server would return it (newest
  /// first). The tabs narrow it exactly as `GET /requests?status=` would.
  static List<ClientRequest> all() => [
    _homeCleaning(),
    _acMaintenance(),
    _carService(),
    _furnitureAssembly(),
    _movingService(),
  ];

  /// The hero card: live work with a crowded offer stack — Figma's `Active`
  /// card (`8385:4391`).
  ///
  /// `offerCount` 18 against three matched branches is what draws three
  /// portraits and a `+15` chip; the card derives both from these two fields,
  /// so the stack cannot say one thing while the count says another.
  static ClientRequest _homeCleaning() => ClientRequest(
    id: 'mock-active-cleaning',
    status: ClientRequestStatus.inProgress,
    createdAt: DateTime(2028, 8, 20, 9),
    serviceId: 'svc-home-cleaning',
    serviceName: 'Home Cleaning',
    categoryId: 'cat-home',
    categoryName: 'Home Services',
    lat: 25.1,
    lng: 55.25,
    addressLine: 'Villa 12, Street 4, Dubai Hills',
    areaName: 'Dubai Hills',
    note:
        'Deep cleaning of the entire home including kitchen, bathrooms, '
        'and all living areas.',
    submittedAt: DateTime(2028, 8, 20, 10),
    offerCount: 18,
    matchedBranches: const [
      MatchedBranch(
        branchId: 'mock-branch-1',
        branchName: 'Sparkle Cleaning',
        providerId: 'mock-provider-1',
        providerName: 'Sparkle Cleaning LLC',
        distanceKm: 2.4,
      ),
      MatchedBranch(
        branchId: 'mock-branch-2',
        branchName: 'Maya Home',
        providerId: 'mock-provider-2',
        providerName: 'Maya Home Services',
        distanceKm: 3.8,
      ),
      MatchedBranch(
        branchId: 'mock-branch-3',
        branchName: 'Crystal Care',
        providerId: 'mock-provider-3',
        providerName: 'Crystal Care',
        distanceKm: 5.1,
      ),
    ],
  );

  /// The "needs your attention" card: an unfinished draft whose blocker is its
  /// address — Figma's amber `missing address` pill (`8433:38432`).
  ///
  /// A **separate card**, not a badge bolted onto the one above. The pill is
  /// derived from `ClientRequest.missingForSubmit`, which is only non-empty
  /// for a draft, and a request cannot be both in progress and un-submitted.
  /// Teaching the card to show the pill regardless would be inventing
  /// widget-only state for a screenshot — and it would have to be un-invented
  /// before the screen ships. Two cards demonstrate the same two states and
  /// additionally put the screen's own "Needs your attention" section on
  /// screen, which one card cannot.
  static ClientRequest _acMaintenance() => ClientRequest(
    id: 'mock-active-ac',
    status: ClientRequestStatus.draft,
    createdAt: DateTime(2028, 8, 22, 16),
    serviceId: 'svc-ac',
    serviceName: 'AC Maintenance',
    categoryId: 'cat-home',
    categoryName: 'Home Services',
    // No lat/lng — this is the missing address the pill names. No
    // `preferredAt` either: a half-finished draft has neither, and
    // `waitingOnKey` names the location blocker first, which is the pill
    // Figma draws.
    note: 'Annual servicing for four split units.',
  );

  /// Figma's `Scheduled` card (`8385:4513`): a booking with no live offers, so
  /// the middle row draws the date and area pills instead of an offer stack.
  static ClientRequest _carService() => ClientRequest(
    id: 'mock-scheduled-car',
    status: ClientRequestStatus.scheduled,
    createdAt: DateTime(2028, 8, 18, 11),
    serviceId: 'svc-car',
    serviceName: 'Car Service',
    categoryId: 'cat-auto',
    categoryName: 'Automotive',
    lat: 25.1,
    lng: 55.25,
    addressLine: 'Villa 12, Street 4, Dubai Hills',
    areaName: 'Dubai Hills',
    submittedAt: DateTime(2028, 8, 18, 12),
    scheduledAt: scheduledDay,
  );

  /// A second upcoming booking, so the `Upcoming requests` heading has a
  /// section under it rather than a single row.
  static ClientRequest _furnitureAssembly() => ClientRequest(
    id: 'mock-scheduled-furniture',
    status: ClientRequestStatus.scheduled,
    createdAt: DateTime(2028, 8, 19, 14),
    serviceId: 'svc-furniture',
    serviceName: 'Furniture Assembly',
    categoryId: 'cat-home',
    categoryName: 'Home Services',
    lat: 25.18,
    lng: 55.27,
    addressLine: 'Tower 2, Business Bay',
    areaName: 'Business Bay',
    submittedAt: DateTime(2028, 8, 19, 15),
    scheduledAt: DateTime(2028, 8, 30, 13),
  );

  /// Figma's `Cancelled` card (`8385:31898`): closed, so the trailing slot
  /// becomes Rebook and the header loses its Cancel control.
  static ClientRequest _movingService() => ClientRequest(
    id: 'mock-cancelled-moving',
    status: ClientRequestStatus.cancelled,
    createdAt: DateTime(2028, 8, 15, 8),
    serviceId: 'svc-moving',
    serviceName: 'Moving Service',
    categoryId: 'cat-logistics',
    categoryName: 'Logistics',
    lat: 25.1,
    lng: 55.25,
    addressLine: 'Villa 12, Street 4, Dubai Hills',
    areaName: 'Dubai Hills',
    submittedAt: DateTime(2028, 8, 15, 9),
    scheduledAt: scheduledDay,
    cancelReason: 'Moved the date and rebooked with another provider.',
  );
}

/// Serves [MockClientRequests] through the production repository interface.
///
/// Reads behave like the endpoint: `list` applies the same single-status
/// filter `GET /requests?status=` applies, and answers one full page, so the
/// bloc's own tab logic, including Active's client-side "everything the other
/// two tabs do not own" step — runs for real rather than being bypassed.
///
/// Writes are the honest part. `cancel` works, because cancelling from the
/// list is a thing a presenter shows; everything else answers a
/// [ServerFailure] rather than pretending, because a stand-in that silently
/// accepts a draft submission demonstrates something that does not exist.
class MockClientRequestsRepository implements ClientRequestsRepository {
  /// Creates the mock repository over [MockClientRequests.all].
  MockClientRequestsRepository() : _requests = MockClientRequests.all();

  /// Mutable so `cancel` really moves a row from Scheduled to Cancelled, as it
  /// would against the API.
  ///
  /// One instance per app run, because DI registers it as a lazy singleton: a
  /// cancellation therefore survives leaving the screen and coming back, which
  /// is what the real repository does too. A restart is what resets it.
  List<ClientRequest> _requests;

  static const _unsupported = ServerFailure(
    message: 'Not available against the mock backend.',
    code: 'MOCK_UNSUPPORTED',
  );

  @override
  TaskEither<Failure, Page<ClientRequest>> list(ClientRequestsQuery query) {
    final status = query.status;
    final items = status == null
        ? _requests
        : [
            for (final request in _requests)
              if (request.status == status) request,
          ];

    return TaskEither.right(
      Page<ClientRequest>(
        items: items,
        meta: PageMeta(
          totalItems: items.length,
          itemCount: items.length,
          itemsPerPage: query.limit,
          totalPages: 1,
          currentPage: 1,
        ),
      ),
    );
  }

  @override
  TaskEither<Failure, ClientRequest> getById(String id) {
    for (final request in _requests) {
      if (request.id == id) return TaskEither.right(request);
    }
    return TaskEither.left(
      const ServerFailure(message: 'No such request.', code: 'MOCK_NOT_FOUND'),
    );
  }

  @override
  TaskEither<Failure, ClientRequest> cancel(String id, String reason) {
    for (final request in _requests) {
      if (request.id != id) continue;
      final cancelled = request.copyWith(
        status: ClientRequestStatus.cancelled,
      );
      _requests = [
        for (final candidate in _requests)
          if (candidate.id == id) cancelled else candidate,
      ];
      return TaskEither.right(cancelled);
    }
    return TaskEither.left(
      const ServerFailure(message: 'No such request.', code: 'MOCK_NOT_FOUND'),
    );
  }

  @override
  TaskEither<Failure, ClientRequest> createDraft(SaveDraftParams params) =>
      TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> update(
    String id,
    SaveDraftParams params,
  ) => TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> submit(String id) =>
      TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> confirm(String id) =>
      TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> dispute(String id, String reason) =>
      TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> acceptOffer({
    required String requestId,
    required String offerId,
  }) => TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> rejectOffer({
    required String requestId,
    required String offerId,
  }) => TaskEither.left(_unsupported);

  @override
  TaskEither<Failure, ClientRequest> counterOffer({
    required String requestId,
    required String offerId,
    required CounterOfferRequest body,
  }) => TaskEither.left(_unsupported);
}
