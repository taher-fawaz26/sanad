import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_type.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/presentation/widgets/select_worker_action_sheet.dart';

class _MockGetWorkers extends Mock implements GetWorkersUseCase {}

Page<WorkerEntity> _page(List<WorkerEntity> items) => Page<WorkerEntity>(
  items: items,
  meta: PageMeta(
    totalItems: items.length,
    itemCount: items.length,
    itemsPerPage: 100,
    totalPages: 1,
    currentPage: 1,
  ),
);

void main() {
  late _MockGetWorkers useCase;

  setUpAll(() => registerFallbackValue(const WorkersQuery()));

  setUp(() {
    useCase = _MockGetWorkers();
    if (sl.isRegistered<GetWorkersUseCase>()) {
      sl.unregister<GetWorkersUseCase>();
    }
    sl.registerSingleton<GetWorkersUseCase>(useCase);
  });

  tearDown(() {
    if (sl.isRegistered<GetWorkersUseCase>()) {
      sl.unregister<GetWorkersUseCase>();
    }
  });

  testWidgets(
    'requests workers with type=worker (managers are excluded server-side)',
    (tester) async {
      when(
        () => useCase(any()),
      ).thenAnswer((_) => TaskEither.of(_page(const [])));

      await tester.binding.setSurfaceSize(const Size(1200, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showSelectWorkerActionSheet(context: context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final captured = verify(() => useCase(captureAny())).captured
          .cast<WorkersQuery>();
      expect(captured, isNotEmpty);
      expect(captured.last.type, WorkerType.worker);
      expect(captured.last.toQueryMap()['type'], 'worker');
    },
  );
}
