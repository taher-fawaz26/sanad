// SAN-581 root-cause instrumentation.
//
// The bug report claims the two real entry points to Edit Service diverge:
//   PATH A: Services List --(swipe action)--> Edit Service --(swipe back)-->
//            correctly returns to Services List.
//   PATH B: Services List -> Service Details --("..." sheet -> Edit row)-->
//            Edit Service --(swipe back)--> exits the app instead of
//            returning to Service Details.
//
// Both paths call the exact same `editService()` helper
// (`context.push(ServiceRoutes.editFor(id))`), so the only REAL structural
// difference between them is that Path B interposes a real
// `ModalSheetRoute` — pushed with a raw, IMPERATIVE
// `Navigator.of(context, rootNavigator: true).push(...)` on the app's TRUE
// root navigator (see `sheet_navigation`'s `SheetNavigator.push`) — that is
// popped immediately before the `context.push` for Edit runs.
//
// go_router's own back-button handling
// (`GoRouterDelegate._findCurrentNavigators`, go_router 17.5.0) walks from
// the root navigator down into each StatefulShellRoute branch navigator, but
// ABORTS the walk entirely if it finds a "pageless route on top of the
// shell" (i.e. `ModalRoute.of(shellContext)?.isCurrent == false`) — which is
// EXACTLY what a root-level `ModalSheetRoute` looks like while it exists.
// `GoRouterDelegate.popRoute()` then only ever tries the ROOT navigator's own
// `maybePop()`, which reports nothing left to pop, and the delegate's
// `popRoute()` returns `false` — this is the PRECISE signal the platform
// embedder uses to decide "Flutter didn't handle this back gesture, exit the
// app". `tester.binding.handlePopRoute()` returns exactly that boolean, so it
// is asserted directly below rather than only inferring the bug from what
// ends up on screen.
//
// This test drives the REAL `editService()` helper, the REAL
// `ServiceListItem`/`AppSwipeAction` (Path A), the REAL
// `showServiceActionsBottomSheet`/`SheetNavigator` (Path B), and the REAL,
// already-fixed `EditServicePage` — inside a real `StatefulShellRoute`
// mirroring `services_module.dart`'s actual nesting
// (`/services` -> `:id` -> `edit`, all one branch navigator) — to get
// empirical evidence rather than inferring from the route declarations
// alone.
import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:media_upload/media_upload.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/add_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_primary_provider_service_image_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/domain/usecases/update_provider_service_description_usecase.dart';
import 'package:services/src/presentation/bloc/edit_service/edit_service_bloc.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_details/service_details_bloc.dart';
import 'package:services/src/presentation/bloc/service_images/service_images_bloc.dart';
import 'package:services/src/presentation/pages/edit_service_page.dart';
import 'package:services/src/presentation/widgets/edit_service_form_body.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';
import 'package:services/src/presentation/widgets/service_list_item.dart';
import 'package:text_optimization/text_optimization.dart';

class _MockRepository extends Mock implements ProviderServicesRepository {}

class _MockMediaUploadRepository extends Mock
    implements MediaUploadRepository {}

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

ProviderServiceEntity _service({
  String id = 'svc-1',
  List<ProviderServiceImageEntity> images = const [],
}) => ProviderServiceEntity(
  id: id,
  serviceId: 'catalog-1',
  serviceName: 'Wash Car',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Car',
    description: null,
  ),
  description: 'A description',
  status: ProviderServiceStatus.active,
  images: images,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late _MockRepository repository;
  late _MockMediaUploadRepository uploadRepository;
  late ServiceActionBloc actionBloc;

  setUp(() {
    repository = _MockRepository();
    uploadRepository = _MockMediaUploadRepository();
    actionBloc = ServiceActionBloc(
      deleteProviderServiceUseCase: DeleteProviderServiceUseCase(repository),
      setProviderServiceStatusUseCase: SetProviderServiceStatusUseCase(
        repository,
      ),
    );
    when(
      () => repository.getProviderService('svc-1'),
    ).thenReturn(TaskEither.right(_service()));

    sl
      ..registerFactory<EditServiceBloc>(
        () => EditServiceBloc(
          updateProviderServiceDescriptionUseCase:
              UpdateProviderServiceDescriptionUseCase(repository),
        ),
      )
      ..registerFactoryParam<MediaUploadBloc, MediaUploadConfig, void>(
        (config, _) =>
            MediaUploadBloc(repository: uploadRepository, config: config),
      )
      ..registerFactoryParam<ServiceImagesBloc, ProviderServiceEntity, void>(
        (initialService, _) => ServiceImagesBloc(
          addProviderServiceImageUseCase: AddProviderServiceImageUseCase(
            repository,
          ),
          deleteProviderServiceImageUseCase: DeleteProviderServiceImageUseCase(
            repository,
          ),
          setPrimaryProviderServiceImageUseCase:
              SetPrimaryProviderServiceImageUseCase(repository),
          initialService: initialService,
        ),
      )
      ..registerFactory<TextOptimizationCubit>(() {
        final textOptimizationRepository = _MockTextOptimizationRepository();
        when(
          () => textOptimizationRepository.optimize(any()),
        ).thenAnswer((_) => TaskEither.right(''));
        return TextOptimizationCubit(
          OptimizeTextUseCase(textOptimizationRepository),
        );
      });
  });

  tearDown(() async {
    await actionBloc.close();
    sl
      ..unregister<EditServiceBloc>()
      ..unregister<MediaUploadBloc>()
      ..unregister<ServiceImagesBloc>()
      ..unregister<TextOptimizationCubit>();
  });

  /// Real `StatefulShellRoute` shape matching `services_module.dart`:
  /// `/services` (list) -> `:id` (details) -> `edit`, all one branch
  /// navigator under a single `providerRootNavigatorKey`-style root. The
  /// leaf route is the REAL, already-fixed `EditServicePage`; the two
  /// ancestor pages are the minimum needed to exercise each REAL entry point
  /// (`ServiceListItem`'s swipe action for Path A; the REAL
  /// `showServiceActionsBottomSheet` for Path B).
  /// [canHandlePopLog], when supplied, records every `NavigationNotification`
  /// value the app would forward to
  /// `SystemNavigator.setFrameworkHandlesBack` — the ONE signal Android
  /// consults to decide whether to ask Flutter about a back gesture at all.
  /// Its LAST entry is the latched value at swipe time.
  ///
  /// [realAnimations] keeps the sheet's real exit transition (the default
  /// `disableAnimations: true` collapses it and can hide ordering races).
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    List<bool>? canHandlePopLog,
    bool realAnimations = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    if (!realAnimations) {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
    }
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('A RenderFlex overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    final rootKey = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/services',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => shell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/services',
                  builder: (context, state) =>
                      BlocProvider<ServiceActionBloc>.value(
                        value: actionBloc,
                        child: Scaffold(
                          body: ServiceListItem(service: _service()),
                        ),
                      ),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) =>
                          BlocProvider<ServiceActionBloc>.value(
                            value: actionBloc,
                            // `Builder` so `showServiceActionsBottomSheet`'s
                            // `context.read<ServiceActionBloc>()` (called
                            // from inside `onPressed`) resolves a context
                            // BELOW the BlocProvider above — the outer
                            // `builder`'s own `context` parameter sits ABOVE
                            // it and would fail to find the provider.
                            child: Scaffold(
                              body: Center(
                                child: Builder(
                                  builder: (innerContext) => TextButton(
                                    child: const Text('DETAILS_MORE_BUTTON'),
                                    onPressed: () =>
                                        showServiceActionsBottomSheet(
                                          context: innerContext,
                                          service: _service(),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (context, state) =>
                          BlocProvider<ServiceDetailsBloc>(
                            create: (_) => ServiceDetailsBloc(
                              getProviderServiceUseCase:
                                  GetProviderServiceUseCase(repository),
                            )..add(const ServiceDetailsFetchRequested('svc-1')),
                            child: const EditServicePage(serviceId: 'svc-1'),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 800),
        minTextAdapt: true,
        builder: (_, _) => MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          // Mirrors `WidgetsApp`'s own default handler, which is what calls
          // `SystemNavigator.setFrameworkHandlesBack(canHandlePop)`. Capturing
          // here records exactly what the platform would be told.
          onNavigationNotification: (notification) {
            canHandlePopLog?.add(notification.canHandlePop);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'PATH A: Services List -> swipe action -> Edit -> system back correctly '
    'returns to the List (handlePopRoute reports handled == true)',
    (tester) async {
      await pumpApp(tester);
      expect(find.byType(ServiceListItem), findsOneWidget);

      // Real `AppSwipeAction.onPressed` — the exact callback wired by
      // `ServiceListItem`, calling the exact same `editService()` helper Path
      // B uses.
      final swipeActions = tester.widget<AppSwipeActions>(
        find.byType(AppSwipeActions),
      );
      swipeActions.actions.first.onPressed();
      await tester.pumpAndSettle();

      expect(find.byType(EditServicePage), findsOneWidget);
      expect(find.byType(EditServiceFormBody), findsOneWidget);

      // The precise signal the platform embedder uses to decide whether to
      // exit the app: false == "Flutter did not handle this back gesture".
      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        handled,
        isTrue,
        reason:
            'GoRouterDelegate.popRoute() must report the back gesture as '
            'handled — false is exactly the condition under which the '
            'platform embedder exits the app.',
      );
      expect(find.byType(EditServicePage), findsNothing);
      expect(find.byType(ServiceListItem), findsOneWidget);
    },
  );

  testWidgets(
    'PATH B: Services List -> Service Details -> "..." sheet -> Edit row -> '
    'Edit -> system back must ALSO return to Details (not exit the app)',
    (tester) async {
      final router = await pumpApp(tester);

      unawaited(router.push('/services/svc-1'));
      await tester.pumpAndSettle();
      expect(find.text('DETAILS_MORE_BUTTON'), findsOneWidget);

      // Real `showServiceActionsBottomSheet` — a real `ModalSheetRoute`
      // pushed via `SheetNavigator` (raw imperative
      // `Navigator.of(context, rootNavigator: true).push`), exactly as
      // production code does.
      await tester.tap(find.text('DETAILS_MORE_BUTTON'));
      await tester.pumpAndSettle();
      expect(find.text('services.action_edit'), findsOneWidget);

      // Real `_onEditPressed`: pops the sheet, then calls the real
      // `editService()` helper — identical to Path A's call.
      await tester.tap(find.text('services.action_edit'));
      await tester.pumpAndSettle();

      expect(find.byType(EditServicePage), findsOneWidget);
      expect(find.byType(EditServiceFormBody), findsOneWidget);
      // The sheet's route must be fully gone by now (not lingering as a
      // "pageless route on top of the shell", which would make go_router's
      // own `_findCurrentNavigators()` abort before ever reaching Edit's
      // branch navigator).
      expect(find.byType(BottomSheet), findsNothing);

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        handled,
        isTrue,
        reason:
            'SAN-581: this must be true. false here is the EXACT mechanism '
            'behind "swipe-back exits the app" — go_router found no '
            'navigator willing to pop, which is what the platform embedder '
            'interprets as "let the OS handle it" (exit).',
      );
      expect(find.byType(EditServicePage), findsNothing);
      expect(find.text('DETAILS_MORE_BUTTON'), findsOneWidget);
    },
  );

  testWidgets(
    'PATH B variant: system back fired IMMEDIATELY after the sheet-driven '
    'push, with only a single pump (no settle) — the worst-case race between '
    "the sheet route's own removal and the next back gesture",
    (tester) async {
      final router = await pumpApp(tester);
      unawaited(router.push('/services/svc-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('DETAILS_MORE_BUTTON'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('services.action_edit'));
      // Deliberately only ONE pump — the sheet's reverse transition and the
      // new Edit page's enter transition may both still be mid-flight.
      await tester.pump();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        handled,
        isTrue,
        reason:
            'Even mid-transition, go_router must not report the back '
            'gesture as unhandled.',
      );
    },
  );

  // ── The ACTUAL failing layer ───────────────────────────────────────────
  //
  // `handlePopRoute()` above only exercises `Router.popRoute()` — what
  // happens once Android has ALREADY decided to ask Flutter. But with
  // `android:enableOnBackInvokedCallback="true"` (set in this app's
  // AndroidManifest), Android first consults a LATCHED boolean to decide
  // whether to ask Flutter at all. That boolean is pushed by
  // `WidgetsApp`'s default `onNavigationNotification` handler calling
  // `SystemNavigator.setFrameworkHandlesBack(canHandlePop)`.
  //
  // `NavigationNotification`s bubble UP the widget tree. The corrective
  // listener that rewrites `false -> true` lives INSIDE
  // `NavigatorState.build()` (navigator.dart ~5900), making it a DESCENDANT
  // of that Navigator's own element — while `_handleHistoryChanged()`
  // (navigator.dart ~3734) dispatches at the Navigator's OWN `context`.
  // A Navigator's own history change therefore bypasses its own corrective
  // listener AND every nested navigator beneath it, reaching `WidgetsApp`
  // uncorrected.
  //
  // The root navigator under `StatefulShellRoute` holds exactly one page
  // (the shell), so its `canPop()` is false and it dispatches
  // `canHandlePop: false`. `SheetNavigator.push` puts the actions sheet on
  // THAT root navigator; popping it mutates root history and emits that
  // `false` — and the sheet's exit transition outlives the synchronous
  // `context.push` of Edit, so `false` lands LAST and stays latched.
  //
  // Path A never touches the root navigator, so its last emission comes from
  // Edit's own PopScope and stays `true`. That is the entire path-dependence.
  group('latched back signal (setFrameworkHandlesBack)', () {
    testWidgets(
      'PATH A: last latched canHandlePop is TRUE — Android asks Flutter, so '
      'back works',
      (tester) async {
        final log = <bool>[];
        await pumpApp(tester, canHandlePopLog: log);

        final swipeActions = tester.widget<AppSwipeActions>(
          find.byType(AppSwipeActions),
        );
        swipeActions.actions.first.onPressed();
        await tester.pumpAndSettle();
        expect(find.byType(EditServicePage), findsOneWidget);

        // Sit on Edit, as the user did before swiping. Bounded pumps only —
        // the description field's AI-enhance button runs a perpetual
        // animation that never lets pumpAndSettle converge here.
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();

        expect(log, isNotEmpty);
        expect(
          log.last,
          isTrue,
          reason:
              'Path A latches true, which is why swipe-back works from the '
              'list-swipe entry point.',
        );
      },
    );

    testWidgets(
      'PATH B: last latched canHandlePop must be TRUE after the sheet closes '
      '— a latched FALSE is SAN-581 (Android exits without asking Flutter)',
      (tester) async {
        final log = <bool>[];
        final router = await pumpApp(tester, canHandlePopLog: log);

        unawaited(router.push('/services/svc-1'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('DETAILS_MORE_BUTTON'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('services.action_edit'));
        await tester.pumpAndSettle();

        expect(find.byType(EditServicePage), findsOneWidget);

        // Reproduce the reported repro exactly: WAIT on Edit, untouched,
        // before swiping. Nothing re-dispatches during this window, so
        // whatever was latched last is what Android will act on. Bounded
        // pumps only (perpetual AI-enhance animation never settles).
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();

        expect(log, isNotEmpty);
        expect(
          log.last,
          isTrue,
          reason:
              'SAN-581: latched=${log.last}, full=$log. '
              'A latched false means Android exits the app on the next back '
              'gesture WITHOUT ever calling into Flutter — which is why no '
              'PopScope/go_router change can rescue it.',
        );
      },
    );
  });
}
