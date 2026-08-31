import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/protocol_test_support.dart';

void main() {
  group('schemaVersion', () {
    test('accepts the current version', () {
      final result = validatorWith().validate(payload([textNode('hi')]));

      expect(result.hasRenderableUi, isTrue);
      expect(result.document!.schemaVersion, 1);
      expect(result.diagnostics, isEmpty);
    });

    test('rejects a newer version outright and explains why', () {
      final result = validatorWith().validate(
        payload([textNode('hi')], schemaVersion: 2),
      );

      expect(result.hasRenderableUi, isFalse);
      expect(result.document, isNull);
      expect(
        result.hasCode(AiUiDiagnosticCode.unsupportedSchemaVersion),
        isTrue,
      );
    });

    test('rejects a missing version', () {
      final result = validatorWith().validate(
        payload([textNode('hi')], schemaVersion: null),
      );

      expect(result.hasRenderableUi, isFalse);
      expect(
        result.hasCode(AiUiDiagnosticCode.unsupportedSchemaVersion),
        isTrue,
      );
    });

    test('rejects a stringly-typed version', () {
      // `"1"` is the mistake an agent is most likely to make. It must not be
      // silently coerced — a client that guesses here would happily render a
      // payload written against a different contract.
      final result = validatorWith().validate(
        payload([textNode('hi')], schemaVersion: '1'),
      );

      expect(result.hasRenderableUi, isFalse);
      expect(
        result.hasCode(AiUiDiagnosticCode.unsupportedSchemaVersion),
        isTrue,
      );
    });

    test('rejects version 0', () {
      final result = validatorWith().validate(
        payload([textNode('hi')], schemaVersion: 0),
      );

      expect(result.hasRenderableUi, isFalse);
    });
  });

  group('blocks', () {
    test('rejects a payload with no blocks array', () {
      final result = validatorWith().validate(<String, dynamic>{
        'schemaVersion': 1,
      });

      expect(result.hasRenderableUi, isFalse);
      expect(result.hasCode(AiUiDiagnosticCode.malformedPayload), isTrue);
    });

    test('rejects blocks that is not an array', () {
      final result = validatorWith().validate(<String, dynamic>{
        'schemaVersion': 1,
        'blocks': <String, dynamic>{},
      });

      expect(result.hasRenderableUi, isFalse);
      expect(result.hasCode(AiUiDiagnosticCode.malformedPayload), isTrue);
    });

    test('an empty blocks array parses but is not renderable', () {
      final result = validatorWith().validate(payload([]));

      expect(result.document, isNotNull);
      expect(result.hasRenderableUi, isFalse);
    });

    test('truncates past maxBlocks but keeps the rest', () {
      final result = validatorWith().validate(
        payload([for (var i = 0; i < 20; i++) textNode('t$i', id: 'n$i')]),
      );

      expect(result.document!.blocks, hasLength(AiUiLimits.defaults.maxBlocks));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('a malformed block is dropped without taking its siblings', () {
      final result = validatorWith().validate(
        payload([
          textNode('first', id: 'a'),
          <String, dynamic>{'type': 'text', 'id': 'bad'}, // no `text`
          textNode('third', id: 'c'),
        ]),
      );

      expect(result.document!.blocks.map((b) => b.id), ['a', 'c']);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });
  });

  group('unknown node types', () {
    test('renders fallbackText as a text node', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'future_component',
            'id': 'f1',
            'fallbackText': 'Three services near you',
          },
        ]),
      );

      final block = result.document!.blocks.single;
      expect(block, isA<AiUiTextNode>());
      expect((block as AiUiTextNode).text, 'Three services near you');
      expect(result.hasCode(AiUiDiagnosticCode.unknownNodeType), isTrue);
    });

    test('drops the node in release mode when there is no fallbackText', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{'type': 'future_component', 'id': 'f1'},
          textNode('still here', id: 'ok'),
        ]),
      );

      expect(result.document!.blocks.map((b) => b.id), ['ok']);
      expect(result.hasCode(AiUiDiagnosticCode.unknownNodeType), isTrue);
    });

    test('keeps a dev-only marker when keepUnsupportedNodes is set', () {
      final result = validatorWith(keepUnsupportedNodes: true).validate(
        payload([
          <String, dynamic>{'type': 'future_component', 'id': 'f1'},
        ]),
      );

      final block = result.document!.blocks.single;
      expect(block, isA<AiUiUnsupportedNode>());
      expect((block as AiUiUnsupportedNode).rawType, 'future_component');
      expect(block.type, isNull);
    });

    test('drops a node whose type is missing or not a string', () {
      for (final bad in <Object?>[null, 42, <String>[], '']) {
        final result = validatorWith().validate(
          payload([
            <String, dynamic>{'id': 'x', if (bad != null) 'type': bad},
          ]),
        );
        expect(result.document!.blocks, isEmpty, reason: 'for type=$bad');
      }
    });
  });

  group('property handling', () {
    test('ignores an unknown property but says so', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'text',
            'id': 'n1',
            'text': 'hi',
            'color': '#FF0000', // never honoured — tokens only
            'padding': 17,
          },
        ]),
      );

      expect(result.hasRenderableUi, isTrue);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
      expect(
        result.diagnostics.where(
          (d) => d.code == AiUiDiagnosticCode.invalidProperty,
        ),
        hasLength(2),
      );
    });

    test('falls back to the documented default for an unknown enum value', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'text',
            'id': 'n1',
            'text': 'hi',
            'style': 'gigantic',
          },
        ]),
      );

      final node = result.document!.blocks.single as AiUiTextNode;
      expect(node.style, AiUiTextStyleToken.body);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('drops a node whose required property has the wrong type', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{'type': 'text', 'id': 'n1', 'text': 42},
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('drops a node whose required string is blank', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{'type': 'text', 'id': 'n1', 'text': '   '},
        ]),
      );

      expect(result.document!.blocks, isEmpty);
    });

    test('flags a reserved property rather than silently ignoring it', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'text',
            'id': 'n1',
            'text': 'hi',
            'textKey': 'ai_chat.greeting',
          },
        ]),
      );

      expect(result.hasCode(AiUiDiagnosticCode.reservedProperty), isTrue);
      expect(result.hasRenderableUi, isTrue);
    });

    test('derives a stable id from the document path when none is given', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'column',
            'children': [
              <String, dynamic>{'type': 'text', 'text': 'leaf'},
            ],
          },
        ]),
      );

      final column = result.document!.blocks.single;
      expect(column.id, 'blocks[0]');
      expect(column.children.single.id, 'blocks[0].children[0]');
    });
  });

  group('limits', () {
    test('cuts a too-deep branch but keeps content within the budget', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'column',
            'id': 'root',
            'children': [
              textNode('shallow', id: 'keep'),
              nestedColumns(10),
            ],
          },
        ]),
      );

      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
      // The over-deep sibling is cut; the reply is not.
      expect(result.document!.blocks.single.children.map((c) => c.id), [
        'keep',
      ]);
    });

    test('a layout container left empty by truncation is dropped too', () {
      // A chain of columns with nothing inside the depth budget has no content
      // to show, so it collapses entirely rather than rendering a stack of
      // empty Columns. Cards behave differently — see below — because a card
      // still carries its own title.
      final result = validatorWith().validate(payload([nestedColumns(10)]));

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('a card with a title survives having no renderable children', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'card',
            'id': 'c',
            'title': 'Your appointment',
            'children': <Object?>[],
          },
        ]),
      );

      final card = result.document!.blocks.single as AiUiCardNode;
      expect(card.title, 'Your appointment');
      expect(card.children, isEmpty);
    });

    test('truncates row children past the row limit', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'row',
            'id': 'r',
            'children': [
              for (var i = 0; i < 20; i++) textNode('t$i', id: 't$i'),
            ],
          },
        ]),
      );

      expect(
        result.document!.blocks.single.children,
        hasLength(AiUiLimits.defaults.maxRowChildren),
      );
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('truncates list items past the list limit', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'list',
            'id': 'l',
            'children': [
              for (var i = 0; i < 40; i++)
                <String, dynamic>{
                  'type': 'list_item',
                  'id': 'i$i',
                  'title': 'Item $i',
                },
            ],
          },
        ]),
      );

      expect(
        result.document!.blocks.single.children,
        hasLength(AiUiLimits.defaults.maxListChildren),
      );
    });

    test('rejects the whole payload past maxNodes', () {
      // A child/depth overrun truncates; a node-count overrun is a different
      // failure mode on purpose — past that point the tree is not something we
      // want to keep walking.
      final result =
          validatorWith(
            limits: const AiUiLimits(maxNodes: 5),
          ).validate(
            payload([for (var i = 0; i < 10; i++) textNode('t$i', id: 'n$i')]),
          );

      expect(result.document, isNull);
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('truncates over-long text instead of dropping the node', () {
      final result = validatorWith(
        limits: const AiUiLimits(maxTextLength: 10),
      ).validate(payload([textNode('x' * 50)]));

      final node = result.document!.blocks.single as AiUiTextNode;
      expect(node.text, hasLength(10));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('caps the number of actions in one message', () {
      final result =
          validatorWith(
            limits: const AiUiLimits(maxActions: 2),
          ).validate(
            payload([for (var i = 0; i < 5; i++) buttonNode(id: 'b$i')]),
          );

      // Buttons past the cap lose their action and are therefore dropped.
      expect(result.document!.blocks, hasLength(2));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('caps the number of images in one message', () {
      final result =
          validatorWith(
            limits: const AiUiLimits(maxImages: 1),
          ).validate(
            payload([
              for (var i = 0; i < 3; i++)
                <String, dynamic>{
                  'type': 'image',
                  'id': 'img$i',
                  'assetId': publishedAssetId,
                  'alt': 'A service',
                },
            ]),
          );

      expect(result.document!.blocks, hasLength(1));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('truncates rich_text spans past the span limit', () {
      final result =
          validatorWith(
            limits: const AiUiLimits(maxRichTextSpans: 3),
          ).validate(
            payload([
              <String, dynamic>{
                'type': 'rich_text',
                'id': 'rt',
                'spans': [
                  for (var i = 0; i < 10; i++) <String, dynamic>{'text': 's$i'},
                ],
              },
            ]),
          );

      final node = result.document!.blocks.single as AiUiRichTextNode;
      expect(node.spans, hasLength(3));
    });
  });

  group('actions', () {
    test('parses a known action with its params', () {
      final result = validatorWith().validate(payload([buttonNode()]));

      final button = result.document!.blocks.single as AiUiButtonNode;
      expect(button.action.type, AiUiActionType.openService);
      expect(button.action.serviceId, 'svc_1');
    });

    test('drops a button whose action is outside the protocol catalog', () {
      final result = validatorWith().validate(
        payload([
          buttonNode(
            action: <String, dynamic>{'type': 'delete_everything'},
          ),
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.unknownActionType), isTrue);
    });

    test('drops a button whose action this host does not implement', () {
      // The protocol knows `open_url`; this host's registry does not. The
      // validator consults the host's real key set, so an action with no
      // handler can never reach a widget.
      final result =
          validatorWith(
            supportedActions: {AiUiActionType.sendMessage},
          ).validate(
            payload([
              buttonNode(
                action: <String, dynamic>{
                  'type': 'open_url',
                  'url': 'https://cdn.trysanad.us/x',
                },
              ),
            ]),
          );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.unknownActionType), isTrue);
    });

    test('drops a button whose action is missing a required param', () {
      final result = validatorWith().validate(
        payload([
          buttonNode(action: <String, dynamic>{'type': 'open_service'}),
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('drops a button whose action is not an object', () {
      for (final bad in <Object?>['open_service()', 42, <String>[]]) {
        final result = validatorWith().validate(
          payload([
            <String, dynamic>{
              'type': 'button',
              'id': 'b',
              'label': 'Go',
              'action': bad,
            },
          ]),
        );
        expect(result.document!.blocks, isEmpty, reason: 'for action=$bad');
      }
    });

    test('a chip keeps its label when its action cannot be resolved', () {
      // Unlike a button, a chip reads fine as a static label, so it degrades
      // rather than disappearing.
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'chip',
            'id': 'c',
            'label': 'Popular',
            'action': <String, dynamic>{'type': 'nope'},
          },
        ]),
      );

      final chip = result.document!.blocks.single as AiUiChipNode;
      expect(chip.label, 'Popular');
      expect(chip.action, isNull);
      expect(result.hasCode(AiUiDiagnosticCode.unknownActionType), isTrue);
    });

    test('blocks open_url that fails the URL policy', () {
      final result = validatorWith().validate(
        payload([
          buttonNode(
            action: <String, dynamic>{
              'type': 'open_url',
              'url': 'https://evil.example/steal',
            },
          ),
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.blockedUrl), isTrue);
    });

    test('allows open_url on an allowlisted host', () {
      final result = validatorWith().validate(
        payload([
          buttonNode(
            action: <String, dynamic>{
              'type': 'open_url',
              'url': 'https://cdn.trysanad.us/terms.pdf',
            },
          ),
        ]),
      );

      final button = result.document!.blocks.single as AiUiButtonNode;
      expect(button.action.type, AiUiActionType.openUrl);
    });

    test('coerces scalar params and rejects structured ones', () {
      final result = validatorWith().validate(
        payload([
          buttonNode(
            action: <String, dynamic>{
              'type': 'open_route',
              'routeKey': 'home',
              'count': 3,
              'flag': true,
              'nested': <String, dynamic>{'a': 1},
              'params': <String, dynamic>{'tab': 'orders'},
            },
          ),
        ]),
      );

      final button = result.document!.blocks.single as AiUiButtonNode;
      expect(button.action.routeKey, 'home');
      expect(button.action.params['count'], '3');
      expect(button.action.params['flag'], 'true');
      expect(button.action.params.containsKey('nested'), isFalse);
      expect(button.action.routeParams['tab'], 'orders');
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('open_route cannot express a raw path', () {
      // There is simply no field for one — the agent names a symbolic key and
      // the app resolves it, so a payload cannot navigate anywhere the app has
      // not explicitly published.
      expect(
        AiUiActionType.openRoute.requiredParams,
        equals({'routeKey'}),
      );
    });
  });

  group('images', () {
    test('accepts a published assetId', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'image',
            'id': 'i',
            'assetId': publishedAssetId,
            'alt': 'AC unit',
          },
        ]),
      );

      final image = result.document!.blocks.single as AiUiImageNode;
      expect(image.source, const AiUiAssetImage(publishedAssetId));
    });

    test('rejects a remote url regardless of host', () {
      // schemaVersion 1 is assetId-only. This is not a host check — even the
      // app's own CDN is refused, because an agent-supplied image URL is a
      // network and tracking surface v1 does not need.
      for (final url in [
        rejectedImageUrl,
        'https://evil.example/tracker.gif',
      ]) {
        final result = validatorWith().validate(
          payload([
            <String, dynamic>{
              'type': 'image',
              'id': 'i',
              'url': url,
              'alt': 'AC unit',
            },
          ]),
        );

        expect(result.document!.blocks, isEmpty, reason: url);
        expect(
          result.hasCode(AiUiDiagnosticCode.reservedProperty),
          isTrue,
          reason: url,
        );
      }
    });

    test('drops an image with an unpublished assetId', () {
      final result = validatorWith(knownAssetIds: {'service_placeholder'})
          .validate(
            payload([
              <String, dynamic>{
                'type': 'image',
                'id': 'i',
                'assetId': 'arbitrary_file',
                'alt': 'AC unit',
              },
            ]),
          );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.unknownAssetId), isTrue);
    });

    test('drops an image with no alt text', () {
      // An inaccessible image is not an acceptable degradation.
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'image',
            'id': 'i',
            'assetId': publishedAssetId,
          },
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('uses the assetId and flags the url when both are present', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'image',
            'id': 'i',
            'assetId': publishedAssetId,
            'url': rejectedImageUrl,
            'alt': 'AC unit',
          },
        ]),
      );

      final image = result.document!.blocks.single as AiUiImageNode;
      expect(image.source, const AiUiAssetImage(publishedAssetId));
      expect(result.hasCode(AiUiDiagnosticCode.reservedProperty), isTrue);
    });
  });

  group('semantic nodes', () {
    test('parses a service_card with structured price', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'service_card',
            'id': 's1',
            'serviceId': 'svc_123',
            'title': 'AC Maintenance',
            'price': <String, dynamic>{'amount': 100, 'currency': 'aed'},
            'action': <String, dynamic>{
              'type': 'open_service',
              'serviceId': 'svc_123',
            },
          },
        ]),
      );

      final card = result.document!.blocks.single as AiUiServiceCardNode;
      expect(card.serviceId, 'svc_123');
      expect(card.price, const AiUiMoney(amount: 100, currency: 'AED'));
      expect(card.action!.type, AiUiActionType.openService);
    });

    test('drops a malformed price rather than the whole card', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'service_card',
            'id': 's1',
            'serviceId': 'svc_123',
            'title': 'AC Maintenance',
            'price': <String, dynamic>{'amount': '100', 'currency': 'AED'},
          },
        ]),
      );

      final card = result.document!.blocks.single as AiUiServiceCardNode;
      expect(card.price, isNull);
      expect(card.title, 'AC Maintenance');
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('parses appointment_card and normalises the instant to UTC', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'appointment_card',
            'id': 'a1',
            'appointmentId': 'apt_1',
            'title': 'AC Maintenance',
            'startsAt': '2026-09-01T06:00:00+04:00',
            'statusTone': 'success',
          },
        ]),
      );

      final card = result.document!.blocks.single as AiUiAppointmentCardNode;
      expect(card.startsAt.isUtc, isTrue);
      expect(card.startsAt, DateTime.utc(2026, 9, 1, 2));
      expect(card.statusTone, AiUiTone.success);
    });

    test('drops appointment_card with an unparseable instant', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'appointment_card',
            'id': 'a1',
            'appointmentId': 'apt_1',
            'title': 'AC Maintenance',
            'startsAt': 'tomorrow at 10',
          },
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('quick_reply needs at least the minimum number of valid options', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'quick_reply',
            'id': 'q1',
            'options': [
              <String, dynamic>{
                'label': 'Yes',
                'action': <String, dynamic>{
                  'type': 'send_message',
                  'text': 'Yes',
                },
              },
            ],
          },
        ]),
      );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('quick_reply parses a valid pair', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'quick_reply',
            'id': 'q1',
            'options': [
              for (final label in ['Yes', 'No'])
                <String, dynamic>{
                  'label': label,
                  'action': <String, dynamic>{
                    'type': 'send_message',
                    'text': label,
                  },
                },
            ],
          },
        ]),
      );

      final node = result.document!.blocks.single as AiUiQuickReplyNode;
      expect(node.options.map((o) => o.label), ['Yes', 'No']);
      expect(node.options.first.action.text, 'Yes');
    });

    test('a list rejects children that are not list_items', () {
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'list',
            'id': 'l',
            'children': [
              <String, dynamic>{
                'type': 'list_item',
                'id': 'i1',
                'title': 'Downtown',
              },
              textNode('not an item', id: 'stray'),
            ],
          },
        ]),
      );

      final list = result.document!.blocks.single as AiUiListNode;
      expect(list.children.map((c) => c.id), ['i1']);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });
  });

  group('totality', () {
    test('never throws on adversarial or nonsense input', () {
      final cases = <Map<String, dynamic>>[
        <String, dynamic>{},
        <String, dynamic>{'schemaVersion': 1},
        <String, dynamic>{'schemaVersion': 1, 'blocks': null},
        <String, dynamic>{
          'schemaVersion': 1,
          'blocks': [null, 1, 'x', <String>[], <String, dynamic>{}],
        },
        <String, dynamic>{
          'schemaVersion': 1,
          'blocks': [
            <String, dynamic>{'type': 'row', 'children': 'not-a-list'},
          ],
        },
        <String, dynamic>{
          'schemaVersion': 1,
          'blocks': [
            <String, dynamic>{
              'type': 'card',
              'children': [
                <String, dynamic>{'type': 'card', 'children': null},
              ],
            },
          ],
        },
        payload([nestedColumns(200)]),
      ];

      for (final input in cases) {
        expect(
          () => validatorWith().validate(input),
          returnsNormally,
          reason: 'input: $input',
        );
      }
    });

    test('parse() surfaces decode failures as diagnostics, not exceptions', () {
      final result = validatorWith().parse('{not json');

      expect(result.hasRenderableUi, isFalse);
      expect(result.hasCode(AiUiDiagnosticCode.malformedPayload), isTrue);
    });

    test('diagnostics never carry the payload prose they rejected', () {
      const secret = 'CONFIDENTIAL-PATIENT-NAME';
      final result = validatorWith().validate(
        payload([
          <String, dynamic>{
            'type': 'unknown_thing',
            'id': 'n',
            'fallbackText': secret,
          },
        ]),
      );

      expect(result.diagnostics, isNotEmpty);
      for (final diagnostic in result.diagnostics) {
        expect(diagnostic.toString(), isNot(contains(secret)));
      }
    });
  });
}
