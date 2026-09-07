import 'package:branches/src/presentation/utils/coverage_location_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';

void main() {
  group('isCoverageLocationBlocked', () {
    // The core regression: Step 1 resolved a valid branch location, so Step 2
    // (coverage) must proceed — it consumes the stored location and never
    // needs live GPS. A disabled device-location service must NOT block it.
    test(
      'resolved location proceeds regardless of permission/service state',
      () {
        for (final status in [
          null,
          ...LocationPermissionStatus.values,
        ]) {
          expect(
            isCoverageLocationBlocked(
              hasResolvedLocation: true,
              permissionStatus: status,
            ),
            isFalse,
            reason:
                'resolved location should never be blocked (status=$status)',
          );
        }
      },
    );

    test(
      'resolved location + services disabled proceeds (the reported bug)',
      () {
        expect(
          isCoverageLocationBlocked(
            hasResolvedLocation: true,
            permissionStatus: LocationPermissionStatus.serviceDisabled,
          ),
          isFalse,
        );
      },
    );

    group('no resolved location (live-acquisition fallback)', () {
      test('granted proceeds', () {
        expect(
          isCoverageLocationBlocked(
            hasResolvedLocation: false,
            permissionStatus: LocationPermissionStatus.granted,
          ),
          isFalse,
        );
      });

      test('not-yet-checked blocks (must request first)', () {
        expect(
          isCoverageLocationBlocked(
            hasResolvedLocation: false,
            permissionStatus: null,
          ),
          isTrue,
        );
      });

      test('denied / permanentlyDenied / serviceDisabled all block', () {
        for (final status in [
          LocationPermissionStatus.denied,
          LocationPermissionStatus.permanentlyDenied,
          LocationPermissionStatus.serviceDisabled,
        ]) {
          expect(
            isCoverageLocationBlocked(
              hasResolvedLocation: false,
              permissionStatus: status,
            ),
            isTrue,
            reason: 'status=$status should block when no location exists',
          );
        }
      });
    });
  });
}
