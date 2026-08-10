import 'dart:async';

import 'package:deep_linking/deep_linking.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake used instead of a mocked GoRouter — [DeepLinkDispatcher] depends
/// only on this interface, never on go_router directly.
class _FakeDeepLinkingService implements DeepLinkingService {
  _FakeDeepLinkingService({DeepLink? initial}) : _initial = initial;

  final DeepLink? _initial;
  final _controller = StreamController<DeepLink>.broadcast();
  bool disposed = false;

  void emit(DeepLink link) => _controller.add(link);

  @override
  Future<DeepLink?> getInitialLink() async => _initial;

  @override
  Stream<DeepLink> get onLink => _controller.stream;

  @override
  void dispose() {
    disposed = true;
    _controller.close();
  }
}

void main() {
  test('dispatches the cold-start link once started', () async {
    final service = _FakeDeepLinkingService(
      initial: DeepLink(
        uri: Uri.parse('sanadprovider://invitation/abc123'),
        location: '/invitation/abc123',
      ),
    );
    final navigated = <String>[];
    final dispatcher = DeepLinkDispatcher(
      service: service,
      onNavigate: navigated.add,
    );

    await dispatcher.start();

    expect(navigated, ['/invitation/abc123']);
  });

  test('dispatches links received while running (warm start)', () async {
    final service = _FakeDeepLinkingService();
    final navigated = <String>[];
    final dispatcher = DeepLinkDispatcher(
      service: service,
      onNavigate: navigated.add,
    );

    await dispatcher.start();
    service.emit(
      DeepLink(
        uri: Uri.parse('sanadprovider://branch/42'),
        location: '/branch/42',
      ),
    );
    await pumpEventQueue();

    expect(navigated, ['/branch/42']);
  });

  test(
    'stops dispatching after stop() without disposing the service',
    () async {
      final service = _FakeDeepLinkingService();
      final navigated = <String>[];
      final dispatcher = DeepLinkDispatcher(
        service: service,
        onNavigate: navigated.add,
      );

      await dispatcher.start();
      await dispatcher.stop();
      service.emit(
        DeepLink(
          uri: Uri.parse('sanadprovider://branch/42'),
          location: '/branch/42',
        ),
      );
      await pumpEventQueue();

      expect(navigated, isEmpty);
      expect(service.disposed, isFalse);
    },
  );

  test('does nothing when there is no cold-start link', () async {
    final service = _FakeDeepLinkingService();
    final navigated = <String>[];
    final dispatcher = DeepLinkDispatcher(
      service: service,
      onNavigate: navigated.add,
    );

    await dispatcher.start();

    expect(navigated, isEmpty);
  });
}
