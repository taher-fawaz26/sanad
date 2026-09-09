// SAN-774 contract guard.
//
// The live API contract is explicit: `CreateBranchDto`/`UpdateBranchDto`
// document `locationPlaceId` as "the branch city is derived from this and
// cannot be set independently, so there is no `cityId` field to send." Sending
// one is a 400 whose body — "property cityId should not exist" — was shown
// verbatim to users.
//
// The original ticket asked for `cityId` to be sent so the city could be
// edited. That request predates the contract change and must not be revived:
// city changes only by moving the map pin, i.e. by PATCHing
// `locationPlaceId` + `lat` + `lng` together.
import 'package:branches/src/data/models/requests/create_branch_request.dart';
import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const create = CreateBranchRequest(
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

  const update = UpdateBranchRequest(
    branchName: 'Downtown Branch',
    branchAddress: 'Building 5, Sheikh Zayed Road',
    branchPhone: '+971501234567',
    branchType: BranchType.mainBranch,
    locationPlaceId: 'ChIJvRmU9K1DXz4RYKyuhY6v0wM',
    lat: 25.2048,
    lng: 55.2708,
    radiusKm: 5,
  );

  test('neither request body carries a cityId or any city field', () {
    for (final entry in {
      'CreateBranchRequest': create.toMap(),
      'UpdateBranchRequest': update.toMap(),
    }.entries) {
      final keys = entry.value.keys.map((k) => k.toLowerCase());
      expect(
        keys.where((k) => k.contains('city')),
        isEmpty,
        reason: '${entry.key} must send no city field at all',
      );
    }
  });

  test('the city is instead derived from the location triple, which is sent '
      'as a unit', () {
    final map = update.toMap();

    expect(map['locationPlaceId'], 'ChIJvRmU9K1DXz4RYKyuhY6v0wM');
    expect(map['lat'], 25.2048);
    expect(map['lng'], 55.2708);
  });

  test('omitting the place id omits lat/lng too — a partial location is not '
      'a valid update', () {
    final map = const UpdateBranchRequest(
      branchName: 'Downtown Branch',
      branchAddress: 'Building 5, Sheikh Zayed Road',
      branchPhone: '+971501234567',
      lat: 25.2048,
      lng: 55.2708,
    ).toMap();

    expect(map.containsKey('locationPlaceId'), isFalse);
    expect(map.containsKey('lat'), isFalse);
    expect(map.containsKey('lng'), isFalse);
  });
}
