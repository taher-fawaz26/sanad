import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
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

  const completeDraft = AddBranchDraft(
    branchName: ' Test Branch ',
    branchType: BranchType.headquarters,
    city: ' Dubai ',
    phone: ' 0501234567 ',
    branchAddress: '123 Main St',
    pickedPosition: LatLng(25.0, 55.0),
    selectedManagerId: 'mgr-1',
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
      expect(params.city, 'Dubai');
      expect(params.branchPhone, '0501234567');
      expect(params.branchAddress, '123 Main St');
      expect(params.branchManagerId, 'mgr-1');
      expect(params.lat, 25.0);
      expect(params.lng, 55.0);
      expect(params.radiusKm, 5.0);
      expect(
        params.availabilityMode,
        BranchAvailabilityMode.coreHours,
      );
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

    test('trims whitespace from text fields', () {
      final params = AddBranchParamsMapper.toCreateParams(
        completeDraft,
        companySchedule: companySchedule,
      );

      expect(params.branchName, 'Test Branch');
      expect(params.city, 'Dubai');
      expect(params.branchPhone, '0501234567');
    });

    test('handles null address gracefully', () {
      final draft = completeDraft.copyWith(branchAddress: () => null);

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.branchAddress, '');
    });

    test('omits optional lists when empty', () {
      const minimalDraft = AddBranchDraft(
        branchName: 'Branch',
        branchType: BranchType.mainBranch,
        city: 'City',
        phone: '050',
        branchAddress: 'Addr',
        pickedPosition: LatLng(25.0, 55.0),
        selectedManagerId: 'mgr-1',
      );

      final params = AddBranchParamsMapper.toCreateParams(
        minimalDraft,
        companySchedule: companySchedule,
      );

      expect(params.servingAreaPlaceIds, isNull);
      expect(params.serviceIds, isNull);
      expect(params.workerIds, isNull);
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

    test('null position results in null lat/lng', () {
      final draft = completeDraft.copyWith(pickedPosition: () => null);

      final params = AddBranchParamsMapper.toCreateParams(
        draft,
        companySchedule: companySchedule,
      );

      expect(params.lat, isNull);
      expect(params.lng, isNull);
    });
  });
}
