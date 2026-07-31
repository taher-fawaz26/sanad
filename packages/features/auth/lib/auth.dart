/// Authentication — passwordless email OTP, session, auth BLoC, and status.
library;

export 'src/auth/auth_status.dart';
export 'src/auth/auth_status_notifier.dart';
export 'src/data/datasources/auth_local_datasource.dart'
    show AuthLocalDataSource;
export 'src/data/models/adapter/user_adapter.dart';
export 'src/di/auth_di.dart';
export 'src/domain/entities/auth_profile_entity.dart';
export 'src/domain/entities/email_auth_result.dart';
export 'src/domain/entities/user_entity.dart';
export 'src/domain/enums/user_type.dart';
export 'src/domain/repositories/auth_repository.dart';
export 'src/domain/usecases/check_signin_status_usecase.dart';
export 'src/domain/usecases/delete_account_usecase.dart';
export 'src/domain/usecases/logout_usecase.dart';
export 'src/domain/usecases/request_email_otp_usecase.dart';
export 'src/domain/usecases/sign_in_with_google_usecase.dart';
export 'src/domain/usecases/usecase_params.dart';
export 'src/domain/usecases/verify_email_otp_usecase.dart';
export 'src/module/auth_module.dart';
export 'src/presentation/bloc/auth/auth_bloc.dart';
export 'src/presentation/pages/email_otp_page.dart';
export 'src/presentation/pages/login_page.dart';
export 'src/presentation/pages/splash_page.dart';
export 'src/presentation/widgets/app_header.dart';
export 'src/routes/auth_routes.dart';
export 'src/routing/auth_shell.dart';
