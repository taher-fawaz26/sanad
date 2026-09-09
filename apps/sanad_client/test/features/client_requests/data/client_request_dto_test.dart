import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/client_request_dto.dart';
import 'package:sanad_client/src/features/client_requests/src/data/models/save_client_request_request.dart';

import '../support/client_requests_fakes.dart';

void main() {
  group('ClientRequestDto', () {
    test('round-trips a full payload', () {
      final json = clientRequestJson();
      expect(ClientRequestDto.fromJson(json).toJson(), json);
    });

    test('maps a live request onto the entity', () {
      final entity = ClientRequestDto.fromJson(clientRequestJson()).toEntity();

      expect(entity.id, 'req-1');
      expect(entity.status, ClientRequestStatus.submitted);
      expect(entity.serviceName, 'Deep cleaning');
      expect(entity.attachments.single.mediaId, 'media-1');
      expect(entity.matchedBranches.single.branchName, 'Al Barsha Branch');
      expect(entity.threads.single.providerName, 'Sparkle Cleaning LLC');
      expect(entity.preferredAt!.toUtc(), DateTime.utc(2026, 9, 12, 6));
      expect(entity.expiresAt, isNotNull);
    });

    group('a half-finished draft', () {
      // The whole reason these fields are nullable: `POST /requests` accepts a
      // partial draft, and the app has to be able to read back what it just
      // created. Treating any of them as required would throw here.
      final barest = {
        'id': 'req-1',
        'status': 'DRAFT',
        'attachments': <dynamic>[],
        'offerCount': 0,
        'matchedBranches': <dynamic>[],
        'threads': <dynamic>[],
        'createdAt': '2026-09-11T07:00:00+04:00',
      };

      test('parses with every optional field absent', () {
        final entity = ClientRequestDto.fromJson(barest).toEntity();

        expect(entity.status, ClientRequestStatus.draft);
        expect(entity.serviceId, isNull);
        expect(entity.serviceName, isNull);
        expect(entity.categoryId, isNull);
        expect(entity.categoryName, isNull);
        expect(entity.lat, isNull);
        expect(entity.lng, isNull);
        expect(entity.addressLine, isNull);
        expect(entity.preferredAt, isNull);
        expect(entity.submittedAt, isNull);
        expect(entity.expiresAt, isNull);
        expect(entity.scheduledAt, isNull);
        expect(entity.attachments, isEmpty);
        expect(entity.threads, isEmpty);
      });

      test('parses with the optional fields present but null', () {
        final entity = ClientRequestDto.fromJson({
          ...barest,
          'serviceId': null,
          'serviceName': null,
          'lat': null,
          'lng': null,
          'preferredAt': null,
        }).toEntity();

        expect(entity.serviceId, isNull);
        expect(entity.preferredAt, isNull);
      });

      test('is not submittable and says what is missing', () {
        final entity = ClientRequestDto.fromJson(barest).toEntity();

        expect(entity.isSubmittable, isFalse);
        expect(entity.missingForSubmit, [
          'serviceId',
          'location',
          'preferredAt',
        ]);
      });

      test('becomes submittable once the three required fields are set', () {
        final entity = ClientRequestDto.fromJson({
          ...barest,
          'serviceId': 'svc-1',
          'lat': 25.2,
          'lng': 55.3,
          'preferredAt': '2026-09-12T10:00:00+04:00',
        }).toEntity();

        expect(entity.isSubmittable, isTrue);
        expect(entity.missingForSubmit, isEmpty);
      });
    });

    test('an unknown status degrades rather than throwing', () {
      final entity = ClientRequestDto.fromJson({
        ...clientRequestJson(),
        'status': 'ON_HOLD',
      }).toEntity();

      expect(entity.status, ClientRequestStatus.unknown);
      expect(entity.id, 'req-1');
    });

    test('a wrongly-typed collection degrades to empty', () {
      final entity = ClientRequestDto.fromJson({
        ...clientRequestJson(),
        'threads': 'oops',
        'matchedBranches': null,
      }).toEntity();

      expect(entity.threads, isEmpty);
      expect(entity.matchedBranches, isEmpty);
    });
  });

  group('offer threads', () {
    test('preserves the contractual oldest-first order', () {
      final entity = ClientRequestDto.fromJson(
        clientRequestJson(
          threads: [
            offerThreadJson(
              offers: [
                offerJson(status: 'SUPERSEDED'),
                offerJson(
                  id: 'offer-2',
                  actorType: 'CLIENT',
                  parentOfferId: 'offer-1',
                ),
              ],
            ),
          ],
        ),
      ).toEntity();

      final thread = entity.threads.single;
      expect(thread.offers.map((o) => o.id), ['offer-1', 'offer-2']);
      expect(thread.latestOffer!.id, 'offer-2');
    });

    test('a pending PROVIDER offer means it is the client turn', () {
      final entity = ClientRequestDto.fromJson(clientRequestJson()).toEntity();
      final thread = entity.threads.single;

      expect(thread.pendingOffer!.id, 'offer-1');
      expect(thread.isAwaitingClient, isTrue);
      expect(thread.isAwaitingProvider, isFalse);
      expect(entity.threadsAwaitingClient, hasLength(1));
    });

    test('a pending CLIENT counter means it is the provider turn', () {
      // Whose turn it is comes from the pending offer's actor, never from the
      // request status.
      final entity = ClientRequestDto.fromJson(
        clientRequestJson(
          threads: [
            offerThreadJson(
              offers: [
                offerJson(status: 'SUPERSEDED'),
                offerJson(
                  id: 'offer-2',
                  actorType: 'CLIENT',
                  parentOfferId: 'offer-1',
                ),
              ],
            ),
          ],
        ),
      ).toEntity();

      final thread = entity.threads.single;
      expect(thread.isAwaitingProvider, isTrue);
      expect(thread.isAwaitingClient, isFalse);
      expect(entity.threadsAwaitingClient, isEmpty);
    });

    test('a settled thread has no pending offer', () {
      final entity = ClientRequestDto.fromJson(
        clientRequestJson(
          threads: [
            offerThreadJson(offers: [offerJson(status: 'LOST')]),
          ],
        ),
      ).toEntity();

      expect(entity.threads.single.pendingOffer, isNull);
    });

    test('LOST is kept distinct from REJECTED', () {
      // Provider-facing copy has to tell "another provider won" apart from
      // "the client declined you".
      final lost = ClientRequestDto.fromJson(
        clientRequestJson(
          threads: [
            offerThreadJson(offers: [offerJson(status: 'LOST')]),
          ],
        ),
      ).toEntity().threads.single.offers.single;
      final rejected = ClientRequestDto.fromJson(
        clientRequestJson(
          threads: [
            offerThreadJson(offers: [offerJson(status: 'REJECTED')]),
          ],
        ),
      ).toEntity().threads.single.offers.single;

      expect(lost.status, RequestOfferStatus.lost);
      expect(rejected.status, RequestOfferStatus.rejected);
    });
  });

  group('SaveClientRequestRequest', () {
    test('omits every field the user has not filled in', () {
      // Sending nulls would clear values already saved, and sending the whole
      // shape invites submit-time validation at draft time.
      expect(const SaveClientRequestRequest().toJson(), isEmpty);
    });

    test('sends only what was set', () {
      final body = SaveClientRequestRequest(
        serviceId: 'svc-1',
        preferredAt: DateTime(2026, 9, 12, 10),
      ).toJson();

      expect(body.keys, unorderedEquals(['serviceId', 'preferredAt']));
    });

    test('encodes preferredAt with an explicit offset', () {
      final body = SaveClientRequestRequest(
        preferredAt: DateTime(2026, 9, 12, 10),
      ).toJson();

      expect(body['preferredAt'], endsWith('Z'));
    });

    test('trims text and drops it when blank', () {
      expect(
        const SaveClientRequestRequest(
          note: '  leaking tap  ',
          addressLine: '   ',
        ).toJson(),
        {'note': 'leaking tap'},
      );
    });

    test('sends an empty mediaIds list, because it replaces the whole set', () {
      // Distinct from omitting the key: `[]` detaches every attachment.
      expect(
        const SaveClientRequestRequest(mediaIds: []).toJson(),
        {'mediaIds': <String>[]},
      );
    });
  });
}
