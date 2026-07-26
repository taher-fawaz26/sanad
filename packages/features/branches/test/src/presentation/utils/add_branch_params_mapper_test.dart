import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

void main() {
  const companySchedule = [
    BranchAvailabilityEntity(
      day: 'SUNDAY',
      slots: [BranchTimeSlotEntity(from: '09:00', to: '17:00')],
    ),
  ];

  const customSchedule = [
    BranchAvailabilityEntity(
      day: 'MONDAY',
      slots: [BranchTimeSlotEntity(from: '10:00', to: '18:00')],
    ),
  ];

  const testCity = CityEntity(id: 'city-1', nameEn: 'Dubai', nameAr: 'دبي');
  const testManager = BranchManagerEntity(
    id: 'mgr-1',
    fullName: 'Test Manager',
    initials: 'TM',
  );

  const completeDraft = AddBranchDraft(
    branchName: ' Test Branch ',
    branchType: BranchType.headquarters,
    selectedCity: testCity,
    phone: ' 0501234567 ',
    branchAddress: '123 Main St',
    pickedPosition: LatLng(25.0, 55.0),
    selectedManager: testManager,
    scheduleMode: BranchScheduleMode.company,
    customSchedule: customSchedule,
    coverageRadiusKm: 5.0,
    servingAreas: [
      ServingArea(
        placeId: 'p1',
        name: 'Area 1',
        address: 'Addr 1',
        latLng: LatLng(25.0, 55.0),
      ),
    ],
    selectedServices: [
      ServiceEntity(id: 's1', name: 'Haircut', category: 'Hair'),
    ],
    selectedWorkers: [
      WorkerEntity(
        id: 'w1',
        fullName: 'John',
        role: 'Barber',
        initials: 'J',
      ),
    ],
  );

  group('AddBranchParamsMapper', () {
    test('maps complete draft with company schedule', () {
      final params = AddBranchParamsMapper.toCreateParams(
        completeDraft,
        companySchedule: companySchedule,
      );

      expect(params.branchName, 'Test Branch');
      expect(params.branchType, BranchType.headquarters);
      expect(params.cityId, 'city-1');
      expect(params.branchPhone, '+971501234567');
      expect(params.branchAddress, '123 Main St');
      expect(params.branchManagerId, 'mgr-1');
      expect(params.lat, 25.0);
      expect(params.lng, 55.0);
      expect(params.radiusKm, 5.0);
      expect(params.availabilityMode, BranchAvailabilityMode.coreHours);
      expect(params.availability, companySchedule);
      expect(params.servingAreaPlaceIds, ['p1']);
      expect(params.serviceIds, ['s1']);
      expect(params.workerIds, ['w1']);
    });

    test('uses custom schedule when mode is custom', () {
      final draft = completeDraft.copyWith(
        scheduleMode: BranchScheduleMode.custom,
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.availabilityMode, BranchAvailabilityMode.custom);
      expect(params.availability, customSchedule);
    });

    test('trims whitespace and normalizes phone', () {
      final params = AddBranchParamsMapper.toCreateParams(
        completeDraft,
        companySchedule: companySchedule,
      );

      expect(params.branchName, 'Test Branch');
      expect(params.branchPhone, '+971501234567');
    });

    test('handles null address gracefully', () {
      final draft = completeDraft.copyWith(branchAddress: () => null);

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.branchAddress, '');
    });

    test('drops synthetic latlng: serving-area ids, keeps catalogue ids', () {
      final draft = completeDraft.copyWith(
        servingAreas: const [
          ServingArea(
            placeId: 'ChIJ_catalogue',
            name: 'Catalogue Area',
            address: '',
            latLng: LatLng(25.0, 55.0),
          ),
          ServingArea(
            placeId: 'latlng:25.03,55.17',
            name: 'Geocoder Area',
            address: '',
            latLng: LatLng(25.03, 55.17),
          ),
        ],
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      // The synthetic geocoder id is stripped; only the catalogue id is sent
      // (the backend 400s the whole branch on any non-catalogue place_id).
      expect(params.servingAreaPlaceIds, ['ChIJ_catalogue']);
    });

    test('sends null serving areas when only synthetic ids remain', () {
      final draft = completeDraft.copyWith(
        servingAreas: const [
          ServingArea(
            placeId: 'latlng:25.03,55.17',
            name: 'Geocoder Area',
            address: '',
            latLng: LatLng(25.03, 55.17),
          ),
        ],
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, isNull);
    });

    test('omits optional area and service lists when empty', () {
      final draft = completeDraft.copyWith(
        servingAreas: [],
        selectedServices: [],
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, isNull);
      expect(params.serviceIds, isNull);
      expect(params.workerIds, ['w1']);
    });

    test('throws ArgumentError when workers is empty', () {
      final draft = completeDraft.copyWith(selectedWorkers: []);

      expect(
        () => AddBranchParamsMapper.toCreateParams(
          draft,
          companySchedule: companySchedule,
        ),
        throwsArgumentError,
      );
    });

    test('preserves BranchType through mapping', () {
      for (final type in BranchType.values) {
        final draft = completeDraft.copyWith(branchType: type);
        final params = AddBranchParamsMapper.toCreateParams(
          draft,
          companySchedule: companySchedule,
        );
        expect(params.branchType, type);
      }
    });

    test('default BranchType is mainBranch', () {
      const draft = AddBranchDraft();
      expect(draft.branchType, BranchType.mainBranch);
    });

    test('servingAreaPlaceIds uses real placeIds, not synthetic latlng:', () {
      final draft = completeDraft.copyWith(
        servingAreas: const [
          ServingArea(
            placeId: 'ChIJ3QPOgqjK9T4R3KMk0f9ucsg',
            name: 'Al Barsha',
            address: '',
            latLng: LatLng(25.0, 55.0),
          ),
          ServingArea(
            placeId: 'ChIJRULP3yjK9T4RqYPvJA6bEHo',
            name: 'Dubai Marina',
            address: '',
            latLng: LatLng(25.1, 55.1),
          ),
        ],
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, isNotNull);
      for (final id in params.servingAreaPlaceIds!) {
        expect(id.startsWith('latlng:'), isFalse);
      }
      expect(params.servingAreaPlaceIds, [
        'ChIJ3QPOgqjK9T4R3KMk0f9ucsg',
        'ChIJRULP3yjK9T4RqYPvJA6bEHo',
      ]);
    });
  });

  group('AddBranchParamsMapper.toUpdateParams', () {
    test('maps complete draft to update params (incl. type + workerIds)', () {
      final params = AddBranchParamsMapper.toUpdateParams(
        completeDraft,
        id: 'branch-1',
        companySchedule: companySchedule,
      );

      expect(params.id, 'branch-1');
      expect(params.branchName, 'Test Branch');
      expect(params.branchType, BranchType.headquarters);
      expect(params.cityId, 'city-1');
      expect(params.branchPhone, '+971501234567');
      expect(params.branchAddress, '123 Main St');
      expect(params.branchManagerId, 'mgr-1');
      expect(params.lat, 25.0);
      expect(params.lng, 55.0);
      expect(params.radiusKm, 5.0);
      expect(params.availabilityMode, BranchAvailabilityMode.coreHours);
      expect(params.availability, companySchedule);
      expect(params.servingAreaPlaceIds, ['p1']);
      expect(params.serviceIds, ['s1']);
      expect(params.workerIds, ['w1']);
    });

    test('uses custom schedule when mode is custom', () {
      final draft = completeDraft.copyWith(
        scheduleMode: BranchScheduleMode.custom,
      );

      final params = AddBranchParamsMapper.toUpdateParams(
        draft,
        id: 'branch-1',
        companySchedule: companySchedule,
      );

      expect(params.availabilityMode, BranchAvailabilityMode.custom);
      expect(params.availability, customSchedule);
    });

    test('drops synthetic latlng: serving-area ids', () {
      final draft = completeDraft.copyWith(
        servingAreas: const [
          ServingArea(
            placeId: 'ChIJ_real',
            name: 'Real Area',
            address: '',
            latLng: LatLng(25.0, 55.0),
          ),
          ServingArea(
            placeId: 'latlng:25.03,55.17',
            name: 'Geocoder Area',
            address: '',
            latLng: LatLng(25.03, 55.17),
          ),
        ],
      );

      final params = AddBranchParamsMapper.toUpdateParams(
        draft,
        id: 'branch-1',
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, ['ChIJ_real']);
    });

    test('throws ArgumentError when workers is empty', () {
      final draft = completeDraft.copyWith(selectedWorkers: []);

      expect(
        () => AddBranchParamsMapper.toUpdateParams(
          draft,
          id: 'branch-1',
          companySchedule: companySchedule,
        ),
        throwsArgumentError,
      );
    });
  });
}
