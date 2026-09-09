import 'package:flutter_test/flutter_test.dart';
import 'package:notifications/notifications.dart';

Map<String, dynamic> _json({
  Object? subjectType = 'CLIENT_REQUEST',
  Object? subjectId = 'req-1',
  Object? metadata,
  Object? readAt,
  Object? type = 'REQUEST_MATCHED',
}) => {
  'id': 'notif-1',
  'type': type,
  'title': 'Providers matched',
  'body': 'Three providers can help.',
  'readAt': readAt,
  'subjectType': subjectType,
  'subjectId': subjectId,
  'metadata': metadata,
  'createdAt': '2026-09-12T10:00:00+04:00',
};

void main() {
  group('NotificationDto', () {
    test('round-trips a full payload', () {
      final json = _json(metadata: {'serviceName': 'Deep cleaning'});
      final dto = NotificationDto.fromJson(json);
      expect(dto.toJson(), json);
    });

    test('maps the new deep-link fields onto the entity', () {
      final entity = NotificationDto.fromJson(
        _json(metadata: {'serviceName': 'Deep cleaning'}),
      ).toEntity();

      expect(entity.id, 'notif-1');
      expect(entity.type, NotificationType.requestMatched);
      expect(entity.subject.type, NotificationSubjectType.clientRequest);
      expect(entity.subject.requestId, 'req-1');
      expect(entity.subject.serviceName, 'Deep cleaning');
      expect(entity.isUnread, isTrue);
      expect(entity.createdAt.toUtc(), DateTime.utc(2026, 9, 12, 6));
    });

    test(
      'a notification that predates deep links still parses and renders',
      () {
        // subjectType, subjectId and metadata are all nullable on the wire.
        // Older rows carry none of them and must not be dropped.
        final entity = NotificationDto.fromJson(
          _json(
            subjectType: null,
            subjectId: null,
            type: 'ADMIN_MESSAGE_RECEIVED',
          ),
        ).toEntity();

        expect(entity.title, 'Providers matched');
        expect(entity.type, NotificationType.adminMessageReceived);
        expect(entity.subject, NotificationSubject.none);
        expect(entity.subject.isNavigable, isFalse);
      },
    );

    test('an unrecognised type still renders its server-written copy', () {
      final entity = NotificationDto.fromJson(
        _json(type: 'SOMETHING_NEW_NEXT_RELEASE'),
      ).toEntity();

      expect(entity.type, NotificationType.unknown);
      expect(entity.title, 'Providers matched');
      expect(entity.body, 'Three providers can help.');
    });

    test('an unrecognised subjectType is not navigable', () {
      final entity = NotificationDto.fromJson(
        _json(subjectType: 'INVOICE', subjectId: 'inv-1'),
      ).toEntity();

      expect(entity.subject, NotificationSubject.none);
      expect(entity.subject.isNavigable, isFalse);
    });

    test('readAt marks the row read', () {
      final entity = NotificationDto.fromJson(
        _json(readAt: '2026-09-12T11:00:00+04:00'),
      ).toEntity();

      expect(entity.isUnread, isFalse);
      expect(entity.readAt, isNotNull);
    });

    test('an unparseable createdAt keeps the row instead of dropping it', () {
      final entity = NotificationDto.fromJson({
        ..._json(),
        'createdAt': 'not-a-date',
      }).toEntity();

      expect(entity.id, 'notif-1');
      expect(entity.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('a non-map metadata is ignored rather than throwing', () {
      final dto = NotificationDto.fromJson({..._json(), 'metadata': 'nope'});
      expect(dto.metadata, isNull);
    });
  });

  group('NotificationSubject routing coordinates', () {
    test('a CLIENT_REQUEST subject opens that request', () {
      const subject = NotificationSubject(
        type: NotificationSubjectType.clientRequest,
        id: 'req-9',
      );
      expect(subject.requestId, 'req-9');
      expect(subject.offerId, isNull);
      expect(subject.isNavigable, isTrue);
    });

    test(
      'a REQUEST_OFFER subject opens the thread INSIDE its request',
      () {
        // subjectId is the OFFER; the request comes from metadata. Treating
        // subjectId as the request would open the wrong screen (or none).
        const subject = NotificationSubject(
          type: NotificationSubjectType.requestOffer,
          id: 'offer-3',
          metadata: {'requestId': 'req-9'},
        );
        expect(subject.offerId, 'offer-3');
        expect(subject.requestId, 'req-9');
        expect(subject.isNavigable, isTrue);
      },
    );

    test(
      'a REQUEST_OFFER with no requestId is NOT navigable',
      () {
        // metadata.requestId is optional in the contract. Without it there is
        // genuinely no screen to open, so the caller must fall back rather
        // than guess that subjectId is a request id.
        const subject = NotificationSubject(
          type: NotificationSubjectType.requestOffer,
          id: 'offer-3',
        );
        expect(subject.requestId, isNull);
        expect(subject.isNavigable, isFalse);
      },
    );

    test('accepts the snake_case request_id spelling', () {
      const subject = NotificationSubject(
        type: NotificationSubjectType.requestOffer,
        id: 'offer-3',
        metadata: {'request_id': 'req-9'},
      );
      expect(subject.requestId, 'req-9');
    });

    test('blank ids are treated as absent', () {
      const subject = NotificationSubject(
        type: NotificationSubjectType.clientRequest,
        id: '   ',
      );
      expect(subject.requestId, isNull);
      expect(subject.isNavigable, isFalse);
    });
  });
}
