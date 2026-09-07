import 'package:bloc_test/bloc_test.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_location_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocationService extends Mock implements LocationService {}

void main() {
  late _MockLocationService locationService;

  setUp(() {
    locationService = _MockLocationService();
  });

  AddBranchLocationBloc buildCubit() => AddBranchLocationBloc(locationService);

  group('AddBranchLocationBloc', () {
    test('initial state has not checked yet', () {
      final cubit = buildCubit();
      expect(cubit.state.hasChecked, isFalse);
      expect(cubit.state.isGranted, isFalse);
      expect(cubit.state.isBlocked, isFalse);
      cubit.close();
    });

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'ensureAccess emits granted directly when already granted',
      setUp: () => when(locationService.checkPermission).thenAnswer(
        (_) async => LocationPermissionStatus.granted,
      ),
      build: buildCubit,
      act: (cubit) => cubit.ensureAccess(),
      expect: () => [
        isA<AddBranchLocationState>().having(
          (s) => s.isGranted,
          'isGranted',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(locationService.requestPermission);
      },
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'ensureAccess requests the native prompt when merely denied, '
      'then emits the request outcome (SAN-603)',
      setUp: () {
        when(locationService.checkPermission).thenAnswer(
          (_) async => LocationPermissionStatus.denied,
        );
        when(locationService.requestPermission).thenAnswer(
          (_) async => LocationPermissionStatus.granted,
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.ensureAccess(),
      expect: () => [
        isA<AddBranchLocationState>().having(
          (s) => s.isGranted,
          'isGranted',
          isTrue,
        ),
      ],
      verify: (_) {
        verify(locationService.requestPermission).called(1);
      },
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'ensureAccess stays denied when the user dismisses the native prompt',
      setUp: () {
        when(locationService.checkPermission).thenAnswer(
          (_) async => LocationPermissionStatus.denied,
        );
        when(locationService.requestPermission).thenAnswer(
          (_) async => LocationPermissionStatus.denied,
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.ensureAccess(),
      expect: () => [
        isA<AddBranchLocationState>()
            .having((s) => s.isGranted, 'isGranted', isFalse)
            .having((s) => s.isBlocked, 'isBlocked', isFalse),
      ],
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'ensureAccess does not request again when permanently denied',
      setUp: () => when(locationService.checkPermission).thenAnswer(
        (_) async => LocationPermissionStatus.permanentlyDenied,
      ),
      build: buildCubit,
      act: (cubit) => cubit.ensureAccess(),
      expect: () => [
        isA<AddBranchLocationState>().having(
          (s) => s.isBlocked,
          'isBlocked',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(locationService.requestPermission);
      },
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'ensureAccess reports serviceDisabled as blocked',
      setUp: () => when(locationService.checkPermission).thenAnswer(
        (_) async => LocationPermissionStatus.serviceDisabled,
      ),
      build: buildCubit,
      act: (cubit) => cubit.ensureAccess(),
      expect: () => [
        isA<AddBranchLocationState>()
            .having((s) => s.isServiceDisabled, 'isServiceDisabled', isTrue)
            .having((s) => s.isBlocked, 'isBlocked', isTrue),
      ],
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'refresh only checks — never triggers the native prompt (SAN-602)',
      setUp: () => when(locationService.checkPermission).thenAnswer(
        (_) async => LocationPermissionStatus.granted,
      ),
      build: buildCubit,
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<AddBranchLocationState>().having(
          (s) => s.isGranted,
          'isGranted',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(locationService.requestPermission);
      },
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'refresh clears a permanently-blocked state once granted in Settings',
      setUp: () => when(locationService.checkPermission).thenAnswer(
        (_) async => LocationPermissionStatus.granted,
      ),
      build: buildCubit,
      seed: () => const AddBranchLocationState(
        status: LocationPermissionStatus.permanentlyDenied,
      ),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<AddBranchLocationState>()
            .having((s) => s.isGranted, 'isGranted', isTrue)
            .having((s) => s.isBlocked, 'isBlocked', isFalse),
      ],
    );

    test(
      'refresh is a no-op (no new emission) when still permanently denied',
      () async {
        when(locationService.checkPermission).thenAnswer(
          (_) async => LocationPermissionStatus.permanentlyDenied,
        );
        final cubit = buildCubit();
        await cubit.refresh();
        final states = <AddBranchLocationState>[];
        final sub = cubit.stream.listen(states.add);

        await cubit.refresh();

        await sub.cancel();
        expect(states, isEmpty);
        expect(cubit.state.isBlocked, isTrue);
        await cubit.close();
      },
    );

    blocTest<AddBranchLocationBloc, AddBranchLocationState>(
      'requestAgain triggers the native prompt directly',
      setUp: () => when(locationService.requestPermission).thenAnswer(
        (_) async => LocationPermissionStatus.granted,
      ),
      build: buildCubit,
      act: (cubit) => cubit.requestAgain(),
      expect: () => [
        isA<AddBranchLocationState>().having(
          (s) => s.isGranted,
          'isGranted',
          isTrue,
        ),
      ],
      verify: (_) {
        verifyNever(locationService.checkPermission);
      },
    );

    test('openSettings delegates to LocationService', () async {
      when(locationService.openAppSettings).thenAnswer((_) async => true);
      final cubit = buildCubit();

      await cubit.openSettings();

      verify(locationService.openAppSettings).called(1);
      await cubit.close();
    });
  });
}
