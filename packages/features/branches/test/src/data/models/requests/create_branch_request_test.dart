import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseRequest = CreateBranchRequest(
    branchName: 'Downtown Branch',
    branchType: BranchType.mainBranch,
    branchAddress: 'Building 5, Sheikh Zayed Road',
    cityId: 'city-1',
    branchPhone: '+971501234567',
    branchManagerId: 'mgr-1',
    lat: 25.2048,
    lng: 55.2708,
    radiusKm: 5,
    workerIds: ['w1'],
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

    test('omits servingAreaPlaceIds key entirely when null', () {
      final map = baseRequest.toMap();
      expect(map.containsKey('servingAreaPlaceIds'), isFalse);
    });

    test('omits servingAreaPlaceIds key entirely when empty', () {
      final map = baseRequest.copyWith(servingAreaPlaceIds: const []).toMap();
      expect(map.containsKey('servingAreaPlaceIds'), isFalse);
    });
  });
}

extension on CreateBranchRequest {
  CreateBranchRequest copyWith({List<String>? servingAreaPlaceIds}) =>
      CreateBranchRequest(
        branchName: branchName,
        branchType: branchType,
        branchAddress: branchAddress,
        cityId: cityId,
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
        serviceIds: serviceIds,
        servingAreaPlaceIds: servingAreaPlaceIds ?? this.servingAreaPlaceIds,
      );
}
