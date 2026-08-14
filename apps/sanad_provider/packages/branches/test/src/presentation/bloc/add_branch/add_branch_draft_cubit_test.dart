import 'package:bloc_test/bloc_test.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_cubit.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

void main() {
  const testCity = CityEntity(id: 'city-1', nameEn: 'Dubai', nameAr: 'دبي');
  const testManager = BranchManagerEntity(
    id: 'mgr-1',
    fullName: 'Test Manager',
    initials: 'TM',
  );

  group('AddBranchDraftCubit', () {
    late AddBranchDraftCubit cubit;

    setUp(() {
      cubit = AddBranchDraftCubit();
    });

    tearDown(() => cubit.close());

    test('initial state has correct defaults', () {
      expect(cubit.state, const AddBranchDraft());
      expect(cubit.state.branchType, BranchType.mainBranch);
      expect(cubit.state.branchName, '');
      expect(cubit.state.selectedCity, isNull);
      expect(cubit.state.phone, '');
      expect(cubit.state.branchAddress, isNull);
      expect(cubit.state.pickedPosition, isNull);
      expect(cubit.state.selectedManager, isNull);
      expect(cubit.state.scheduleMode, BranchScheduleMode.company);
      expect(cubit.state.customSchedule, isEmpty);
      expect(cubit.state.coverageRadiusKm, isNull);
      expect(cubit.state.servingAreas, isEmpty);
      expect(cubit.state.selectedServices, isEmpty);
      expect(cubit.state.selectedWorkers, isEmpty);
    });

    group('updateBasicInfo', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updates branch name',
        build: () => cubit,
        act: (c) => c.updateBasicInfo(branchName: 'Test Branch'),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.branchName,
            'branchName',
            'Test Branch',
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updates name and phone together',
        build: () => cubit,
        act: (c) => c.updateBasicInfo(
          branchName: 'Branch',
          phone: '0501234567',
        ),
        expect: () => [
          isA<AddBranchDraft>()
              .having((d) => d.branchName, 'branchName', 'Branch')
              .having((d) => d.phone, 'phone', '0501234567'),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'preserves unmentioned fields',
        build: () => cubit,
        seed: () => const AddBranchDraft(selectedCity: testCity),
        act: (c) => c.updateBasicInfo(branchName: 'New'),
        expect: () => [
          isA<AddBranchDraft>()
              .having((d) => d.branchName, 'branchName', 'New')
              .having((d) => d.selectedCity, 'city', testCity),
        ],
      );
    });

    group('updateCity', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'sets selected city entity',
        build: () => cubit,
        act: (c) => c.updateCity(testCity),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedCity,
            'selectedCity',
            testCity,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'replaces previous city',
        build: () => cubit,
        seed: () => const AddBranchDraft(selectedCity: testCity),
        act: (c) => c.updateCity(
          const CityEntity(
            id: 'city-2',
            nameEn: 'Abu Dhabi',
            nameAr: 'أبو ظبي',
          ),
        ),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedCity?.id,
            'cityId',
            'city-2',
          ),
        ],
      );
    });

    group('updateBranchType', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'changes branch type from default',
        build: () => cubit,
        act: (c) => c.updateBranchType(BranchType.warehouse),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.branchType,
            'branchType',
            BranchType.warehouse,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'default is mainBranch',
        build: () => cubit,
        verify: (c) {
          expect(c.state.branchType, BranchType.mainBranch);
        },
      );
    });

    group('updateLocation', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'sets address and position',
        build: () => cubit,
        act: (c) => c.updateLocation(
          address: '123 Main St',
          position: const LatLng(25.0, 55.0),
        ),
        expect: () => [
          isA<AddBranchDraft>()
              .having((d) => d.branchAddress, 'address', '123 Main St')
              .having(
                (d) => d.pickedPosition,
                'position',
                const LatLng(25.0, 55.0),
              ),
        ],
      );
    });

    group('updateManager', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'sets selected manager entity',
        build: () => cubit,
        act: (c) => c.updateManager(testManager),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedManager,
            'selectedManager',
            testManager,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'clears manager when null',
        build: () => cubit,
        seed: () => const AddBranchDraft(selectedManager: testManager),
        act: (c) => c.updateManager(null),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedManager,
            'selectedManager',
            isNull,
          ),
        ],
      );
    });

    group('schedule', () {
      const schedule = [
        BranchAvailabilityEntity(
          day: 'MONDAY',
          slots: [BranchTimeSlotEntity(from: '09:00', to: '17:00')],
        ),
      ];

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updateScheduleMode changes mode',
        build: () => cubit,
        act: (c) => c.updateScheduleMode(BranchScheduleMode.custom),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.scheduleMode,
            'mode',
            BranchScheduleMode.custom,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updateCustomSchedule sets schedule',
        build: () => cubit,
        act: (c) => c.updateCustomSchedule(schedule),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.customSchedule,
            'schedule',
            schedule,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'initializeCustomSchedule sets only when empty',
        build: () => cubit,
        seed: () => const AddBranchDraft(customSchedule: schedule),
        act: (c) => c.initializeCustomSchedule(const [
          BranchAvailabilityEntity(
            day: 'TUESDAY',
            slots: [BranchTimeSlotEntity(from: '08:00', to: '16:00')],
          ),
        ]),
        expect: () => <AddBranchDraft>[],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'initializeCustomSchedule sets when empty',
        build: () => cubit,
        act: (c) => c.initializeCustomSchedule(schedule),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.customSchedule,
            'schedule',
            schedule,
          ),
        ],
      );
    });

    group('updateCoverage', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'sets all coverage fields',
        build: () => cubit,
        act: (c) => c.updateCoverage(
          address: 'Coverage St',
          position: const LatLng(25.1, 55.1),
          radiusKm: 5.0,
          servingAreas: const [
            ServingArea(
              placeId: 'p1',
              name: 'Area 1',
              address: 'Addr',
              latLng: LatLng(25.0, 55.0),
            ),
          ],
        ),
        expect: () => [
          isA<AddBranchDraft>()
              .having((d) => d.branchAddress, 'address', 'Coverage St')
              .having((d) => d.coverageRadiusKm, 'radius', 5.0)
              .having((d) => d.servingAreas.length, 'areas', 1),
        ],
      );
    });

    group('services and workers', () {
      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updateServices sets service list',
        build: () => cubit,
        act: (c) => c.updateServices(const [
          CatalogServiceSelection(
            id: 's1',
            name: 'Haircut',
            categoryName: 'Hair',
          ),
        ]),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedServices.length,
            'count',
            1,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'updateWorkers sets worker list',
        build: () => cubit,
        act: (c) => c.updateWorkers(const [
          WorkerEntity(
            id: 'w1',
            fullName: 'John',
            role: 'Barber',
            initials: 'J',
          ),
        ]),
        expect: () => [
          isA<AddBranchDraft>().having(
            (d) => d.selectedWorkers.length,
            'count',
            1,
          ),
        ],
      );

      blocTest<AddBranchDraftCubit, AddBranchDraft>(
        'removeWorker removes by id',
        build: () => cubit,
        seed: () => const AddBranchDraft(
          selectedWorkers: [
            WorkerEntity(
              id: 'w1',
              fullName: 'John',
              role: 'Barber',
              initials: 'J',
            ),
            WorkerEntity(
              id: 'w2',
              fullName: 'Jane',
              role: 'Stylist',
              initials: 'J',
            ),
          ],
        ),
        act: (c) => c.removeWorker(
          const WorkerEntity(
            id: 'w1',
            fullName: 'John',
            role: 'Barber',
            initials: 'J',
          ),
        ),
        expect: () => [
          isA<AddBranchDraft>()
              .having((d) => d.selectedWorkers.length, 'count', 1)
              .having(
                (d) => d.selectedWorkers.first.id,
                'remaining',
                'w2',
              ),
        ],
      );
    });

    group('step completion validation', () {
      test('isStepOneComplete requires all mandatory fields', () {
        const draft = AddBranchDraft();
        expect(draft.isStepOneComplete, isFalse);

        const complete = AddBranchDraft(
          branchName: 'Branch',
          selectedCity: testCity,
          phone: '0501234567',
          branchAddress: '123 Main St',
          pickedPosition: LatLng(25.0, 55.0),
          selectedManager: testManager,
        );
        expect(complete.isStepOneComplete, isTrue);
      });

      test('isStepOneComplete fails with empty trimmed name', () {
        const draft = AddBranchDraft(
          branchName: '   ',
          selectedCity: testCity,
          phone: '0501234567',
          branchAddress: '123 Main St',
          pickedPosition: LatLng(25.0, 55.0),
          selectedManager: testManager,
        );
        expect(draft.isStepOneComplete, isFalse);
      });

      test('isStepOneComplete fails without selected city', () {
        const draft = AddBranchDraft(
          branchName: 'Branch',
          phone: '0501234567',
          branchAddress: '123 Main St',
          pickedPosition: LatLng(25.0, 55.0),
          selectedManager: testManager,
        );
        expect(draft.isStepOneComplete, isFalse);
      });

      test('isStepOneComplete fails without selected manager', () {
        const draft = AddBranchDraft(
          branchName: 'Branch',
          selectedCity: testCity,
          phone: '0501234567',
          branchAddress: '123 Main St',
          pickedPosition: LatLng(25.0, 55.0),
        );
        expect(draft.isStepOneComplete, isFalse);
      });

      test('isStepTwoComplete requires radius and address', () {
        expect(const AddBranchDraft().isStepTwoComplete, isFalse);
        expect(
          const AddBranchDraft(
            branchAddress: 'Addr',
            coverageRadiusKm: 5.0,
          ).isStepTwoComplete,
          isTrue,
        );
      });

      test('isStepThreeComplete requires services', () {
        expect(const AddBranchDraft().isStepThreeComplete, isFalse);
        expect(
          const AddBranchDraft(
            selectedServices: [
              CatalogServiceSelection(
                id: 's1',
                name: 'Cut',
                categoryName: 'Hair',
              ),
            ],
          ).isStepThreeComplete,
          isTrue,
        );
      });

      test('isStepFourComplete requires workers', () {
        expect(const AddBranchDraft().isStepFourComplete, isFalse);
        expect(
          const AddBranchDraft(
            selectedWorkers: [
              WorkerEntity(
                id: 'w1',
                fullName: 'John',
                role: 'Barber',
                initials: 'J',
              ),
            ],
          ).isStepFourComplete,
          isTrue,
        );
      });
    });

    group('data survives step transitions', () {
      test('all draft fields persist across cubit lifetime', () {
        cubit.updateBasicInfo(branchName: 'Branch', phone: '050');
        cubit.updateCity(testCity);
        cubit.updateBranchType(BranchType.headquarters);
        cubit.updateLocation(
          address: 'Addr',
          position: const LatLng(25.0, 55.0),
        );
        cubit.updateManager(testManager);
        cubit.updateScheduleMode(BranchScheduleMode.custom);
        cubit.updateCustomSchedule(const [
          BranchAvailabilityEntity(
            day: 'MONDAY',
            slots: [BranchTimeSlotEntity(from: '09:00', to: '17:00')],
          ),
        ]);
        cubit.updateCoverage(
          address: 'Coverage Addr',
          position: const LatLng(25.1, 55.1),
          radiusKm: 10.0,
          servingAreas: const [
            ServingArea(
              placeId: 'p1',
              name: 'Area',
              address: 'A',
              latLng: LatLng(25.0, 55.0),
            ),
          ],
        );
        cubit.updateServices(const [
          CatalogServiceSelection(id: 's1', name: 'Cut', categoryName: 'Hair'),
        ]);
        cubit.updateWorkers(const [
          WorkerEntity(
            id: 'w1',
            fullName: 'John',
            role: 'Barber',
            initials: 'J',
          ),
        ]);

        final draft = cubit.state;
        expect(draft.branchName, 'Branch');
        expect(draft.branchType, BranchType.headquarters);
        expect(draft.selectedCity, testCity);
        expect(draft.phone, '050');
        expect(draft.branchAddress, 'Coverage Addr');
        expect(draft.pickedPosition, const LatLng(25.1, 55.1));
        expect(draft.selectedManager, testManager);
        expect(draft.scheduleMode, BranchScheduleMode.custom);
        expect(draft.customSchedule.length, 1);
        expect(draft.coverageRadiusKm, 10.0);
        expect(draft.servingAreas.length, 1);
        expect(draft.selectedServices.length, 1);
        expect(draft.selectedWorkers.length, 1);
      });
    });
  });
}
