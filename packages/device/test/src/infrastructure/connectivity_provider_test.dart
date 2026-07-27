import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device/src/domain/enums/connectivity_status.dart';
import 'package:device/src/infrastructure/providers/connectivity_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityProvider provider;

  setUp(() {
    connectivity = _MockConnectivity();
    provider = ConnectivityProvider(connectivity);
  });

  group('currentStatus mapping', () {
    Future<ConnectivityStatus> statusFor(List<ConnectivityResult> r) {
      when(connectivity.checkConnectivity).thenAnswer((_) async => r);
      return provider.currentStatus();
    }

    test('maps wifi', () async {
      expect(
        await statusFor([ConnectivityResult.wifi]),
        ConnectivityStatus.wifi,
      );
    });

    test('maps mobile', () async {
      expect(
        await statusFor([ConnectivityResult.mobile]),
        ConnectivityStatus.mobile,
      );
    });

    test('maps ethernet', () async {
      expect(
        await statusFor([ConnectivityResult.ethernet]),
        ConnectivityStatus.ethernet,
      );
    });

    test('maps none', () async {
      expect(
        await statusFor([ConnectivityResult.none]),
        ConnectivityStatus.none,
      );
    });

    test('maps satellite to other', () async {
      expect(
        await statusFor([ConnectivityResult.satellite]),
        ConnectivityStatus.other,
      );
    });

    test('empty list is none', () async {
      expect(await statusFor([]), ConnectivityStatus.none);
    });

    test('prefers wifi over mobile when both present', () async {
      expect(
        await statusFor([ConnectivityResult.mobile, ConnectivityResult.wifi]),
        ConnectivityStatus.wifi,
      );
    });
  });

  group('onStatusChanged', () {
    test('maps the plugin stream to domain statuses', () async {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.wifi],
          [ConnectivityResult.none],
        ]),
      );

      final emitted = await provider.onStatusChanged().toList();

      expect(
        emitted,
        [ConnectivityStatus.wifi, ConnectivityStatus.none],
      );
    });
  });
}
