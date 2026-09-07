import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  group('AddBranchDraft.hasValidResolvedLocation', () {
    const position = LatLng(25.2048, 55.2708);

    test('false on the initial (empty) draft', () {
      expect(const AddBranchDraft().hasValidResolvedLocation, isFalse);
    });

    test('true only with place id + position + non-empty address', () {
      final resolved = const AddBranchDraft().copyWith(
        branchAddress: () => 'Downtown, Dubai',
        pickedPosition: () => position,
        locationPlaceId: () => 'place-123',
      );
      expect(resolved.hasValidResolvedLocation, isTrue);
    });

    test('false when the Place ID is missing (dragged pin / raw GPS)', () {
      final noPlaceId = const AddBranchDraft().copyWith(
        branchAddress: () => 'Downtown, Dubai',
        pickedPosition: () => position,
        locationPlaceId: () => null,
      );
      expect(noPlaceId.hasValidResolvedLocation, isFalse);
    });

    test('false when the address is empty', () {
      final emptyAddress = const AddBranchDraft().copyWith(
        branchAddress: () => '',
        pickedPosition: () => position,
        locationPlaceId: () => 'place-123',
      );
      expect(emptyAddress.hasValidResolvedLocation, isFalse);
    });

    test('false when the position is missing', () {
      final noPosition = const AddBranchDraft().copyWith(
        branchAddress: () => 'Downtown, Dubai',
        pickedPosition: () => null,
        locationPlaceId: () => 'place-123',
      );
      expect(noPosition.hasValidResolvedLocation, isFalse);
    });

    test('a resolved location survives a later coverage-radius update', () {
      final resolved = const AddBranchDraft().copyWith(
        branchAddress: () => 'Downtown, Dubai',
        pickedPosition: () => position,
        locationPlaceId: () => 'place-123',
      );
      // Simulates staying on Step 2 and adjusting coverage — the canonical
      // branch location must not be invalidated by unrelated updates.
      final afterCoverage = resolved.copyWith(coverageRadiusKm: () => 5);
      expect(afterCoverage.hasValidResolvedLocation, isTrue);
    });
  });
}
