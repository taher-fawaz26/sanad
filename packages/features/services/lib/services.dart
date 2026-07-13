/// Services feature — list provider services and select via action sheet.
///
/// Public API surface:
/// * Register the module: add [ServicesModule] to the app [ModuleRegistry].
/// * Load services via [GetServicesUseCase].
/// * Show picker: [showSelectServiceActionSheet].
library;

export 'src/di/services_di.dart';
export 'src/domain/entities/service_entity.dart';
export 'src/domain/repositories/service_repository.dart';
export 'src/domain/usecases/get_services_usecase.dart';
export 'src/module/services_module.dart';
export 'src/presentation/widgets/select_service_action_sheet.dart';
