/// Services feature — list provider services and select via action sheet.
///
/// Public API surface:
/// * Register the module: add [ServicesModule] to the app [ModuleRegistry].
/// * Load services via [GetServicesUseCase].
/// * Show picker: [showSelectServiceActionSheet].
/// * Provider dashboard UI: [ProviderServicesPage].
library;

export 'src/di/services_di.dart';
export 'src/domain/entities/service_entity.dart';
export 'src/domain/repositories/service_repository.dart';
export 'src/domain/usecases/get_services_usecase.dart';
export 'src/module/services_module.dart';
export 'src/presentation/models/provider_service_card_data.dart';
export 'src/presentation/pages/add_service_page.dart';
export 'src/presentation/pages/request_new_service_page.dart';
export 'src/presentation/pages/services_page.dart';
export 'src/presentation/widgets/select_service_action_sheet.dart';
export 'src/presentation/widgets/select_service_name_sheet.dart';
export 'src/presentation/widgets/service_list_card.dart';
export 'src/presentation/widgets/service_metrics_section.dart';
export 'src/presentation/widgets/service_provider_card.dart';
export 'src/presentation/widgets/services_empty_state.dart';
export 'src/presentation/widgets/services_filter_bar.dart';
export 'src/routes/service_routes.dart';
