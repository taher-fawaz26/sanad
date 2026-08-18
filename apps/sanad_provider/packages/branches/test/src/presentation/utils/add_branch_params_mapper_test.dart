import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:branches/src/domain/entities/branch_worker_type.dart';
import 'package:branches/src/domain/entities/worker_status.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:branches/src/presentation/utils/add_branch_params_mapper.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart' hide WorkerStatus;

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

  const testCity = CityEntity(id: 'city-1', name: 'Dubai');
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
      CatalogServiceSelection(id: 's1', name: 'Haircut', categoryName: 'Hair'),
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

    test('deduplicates the same place_id discovered via auto + manual areas '
        'while preserving first-seen order', () {
      final draft = completeDraft.copyWith(
        servingAreas: const [
          ServingArea(
            placeId: 'ChIJ_dup',
            name: 'Auto-discovered',
            address: '',
            latLng: LatLng(25.0, 55.0),
          ),
          ServingArea(
            placeId: 'ChIJ_unique',
            name: 'Unique Area',
            address: '',
            latLng: LatLng(25.1, 55.1),
          ),
          ServingArea(
            placeId: 'ChIJ_dup',
            name: 'Manually re-added',
            address: '',
            latLng: LatLng(25.0, 55.0),
          ),
        ],
      );

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, ['ChIJ_dup', 'ChIJ_unique']);
    });
  });

  group('AddBranchParamsMapper.fromBranch', () {
    const completeBranch = BranchEntity(
      id: 'branch-1',
      branchName: 'Downtown Branch',
      branchAddress: '123 Main St',
      city: 'Dubai',
      cityId: 'city-1',
      branchPhone: '+971501234567',
      isAvailable: true,
      availabilityMode: BranchAvailabilityMode.custom,
      branchType: BranchType.headquarters,
      branchManagerId: 'mgr-1',
      branchManagerName: 'Test Manager',
      lat: 25.0,
      lng: 55.0,
      radiusKm: 5.0,
      googleMapsLink: 'https://maps.google.com/x',
      socialMediaLink: 'https://instagram.com/branch',
      availability: customSchedule,
      servingAreaPlaceIds: ['p1'],
      servingAreaNames: ['Area 1'],
      serviceIds: ['s1'],
      serviceNames: ['Haircut'],
      workers: [
        BranchWorkerEntity(
          id: 'w1',
          fullName: 'John',
          initials: 'J',
          type: BranchWorkerType.worker,
          status: WorkerStatus.active,
        ),
      ],
    );

    test('maps every field from the branch (full-payload PATCH)', () {
      final params = AddBranchParamsMapper.fromBranch(completeBranch);

      expect(params.id, 'branch-1');
      expect(params.branchName, 'Downtown Branch');
      expect(params.branchAddress, '123 Main St');
      expect(params.branchPhone, '+971501234567');
      expect(params.branchType, BranchType.headquarters);
      expect(params.cityId, 'city-1');
      expect(params.branchManagerId, 'mgr-1');
      expect(params.lat, 25.0);
      expect(params.lng, 55.0);
      expect(params.radiusKm, 5.0);
      expect(params.googleMapsLink, 'https://maps.google.com/x');
      expect(params.socialMediaLink, 'https://instagram.com/branch');
      expect(params.availabilityMode, BranchAvailabilityMode.custom);
      expect(params.availability, customSchedule);
      expect(params.servingAreaPlaceIds, ['p1']);
      expect(params.workerIds, ['w1']);
    });

    test('omits serviceIds — backend ignores it (deprecated)', () {
      final params = AddBranchParamsMapper.fromBranch(completeBranch);
      expect(params.serviceIds, isNull);
    });

    test(
      'editing one section preserves every other field '
      '(Branch Info: name/type/city change only)',
      () {
        final updated = completeBranch.copyWith(
          branchName: 'Renamed Branch',
          branchType: BranchType.mainStore,
          cityId: 'city-2',
          city: 'Abu Dhabi',
        );
        final params = AddBranchParamsMapper.fromBranch(updated);

        expect(params.branchName, 'Renamed Branch');
        expect(params.branchType, BranchType.mainStore);
        expect(params.cityId, 'city-2');
        // Everything else must be untouched.
        expect(params.branchAddress, completeBranch.branchAddress);
        expect(params.branchPhone, completeBranch.branchPhone);
        expect(params.branchManagerId, completeBranch.branchManagerId);
        expect(params.lat, completeBranch.lat);
        expect(params.lng, completeBranch.lng);
        expect(params.radiusKm, completeBranch.radiusKm);
        expect(params.availabilityMode, completeBranch.availabilityMode);
        expect(params.availability, completeBranch.availability);
        expect(
          params.servingAreaPlaceIds,
          completeBranch.servingAreaPlaceIds,
        );
        expect(params.workerIds, ['w1']);
      },
    );

    test(
      'editing Contact (phone + manager) preserves every other field',
      () {
        final updated = completeBranch.copyWith(
          branchPhone: '+971509999999',
          branchManagerId: 'mgr-2',
          branchManagerName: 'New Manager',
        );
        final params = AddBranchParamsMapper.fromBranch(updated);

        expect(params.branchPhone, '+971509999999');
        expect(params.branchManagerId, 'mgr-2');
        expect(params.branchName, completeBranch.branchName);
        expect(params.branchAddress, completeBranch.branchAddress);
        expect(params.cityId, completeBranch.cityId);
        expect(params.branchType, completeBranch.branchType);
        expect(params.lat, completeBranch.lat);
        expect(params.lng, completeBranch.lng);
        expect(params.radiusKm, completeBranch.radiusKm);
        expect(params.availability, completeBranch.availability);
        expect(
          params.servingAreaPlaceIds,
          completeBranch.servingAreaPlaceIds,
        );
        expect(params.workerIds, ['w1']);
      },
    );

    test(
      'editing Working Hours preserves every other field',
      () {
        const newSchedule = [
          BranchAvailabilityEntity(
            day: 'FRIDAY',
            slots: [BranchTimeSlotEntity(from: '08:00', to: '16:00')],
          ),
        ];
        final updated = completeBranch.copyWith(
          availabilityMode: BranchAvailabilityMode.coreHours,
          availability: newSchedule,
        );
        final params = AddBranchParamsMapper.fromBranch(updated);

        expect(params.availabilityMode, BranchAvailabilityMode.coreHours);
        expect(params.availability, newSchedule);
        expect(params.branchName, completeBranch.branchName);
        expect(params.branchPhone, completeBranch.branchPhone);
        expect(params.branchManagerId, completeBranch.branchManagerId);
        expect(params.lat, completeBranch.lat);
        expect(params.radiusKm, completeBranch.radiusKm);
        expect(
          params.servingAreaPlaceIds,
          completeBranch.servingAreaPlaceIds,
        );
        expect(params.workerIds, ['w1']);
      },
    );

    test(
      'editing Coverage (lat/lng/radius/serving areas) preserves every '
      'other field',
      () {
        final updated = completeBranch.copyWith(
          branchAddress: 'New Address',
          lat: 26.0,
          lng: 56.0,
          radiusKm: 10.0,
          servingAreaPlaceIds: ['p2', 'p3'],
        );
        final params = AddBranchParamsMapper.fromBranch(updated);

        expect(params.branchAddress, 'New Address');
        expect(params.lat, 26.0);
        expect(params.lng, 56.0);
        expect(params.radiusKm, 10.0);
        expect(params.servingAreaPlaceIds, ['p2', 'p3']);
        expect(params.branchName, completeBranch.branchName);
        expect(params.branchPhone, completeBranch.branchPhone);
        expect(params.branchManagerId, completeBranch.branchManagerId);
        expect(params.availabilityMode, completeBranch.availabilityMode);
        expect(params.availability, completeBranch.availability);
        expect(params.workerIds, ['w1']);
      },
    );

    test(
      'editing Team (workerIds override) preserves every other field '
      'and does not require BranchEntity.workers to change',
      () {
        final params = AddBranchParamsMapper.fromBranch(
          completeBranch,
          workerIds: ['w2', 'w3'],
        );

        expect(params.workerIds, ['w2', 'w3']);
        expect(params.branchName, completeBranch.branchName);
        expect(params.branchPhone, completeBranch.branchPhone);
        expect(params.branchManagerId, completeBranch.branchManagerId);
        expect(params.lat, completeBranch.lat);
        expect(params.radiusKm, completeBranch.radiusKm);
        expect(params.availabilityMode, completeBranch.availabilityMode);
        expect(
          params.servingAreaPlaceIds,
          completeBranch.servingAreaPlaceIds,
        );
      },
    );

    test('normalizes an already-international phone idempotently', () {
      final params = AddBranchParamsMapper.fromBranch(completeBranch);
      expect(params.branchPhone, '+971501234567');
    });
  });
}
