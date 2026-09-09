import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseRequest = CreateBranchRequest(
    branchName: 'Downtown Branch',
    branchType: BranchType.mainBranch,
    branchAddress: 'Building 5, Sheikh Zayed Road',
    locationPlaceId: 'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
    branchPhone: '+971501234567',
    branchManagerId: 'mgr-1',
    lat: 25.2048,
    lng: 55.2708,
    radiusKm: 5,
    workerIds: ['w1'],
    serviceIds: ['svc-1'],
    servingAreaPlaceIds: ['ChIJvRmU9K1DXz4RYKyuhY6v0wM'],
  );

  group('CreateBranchRequest.toMap', () {
    test('emits servingAreaPlaceIds as the raw Google place_id list, never '
        'a Places-API-New resource-name-prefixed value', () {
      final map = baseRequest
          .copyWith(
            servingAreaPlaceIds: ['ChIJvRmU9K1DXz4RYKyuhY6v0wM', 'ChIJ_other'],
          )
          .toMap();

      expect(map['servingAreaPlaceIds'], [
        'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
        'ChIJ_other',
      ]);
      for (final id in map['servingAreaPlaceIds'] as List<String>) {
        expect(id.startsWith('places/'), isFalse);
      }
    });

    test('sends lat/lng/radiusKm matching the exact selected values, '
        'lat and lng not swapped', () {
      final map = baseRequest.toMap();

      expect(map['lat'], 25.2048);
      expect(map['lng'], 55.2708);
      expect(map['radiusKm'], 5);
    });

    test(
      'always sends servingAreaPlaceIds and serviceIds — both are required '
      'with at least one entry, and omitting either now answers 400',
      () {
        // This replaces two tests that pinned the opposite behaviour: the
        // request used to drop `servingAreaPlaceIds` when empty, which under
        // the current contract produces a rejected POST rather than a
        // harmless no-op.
        final map = baseRequest.toMap();

        expect(map['servingAreaPlaceIds'], ['ChIJvRmU9K1DXz4RYKyuhY6v0wM']);
        expect(map['serviceIds'], ['svc-1']);
      },
    );

    test('transmits an empty required array rather than dropping the key', () {
      // If the wizard ever lets an empty selection through, the server must
      // get the chance to say so. Silently omitting the key — the old
      // behaviour — turned a fixable validation error into a confusing one.
      final map = baseRequest.copyWith(servingAreaPlaceIds: const []).toMap();

      expect(map.containsKey('servingAreaPlaceIds'), isTrue);
      expect(map['servingAreaPlaceIds'], isEmpty);
    });

    test('includes branchManagerId when a manager is assigned', () {
      final map = baseRequest.toMap();
      expect(map['branchManagerId'], 'mgr-1');
    });

    test(
      'serializes canonical all-caps availability days as Title-case — the '
      'backend rejects "SATURDAY" with 400 (SAN-780 write regression)',
      () {
        const request = CreateBranchRequest(
          branchName: 'Downtown Branch',
          branchType: BranchType.mainBranch,
          branchAddress: 'Building 5, Sheikh Zayed Road',
          locationPlaceId: 'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
          branchPhone: '+971501234567',
          branchManagerId: 'mgr-1',
          lat: 25.2048,
          lng: 55.2708,
          radiusKm: 5,
          workerIds: ['w1'],
          availabilityMode: BranchAvailabilityMode.custom,
          availability: [
            BranchAvailabilityEntity(
              day: BranchWeekdays.saturday,
              slots: [BranchTimeSlotEntity(from: '10:00', to: '14:00')],
            ),
            BranchAvailabilityEntity(
              day: BranchWeekdays.friday,
              slots: [BranchTimeSlotEntity(from: '09:00', to: '13:00')],
            ),
          ],
          serviceIds: ['svc-1'],
          servingAreaPlaceIds: ['ChIJvRmU9K1DXz4RYKyuhY6v0wM'],
        );

        final map = request.toMap();
        final availability = map['availability'] as List<dynamic>;
        expect(
          availability.map((e) => (e as Map<String, dynamic>)['day']),
          ['Saturday', 'Friday'],
        );
      },
    );

    test(
      'omits branchManagerId key entirely when null, never sends a null '
      'value — the Swagger spec lists branchManagerId as optional, but the '
      'backend actually rejects a null value at runtime (400 '
      '"branchManagerId must be a UUID"); the UI now requires a manager '
      'before submission, so this path is a defensive fallback, not a '
      'supported request shape',
      () {
        const noManagerRequest = CreateBranchRequest(
          branchName: 'Downtown Branch',
          branchType: BranchType.mainBranch,
          branchAddress: 'Building 5, Sheikh Zayed Road',
          locationPlaceId: 'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
          branchPhone: '+971501234567',
          lat: 25.2048,
          lng: 55.2708,
          radiusKm: 5,
          workerIds: ['w1'],
          serviceIds: ['svc-1'],
          servingAreaPlaceIds: ['ChIJvRmU9K1DXz4RYKyuhY6v0wM'],
        );

        final map = noManagerRequest.toMap();
        expect(map.containsKey('branchManagerId'), isFalse);
      },
    );
  });
}

extension on CreateBranchRequest {
  CreateBranchRequest copyWith({
    List<String>? servingAreaPlaceIds,
    List<String>? serviceIds,
  }) =>
      CreateBranchRequest(
        branchName: branchName,
        branchType: branchType,
        branchAddress: branchAddress,
        locationPlaceId: locationPlaceId,
        branchPhone: branchPhone,
        branchManagerId: branchManagerId,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        workerIds: workerIds,
        googleMapsLink: googleMapsLink,
        socialMediaLink: socialMediaLink,
        availabilityMode: availabilityMode,
        availability: availability,
        serviceIds: serviceIds ?? this.serviceIds,
        servingAreaPlaceIds: servingAreaPlaceIds ?? this.servingAreaPlaceIds,
      );
}
