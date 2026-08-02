import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:maps/maps.dart';
import 'package:maps/src/domain/repositories/locations_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationsRepository extends Mock implements LocationsRepository {}

void main() {
  late _MockLocationsRepository repository;
  late GetCitiesUseCase useCase;

  const uaeCountry = CountryEntity(
    id: 'country-ae-id',
    nameEn: 'United Arab Emirates',
    nameAr: 'الإمارات العربية المتحدة',
    code: 'AE',
  );

  const otherCountry = CountryEntity(
    id: 'country-other-id',
    nameEn: 'Other Country',
    nameAr: 'دولة أخرى',
    code: 'XX',
  );

  const cities = [
    CityEntity(id: 'city-dubai', nameEn: 'Dubai', nameAr: 'دبي'),
    CityEntity(id: 'city-abudhabi', nameEn: 'Abu Dhabi', nameAr: 'أبوظبي'),
  ];

  setUp(() {
    repository = _MockLocationsRepository();
    useCase = GetCitiesUseCase(repository);
  });

  group('GetCitiesUseCase', () {
    test('fetches cities for the single returned country', () async {
      when(
        () => repository.getCountries(),
      ).thenReturn(TaskEither.right([uaeCountry]));
      when(
        () => repository.getCities(countryId: uaeCountry.id),
      ).thenReturn(TaskEither.right(cities));

      final result = await useCase(const NoParams()).run();

      expect(result.isRight(), true);
      expect(result.getOrElse((_) => []), cities);
      verify(() => repository.getCities(countryId: uaeCountry.id)).called(1);
    });

    test(
      'returns LocationsNoCountryFailure when countries list is empty',
      () async {
        when(() => repository.getCountries()).thenReturn(TaskEither.right([]));

        final result = await useCase(const NoParams()).run();

        expect(result.isLeft(), true);
        result.fold(
          (f) => expect(f, isA<LocationsNoCountryFailure>()),
          (_) => fail('expected Left'),
        );
        verifyNever(
          () => repository.getCities(countryId: any(named: 'countryId')),
        );
      },
    );

    test(
      'fetches cities for the first country when multiple are returned',
      () async {
        when(
          () => repository.getCountries(),
        ).thenReturn(TaskEither.right([uaeCountry, otherCountry]));
        when(
          () => repository.getCities(countryId: uaeCountry.id),
        ).thenReturn(TaskEither.right(cities));

        final result = await useCase(const NoParams()).run();

        expect(result.isRight(), true);
        expect(result.getOrElse((_) => []), cities);
        verify(() => repository.getCities(countryId: uaeCountry.id)).called(1);
        verifyNever(
          () => repository.getCities(countryId: otherCountry.id),
        );
      },
    );

    test('propagates failure from getCountries', () async {
      const failure = NetworkFailure(message: 'offline');
      when(
        () => repository.getCountries(),
      ).thenReturn(TaskEither.left(failure));

      final result = await useCase(const NoParams()).run();

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, failure),
        (_) => fail('expected Left'),
      );
    });

    test('propagates failure from getCities', () async {
      const failure = ServerFailure(message: 'internal error');
      when(
        () => repository.getCountries(),
      ).thenReturn(TaskEither.right([uaeCountry]));
      when(
        () => repository.getCities(countryId: uaeCountry.id),
      ).thenReturn(TaskEither.left(failure));

      final result = await useCase(const NoParams()).run();

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, failure),
        (_) => fail('expected Left'),
      );
    });
  });
}
