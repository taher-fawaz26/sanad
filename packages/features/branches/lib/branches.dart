/// Branches feature — list, create, update, and delete provider branches.
///
/// Public API surface:
/// * Register the module: add [BranchesModule] to the app [ModuleRegistry].
/// * Navigate via [BranchRoutes] constants.
/// * Consume domain data through [BranchEntity] and [PaginatedBranchesEntity].
/// * Manage state via [BranchesBloc] (list) and [AddBranchBloc] (create).
library;

export 'src/di/branches_di.dart';
export 'src/domain/entities/branch_availability_entity.dart';
export 'src/domain/entities/branch_entity.dart';
export 'src/domain/entities/branch_time_slot_entity.dart';
export 'src/domain/entities/paginated_branches_entity.dart';
export 'src/domain/repositories/branch_repository.dart';
export 'src/domain/usecases/branch_usecase_params.dart';
export 'src/domain/usecases/create_branch_usecase.dart';
export 'src/domain/usecases/delete_branch_usecase.dart';
export 'src/domain/usecases/get_branch_usecase.dart';
export 'src/domain/usecases/get_branches_usecase.dart';
export 'src/domain/usecases/update_branch_usecase.dart';
export 'src/module/branches_module.dart';
export 'src/presentation/bloc/add_branch/add_branch_bloc.dart';
export 'src/presentation/bloc/branches/branches_bloc.dart';
export 'src/presentation/pages/add_branch_page.dart';
export 'src/presentation/pages/branches_page.dart';
export 'src/routes/branch_routes.dart';
