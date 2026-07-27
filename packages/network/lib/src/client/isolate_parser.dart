import 'dart:isolate';

/// Parses a JSON list off the UI isolate using [Isolate.run].
///
/// Use this from a repository when the list is large enough to jank the
/// main frame (e.g. > 100 items with non-trivial per-item work). The
/// [mapper] must be a top-level function or static method — Dart closes
/// over captured state, so lambdas that reference `this` or instance fields
/// will fail at the isolate boundary.
///
/// ```dart
/// final workers = await parseListInIsolate<WorkerDto>(
///   json['data'] as List<dynamic>,
///   WorkerDto.fromJsonDynamic,
/// );
/// ```
///
/// Rule of thumb — measure before switching. Small lists (< 50 items) pay
/// more in isolate-spawn cost than they gain in parse-time savings.
Future<List<T>> parseListInIsolate<T>(
  List<dynamic> data,
  T Function(dynamic item) mapper,
) => Isolate.run(() => data.map(mapper).toList(growable: false));

/// Parses an arbitrary JSON tree off the UI isolate.
///
/// [decoder] receives the raw decoded value (Map/List/scalar) and returns
/// the domain object. Same closure-safety rule as [parseListInIsolate].
Future<T> parseInIsolate<T>(
  Object? data,
  T Function(Object? data) decoder,
) => Isolate.run(() => decoder(data));
