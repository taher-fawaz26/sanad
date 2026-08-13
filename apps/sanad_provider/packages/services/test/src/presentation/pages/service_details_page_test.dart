import 'package:core/core.dart';
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
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';
import 'package:services/src/domain/usecases/set_provider_service_status_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/pages/service_details_page.dart';
import 'package:shared_ui/shared_ui.dart';

// No EasyLocalization bootstrap (avoids a real SharedPreferences hang in this
// sandboxed test environment) — `.tr()` calls fall back to the raw key.

class _MockRepository extends Mock implements ProviderServicesRepository {}

final _service = ProviderServiceEntity(
  id: 'svc-1',
  serviceId: 'catalog-1',
  serviceName: 'Leak Detection & Repair',
  category: const CategoryRefEntity(
    id: 'cat-1',
    name: 'Plumbing',
    description: null,
  ),
  description: 'Fixes leaks',
  status: ProviderServiceStatus.active,
  images: const [],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  requests: 42,
  revenue: 1500,
);

const _surfaceSize = Size(1200, 1600);

void main() {
  late _MockRepository repository;
  late ServiceActionBloc actionBloc;

  setUp(() {
    repository = _MockRepository();
    actionBloc = ServiceActionBloc(
      deleteProviderServiceUseCase: DeleteProviderServiceUseCase(repository),
      setProviderServiceStatusUseCase: SetProviderServiceStatusUseCase(
        repository,
      ),
    );
  });

  tearDown(() async {
    await actionBloc.close();
  });

  Future<void> pump(WidgetTester tester) async {
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
            child: const ServiceDetailsPage(serviceId: 'svc-1'),
          ),
        ),
      ),
    );
  }

  group('ServiceDetailsPage', () {
    testWidgets(
      'fetches the service by id (GET /provider-services/:id) instead of '
      'trusting a passed-in list row',
      (tester) async {
        when(
          () => repository.getProviderService('svc-1'),
        ).thenReturn(TaskEither.right(_service));
        sl.registerLazySingleton<GetProviderServiceUseCase>(
          () => GetProviderServiceUseCase(repository),
        );
        addTearDown(() => sl.unregister<GetProviderServiceUseCase>());

        await pump(tester);
        await tester.pump(); // let the fetch future resolve
        await tester.pumpAndSettle();

        verify(() => repository.getProviderService('svc-1')).called(1);
        expect(find.text('Leak Detection & Repair'), findsWidgets);
        expect(find.text('Plumbing'), findsWidgets);
      },
    );

    testWidgets(
      'shows requests/revenue from the fetched entity (not the removed '
      'per-service overview endpoint)',
      (tester) async {
        when(
          () => repository.getProviderService('svc-1'),
        ).thenReturn(TaskEither.right(_service));
        sl.registerLazySingleton<GetProviderServiceUseCase>(
          () => GetProviderServiceUseCase(repository),
        );
        addTearDown(() => sl.unregister<GetProviderServiceUseCase>());

        await pump(tester);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('42'), findsOneWidget);
        expect(find.text('1,500'), findsOneWidget);
      },
    );

    testWidgets(
      'a failed fetch shows a retryable error state; retry re-fetches',
      (tester) async {
        var callCount = 0;
        when(() => repository.getProviderService('svc-1')).thenAnswer((_) {
          callCount++;
          return callCount == 1
              ? TaskEither.left(const ServerFailure(message: 'boom'))
              : TaskEither.right(_service);
        });
        sl.registerLazySingleton<GetProviderServiceUseCase>(
          () => GetProviderServiceUseCase(repository),
        );
        addTearDown(() => sl.unregister<GetProviderServiceUseCase>());

        await pump(tester);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Leak Detection & Repair'), findsNothing);

        final errorState = tester.widget<AppErrorState>(
          find.byType(AppErrorState),
        );
        errorState.onRetry?.call();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(callCount, 2);
        expect(find.text('Leak Detection & Repair'), findsWidgets);
      },
    );
  });
}
