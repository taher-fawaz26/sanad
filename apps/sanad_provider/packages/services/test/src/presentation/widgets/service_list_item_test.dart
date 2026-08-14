import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/repositories/provider_services_repository.dart';
import 'package:services/src/domain/usecases/delete_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/service_list_item.dart';

// See workers/test/.../worker_list_item_test.dart for the full root-cause
// note: no EasyLocalization bootstrap (avoids a real SharedPreferences hang
// in this sandboxed test environment), and a matched design/surface size
// (avoids status-badge/text overflowing on the raw `.tr()` fallback key).

class _MockRepo extends Mock implements ProviderServicesRepository {}

final _activeService = ProviderServiceEntity(
  id: 's1',
  serviceId: 'catalog-1',
  serviceName: 'Plumbing service',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Home',
    description: null,
  ),
  description: 'Fixes pipes',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

final _longNameService = ProviderServiceEntity(
  id: 's2',
  serviceId: 'catalog-2',
  serviceName:
      'A very long plumbing and drainage maintenance service name that '
      'should never overflow the row',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Home',
    description: null,
  ),
  description: null,
  status: ProviderServiceStatus.inactive,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

const _surfaceSize = Size(900, 1200);

Future<void> _pump(
  WidgetTester tester, {
  required ServiceActionBloc actionBloc,
  ProviderServiceEntity? service,
  VoidCallback? onTap,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: _surfaceSize,
      minTextAdapt: true,
      builder: (_, _) => MaterialApp(
        theme: AppTheme.light(),
        home: BlocProvider<ServiceActionBloc>.value(
          value: actionBloc,
          child: Scaffold(
            body: ServiceListItem(
              service: service ?? _activeService,
              onTap: onTap,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSwipePane(
  WidgetTester tester, {
  String title = 'Plumbing service',
}) async {
  await tester.drag(find.text(title), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester, String actionLabelKey) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(actionLabelKey));
  await tester.pumpAndSettle();
}

void main() {
  group('ServiceListItem swipe actions', () {
    late _MockRepo repo;
    late ServiceActionBloc actionBloc;
    late SemanticsHandle semanticsHandle;

    setUp(() {
      repo = _MockRepo();
      actionBloc = ServiceActionBloc(
        deleteProviderServiceUseCase: DeleteProviderServiceUseCase(repo),
        setProviderServiceStatusUseCase: SetProviderServiceStatusUseCase(repo),
      );
      semanticsHandle = WidgetsBinding.instance.ensureSemantics();
    });

    tearDown(() {
      semanticsHandle.dispose();
      actionBloc.close();
    });

    testWidgets(
      'renders service name, status, revenue, requests, and thumbnail',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc);

        expect(find.text('Plumbing service'), findsOneWidget);
        expect(find.text('services.status_active'), findsOneWidget);
        expect(find.text('services.card_revenue'), findsOneWidget);
        expect(find.text('services.card_requests'), findsOneWidget);
        expect(find.byType(AppNetworkImage), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'exposes no More button / more_vert entry point',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc);

        expect(find.byIcon(Icons.more_vert), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'renders without overflow — no old large-card sections present',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc);

        expect(tester.takeException(), isNull);
        // The old card's category chip / description text / divider are gone.
        expect(find.byType(AppChip), findsNothing);
        expect(find.byType(Divider), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'long service names do not overflow',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc, service: _longNameService);

        expect(tester.takeException(), isNull);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'row tap invokes onTap',
      (tester) async {
        var tapped = false;
        await _pump(
          tester,
          actionBloc: actionBloc,
          onTap: () => tapped = true,
        );

        await tester.tap(find.text('Plumbing service'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'swipe reveals Edit / Pause / Delete for an active service',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc);

        await _openSwipePane(tester);

        expect(find.bySemanticsLabel('services.action_edit'), findsOneWidget);
        expect(
          find.bySemanticsLabel('services.action_pause'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('services.action_resume'),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel('services.action_delete'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'swipe reveals Resume for an inactive service',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc, service: _longNameService);

        await _openSwipePane(tester, title: _longNameService.serviceName);

        expect(
          find.bySemanticsLabel('services.action_resume'),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('services.action_pause'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Pause swipe action confirms then toggles status via the BLoC',
      (tester) async {
        when(
          () => repo.updateProviderServiceStatus(
            id: 's1',
            status: ProviderServiceStatus.inactive,
          ),
        ).thenAnswer(
          (_) => TaskEither.of(
            _activeService.copyWith(status: ProviderServiceStatus.inactive),
          ),
        );

        await _pump(tester, actionBloc: actionBloc);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('services.action_pause'));
        await _confirm(tester, 'services.pause_confirm');

        verify(
          () => repo.updateProviderServiceStatus(
            id: 's1',
            status: ProviderServiceStatus.inactive,
          ),
        ).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'Delete swipe action confirms then calls delete via the BLoC',
      (tester) async {
        when(
          () => repo.deleteProviderService('s1'),
        ).thenAnswer((_) => TaskEither.of(unit));

        await _pump(tester, actionBloc: actionBloc);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('services.action_delete'));
        await _confirm(tester, 'services.delete_confirm');

        verify(() => repo.deleteProviderService('s1')).called(1);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'cancelling the confirmation sheet does not call delete',
      (tester) async {
        await _pump(tester, actionBloc: actionBloc);
        await _openSwipePane(tester);

        await tester.tap(find.bySemanticsLabel('services.action_delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('common.cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => repo.deleteProviderService(any()));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
