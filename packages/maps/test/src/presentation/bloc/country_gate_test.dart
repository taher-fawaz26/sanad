import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps/src/presentation/bloc/coverage_area/coverage_area_bloc.dart';
import 'package:maps/src/presentation/bloc/location_picker/location_picker_bloc.dart';

void main() {
  const center = LatLng(25.2, 55.3);

  group('CoverageAreaState country gate', () {
    CoverageAreaState ready({String? iso}) => CoverageAreaState(
      status: CoverageAreaStatus.ready,
      center: center,
      address: 'Somewhere',
      isoCountryCode: iso,
    );

    test('allows confirm inside the UAE (AE)', () {
      final state = ready(iso: 'AE');
      expect(state.isOutsideCountry, isFalse);
      expect(state.canConfirm, isTrue);
    });

    test('blocks confirm when the centre is in another country', () {
      final state = ready(iso: 'OM');
      expect(state.isOutsideCountry, isTrue);
      expect(state.canConfirm, isFalse);
    });

    test('unknown country does not block (null geocode is a no-op)', () {
      final state = ready();
      expect(state.isOutsideCountry, isFalse);
      expect(state.canConfirm, isTrue);
    });
  });

  group('LocationPickerState country gate', () {
    LocationPickerState ready({String? iso}) => LocationPickerState(
      status: LocationPickerStatus.ready,
      position: center,
      address: 'Somewhere',
      isoCountryCode: iso,
    );

    test('allows confirm inside the UAE (AE)', () {
      final state = ready(iso: 'AE');
      expect(state.isOutsideCountry, isFalse);
      expect(state.canConfirm, isTrue);
    });

    test('blocks confirm when the pin is in another country', () {
      final state = ready(iso: 'SA');
      expect(state.isOutsideCountry, isTrue);
      expect(state.canConfirm, isFalse);
    });

    test('unknown country does not block (null geocode is a no-op)', () {
      final state = ready();
      expect(state.isOutsideCountry, isFalse);
      expect(state.canConfirm, isTrue);
    });
  });
}
