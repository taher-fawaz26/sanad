import 'package:core/core.dart' hide Page;
import 'package:core/core.dart' as core show Page;
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:storage/storage.dart' show HiveBoxes;
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/repositories/worker_repository.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/widgets/invitation_list_item.dart';
import 'package:workers/src/presentation/widgets/invitations_content.dart';

import '../../../support/fake_hive_local_storage.dart';

// No EasyLocalization bootstrap — `.tr()` falls back to raw keys, matching
// the sibling `workers_page_test.dart`/`invitation_list_item_test.dart`.
//
// The animation/timing/cancellation mechanics themselves are covered by the
// shared driver's own suite
// (design_system/test/src/components/app_swipe_action_hint_test.dart) —
// these tests only verify this widget wires it correctly.

class _MockRepo extends Mock implements WorkerRepository {}

const _invitation = InvitationEntity(
  id: 'i-1',
  fullName: 'Sara',
  role: 'Worker',
  initials: 'S',
);

core.Page<InvitationEntity> _onePage() => const core.Page(
  items: [_invitation],
  meta: PageMeta(
    totalItems: 1,
    itemCount: 1,
    itemsPerPage: 10,
    totalPages: 1,
    currentPage: 1,
  ),
);

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const InvitationsQuery());
  });

  setUp(() {
    repo = _MockRepo();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final invitationsListBloc = InvitationsListBloc(
      getInvitationsUseCase: GetInvitationsUseCase(repo),
    )..add(const InvitationsListFetchEvent());
    final invitationActionCubit = InvitationActionCubit(
      resendInvitationUseCase: ResendInvitationUseCase(repo),
      cancelInvitationUseCase: CancelInvitationUseCase(repo),
      deleteInvitationUseCase: DeleteInvitationUseCase(repo),
    );
    addTearDown(() {
      invitationsListBloc.close();
      invitationActionCubit.close();
    });

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<InvitationsListBloc>.value(
                value: invitationsListBloc,
              ),
              BlocProvider<InvitationActionCubit>.value(
                value: invitationActionCubit,
              ),
            ],
            child: const Scaffold(body: InvitationsContent()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('InvitationsContent — swipe discoverability hint wiring', () {
    testWidgets(
      'unseen: the first row is wrapped in the shared AppSwipeActionHint '
      'driver',
      (tester) async {
        registerFakeHiveLocalStorage();
        when(
          () => repo.getInvitations(any()),
        ).thenAnswer((_) => TaskEither.of(_onePage()));

        await pump(tester);
        await tester.pump();

        expect(find.byType(AppSwipeActionHint), findsOneWidget);
      },
    );

    testWidgets(
      'already seen: no AppSwipeActionHint is mounted — the row renders as '
      'a plain InvitationListItem',
      (tester) async {
        registerFakeHiveLocalStorage(hintSeen: true);
        when(
          () => repo.getInvitations(any()),
        ).thenAnswer((_) => TaskEither.of(_onePage()));

        await pump(tester);
        await tester.pump();

        expect(find.byType(AppSwipeActionHint), findsNothing);
        expect(find.byType(InvitationListItem), findsOneWidget);
      },
    );

    testWidgets(
      'a real swipe on the row cancels the hint and persists it as seen',
      (tester) async {
        final storage = registerFakeHiveLocalStorage();
        when(
          () => repo.getInvitations(any()),
        ).thenAnswer((_) => TaskEither.of(_onePage()));

        await pump(tester);
        await tester.pump();
        expect(find.byType(AppSwipeActionHint), findsOneWidget);

        await tester.drag(find.text('Sara'), const Offset(-300, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => storage.save(
            key: StorageKeys.invitationsSwipeHintSeen,
            value: true,
            boxName: HiveBoxes.defaultBox,
          ),
        ).called(1);
      },
    );

    testWidgets(
      'an empty invitations list makes the hint self-abort without '
      'throwing',
      (tester) async {
        registerFakeHiveLocalStorage();
        when(() => repo.getInvitations(any())).thenAnswer(
          (_) => TaskEither.of(const core.Page<InvitationEntity>.empty()),
        );

        await pump(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.byType(AppSwipeActionHint), findsNothing);
      },
    );
  });
}
