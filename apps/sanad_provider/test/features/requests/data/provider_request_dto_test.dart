import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_provider/src/features/requests/requests.dart';
import 'package:sanad_provider/src/features/requests/src/data/models/provider_request_dto.dart';

import '../support/provider_requests_fakes.dart';

void main() {
  group('ProviderRequestDto', () {
    test('round-trips a full payload', () {
      final json = providerRequestJson(
        myOffers: [providerOfferJson()],
        myOfferStatus: 'PENDING',
      );
      expect(ProviderRequestDto.fromJson(json).toJson(), json);
    });

    test('maps the provider view onto the entity', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(),
      ).toEntity();

      expect(entity.id, 'req-1');
      expect(entity.status, ClientRequestStatus.submitted);
      expect(entity.serviceName, 'Deep cleaning');
      expect(entity.areaName, 'Al Barsha 1');
      expect(entity.distanceKm, 4.2);
      expect(entity.remainingRebids, 2);
      expect(entity.attachments, hasLength(1));
    });

    test('carries no rival offers — only this provider is represented', () {
      // The provider payload has no `threads` array at all. If one is ever
      // added it must not be read here: a matched provider must never learn
      // what a competitor offered.
      final json = providerRequestJson();

      expect(json.containsKey('threads'), isFalse);
      expect(json.containsKey('matchedBranches'), isFalse);
      expect(json.containsKey('addressLine'), isFalse);
      expect(json.containsKey('lat'), isFalse);
      expect(json.containsKey('lng'), isFalse);
    });
  });

  group('the tab is server-derived', () {
    test('is read from the payload, never computed from the status', () {
      // The same SUBMITTED request is NEW to a provider that has not bid and
      // AWAITING_CLIENT to one that has. The status alone cannot tell them
      // apart, which is exactly why the server sends the tab.
      final untouched = ProviderRequestDto.fromJson(
        providerRequestJson(),
      ).toEntity();
      final bidOn = ProviderRequestDto.fromJson(
        providerRequestJson(
          tab: 'AWAITING_CLIENT',
          myOffers: [providerOfferJson()],
          myOfferStatus: 'PENDING',
        ),
      ).toEntity();

      expect(untouched.status, bidOn.status);
      expect(untouched.tab, ProviderRequestTab.newRequest);
      expect(bidOn.tab, ProviderRequestTab.awaitingClient);
    });

    test('every documented tab parses', () {
      const wire = [
        'NEW',
        'AWAITING_CLIENT',
        'YOUR_TURN',
        'SCHEDULED',
        'IN_PROGRESS',
        'TO_CONFIRM',
        'CLOSED',
      ];
      for (final raw in wire) {
        expect(ProviderRequestTab.fromApi(raw).apiValue, raw);
      }
    });

    test('an unknown tab degrades rather than throwing', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(tab: 'ARCHIVED'),
      ).toEntity();

      expect(entity.tab, ProviderRequestTab.unknown);
      expect(entity.id, 'req-1');
    });
  });

  group('contact gating', () {
    test('a locked block withholds every detail', () {
      final contact = ProviderRequestDto.fromJson(
        providerRequestJson(),
      ).toEntity().contact;

      expect(contact.isUnlocked, isFalse);
      expect(contact.clientName, isNull);
      expect(contact.clientPhone, isNull);
      expect(contact.addressLine, isNull);
      expect(contact.lat, isNull);
      expect(contact.lng, isNull);
      expect(contact.hasCoordinates, isFalse);
    });

    test('an unlocked block carries the details', () {
      final contact = ProviderRequestDto.fromJson(
        providerRequestJson(contact: unlockedContactJson()),
      ).toEntity().contact;

      expect(contact.isUnlocked, isTrue);
      expect(contact.clientPhone, '+971501234567');
      expect(contact.hasCoordinates, isTrue);
    });

    test('a missing contact block fails closed', () {
      // Fail closed on an ambiguity: absent means locked, never "assume the
      // provider has earned the details".
      final entity = ProviderRequestDto.fromJson({
        ...providerRequestJson(),
        'contact': null,
      }).toEntity();

      expect(entity.contact.isUnlocked, isFalse);
    });

    test(
      'unlocked is not inferable from the request or offer status',
      () {
        // A booked, in-progress request with an accepted offer still reads
        // locked if the server says so. Nothing in the UI may second-guess it.
        final entity = ProviderRequestDto.fromJson(
          providerRequestJson(
            status: 'IN_PROGRESS',
            tab: 'IN_PROGRESS',
            myOfferStatus: 'ACCEPTED',
            myOffers: [providerOfferJson(status: 'ACCEPTED')],
          ),
        ).toEntity();

        expect(entity.myOfferStatus, RequestOfferStatus.accepted);
        expect(entity.status, ClientRequestStatus.inProgress);
        expect(entity.contact.isUnlocked, isFalse);
      },
    );
  });

  group('own thread', () {
    test('a pending PROVIDER offer means we are waiting on the client', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(
          myOffers: [providerOfferJson()],
          myOfferStatus: 'PENDING',
        ),
      ).toEntity();

      expect(entity.isAwaitingClient, isTrue);
      expect(entity.isAwaitingProvider, isFalse);
      expect(entity.canWithdraw, isTrue);
      expect(entity.canSendOffer, isFalse);
    });

    test('a pending CLIENT counter means it is our turn', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(
          tab: 'YOUR_TURN',
          myOffers: [
            providerOfferJson(status: 'SUPERSEDED'),
            providerOfferJson(
              id: 'offer-1b',
              actorType: 'CLIENT',
              parentOfferId: 'offer-1',
            ),
          ],
          myOfferStatus: 'PENDING',
        ),
      ).toEntity();

      expect(entity.isAwaitingProvider, isTrue);
      expect(entity.isAwaitingClient, isFalse);
      // Countering is the answer here, not a fresh offer.
      expect(entity.canWithdraw, isFalse);
      expect(entity.canSendOffer, isFalse);
    });

    test('myOfferStatus stays null before the first bid', () {
      // Null is "has not bid", which must stay distinguishable from a value
      // this build could not parse.
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(),
      ).toEntity();

      expect(entity.myOfferStatus, isNull);
      expect(entity.myOffers, isEmpty);
      expect(entity.canSendOffer, isTrue);
    });
  });

  group('re-bid budget', () {
    test('an exhausted budget closes the offer affordance', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(
          remainingRebids: 0,
          myOffers: [providerOfferJson(status: 'REJECTED')],
          myOfferStatus: 'REJECTED',
        ),
      ).toEntity();

      expect(entity.remainingRebids, 0);
      expect(entity.canSendOffer, isFalse);
    });

    test('a remaining budget re-opens it after a rejection', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(
          myOffers: [providerOfferJson(status: 'REJECTED')],
          myOfferStatus: 'REJECTED',
        ),
      ).toEntity();

      expect(entity.canSendOffer, isTrue);
    });

    test('a closed request closes it regardless of budget', () {
      final entity = ProviderRequestDto.fromJson(
        providerRequestJson(
          status: 'EXPIRED',
          tab: 'CLOSED',
          remainingRebids: 5,
          myOffers: [providerOfferJson(status: 'EXPIRED')],
          myOfferStatus: 'EXPIRED',
        ),
      ).toEntity();

      expect(entity.canSendOffer, isFalse);
    });
  });

  group('counts and stats', () {
    test('counts map onto the tab enum', () {
      final counts = ProviderRequestCountsDto.fromJson(
        countsJson(),
      ).toEntity();

      expect(counts.of(ProviderRequestTab.newRequest), 7);
      expect(counts.of(ProviderRequestTab.yourTurn), 1);
      expect(counts.of(ProviderRequestTab.closed), 24);
    });

    test('an unrecognised tab key is dropped, not crashed on', () {
      final counts = ProviderRequestCountsDto.fromJson({
        ...countsJson(),
        'ARCHIVED': 3,
      }).toEntity();

      expect(counts.byTab.containsKey(ProviderRequestTab.unknown), isFalse);
      expect(counts.of(ProviderRequestTab.newRequest), 7);
    });

    test('a missing tab reads as zero', () {
      final counts = ProviderRequestCountsDto.fromJson(
        const {'NEW': 4},
      ).toEntity();

      expect(counts.of(ProviderRequestTab.scheduled), 0);
    });

    test('stats round-trip', () {
      final json = statsJson();
      final dto = ProviderRequestStatsDto.fromJson(json);

      expect(dto.toJson(), json);
      expect(dto.toEntity().completedThisMonth, 14);
    });
  });
}
