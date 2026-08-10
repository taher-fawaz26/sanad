import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:invitation/src/domain/entities/invitation_preview_entity.dart';
import 'package:invitation/src/domain/entities/invitation_status.dart';
import 'package:invitation/src/domain/usecases/usecase_params.dart';
import 'package:invitation/src/domain/usecases/verify_invitation_token_usecase.dart';
import 'package:invitation/src/presentation/bloc/invitation_details_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockVerifyInvitationTokenUseCase extends Mock
    implements VerifyInvitationTokenUseCase {}

void main() {
  late _MockVerifyInvitationTokenUseCase useCase;

  const token = '11111111-1111-1111-1111-111111111111';

  setUp(() {
    useCase = _MockVerifyInvitationTokenUseCase();
  });

  blocTest<InvitationDetailsCubit, InvitationDetailsState>(
    'emits [Loading, Loaded] when the token resolves valid',
    build: () => InvitationDetailsCubit(useCase),
    setUp: () {
      const preview = InvitationPreview(
        valid: true,
        email: 'worker@example.com',
        providerName: 'Horizon Ventures',
      );
      when(() => useCase(const InvitationTokenParams(token: token))).thenReturn(
        TaskEither.right(preview),
      );
    },
    act: (cubit) => cubit.loadToken(token),
    expect: () => [
      const InvitationDetailsLoading(),
      const InvitationDetailsLoaded(
        InvitationPreview(
          valid: true,
          email: 'worker@example.com',
          providerName: 'Horizon Ventures',
        ),
      ),
    ],
  );

  blocTest<InvitationDetailsCubit, InvitationDetailsState>(
    'emits [Loading, Invalid] when the token resolves valid: false',
    build: () => InvitationDetailsCubit(useCase),
    setUp: () {
      const preview = InvitationPreview(
        valid: false,
        status: InvitationStatus.expired,
      );
      when(() => useCase(const InvitationTokenParams(token: token))).thenReturn(
        TaskEither.right(preview),
      );
    },
    act: (cubit) => cubit.loadToken(token),
    expect: () => [
      const InvitationDetailsLoading(),
      const InvitationDetailsInvalid(
        InvitationPreview(valid: false, status: InvitationStatus.expired),
      ),
    ],
  );

  blocTest<InvitationDetailsCubit, InvitationDetailsState>(
    'emits [Loading, Failure] when the call itself fails',
    build: () => InvitationDetailsCubit(useCase),
    setUp: () {
      when(() => useCase(const InvitationTokenParams(token: token))).thenReturn(
        TaskEither.left(const ValidationFailure(message: 'bad token')),
      );
    },
    act: (cubit) => cubit.loadToken(token),
    expect: () => [
      const InvitationDetailsLoading(),
      const InvitationDetailsFailure(ValidationFailure(message: 'bad token')),
    ],
  );
}
