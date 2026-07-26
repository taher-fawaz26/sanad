import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:branches/src/domain/entities/branch_worker_type.dart';
import 'package:branches/src/domain/entities/worker_status.dart';
import 'package:branches/src/presentation/utils/branch_draft_seeder.dart';
import 'package:branches/src/presentation/widgets/branch_schedule_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:workers/workers.dart' as workers;

void main() {
  const customAvailability = [
    BranchAvailabilityEntity(
      day: 'MONDAY',
      slots: [BranchTimeSlotEntity(from: '10:00', to: '18:00')],
    ),
  ];

  BranchEntity buildBranch({
    BranchAvailabilityMode availabilityMode = BranchAvailabilityMode.custom,
    String? cityId = 'city-1',
    String? branchManagerId = 'mgr-1',
    double? lat = 25.1,
    double? lng = 55.2,
  }) => BranchEntity(
    id: 'b1',
    branchName: 'Main Branch',
    branchAddress: '123 Road',
    city: 'Dubai',
    cityId: cityId,
    cityNameAr: 'دبي',
    branchPhone: '+971501234567',
    isAvailable: true,
    availabilityMode: availabilityMode,
    branchType: BranchType.warehouse,
    branchManagerId: branchManagerId,
    branchManagerName: 'Ali Hassan',
    lat: lat,
    lng: lng,
    radiusKm: 7,
    availability: customAvailability,
    servingAreaPlaceIds: const ['p1'],
    servingAreaNames: const ['Area 1'],
    servingAreas: const [
      ServingArea(
        placeId: 'p1',
        name: 'Area 1',
        address: '',
        latLng: LatLng(25.1, 55.2),
      ),
    ],
    serviceIds: const ['s1', 's2'],
    serviceNames: const ['Service 1', 'Service 2'],
    workers: const [
      BranchWorkerEntity(
        id: 'w1',
        fullName: 'John Doe',
        initials: 'JD',
        type: BranchWorkerType.worker,
        status: WorkerStatus.active,
      ),
    ],
  );

  group('BranchDraftSeeder.fromBranch', () {
    test('prefills scalar fields, position, city and manager', () {
      final draft = BranchDraftSeeder.fromBranch(buildBranch());

      expect(draft.branchName, 'Main Branch');
      expect(draft.branchType, BranchType.warehouse);
      expect(draft.phone, '+971501234567');
      expect(draft.branchAddress, '123 Road');
      expect(draft.coverageRadiusKm, 7);
      expect(draft.pickedPosition, const LatLng(25.1, 55.2));

      expect(draft.selectedCity?.id, 'city-1');
      expect(draft.selectedCity?.nameEn, 'Dubai');
      expect(draft.selectedCity?.nameAr, 'دبي');

      expect(draft.selectedManager?.id, 'mgr-1');
      expect(draft.selectedManager?.fullName, 'Ali Hassan');
      expect(draft.selectedManager?.initials, 'AH');
    });

    test('reconstructs services from ids + names (empty category)', () {
      final draft = BranchDraftSeeder.fromBranch(buildBranch());

      expect(draft.selectedServices.map((s) => s.id).toList(), ['s1', 's2']);
      expect(
        draft.selectedServices.map((s) => s.name).toList(),
        ['Service 1', 'Service 2'],
      );
      expect(draft.selectedServices.every((s) => s.category.isEmpty), isTrue);
    });

    test('reconstructs workers with id, name, role and status', () {
      final draft = BranchDraftSeeder.fromBranch(buildBranch());

      expect(draft.selectedWorkers, hasLength(1));
      final worker = draft.selectedWorkers.single;
      expect(worker.id, 'w1');
      expect(worker.fullName, 'John Doe');
      expect(worker.role, 'worker');
      expect(worker.initials, 'JD');
      expect(worker.status, workers.WorkerStatus.active);
    });

    test('carries serving areas with geometry through unchanged', () {
      final draft = BranchDraftSeeder.fromBranch(buildBranch());

      expect(draft.servingAreas, hasLength(1));
      expect(draft.servingAreas.single.placeId, 'p1');
      expect(draft.servingAreas.single.latLng, const LatLng(25.1, 55.2));
    });

    test('maps custom availability mode to a custom schedule', () {
      final draft = BranchDraftSeeder.fromBranch(buildBranch());

      expect(draft.scheduleMode, BranchScheduleMode.custom);
      expect(draft.customSchedule, customAvailability);
    });

    test('maps core-hours availability mode to the company schedule', () {
      final draft = BranchDraftSeeder.fromBranch(
        buildBranch(availabilityMode: BranchAvailabilityMode.coreHours),
      );

      expect(draft.scheduleMode, BranchScheduleMode.company);
    });

    test('leaves optional entities null when the branch lacks them', () {
      final draft = BranchDraftSeeder.fromBranch(
        buildBranch(cityId: null, branchManagerId: null, lat: null, lng: null),
      );

      expect(draft.selectedCity, isNull);
      expect(draft.selectedManager, isNull);
      expect(draft.pickedPosition, isNull);
    });
  });
}
