import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:notifications/notifications.dart';
import 'package:testing/testing.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

AppNotification _notification({
  String id = 'notif-1',
  bool unread = true,
  NotificationSubject subject = NotificationSubject.none,
}) => AppNotification(
  id: id,
  type: NotificationType.requestMatched,
  title: 'Providers matched',
  body: 'Three providers can help.',
  createdAt: DateTime(2026, 9, 12, 10),
  subject: subject,
  readAt: unread ? null : DateTime(2026, 9, 12, 11),
);

NotificationsFeed _feed({
  List<AppNotification>? items,
  int unreadCount = 1,
  int totalPages = 1,
  int currentPage = 1,
}) {
  final rows = items ?? [_notification()];
  return NotificationsFeed(
    page: Page<AppNotification>(
      items: rows,
      meta: PageMeta(
        totalItems: rows.length,
        itemCount: rows.length,
        itemsPerPage: 20,
        totalPages: totalPages,
        currentPage: currentPage,
      ),
    ),
    unreadCount: unreadCount,
  );
}

void main() {
  setUpAll(() => registerFallbackValue(const NotificationsQuery()));

  late _MockRepository repository;

  NotificationsBloc build() => NotificationsBloc(
    getNotifications: GetNotificationsUseCase(repository),
    markRead: MarkNotificationReadUseCase(repository),
    markAllRead: MarkAllNotificationsReadUseCase(repository),
  );

  setUp(() {
    repository = _MockRepository();
    when(() => repository.markRead(any())).thenReturn(TaskEither.right(null));
    when(() => repository.markAllRead()).thenReturn(TaskEither.right(null));
  });

  group('loading', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'loads the first page and the server unread count together',
      setUp: () => when(
        () => repository.getNotifications(any()),
      ).thenReturn(TaskEither.right(_feed(unreadCount: 4))),
      build: build,
      act: (bloc) => bloc.add(const NotificationsStarted()),
      verify: (bloc) {
        expect(bloc.state.data.status, RequestStatus.success);
        expect(bloc.state.data.items, hasLength(1));
        // The endpoint returns unreadCount beside the envelope, so the bell
        // badge needs no second request.
        expect(bloc.state.unreadCount, 4);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'surfaces a first-page failure without losing the list state',
      setUp: () => when(() => repository.getNotifications(any())).thenReturn(
        TaskEither.left(const NoInternetFailure(message: 'errors.no_internet')),
      ),
      build: build,
      act: (bloc) => bloc.add(const NotificationsStarted()),
      verify: (bloc) {
        expect(bloc.state.data.status, RequestStatus.failure);
        expect(bloc.state.data.firstPageError, isA<NoInternetFailure>());
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'requests page 1 with the default capped limit',
      setUp: () => when(
        () => repository.getNotifications(any()),
      ).thenReturn(TaskEither.right(_feed())),
      build: build,
      act: (bloc) => bloc.add(const NotificationsStarted()),
      verify: (_) {
        final query =
            verify(
                  () => repository.getNotifications(captureAny()),
                ).captured.single
                as NotificationsQuery;
        expect(query.page, 1);
        expect(query.toQueryMap()['limit'], lessThanOrEqualTo(kMaxPageLimit));
      },
    );
  });

  group('mark read', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'un-bolds the row immediately and decrements the badge',
      setUp: () => when(
        () => repository.getNotifications(any()),
      ).thenReturn(TaskEither.right(_feed(unreadCount: 3))),
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationMarkedRead('notif-1'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.data.items.single.isUnread, isFalse);
        expect(bloc.state.unreadCount, 2);
        verify(() => repository.markRead('notif-1')).called(1);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'does not re-mark an already-read row',
      setUp: () => when(() => repository.getNotifications(any())).thenReturn(
        TaskEither.right(
          _feed(items: [_notification(unread: false)], unreadCount: 0),
        ),
      ),
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationMarkedRead('notif-1'));
      },
      wait: const Duration(milliseconds: 50),
      verify: (_) => verifyNever(() => repository.markRead(any())),
    );

    blocTest<NotificationsBloc, NotificationsState>(
      're-reads from the server when marking read fails',
      setUp: () {
        when(
          () => repository.getNotifications(any()),
        ).thenReturn(TaskEither.right(_feed(unreadCount: 3)));
        when(() => repository.markRead(any())).thenReturn(
          TaskEither.left(const ServerFailure(message: 'boom')),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationMarkedRead('notif-1'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        // Rather than hand-rolling a rollback: the server is the authority on
        // read state, so re-read it.
        verify(() => repository.getNotifications(any())).called(2);
      },
    );
  });

  group('mark all read', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'refetches so the badge comes from the server, not local arithmetic',
      setUp: () => when(
        () => repository.getNotifications(any()),
      ).thenReturn(TaskEither.right(_feed(unreadCount: 0))),
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationsAllMarkedRead());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.markAllStatus, RequestStatus.success);
        verify(() => repository.markAllRead()).called(1);
        verify(() => repository.getNotifications(any())).called(2);
      },
    );

    blocTest<NotificationsBloc, NotificationsState>(
      'exposes a mark-all failure for the UI to surface',
      setUp: () {
        when(
          () => repository.getNotifications(any()),
        ).thenReturn(TaskEither.right(_feed()));
        when(() => repository.markAllRead()).thenReturn(
          TaskEither.left(const ServerFailure(message: 'boom')),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationsAllMarkedRead());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.markAllStatus, RequestStatus.failure);
        expect(bloc.state.markAllFailure, isA<ServerFailure>());
      },
    );
  });

  group('pagination', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'appends the next page and dedupes by notification id',
      setUp: () {
        var call = 0;
        when(() => repository.getNotifications(any())).thenAnswer((_) {
          call++;
          return call == 1
              ? TaskEither.right(
                  _feed(items: [_notification()], totalPages: 2),
                )
              : TaskEither.right(
                  _feed(
                    // The first row repeats because the backing list shifted
                    // between requests; it must not render twice.
                    items: [
                      _notification(),
                      _notification(id: 'notif-2'),
                    ],
                    totalPages: 2,
                    currentPage: 2,
                  ),
                );
        });
      },
      build: build,
      act: (bloc) async {
        bloc.add(const NotificationsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationsNextPageRequested());
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.data.items.map((e) => e.id), ['notif-1', 'notif-2']);
      },
    );
  });
}
