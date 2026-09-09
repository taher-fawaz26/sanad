import 'package:branches/src/data/models/requests/update_branch_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = UpdateBranchRequest(
    branchName: 'Downtown Branch',
    branchAddress: 'Building 5, Sheikh Zayed Road',
    branchPhone: '+971501234567',
  );

  group('UpdateBranchRequest.toMap', () {
    test('omits both arrays when they are absent — the no-change case', () {
      final map = base.toMap();

      expect(map.containsKey('serviceIds'), isFalse);
      expect(map.containsKey('servingAreaPlaceIds'), isFalse);
    });

    test('sends both arrays when populated', () {
      final map = const UpdateBranchRequest(
            branchName: 'Downtown Branch',
        branchAddress: 'Building 5, Sheikh Zayed Road',
        branchPhone: '+971501234567',
        serviceIds: ['svc-1', 'svc-2'],
        servingAreaPlaceIds: ['ChIJvRmU9K1DXz4RYKyuhY6v0wM'],
      ).toMap();

      expect(map['serviceIds'], ['svc-1', 'svc-2']);
      expect(map['servingAreaPlaceIds'], ['ChIJvRmU9K1DXz4RYKyuhY6v0wM']);
    });

    test(
      'never transmits an explicitly empty array — PATCH now rejects one',
      () {
        // The regression this pins: a section edit builds a full-payload PATCH
        // from the current branch, and a branch whose areas or services failed
        // to load would previously send `[]`. That used to be a harmless no-op
        // and is now a `400`, so an empty list has to read as "no change".
        final map = const UpdateBranchRequest(
                branchName: 'Downtown Branch',
          branchAddress: 'Building 5, Sheikh Zayed Road',
          branchPhone: '+971501234567',
          serviceIds: [],
          servingAreaPlaceIds: [],
        ).toMap();

        expect(map.containsKey('serviceIds'), isFalse);
        expect(map.containsKey('servingAreaPlaceIds'), isFalse);
      },
    );

    test('keeps the always-present identity fields', () {
      final map = base.toMap();

      expect(map['branchName'], 'Downtown Branch');
      expect(map['branchAddress'], 'Building 5, Sheikh Zayed Road');
      expect(map['branchPhone'], '+971501234567');
    });

    test('sends workerIds when given, including an empty list', () {
      // Unlike the two arrays above, `workerIds` has no minItems rule on
      // PATCH, so an empty list stays meaningful and is passed through.
      final map = const UpdateBranchRequest(
            branchName: 'Downtown Branch',
        branchAddress: 'Building 5, Sheikh Zayed Road',
        branchPhone: '+971501234567',
        workerIds: [],
      ).toMap();

      expect(map['workerIds'], isEmpty);
    });
  });
}
