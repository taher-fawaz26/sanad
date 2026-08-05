import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:organization_settings/organization_settings.dart';
import 'package:organization_settings/src/domain/entities/organization_contact_entity.dart';
import 'package:organization_settings/src/domain/usecases/get_organization_contact_usecase.dart';

class _MockGetContactUseCase extends Mock
    implements GetOrganizationContactUseCase {}

void main() {
  late _MockGetContactUseCase getContact;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getContact = _MockGetContactUseCase();
  });

  ContactInformationBloc build() =>
      ContactInformationBloc(getContact: getContact);

  blocTest<ContactInformationBloc, ContactInformationState>(
    'loads contact info: loading -> success',
    build: build,
    setUp: () {
      when(() => getContact(any())).thenAnswer(
        (_) => TaskEither.right(
          const OrganizationContactEntity(
            phone: '500000000',
            email: 'ops@sanad.ae',
            phoneVerified: true,
            emailVerified: true,
          ),
        ),
      );
    },
    act: (bloc) => bloc.add(const ContactInformationLoaded()),
    expect: () => [
      isA<ContactInformationState>().having(
        (s) => s.status,
        'status',
        RequestStatus.loading,
      ),
      isA<ContactInformationState>()
          .having((s) => s.status, 'status', RequestStatus.success)
          .having((s) => s.phone, 'phone', '500000000')
          .having((s) => s.email, 'email', 'ops@sanad.ae')
          .having((s) => s.phoneVerified, 'phoneVerified', isTrue)
          .having((s) => s.emailVerified, 'emailVerified', isTrue),
    ],
  );

  blocTest<ContactInformationBloc, ContactInformationState>(
    'load failure surfaces the failure',
    build: build,
    setUp: () {
      when(() => getContact(any())).thenAnswer(
        (_) => TaskEither.left(const ServerFailure(message: 'boom')),
      );
    },
    act: (bloc) => bloc.add(const ContactInformationLoaded()),
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.failure, isA<ServerFailure>());
    },
  );

  blocTest<ContactInformationBloc, ContactInformationState>(
    'refresh re-fetches contact info',
    build: build,
    setUp: () {
      when(() => getContact(any())).thenAnswer(
        (_) => TaskEither.right(
          const OrganizationContactEntity(
            phone: '500000001',
            phoneVerified: true,
          ),
        ),
      );
    },
    act: (bloc) => bloc.add(const ContactInformationRefreshed()),
    verify: (bloc) {
      expect(bloc.state.phone, '500000001');
      verify(() => getContact(any())).called(1);
    },
  );
}
