/// Workers feature — list provider workers and select via action sheet.
///
/// Public API surface:
/// * Register the module: add [WorkersModule] to the app [ModuleRegistry].
/// * Load workers via [GetWorkersUseCase].
/// * Show picker: [showSelectWorkerActionSheet].
library;

export 'src/di/workers_di.dart';
export 'src/domain/entities/worker_entity.dart';
export 'src/domain/repositories/worker_repository.dart';
export 'src/domain/usecases/get_workers_usecase.dart';
export 'src/module/workers_module.dart';
export 'src/presentation/widgets/select_worker_action_sheet.dart';
export 'src/presentation/widgets/worker_list_card.dart';
