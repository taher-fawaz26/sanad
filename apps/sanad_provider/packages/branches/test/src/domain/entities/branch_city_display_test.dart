// SAN-774: the City row and the address line must never disagree.
//
// `BranchEntity.city` is the backend's `city.name`, which it localizes from
// the request language. One field feeds both the City key/value row and
// `displayAddress` (used for the header caption, the address row and the maps
// launcher), so there is structurally only one spelling of the city on screen.
//
// The bug this replaces: the City row was fed a name re-resolved from the
// cities list while `displayAddress` kept using the payload's own `city`, so
// under Arabic the row read "حتا" and the address line right above it read
// "…, Hatta".
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:flutter_test/flutter_test.dart';

BranchEntity branchIn(String city) => BranchEntity(
  id: 'branch-1',
  branchName: 'HQ Branch',
  branchAddress: '1 Sheikh Zayed Rd',
  city: city,
  branchPhone: '+971501234567',
  isAvailable: true,
  availabilityMode: BranchAvailabilityMode.coreHours,
  branchType: BranchType.mainBranch,
  cityId: 'city-1',
);

void main() {
  test('displayAddress is built from the same city the City row shows', () {
    for (final city in ['Hatta', 'حتا', 'Dubai', 'دبي']) {
      final branch = branchIn(city);

      expect(branch.city, city);
      expect(
        branch.displayAddress,
        '1 Sheikh Zayed Rd, $city',
        reason: 'the address line must not carry a different spelling',
      );
      expect(branch.displayAddress, endsWith(branch.city));
    }
  });

  test('an Arabic payload stays Arabic end to end', () {
    final branch = branchIn('حتا');

    expect(branch.displayAddress.contains('Hatta'), isFalse);
    expect(branch.displayAddress.contains('حتا'), isTrue);
  });
}
