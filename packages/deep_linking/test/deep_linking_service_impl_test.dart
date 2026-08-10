import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:deep_linking/deep_linking.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLinks extends Mock implements AppLinks {}

void main() {
  const config = DeepLinkConfig(hosts: {'links.trysanad.us'});

  late _MockAppLinks appLinks;
  late StreamController<Uri> uriStreamController;
  late DeepLinkingServiceImpl service;

  setUp(() {
    appLinks = _MockAppLinks();
    uriStreamController = StreamController<Uri>.broadcast();
    when(
      () => appLinks.uriLinkStream,
    ).thenAnswer((_) => uriStreamController.stream);
    service = DeepLinkingServiceImpl(config: config, appLinks: appLinks);
  });

  tearDown(() async {
    service.dispose();
    await uriStreamController.close();
  });

  group('getInitialLink (cold start)', () {
    test('resolves a trusted initial link', () async {
      when(() => appLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('https://links.trysanad.us/invitation/abc123'),
      );

      final link = await service.getInitialLink();

      expect(link?.location, '/invitation/abc123');
    });

    test('returns null when there is no initial link', () async {
      when(() => appLinks.getInitialLink()).thenAnswer((_) async => null);

      expect(await service.getInitialLink(), isNull);
    });

    test(
      'returns null instead of throwing when the platform call fails',
      () async {
        when(
          () => appLinks.getInitialLink(),
        ).thenThrow(Exception('platform error'));

        expect(await service.getInitialLink(), isNull);
      },
    );

    test('returns null for an untrusted initial link', () async {
      when(() => appLinks.getInitialLink()).thenAnswer(
        (_) async => Uri.parse('https://evil.example.com/invitation/abc123'),
      );

      expect(await service.getInitialLink(), isNull);
    });
  });

  group('onLink (warm start / resume)', () {
    test('emits a validated link received while running', () async {
      final links = <DeepLink>[];
      service.onLink.listen(links.add);

      uriStreamController.add(
        Uri.parse('https://links.trysanad.us/invitation/xyz789'),
      );
      await pumpEventQueue();

      expect(links, hasLength(1));
      expect(links.single.location, '/invitation/xyz789');
    });

    test('does not emit an untrusted link', () async {
      final links = <DeepLink>[];
      service.onLink.listen(links.add);

      uriStreamController.add(
        Uri.parse('https://evil.example.com/invitation/xyz789'),
      );
      await pumpEventQueue();

      expect(links, isEmpty);
    });

    test(
      'does not re-emit an exact duplicate of the last handled link',
      () async {
        final links = <DeepLink>[];
        service.onLink.listen(links.add);

        final uri = Uri.parse('https://links.trysanad.us/invitation/dup1');
        uriStreamController
          ..add(uri)
          ..add(uri);
        await pumpEventQueue();

        expect(links, hasLength(1));
      },
    );

    test(
      'does not process the cold-start link a second time via the stream',
      () async {
        when(() => appLinks.getInitialLink()).thenAnswer(
          (_) async => Uri.parse('https://links.trysanad.us/invitation/cold1'),
        );
        await service.getInitialLink();

        final links = <DeepLink>[];
        service.onLink.listen(links.add);
        uriStreamController.add(
          Uri.parse('https://links.trysanad.us/invitation/cold1'),
        );
        await pumpEventQueue();

        expect(links, isEmpty);
      },
    );
  });
}
