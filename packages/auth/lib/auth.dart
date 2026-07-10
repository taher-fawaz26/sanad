/// routing, and auth status tracking.
library;

// Auth status
export 'src/auth/auth_status.dart';
export 'src/auth/auth_status_notifier.dart';
// Data â€” models (public for app-level DI / testing)
export 'src/data/datasources/auth_local_datasource.dart';
export 'src/data/datasources/auth_remote_datasource.dart';
export 'src/data/models/adapter/user_adapter.dart';
export 'src/data/models/auth_otp_purpose.dart';
export 'src/data/models/login_response_model.dart';
export 'src/data/models/user_model.dart';
export 'src/data/repositories/auth_repository_impl.dart';
// DI
export 'src/di/auth_di.dart';
// Domain â€” entities
export 'src/domain/entities/login_response_entity.dart';
export 'src/domain/entities/user_entity.dart';
export 'src/domain/enums/user_type.dart';
// Domain â€” repository contract
export 'src/domain/repositories/auth_repository.dart';
// Domain â€” use cases
export 'src/domain/usecases/check_signin_status_usecase.dart';
export 'src/domain/usecases/delete_account_usecase.dart';
export 'src/domain/usecases/login_usecase.dart';
export 'src/domain/usecases/logout_usecase.dart';
export 'src/domain/usecases/register_usecase.dart';
export 'src/domain/usecases/request_forgot_password_usecase.dart';
export 'src/domain/usecases/resend_otp_usecase.dart';
export 'src/domain/usecases/reset_password_usecase.dart';
export 'src/domain/usecases/usecase_params.dart';
export 'src/domain/usecases/validate_otp_usecase.dart';
export 'src/domain/usecases/verify_forgot_password_otp_usecase.dart';
// Presentation — BLoC
export 'src/presentation/bloc/auth/auth_bloc.dart';
// Presentation — Pages
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/splash_page.dart';
// Routes
export 'src/routes/auth_routes.dart';
