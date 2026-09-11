import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/protocol_test_support.dart';

/// Validation of the semantic node types added for the current Figma
/// component set, plus the shared `actions` row every card now accepts.
///
/// The round-trip suite already proves each node's *happy* path — a fully
/// populated instance serializes to something the validator accepts with zero
/// diagnostics. What is asserted here is the other half: what the validator
/// does with a payload the agent got wrong, which is the half a backend
/// actually hits.
void main() {
  const sendYes = AiUiAction(
    type: AiUiActionType.sendMessage,
    params: {'text': 'Yes'},
  );

  Map<String, dynamic> sendAction([String text = 'Yes']) => {
    'type': 'send_message',
    'text': text,
  };

  AiUiParseResult parse(Map<String, dynamic> node) =>
      validatorWith().validate(payload([node]));

  T? single<T extends AiUiNode>(Map<String, dynamic> node) {
    final blocks = parse(node).document?.blocks ?? const [];
    return blocks.isEmpty ? null : blocks.single as T;
  }

  group('the shared actions row', () {
    Map<String, dynamic> orderWith(Object? actions) => {
      'type': 'order_card',
      'id': 'o1',
      'orderId': 'ord_1',
      'title': 'Order #1042',
      if (actions != null) 'actions': actions,
    };

    test('parses label, action, variant and intent', () {
      final node = single<AiUiOrderCardNode>(
        orderWith([
          {
            'label': 'Cancel order',
            'action': sendAction('Cancel my order'),
            'variant': 'outline',
            'intent': 'destructive',
          },
        ]),
      )!;

      final entry = node.actions.single;
      expect(entry.label, 'Cancel order');
      expect(entry.action.type, AiUiActionType.sendMessage);
      expect(entry.variant, AiUiButtonVariant.outline);
      expect(entry.intent, AiUiButtonIntent.destructive);
    });

    test('defaults variant and intent to a standard primary button', () {
      final node = single<AiUiOrderCardNode>(
        orderWith([
          {'label': 'Track', 'action': sendAction()},
        ]),
      )!;

      expect(node.actions.single.variant, AiUiButtonVariant.primary);
      expect(node.actions.single.intent, AiUiButtonIntent.standard);
    });

    test('drops the entry whose action is unresolvable, keeps the card', () {
      // The `button` rule, not the `chip` rule: these are buttons, and a
      // button no handler implements is a dead control.
      final result = parse(
        orderWith([
          {
            'label': 'Delete everything',
            'action': {'type': 'delete_account'},
          },
          {'label': 'Track', 'action': sendAction()},
        ]),
      );

      final node = result.document!.blocks.single as AiUiOrderCardNode;
      expect(node.actions.map((a) => a.label), ['Track']);
      expect(result.hasCode(AiUiDiagnosticCode.unknownActionType), isTrue);
    });

    test('drops an entry with no label', () {
      final node = single<AiUiOrderCardNode>(
        orderWith([
          {'action': sendAction()},
        ]),
      )!;

      expect(node.actions, isEmpty);
    });

    test('truncates past the row limit', () {
      final result = parse(
        orderWith([
          for (var i = 0; i < 6; i++)
            {'label': 'Action $i', 'action': sendAction('$i')},
        ]),
      );

      final node = result.document!.blocks.single as AiUiOrderCardNode;
      expect(node.actions, hasLength(AiUiLimits.defaults.maxCardActions));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('a non-array actions value is ignored, not fatal', () {
      final result = parse(orderWith('Confirm'));

      final node = result.document!.blocks.single as AiUiOrderCardNode;
      expect(node.actions, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });
  });

  group('order_card', () {
    test('needs an id and a title', () {
      expect(
        parse({'type': 'order_card', 'id': 'o1', 'title': 'Order #1'}).document,
        isNotNull,
      );
      expect(
        single<AiUiOrderCardNode>({
          'type': 'order_card',
          'id': 'o1',
          'title': 'Order #1',
        }),
        isNull,
        reason: 'orderId is required',
      );
      expect(
        single<AiUiOrderCardNode>({
          'type': 'order_card',
          'id': 'o1',
          'orderId': 'ord_1',
        }),
        isNull,
        reason: 'title is required',
      );
    });

    test('keeps the card when the amount is malformed', () {
      // The same asymmetry `service_card` already has for `price`: a bad
      // number loses the number, not the order.
      final result = parse({
        'type': 'order_card',
        'id': 'o1',
        'orderId': 'ord_1',
        'title': 'Order #1042',
        'amount': {'amount': 'ninety', 'currency': 'AED'},
      });

      final node = result.document!.blocks.single as AiUiOrderCardNode;
      expect(node.amount, isNull);
      expect(node.title, 'Order #1042');
    });
  });

  group('provider_card', () {
    Map<String, dynamic> providerWith(Map<String, dynamic> extra) => {
      'type': 'provider_card',
      'id': 'p1',
      'providerId': 'prv_1',
      'name': 'Ahmed K.',
      ...extra,
    };

    test('clamps the rating into 0..5', () {
      expect(
        single<AiUiProviderCardNode>(
          providerWith({'ratingValue': 9}),
        )!.ratingValue,
        5,
      );
      expect(
        single<AiUiProviderCardNode>(
          providerWith({'ratingValue': -3}),
        )!.ratingValue,
        0,
      );
    });

    test('drops a stat with no value and keeps the rest', () {
      final node = single<AiUiProviderCardNode>(
        providerWith({
          'stats': [
            {'label': 'Completed jobs', 'value': '340+'},
            {'label': 'Since'},
          ],
        }),
      )!;

      expect(node.stats.map((s) => s.label), ['Completed jobs']);
    });

    test('truncates the stats strip past its limit', () {
      final result = parse(
        providerWith({
          'stats': [
            for (var i = 0; i < 8; i++) {'label': 'L$i', 'value': 'V$i'},
          ],
        }),
      );

      final node = result.document!.blocks.single as AiUiProviderCardNode;
      expect(node.stats, hasLength(AiUiLimits.defaults.maxStats));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });
  });

  group('booking_summary', () {
    test('is dropped with no valid items', () {
      // A header and two buttons would ask the user to agree to nothing.
      expect(
        single<AiUiBookingSummaryNode>({
          'type': 'booking_summary',
          'id': 'b1',
          'title': 'Booking summary',
          'items': <Object>[],
        }),
        isNull,
      );
    });

    test('drops an item missing its value and keeps the summary', () {
      final node = single<AiUiBookingSummaryNode>({
        'type': 'booking_summary',
        'id': 'b1',
        'items': [
          {'label': 'Service', 'value': 'Deep Cleaning'},
          {'label': 'Provider'},
        ],
      })!;

      expect(node.items.map((i) => i.label), ['Service']);
    });

    test('reads the value tone and the ltr flag', () {
      final node = single<AiUiBookingSummaryNode>({
        'type': 'booking_summary',
        'id': 'b1',
        'items': [
          {'label': 'Cost', 'value': '150 AED', 'valueTone': 'primary'},
          {'label': 'Ref', 'value': 'TXN-1', 'isLtrValue': true},
        ],
      })!;

      expect(node.items.first.valueTone, AiUiTone.primary);
      expect(node.items.last.isLtrValue, isTrue);
    });

    test('an unknown value tone falls back to neutral', () {
      final result = parse({
        'type': 'booking_summary',
        'id': 'b1',
        'items': [
          {'label': 'Cost', 'value': '150 AED', 'valueTone': 'chartreuse'},
        ],
      });

      final node = result.document!.blocks.single as AiUiBookingSummaryNode;
      expect(node.items.single.valueTone, AiUiTone.neutral);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('truncates past the item limit', () {
      final result = parse({
        'type': 'booking_summary',
        'id': 'b1',
        'items': [
          for (var i = 0; i < 20; i++) {'label': 'L$i', 'value': 'V$i'},
        ],
      });

      final node = result.document!.blocks.single as AiUiBookingSummaryNode;
      expect(node.items, hasLength(AiUiLimits.defaults.maxDetailItems));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });
  });

  group('request_summary', () {
    test('keeps a location row whose action cannot be resolved', () {
      // The address is information even when the maps link is not available —
      // the `chip` rule, because this row is not a button.
      final result = parse({
        'type': 'request_summary',
        'id': 'r1',
        'items': [
          {'label': 'Service', 'value': 'Home Cleaning'},
        ],
        'location': {
          'addressText': 'Dubai Marina',
          'action': {'type': 'teleport'},
        },
      });

      final node = result.document!.blocks.single as AiUiRequestSummaryNode;
      expect(node.location!.addressText, 'Dubai Marina');
      expect(node.location!.action, isNull);
    });

    test('drops a location with no address', () {
      final node = single<AiUiRequestSummaryNode>({
        'type': 'request_summary',
        'id': 'r1',
        'items': [
          {'label': 'Service', 'value': 'Home Cleaning'},
        ],
        'location': {'label': 'Home'},
      })!;

      expect(node.location, isNull);
    });
  });

  group('payment_receipt', () {
    test(
      'survives with no items — headline plus total still says what happened',
      () {
        final node = single<AiUiPaymentReceiptNode>({
          'type': 'payment_receipt',
          'id': 'p1',
          'title': 'Payment successful',
          'items': <Object>[],
          'total': {
            'label': 'Amount paid',
            'amount': {'amount': 150, 'currency': 'AED'},
          },
        })!;

        expect(node.items, isEmpty);
        expect(node.total!.amount.amount, 150);
      },
    );

    test('drops a malformed total but keeps the receipt', () {
      final node = single<AiUiPaymentReceiptNode>({
        'type': 'payment_receipt',
        'id': 'p1',
        'title': 'Payment successful',
        'items': [
          {'label': 'Method', 'value': 'Apple Pay'},
        ],
        'total': {'label': 'Amount paid'},
      })!;

      expect(node.total, isNull);
      expect(node.items, hasLength(1));
    });

    test('defaults its tone to success', () {
      expect(
        single<AiUiPaymentReceiptNode>({
          'type': 'payment_receipt',
          'id': 'p1',
          'title': 'Payment successful',
          'items': <Object>[],
        })!.statusTone,
        AiUiTone.success,
      );
    });
  });

  group('time_slots', () {
    Map<String, dynamic> slotsWith({
      Object? slots,
      String? selectedSlotId,
    }) => {
      'type': 'time_slots',
      'id': 't1',
      'slots':
          slots ??
          [
            {'id': 's1', 'label': '9:00 AM'},
            {'id': 's2', 'label': '10:30 AM'},
          ],
      'confirmLabel': 'Confirm time',
      'confirmTemplate': 'Book me the {slot} slot',
      if (selectedSlotId != null) 'selectedSlotId': selectedSlotId,
    };

    test('is dropped below the minimum number of choices', () {
      // One slot plus a confirm button is two taps for a decision the user
      // does not have — that payload wanted a quick_reply.
      final result = parse(
        slotsWith(
          slots: [
            {'id': 's1', 'label': '9:00 AM'},
          ],
        ),
      );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('needs its confirm label and template', () {
      expect(
        single<AiUiTimeSlotsNode>({
          'type': 'time_slots',
          'id': 't1',
          'slots': [
            {'id': 's1', 'label': '9:00 AM'},
            {'id': 's2', 'label': '10:30 AM'},
          ],
          'confirmLabel': 'Confirm',
        }),
        isNull,
        reason: 'confirmTemplate is what makes the button do anything',
      );
    });

    test('drops a duplicate slot id', () {
      // Two slots with one id makes "which is selected" ambiguous.
      final result = parse(
        slotsWith(
          slots: [
            {'id': 's1', 'label': '9:00 AM'},
            {'id': 's1', 'label': '10:30 AM'},
            {'id': 's2', 'label': '12:00 PM'},
          ],
        ),
      );

      final node = result.document!.blocks.single as AiUiTimeSlotsNode;
      expect(node.slots.map((s) => s.label), ['9:00 AM', '12:00 PM']);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('carries a disabled slot rather than omitting it', () {
      final node = single<AiUiTimeSlotsNode>(
        slotsWith(
          slots: [
            {'id': 's1', 'label': '9:00 AM'},
            {'id': 's2', 'label': '11:00 AM', 'enabled': false},
          ],
        ),
      )!;

      expect(node.slots.last.enabled, isFalse);
    });

    test('a selection matching no slot selects nothing and keeps the grid', () {
      final result = parse(slotsWith(selectedSlotId: 's_nope'));

      final node = result.document!.blocks.single as AiUiTimeSlotsNode;
      expect(node.selectedSlotId, isNull);
      expect(node.slots, hasLength(2));
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('truncates past the slot limit', () {
      final result = parse(
        slotsWith(
          slots: [
            for (var i = 0; i < 30; i++) {'id': 's$i', 'label': 'Slot $i'},
          ],
        ),
      );

      final node = result.document!.blocks.single as AiUiTimeSlotsNode;
      expect(node.slots, hasLength(AiUiLimits.defaults.maxTimeSlots));
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });
  });

  group('review_request', () {
    Map<String, dynamic> reviewWith(Map<String, dynamic> extra) => {
      'type': 'review_request',
      'id': 'v1',
      'serviceName': 'Deep Cleaning',
      'submitLabel': 'Submit review',
      'submitTemplate': 'My review: {comment}',
      ...extra,
    };

    test('clamps the comment cap down to the protocol ceiling', () {
      // The agent may ask for a shorter comment than the protocol allows,
      // never a longer one.
      expect(
        single<AiUiReviewRequestNode>(
          reviewWith({'maxCommentLength': 99999}),
        )!.maxCommentLength,
        AiUiLimits.defaults.maxCommentLength,
      );
      expect(
        single<AiUiReviewRequestNode>(
          reviewWith({'maxCommentLength': 120}),
        )!.maxCommentLength,
        120,
      );
    });

    test('needs a submit template', () {
      expect(
        single<AiUiReviewRequestNode>({
          'type': 'review_request',
          'id': 'v1',
          'serviceName': 'Deep Cleaning',
          'submitLabel': 'Submit',
        }),
        isNull,
      );
    });
  });

  group('location_picker', () {
    test('is dropped when there is nothing to pick', () {
      // No saved places and no current-location row is a title plus a button
      // that can only fail.
      final result = parse({
        'type': 'location_picker',
        'id': 'l1',
        'title': 'Set your location',
        'confirmLabel': 'Confirm',
        'confirmTemplate': 'Use {location}',
      });

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('a current-location row alone is enough', () {
      expect(
        single<AiUiLocationPickerNode>({
          'type': 'location_picker',
          'id': 'l1',
          'title': 'Set your location',
          'useCurrentLabel': 'Use current location',
          'confirmLabel': 'Confirm',
          'confirmTemplate': 'Use {location}',
        }),
        isNotNull,
      );
    });

    test('drops a saved place missing its address', () {
      final node = single<AiUiLocationPickerNode>({
        'type': 'location_picker',
        'id': 'l1',
        'title': 'Set your location',
        'confirmLabel': 'Confirm',
        'confirmTemplate': 'Use {location}',
        'savedLocations': [
          {'id': 'home', 'name': 'Home', 'addressText': 'Dubai Marina'},
          {'id': 'gym', 'name': 'Gym'},
        ],
      })!;

      expect(node.savedLocations.map((l) => l.id), ['home']);
    });
  });

  group('permission_request', () {
    test('drops the card when the capability is unknown', () {
      // Guessing would put the wrong rationale in front of the wrong platform
      // prompt, so there is deliberately no default here.
      final result = parse({
        'type': 'permission_request',
        'id': 'pr1',
        'permission': 'read_contacts_and_sms',
        'title': 'Allow access',
        'allowLabel': 'Allow',
      });

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('parses each supported capability', () {
      for (final kind in AiUiPermissionKind.values) {
        final node = single<AiUiPermissionRequestNode>({
          'type': 'permission_request',
          'id': 'pr1',
          'permission': kind.wire,
          'title': 'Allow access',
          'allowLabel': 'Allow',
        });
        expect(node?.permission, kind, reason: 'for ${kind.wire}');
      }
    });

    test('drops an unpublished illustration but keeps the prompt', () {
      // The asset check only runs when the host publishes a set, which is what
      // the app does via `AiAssetResolver.publishedIds`.
      final result =
          validatorWith(
            knownAssetIds: const {publishedAssetId},
          ).validate(
            payload([
              {
                'type': 'permission_request',
                'id': 'pr1',
                'permission': 'location',
                'title': 'Allow location access',
                'allowLabel': 'Allow',
                'image': {'assetId': 'not_published'},
              },
            ]),
          );

      final node = result.document!.blocks.single as AiUiPermissionRequestNode;
      expect(node.image, isNull);
      expect(node.title, 'Allow location access');
      expect(result.hasCode(AiUiDiagnosticCode.unknownAssetId), isTrue);
    });
  });

  group('media_request', () {
    test('is dropped with no valid options', () {
      final result = parse({
        'type': 'media_request',
        'id': 'm1',
        'title': 'Add photos or video',
        'options': <Object>[],
      });

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('an unknown source falls back to the gallery', () {
      final result = parse({
        'type': 'media_request',
        'id': 'm1',
        'title': 'Add photos',
        'options': [
          {'label': 'Scan a document', 'source': 'lidar'},
        ],
      });

      final node = result.document!.blocks.single as AiUiMediaRequestNode;
      expect(node.options.single.source, AiUiMediaSource.gallery);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('parses each supported source', () {
      final node = single<AiUiMediaRequestNode>({
        'type': 'media_request',
        'id': 'm1',
        'title': 'Add photos',
        'options': [
          for (final source in AiUiMediaSource.values)
            {'label': source.wire, 'source': source.wire},
        ],
      })!;

      expect(
        node.options.map((o) => o.source),
        AiUiMediaSource.values.take(AiUiLimits.defaults.maxMediaOptions),
      );
    });
  });

  group('location_confirm', () {
    test('needs a title, an address and a confirm label', () {
      expect(
        single<AiUiLocationConfirmNode>({
          'type': 'location_confirm',
          'id': 'lc1',
          'title': 'Confirm your location',
          'confirmLabel': 'Confirm',
        }),
        isNull,
        reason: 'addressText is the whole point of the card',
      );
      expect(
        single<AiUiLocationConfirmNode>({
          'type': 'location_confirm',
          'id': 'lc1',
          'title': 'Confirm your location',
          'addressText': 'Dubai Marina',
          'confirmLabel': 'Confirm location',
        }),
        isNotNull,
      );
    });
  });

  group('reminder_card', () {
    test('defaults its tone to warning', () {
      expect(
        single<AiUiReminderCardNode>({
          'type': 'reminder_card',
          'id': 'rc1',
          'title': 'Reminder',
          'body': 'Your appointment is in 30 minutes.',
        })!.tone,
        AiUiTone.warning,
      );
    });

    test('needs a body — a title alone is not a reminder', () {
      expect(
        single<AiUiReminderCardNode>({
          'type': 'reminder_card',
          'id': 'rc1',
          'title': 'Reminder',
        }),
        isNull,
      );
    });
  });

  group('the updated fields on existing cards', () {
    test('service_card reads selected', () {
      final node = single<AiUiServiceCardNode>({
        'type': 'service_card',
        'id': 's1',
        'serviceId': 'svc_1',
        'title': 'AC Maintenance',
        'selected': true,
      })!;

      expect(node.selected, isTrue);
    });

    test('service_card defaults selected to false', () {
      expect(
        single<AiUiServiceCardNode>({
          'type': 'service_card',
          'id': 's1',
          'serviceId': 'svc_1',
          'title': 'AC Maintenance',
        })!.selected,
        isFalse,
      );
    });

    test('branch_card reads hoursText', () {
      final node = single<AiUiBranchCardNode>({
        'type': 'branch_card',
        'id': 'b1',
        'branchId': 'br_1',
        'name': 'Downtown',
        'hoursText': 'Closes 9:00 PM',
      })!;

      expect(node.hoursText, 'Closes 9:00 PM');
    });

    test('appointment_card carries an attached action row', () {
      final node = single<AiUiAppointmentCardNode>({
        'type': 'appointment_card',
        'id': 'a1',
        'appointmentId': 'apt_1',
        'title': 'AC Maintenance',
        'startsAt': '2026-09-02T06:00:00Z',
        'actions': [
          {'label': 'Reschedule', 'action': sendAction('Reschedule')},
          {
            'label': 'Cancel',
            'action': sendAction('Cancel'),
            'variant': 'outline',
            'intent': 'destructive',
          },
        ],
      })!;

      expect(node.actions.map((a) => a.label), ['Reschedule', 'Cancel']);
      expect(node.actions.last.intent, AiUiButtonIntent.destructive);
    });
  });

  group('the new actions', () {
    test('call_phone requires a number', () {
      expect(
        validatorWith(
              supportedActions: {
                AiUiActionType.callPhone,
                AiUiActionType.sendMessage,
              },
            )
            .validate(
              payload([
                {
                  'type': 'button',
                  'id': 'b1',
                  'label': 'Call',
                  'action': {'type': 'call_phone'},
                },
              ]),
            )
            .document!
            .blocks,
        isEmpty,
      );
    });

    test('open_map carries its query through as a param', () {
      final result =
          validatorWith(
            supportedActions: {AiUiActionType.openMap},
          ).validate(
            payload([
              {
                'type': 'button',
                'id': 'b1',
                'label': 'Open in maps',
                'action': {'type': 'open_map', 'query': '25.2048,55.2708'},
              },
            ]),
          );

      final button = result.document!.blocks.single as AiUiButtonNode;
      expect(button.action.type, AiUiActionType.openMap);
      expect(button.action.params['query'], '25.2048,55.2708');
    });

    test('request_permission requires a capability', () {
      expect(
        validatorWith(supportedActions: {AiUiActionType.requestPermission})
            .validate(
              payload([
                {
                  'type': 'button',
                  'id': 'b1',
                  'label': 'Allow',
                  'action': {'type': 'request_permission'},
                },
              ]),
            )
            .document!
            .blocks,
        isEmpty,
      );
    });

    test('a host that does not implement one drops the owning button', () {
      // The two-gate rule: in the catalog *and* in the host's registry.
      final result =
          validatorWith(
            supportedActions: {AiUiActionType.sendMessage},
          ).validate(
            payload([
              {
                'type': 'button',
                'id': 'b1',
                'label': 'Call',
                'action': {'type': 'call_phone', 'phone': '+971501234567'},
              },
            ]),
          );

      expect(result.document!.blocks, isEmpty);
      expect(result.hasCode(AiUiDiagnosticCode.unknownActionType), isTrue);
    });
  });

  group('totality over the new types', () {
    test('every new type survives a payload of nothing but its own name', () {
      // Adversarial in the cheapest possible way: the type is right and every
      // other field is missing. None of these may throw.
      for (final type in AiUiNodeType.values.where((t) => t.isSemantic)) {
        expect(
          () => parse({'type': type.wire}),
          returnsNormally,
          reason: 'bare ${type.wire}',
        );
      }
    });

    test('every collection field survives being the wrong type', () {
      const hostile = <String, Object?>{
        'actions': 7,
        'items': 'nope',
        'slots': {'a': 1},
        'stats': true,
        'options': 0.5,
        'savedLocations': <Object?>[null, 1, 'x'],
        'total': 'free',
        'location': <Object>[],
      };

      for (final type in AiUiNodeType.values.where((t) => t.isSemantic)) {
        expect(
          () => parse({'type': type.wire, 'id': 'x', ...hostile}),
          returnsNormally,
          reason: 'hostile ${type.wire}',
        );
      }
    });

    test('a card action never carries a non-scalar param', () {
      final result = parse({
        'type': 'order_card',
        'id': 'o1',
        'orderId': 'ord_1',
        'title': 'Order #1',
        'actions': [
          {
            'label': 'Track',
            'action': {
              'type': 'send_message',
              'text': 'Track',
              'payload': {'nested': 'object'},
            },
          },
        ],
      });

      final node = result.document!.blocks.single as AiUiOrderCardNode;
      expect(node.actions.single.action.params.containsKey('payload'), isFalse);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });
  });

  group('acceptsCardActions', () {
    /// The smallest valid payload for each type that owns its own controls.
    /// Adding `actions` to one of these is a mistake the agent can make, so the
    /// predicate that documents it has to match what the validator does.
    const ownControls = <AiUiNodeType, Map<String, dynamic>>{
      AiUiNodeType.quickReply: {
        'type': 'quick_reply',
        'id': 'q1',
        'options': [
          {
            'label': 'Yes',
            'action': {'type': 'send_message', 'text': 'Yes'},
          },
          {
            'label': 'No',
            'action': {'type': 'send_message', 'text': 'No'},
          },
        ],
      },
      AiUiNodeType.timeSlots: {
        'type': 'time_slots',
        'id': 'ts1',
        'confirmLabel': 'Confirm',
        'confirmTemplate': 'Book {slot}',
        'slots': [
          {'id': 'a', 'label': '9:00 AM'},
          {'id': 'b', 'label': '10:00 AM'},
        ],
      },
      AiUiNodeType.reviewRequest: {
        'type': 'review_request',
        'id': 'rv1',
        'serviceName': 'Deep Cleaning',
        'submitLabel': 'Submit',
        'submitTemplate': 'Review: {comment}',
      },
      AiUiNodeType.locationPicker: {
        'type': 'location_picker',
        'id': 'lp1',
        'title': 'Set your location',
        // Required in practice: a picker offering neither the device's
        // location nor a saved place is dropped as a dead end.
        'useCurrentLabel': 'Use current location',
        'confirmLabel': 'Confirm',
        'confirmTemplate': 'I am at {location}',
      },
      // Its `confirm` block *is* its controls, and the answer is a structured
      // interaction — an extra `actions` row would offer a second, untracked
      // way to resolve the same question.
      AiUiNodeType.confirmPrompt: {
        'type': 'confirm_prompt',
        'id': 'cp1',
        'title': 'Are you sure you want to cancel?',
        'confirm': {'confirmLabel': 'Yes, Cancel', 'cancelLabel': 'Keep It'},
      },
    };

    test('is false for exactly the types that own their controls', () {
      expect(
        AiUiNodeType.values
            .where((type) => type.isSemantic && !type.acceptsCardActions)
            .toSet(),
        ownControls.keys.toSet(),
      );
    });

    test('is true for every other semantic type', () {
      expect(
        AiUiNodeType.values
            .where((type) => type.isSemantic && type.acceptsCardActions)
            .length,
        AiUiNodeType.values.where((type) => type.isSemantic).length -
            ownControls.length,
      );
    });

    for (final entry in ownControls.entries) {
      test('${entry.key.wire} reports an actions array and ignores it', () {
        // Reported rather than silently dropped: an agent emitting a control
        // that will never render should hear about it. The node itself
        // survives — its own controls are still valid.
        final result = validatorWith().validate(
          payload([
            {
              ...entry.value,
              'actions': [
                {'label': 'Extra', 'action': sendAction()},
              ],
            },
          ]),
        );

        expect(result.document!.blocks.single.type, entry.key);
        expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
      });
    }
  });

  group('provider_card as an offer', () {
    Map<String, dynamic> providerWith(Object? offer) => {
      'type': 'provider_card',
      'id': 'p1',
      'providerId': 'prv_1',
      'name': 'Ahmed K',
      if (offer != null) 'offer': offer,
    };

    test('an offer missing a decline label drops the offer, not the card', () {
      // An offer the user can only accept is not an offer. The provider is
      // still worth showing, so only the controls go.
      final node = single<AiUiProviderCardNode>(
        providerWith({'acceptLabel': 'Accept Offer'}),
      );

      expect(node, isNotNull);
      expect(node!.offer, isNull);
      expect(
        parse(providerWith({'acceptLabel': 'Accept Offer'})).hasCode(
          AiUiDiagnosticCode.missingRequiredProperty,
        ),
        isTrue,
      );
    });

    test('presentation defaults to compact and parses expanded', () {
      expect(
        single<AiUiProviderCardNode>(providerWith(null))!.presentation,
        AiUiPresentation.compact,
      );
      expect(
        single<AiUiProviderCardNode>({
          ...providerWith(null),
          'presentation': 'expanded',
        })!.presentation,
        AiUiPresentation.expanded,
      );
    });

    test('an unknown presentation falls back rather than dropping', () {
      final result = parse({
        ...providerWith(null),
        'presentation': 'gigantic',
      });

      expect(
        (result.document!.blocks.single as AiUiProviderCardNode).presentation,
        AiUiPresentation.compact,
      );
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('a non-string service entry is dropped and the rest survive', () {
      final node = single<AiUiProviderCardNode>({
        ...providerWith(null),
        'services': ['Interior clean', 7, 'Polishing'],
      });

      expect(node!.services, ['Interior clean', 'Polishing']);
    });

    test('a photo with no usable source is dropped and the strip lives', () {
      final node = single<AiUiProviderCardNode>({
        ...providerWith(null),
        'photos': [
          {'url': dynamicImageUrl},
          {'url': insecureImageUrl},
          {'assetId': ''},
        ],
      });

      expect(node!.photos, [const AiUiImageSource.url(dynamicImageUrl)]);
    });

    test('an unparseable proposedTime drops the row, not the card', () {
      final node = single<AiUiProviderCardNode>({
        ...providerWith(null),
        'proposedTime': 'thursday evening',
      });

      expect(node, isNotNull);
      expect(node!.proposedTime, isNull);
    });
  });

  group('confirm_prompt', () {
    test('a prompt with no confirm block is dropped', () {
      // The controls are the node: a question the user cannot answer would
      // leave the agent waiting on an answer that can never arrive.
      final result = parse({
        'type': 'confirm_prompt',
        'id': 'cp1',
        'title': 'Are you sure?',
      });

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('a cancel label is optional — the conversation is the way out', () {
      final node = single<AiUiConfirmPromptNode>({
        'type': 'confirm_prompt',
        'id': 'cp1',
        'title': 'Are you sure?',
        'confirm': {'confirmLabel': 'Yes, Cancel'},
      });

      expect(node!.confirm.cancelLabel, isNull);
      expect(node.confirm.destructive, isFalse);
    });
  });

  group('request_summary confirm block', () {
    Map<String, dynamic> summaryWith(Object? confirm) => {
      'type': 'request_summary',
      'id': 'rs1',
      'items': [
        {'label': 'Service', 'value': 'Home Cleaning'},
      ],
      if (confirm != null) 'confirm': confirm,
    };

    test('a malformed confirm drops the block, not the summary', () {
      // The opposite of `confirm_prompt`: this card reads correctly without
      // its controls, so losing them must not lose the request.
      final node = single<AiUiRequestSummaryNode>(summaryWith('yes please'));

      expect(node, isNotNull);
      expect(node!.confirm, isNull);
      expect(
        parse(
          summaryWith('yes please'),
        ).hasCode(AiUiDiagnosticCode.invalidProperty),
        isTrue,
      );
    });

    test('an absent confirm is not reported as missing', () {
      expect(parse(summaryWith(null)).diagnostics, isEmpty);
    });
  });

  group('request_notice', () {
    Map<String, dynamic> noticeWith(Map<String, dynamic> extra) => {
      'type': 'request_notice',
      'id': 'rn1',
      'title': 'Ahmed K. had to cancel',
      ...extra,
    };

    test('a notice with no title at all is dropped', () {
      // The headline is the notice: a card that says a request changed
      // without saying what changed is worse than no card.
      final result = parse({'type': 'request_notice', 'id': 'rn1'});

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('the headline alone is a valid notice', () {
      // The provider-late reading sends a title, a body and one control; the
      // minimum is smaller than that, and a notice with neither a decision
      // nor an actions row is still a statement worth drawing.
      final result = parse(noticeWith(const {}));
      final node = result.document!.blocks.single as AiUiRequestNoticeNode;

      expect(result.diagnostics, isEmpty);
      expect(node.title, 'Ahmed K. had to cancel');
      expect(node.status, isNull);
      expect(node.confirm, isNull);
      expect(node.actions, isEmpty);
    });

    test('the status badge parses its tone', () {
      final node = single<AiUiRequestNoticeNode>(
        noticeWith(const {
          'status': {'label': 'Booking Cancelled', 'tone': 'error'},
          'reference': '#SND-4821',
          'requestId': 'req_4821',
        }),
      );

      expect(node!.status!.label, 'Booking Cancelled');
      expect(node.status!.tone, AiUiTone.error);
      expect(node.reference, '#SND-4821');
      expect(node.requestId, 'req_4821');
    });

    test('an unknown status tone falls back to neutral', () {
      final node = single<AiUiRequestNoticeNode>(
        noticeWith(const {
          'status': {'label': 'Booking Cancelled', 'tone': 'catastrophic'},
        }),
      );

      expect(node!.status!.tone, AiUiTone.neutral);
    });

    test('a malformed status drops the badge, not the notice', () {
      final result = parse(noticeWith(const {'status': 'cancelled'}));
      final node = result.document!.blocks.single as AiUiRequestNoticeNode;

      expect(node.status, isNull);
      expect(node.title, 'Ahmed K. had to cancel');
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('the draft tile and the context chip survive independently', () {
      final node = single<AiUiRequestNoticeNode>(
        noticeWith(const {
          'contextLabel': 'Tied to Active Request: Plumbing Repair',
          'draftText': '"I also need an AC deep cleaning..."',
        }),
      );

      expect(node!.contextLabel, 'Tied to Active Request: Plumbing Repair');
      expect(node.draftText, '"I also need an AC deep cleaning..."');
      // A quote with no heading above it is a complete tile.
      expect(node.draftLabel, isNull);
    });

    test('a malformed confirm drops the decision, not the notice', () {
      // The same rule `request_summary` follows and the opposite of
      // `confirm_prompt`'s: the notice still reads without its controls, so
      // losing them must not lose what the agent was reporting.
      final result = parse(noticeWith(const {'confirm': 7}));
      final node = result.document!.blocks.single as AiUiRequestNoticeNode;

      expect(node.confirm, isNull);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('an absent confirm is not reported as missing', () {
      expect(parse(noticeWith(const {})).diagnostics, isEmpty);
    });

    test('it carries both a decision and an unrelated action row', () {
      // The provider-cancelled reading: "Auto-Match New Provider" is an
      // answer, "Contact Sanad Support" is a different destination. One card
      // has to be able to offer both without the second being read as a "no".
      final node = single<AiUiRequestNoticeNode>(
        noticeWith({
          'confirm': const {'confirmLabel': 'Auto-Match New Provider'},
          'actions': [
            {'label': 'Contact Sanad Support', 'action': sendAction('Support')},
          ],
        }),
      );

      expect(node!.confirm!.confirmLabel, 'Auto-Match New Provider');
      expect(node.actions.single.label, 'Contact Sanad Support');
    });
  });

  group('service_area_notice', () {
    Map<String, dynamic> noticeWith(Map<String, dynamic> extra) => {
      'type': 'service_area_notice',
      'id': 'sa1',
      'title': 'Location outside service area',
      'addressText': 'Al Ruwais, Western Region, Abu Dhabi',
      ...extra,
    };

    test('it is dropped without an address', () {
      // Naming the refused place is the point: a coverage warning the user
      // cannot trace to an address gives them nothing to change.
      final result = parse({
        'type': 'service_area_notice',
        'id': 'sa1',
        'title': 'Location outside service area',
      });

      expect(result.document!.blocks, isEmpty);
      expect(
        result.hasCode(AiUiDiagnosticCode.missingRequiredProperty),
        isTrue,
      );
    });

    test('it is dropped without a title', () {
      final result = parse({
        'type': 'service_area_notice',
        'id': 'sa1',
        'addressText': 'Al Ruwais',
      });

      expect(result.document!.blocks, isEmpty);
    });

    test('the tone defaults to warning', () {
      final node = single<AiUiServiceAreaNoticeNode>(noticeWith(const {}));

      expect(node!.tone, AiUiTone.warning);
      expect(node.changeLabel, isNull);
    });

    test('an unknown tone falls back to warning rather than dropping', () {
      final result = parse(noticeWith(const {'tone': 'apocalyptic'}));
      final node = result.document!.blocks.single as AiUiServiceAreaNoticeNode;

      expect(node.tone, AiUiTone.warning);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('the change control is carried as a label, not as an action', () {
      // The label is all the agent supplies: the control runs the *app's*
      // location flow, exactly as `location_confirm.changeLabel` does, so
      // there is no second location model and no agent-chosen destination.
      final node = single<AiUiServiceAreaNoticeNode>(
        noticeWith(const {'changeLabel': 'Change Location'}),
      );

      expect(node!.changeLabel, 'Change Location');
    });
  });

  group('provider_search state', () {
    Map<String, dynamic> searchWith(Map<String, dynamic> extra) => {
      'type': 'provider_search',
      'id': 'ps1',
      'title': 'Searching nearby providers',
      ...extra,
    };

    test('it defaults to searching', () {
      final node = single<AiUiProviderSearchNode>(searchWith(const {}));

      expect(node!.state, AiUiProviderSearchState.searching);
      expect(node.state.isSearching, isTrue);
    });

    test('exhausted parses', () {
      final result = parse(
        searchWith(const {
          'state': 'exhausted',
          'title': 'No Specialists Available',
          'body': 'No active providers could match your AC Cleaning request.',
        }),
      );
      final node = result.document!.blocks.single as AiUiProviderSearchNode;

      expect(result.diagnostics, isEmpty);
      expect(node.state, AiUiProviderSearchState.exhausted);
      expect(node.state.isSearching, isFalse);
    });

    test('an unknown state falls back to searching', () {
      // A card that says a search is running is still true; dropping the node
      // would leave the conversation silent about it.
      final result = parse(searchWith(const {'state': 'quantum'}));
      final node = result.document!.blocks.single as AiUiProviderSearchNode;

      expect(node.state, AiUiProviderSearchState.searching);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('it carries a confirm block for its own acknowledgement', () {
      final node = single<AiUiProviderSearchNode>(
        searchWith(const {
          'confirm': {
            'confirmLabel': 'Change Time Slot',
            'cancelLabel': 'Cancel',
            'reference': 'req_4821',
          },
          'state': 'exhausted',
        }),
      );

      expect(node!.confirm!.confirmLabel, 'Change Time Slot');
      expect(node.confirm!.cancelLabel, 'Cancel');
      expect(node.confirm!.reference, 'req_4821');
    });

    test('a malformed confirm drops the controls, not the search', () {
      final result = parse(searchWith(const {'confirm': <Object>[]}));
      final node = result.document!.blocks.single as AiUiProviderSearchNode;

      expect(node.confirm, isNull);
      expect(node.title, 'Searching nearby providers');
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });
  });

  group('service_timeline', () {
    Map<String, dynamic> timelineWith(Object? items) => {
      'type': 'service_timeline',
      'id': 'tl1',
      'title': 'Timeline',
      if (items != null) 'items': items,
    };

    test('a timeline with no valid items is dropped', () {
      expect(parse(timelineWith(<Object>[])).document!.blocks, isEmpty);
    });

    test('an unknown state falls back to pending rather than dropping', () {
      // Dropping the step would silently renumber the user's progress, which
      // is worse than drawing one step under-emphasised.
      final result = parse(
        timelineWith([
          {'state': 'teleporting', 'title': 'En Route'},
        ]),
      );
      final node = result.document!.blocks.single as AiUiServiceTimelineNode;

      expect(node.items.single.state, AiUiTimelineState.pending);
      expect(result.hasCode(AiUiDiagnosticCode.invalidProperty), isTrue);
    });

    test('a step with no timestamp is legal — it has not happened yet', () {
      final node = single<AiUiServiceTimelineNode>(
        timelineWith([
          {'state': 'pending', 'title': 'Service Completed'},
        ]),
      );

      expect(node!.items.single.at, isNull);
      expect(node.items.single.isCurrent, isFalse);
    });

    test('the active step is the one reported as current', () {
      final node = single<AiUiServiceTimelineNode>(
        timelineWith([
          {'state': 'completed', 'title': 'Booking Confirmed'},
          {'state': 'active', 'title': 'En Route'},
        ]),
      );

      expect(
        node!.items.where((item) => item.isCurrent).single.title,
        'En Route',
      );
    });

    test('items beyond the limit are truncated, keeping the earliest', () {
      final node = single<AiUiServiceTimelineNode>(
        timelineWith([
          for (var i = 0; i < 20; i++) {'state': 'pending', 'title': 'Step $i'},
        ]),
      );

      expect(node!.items, hasLength(AiUiLimits.defaults.maxTimelineItems));
      expect(node.items.first.title, 'Step 0');
    });
  });

  group('verification_code', () {
    test('whitespace inside a code is not part of the code', () {
      // Every character draws its own box, so a space would draw an empty one.
      final node = single<AiUiVerificationCodeNode>({
        'type': 'verification_code',
        'id': 'vc1',
        'code': '65 066',
      });

      expect(node!.code, '65066');
    });

    test('a code longer than the limit is truncated, not rejected', () {
      final result = parse({
        'type': 'verification_code',
        'id': 'vc1',
        'code': '0123456789ABCDEFGH',
      });
      final node = result.document!.blocks.single as AiUiVerificationCodeNode;

      expect(
        node.code,
        hasLength(AiUiLimits.defaults.maxVerificationCodeLength),
      );
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('a card with no code is dropped', () {
      expect(
        parse({'type': 'verification_code', 'id': 'vc1'}).document!.blocks,
        isEmpty,
      );
    });
  });

  group('review_request rating', () {
    Map<String, dynamic> reviewWith(Map<String, dynamic> extra) => {
      'type': 'review_request',
      'id': 'rv1',
      'serviceName': 'How was your experience?',
      'submitLabel': 'Submit Review',
      'submitTemplate': '{rating} stars: {comment}',
      ...extra,
    };

    test('no maxRating means no rating control at all', () {
      final node = single<AiUiReviewRequestNode>(reviewWith(const {}));

      expect(node!.maxRating, isNull);
      expect(node.ratingRequired, isFalse);
    });

    test('a scale above the protocol ceiling is clamped, not rejected', () {
      final result = parse(reviewWith(const {'maxRating': 500}));
      final node = result.document!.blocks.single as AiUiReviewRequestNode;

      expect(node.maxRating, AiUiLimits.defaults.maxRating);
      expect(result.hasCode(AiUiDiagnosticCode.limitExceeded), isTrue);
    });

    test('a one-star scale is clamped up — one star is not a scale', () {
      expect(
        single<AiUiReviewRequestNode>(
          reviewWith(const {'maxRating': 1}),
        )!.maxRating,
        2,
      );
    });
  });

  group('booking_summary as a confirmation', () {
    Map<String, dynamic> bookingWith(Map<String, dynamic> extra) => {
      'type': 'booking_summary',
      'id': 'bs1',
      'items': [
        {'label': 'Date', 'value': 'Thursday, Oct 24'},
      ],
      ...extra,
    };

    test('a provider whose id is missing drops the ref, not the card', () {
      // A booking that cannot name its provider is still a booking the user
      // needs to read.
      final node = single<AiUiBookingSummaryNode>(
        bookingWith(const {
          'provider': {'name': 'Ahmed K'},
        }),
      );

      expect(node, isNotNull);
      expect(node!.provider, isNull);
    });

    test('statusTone defaults to success, because a status is an outcome', () {
      final node = single<AiUiBookingSummaryNode>(
        bookingWith(const {'statusText': 'Booking Confirmed!'}),
      );

      expect(node!.statusTone, AiUiTone.success);
    });

    test('verified is a flag the agent asserts, not a label it composes', () {
      final node = single<AiUiBookingSummaryNode>(
        bookingWith(const {
          'provider': {
            'providerId': 'prv_1',
            'name': 'Ahmed K',
            'verified': true,
          },
        }),
      );

      expect(node!.provider!.verified, isTrue);
    });
  });

  test('a semantic node keeps its siblings when it is dropped', () {
    final result = validatorWith().validate(
      payload([
        {'type': 'text', 'id': 't1', 'text': 'Here is your booking:'},
        // No items — dropped.
        {'type': 'booking_summary', 'id': 'b1', 'items': <Object>[]},
        {
          'type': 'quick_reply',
          'id': 'q1',
          'options': [
            {'label': 'Yes', 'action': sendAction()},
            {'label': 'No', 'action': sendAction('No')},
          ],
        },
      ]),
    );

    expect(
      result.document!.blocks.map((b) => b.type),
      [AiUiNodeType.text, AiUiNodeType.quickReply],
    );
    expect(sendYes.type, AiUiActionType.sendMessage);
  });
}
