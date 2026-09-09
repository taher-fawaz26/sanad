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
/// `packages/testing`'s `FakeBaseApiClient` answers by path but does not keep
/// the request, and the URL itself is part of this contract: an offer action
/// must be nested under its request, `limit` must respect the cap, and a draft
/// save must omit the fields the user has not filled in. Those are only
/// testable if the call is captured.
class RecordingApiClient implements BaseApiClient {
  RecordingApiClient({Map<String, TaskEither<Failure, dynamic>>? responses})
    : _responses = responses ?? {};

  final Map<String, TaskEither<Failure, dynamic>> _responses;

  /// Every call made, in order.
  final List<RecordedCall> calls = [];

  /// Used when no path-specific response is registered.
  TaskEither<Failure, dynamic> defaultResponse = TaskEither.left(
    const NetworkFailure(message: 'not configured'),
  );

  /// The most recent call.
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

/// A minimal but complete client-view request payload.
///
/// Defaults describe a live SUBMITTED request with one pending provider offer;
/// override to describe a draft, a booking, or anything else.
Map<String, dynamic> clientRequestJson({
  String id = 'req-1',
  String status = 'SUBMITTED',
  Object? serviceId = 'svc-1',
  Object? serviceName = 'Deep cleaning',
  Object? lat = 25.2048,
  Object? lng = 55.2708,
  Object? preferredAt = '2026-09-12T10:00:00+04:00',
  List<Map<String, dynamic>>? threads,
  List<Map<String, dynamic>>? matchedBranches,
  int offerCount = 1,
}) => {
  'id': id,
  'status': status,
  'serviceId': serviceId,
  'serviceName': serviceName,
  'categoryId': 'cat-1',
  'categoryName': 'Home Services',
  'lat': lat,
  'lng': lng,
  'addressLine': 'Villa 12, Street 4, Jumeirah 1',
  'areaName': 'Al Barsha 1',
  'preferredAt': preferredAt,
  'note': 'The kitchen tap has been leaking.',
  'attachments': [
    {
      'id': 'att-1',
      'mediaId': 'media-1',
      'url': 'https://cdn.example.com/leak.jpg',
      'mimeType': 'image/jpeg',
    },
  ],
  'submittedAt': '2026-09-11T08:00:00+04:00',
  'expiresAt': '2026-09-13T08:00:00+04:00',
  'scheduledAt': null,
  'disputeReason': null,
  'cancelReason': null,
  'offerCount': offerCount,
  'matchedBranches':
      matchedBranches ??
      [
        {
          'branchId': 'branch-1',
          'branchName': 'Al Barsha Branch',
          'providerId': 'prov-1',
          'providerName': 'Sparkle Cleaning LLC',
          'distanceKm': 4.2,
        },
      ],
  'threads': threads ?? [offerThreadJson()],
  'createdAt': '2026-09-11T07:00:00+04:00',
};

/// A negotiation thread with one pending provider offer by default.
Map<String, dynamic> offerThreadJson({
  String rootOfferId = 'offer-1',
  String providerId = 'prov-1',
  List<Map<String, dynamic>>? offers,
}) => {
  'rootOfferId': rootOfferId,
  'providerId': providerId,
  'providerName': 'Sparkle Cleaning LLC',
  'branchId': 'branch-1',
  'branchName': 'Al Barsha Branch',
  'distanceKm': 4.2,
  'completedJobs': 12,
  'offers': offers ?? [offerJson()],
};

/// One offer node.
Map<String, dynamic> offerJson({
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

/// The `{data, meta}` envelope every paginated SANAD endpoint answers with.
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
