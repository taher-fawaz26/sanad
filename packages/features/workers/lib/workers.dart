/// Workers feature — domain, data, presentation, DI, and routes.
library;

// DI
export 'src/di/workers_di.dart';
// Domain — entities
export 'src/domain/entities/worker_entity.dart';
export 'src/domain/entities/worker_status.dart';
// Domain — repositories
export 'src/domain/repositories/worker_repository.dart';
// Domain — use cases
export 'src/domain/usecases/delete_worker_usecase.dart';
export 'src/domain/usecases/get_workers_usecase.dart';
export 'src/domain/usecases/update_worker_status_usecase.dart';
// Module & routes
export 'src/module/workers_module.dart';
export 'src/routes/worker_routes.dart';
// Presentation — bloc
export 'src/presentation/bloc/workers/workers_bloc.dart';
// Presentation — pages
export 'src/presentation/pages/worker_details_page.dart';
export 'src/presentation/pages/workers_page.dart';
// Presentation — widgets
export 'src/presentation/widgets/select_worker_action_sheet.dart';
export 'src/presentation/widgets/worker_actions_bottom_sheet.dart';
export 'src/presentation/widgets/worker_list_card.dart';
