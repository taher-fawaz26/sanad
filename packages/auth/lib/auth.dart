/// Authentication — login, logout, register, session, auth BLoC, and status.
library;

// Auth status
export 'src/auth/auth_status.dart';
export 'src/auth/auth_status_notifier.dart';
// Data — only types crossing the package boundary.
// `AuthLocalDataSource` is consumed by the OTP package.
// `LoginResponseModel` is consumed by the OTP data layer.
// `UserAdapter` is a Hive adapter registered by app bootstrap.
export 'src/data/datasources/auth_local_datasource.dart'
    show AuthLocalDataSource;
export 'src/data/models/adapter/user_adapter.dart';
export 'src/data/models/login_response_model.dart' show LoginResponseModel;
// DI
export 'src/di/auth_di.dart';
// Module
export 'src/module/auth_module.dart';
// Domain
export 'src/domain/entities/login_response_entity.dart';
export 'src/domain/entities/user_entity.dart';
export 'src/domain/enums/user_type.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/domain/usecases/check_signin_status_usecase.dart';
export 'src/domain/usecases/delete_account_usecase.dart';
export 'src/domain/usecases/login_usecase.dart';
export 'src/domain/usecases/logout_usecase.dart';
export 'src/domain/usecases/register_usecase.dart';
export 'src/domain/usecases/usecase_params.dart';
// Presentation
export 'src/presentation/bloc/auth/auth_bloc.dart';
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/register_page.dart';
export 'src/presentation/pages/splash_page.dart';
export 'src/presentation/widgets/app_header.dart';
// Routes
export 'src/routes/auth_routes.dart';
