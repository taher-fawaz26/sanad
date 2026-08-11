import 'package:core/core.dart';
import 'package:sanad_provider/src/features/invitation/src/data/datasources/invitation_remote_datasource.dart';
import 'package:sanad_provider/src/features/invitation/src/data/repositories/invitation_repository_impl.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/repositories/invitation_repository.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/accept_invitation_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/get_invitation_resend_info_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/request_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/resend_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/verify_invitation_token_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/presentation/bloc/invitation_details_cubit.dart';
import 'package:network/network.dart';

class InvitationDI {
  InvitationDI._();

  static void init() {
    sl
      ..registerLazySingleton<InvitationRemoteDataSource>(
        () => InvitationRemoteDataSourceImpl(sl<BaseApiClient>()),
      )
      ..registerLazySingleton<InvitationRepository>(
        () => InvitationRepositoryImpl(sl<InvitationRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => VerifyInvitationTokenUseCase(sl<InvitationRepository>()),
      )
      ..registerLazySingleton(
        () => RequestInvitationOtpUseCase(sl<InvitationRepository>()),
      )
      ..registerLazySingleton(
        () => ResendInvitationOtpUseCase(sl<InvitationRepository>()),
      )
      ..registerLazySingleton(
        () => GetInvitationResendInfoUseCase(sl<InvitationRepository>()),
      )
      ..registerLazySingleton(
        () => AcceptInvitationUseCase(sl<InvitationRepository>()),
      )
      ..registerFactory(
        () => InvitationDetailsCubit(sl<VerifyInvitationTokenUseCase>()),
      );
  }
}
