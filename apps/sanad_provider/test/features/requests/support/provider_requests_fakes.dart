import 'dart:async';

import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';

/// One captured outbound call.
class RecordedCall {
  const RecordedCall({
    required this.path,
    required this.method,
    this.query,
    this.body,
  });

  final String path;
  final RequestMethod method;
  final Map<String, dynamic>? query;
  final dynamic body;
}

/// A [BaseApiClient] that records what was sent.
///
/// The URL and query are part of the provider contract — `tab` must be sent
/// server-side, an offer action is addressed by offer id, a job action by
/// request id — so the call itself has to be inspectable.
class RecordingApiClient implements BaseApiClient {
  final List<RecordedCall> calls = [];
  final Map<String, TaskEither<Failure, dynamic>> _responses = {};

  TaskEither<Failure, dynamic> defaultResponse = TaskEither.left(
    const NetworkFailure(message: 'not configured'),
  );

  RecordedCall get lastCall => calls.last;

  /// Registers [response] for [path].
  void stub(String path, TaskEither<Failure, dynamic> response) =>
      _responses[path] = response;

  @override
  TaskEither<Failure, T> request<T>({
    required String path,
    required RequestMethod method,
    required FutureOr<T> Function(dynamic data) parser,
    Map<String, dynamic>? query,
    dynamic body,
    bool authRequired = true,
  }) {
    calls.add(
      RecordedCall(path: path, method: method, query: query, body: body),
    );
    final handler = _responses[path] ?? defaultResponse;
    return TaskEither(() async {
      final result = await handler.run();
      return result.match(left, (data) async => right(await parser(data)));
    });
  }
}

/// A provider-view request payload.
///
/// Defaults describe a matched request this provider has not bid on yet, with
/// the contact block locked — the state most of the privacy rules are about.
Map<String, dynamic> providerRequestJson({
  String id = 'req-1',
  String status = 'SUBMITTED',
  String tab = 'NEW',
  List<Map<String, dynamic>>? myOffers,
  Object? myOfferStatus,
  int remainingRebids = 2,
  Map<String, dynamic>? contact,
  Object? disputeReason,
}) => {
  'id': id,
  'status': status,
  'tab': tab,
  'serviceName': 'Deep cleaning',
  'categoryName': 'Home Services',
  'areaName': 'Al Barsha 1',
  'preferredAt': '2026-09-12T10:00:00+04:00',
  'note': 'The kitchen tap has been leaking.',
  'attachments': [
    {
      'id': 'att-1',
      'mediaId': 'media-1',
      'url': 'https://cdn.example.com/leak.jpg',
      'mimeType': 'image/jpeg',
    },
  ],
  'distanceKm': 4.2,
  'branchId': 'branch-1',
  'branchName': 'Al Barsha Branch',
  'myOfferStatus': myOfferStatus,
  'myOffers': myOffers ?? const <Map<String, dynamic>>[],
  'remainingRebids': remainingRebids,
  'contact': contact ?? lockedContactJson(),
  'disputeReason': disputeReason,
  'createdAt': '2026-09-11T07:00:00+04:00',
};

/// A contact block with everything withheld — the pre-booking state.
Map<String, dynamic> lockedContactJson() => {
  'unlocked': false,
  'clientName': null,
  'clientPhone': null,
  'addressLine': null,
  'lat': null,
  'lng': null,
};

/// A contact block the server has unlocked.
Map<String, dynamic> unlockedContactJson() => {
  'unlocked': true,
  'clientName': 'Aisha Khan',
  'clientPhone': '+971501234567',
  'addressLine': 'Villa 12, Street 4, Jumeirah 1',
  'lat': 25.2048,
  'lng': 55.2708,
};

/// One offer node in this provider's own thread.
Map<String, dynamic> providerOfferJson({
  String id = 'offer-1',
  String actorType = 'PROVIDER',
  String status = 'PENDING',
  String proposedAt = '2026-09-12T11:00:00+04:00',
  Object? parentOfferId,
}) => {
  'id': id,
  'actorType': actorType,
  'status': status,
  'proposedAt': proposedAt,
  'note': 'We can bring the parts with us.',
  'parentOfferId': parentOfferId,
  'createdAt': '2026-09-11T09:00:00+04:00',
};

/// The `{data, meta}` envelope.
Map<String, dynamic> pageJson(
  List<Map<String, dynamic>> items, {
  int totalPages = 1,
  int currentPage = 1,
}) => {
  'data': items,
  'meta': {
    'totalItems': items.length,
    'itemCount': items.length,
    'itemsPerPage': 20,
    'totalPages': totalPages,
    'currentPage': currentPage,
  },
};

/// Badge counts, keyed by wire tab name.
Map<String, dynamic> countsJson() => {
  'NEW': 7,
  'AWAITING_CLIENT': 3,
  'YOUR_TURN': 1,
  'SCHEDULED': 2,
  'IN_PROGRESS': 0,
  'TO_CONFIRM': 1,
  'CLOSED': 24,
};

/// The four headline numbers.
Map<String, dynamic> statsJson() => {
  'needsYourOffer': 7,
  'awaitingClient': 3,
  'scheduledToday': 2,
  'completedThisMonth': 14,
};
