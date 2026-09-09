import 'dart:math';

/// Mints an idempotency key for one interaction result.
///
/// Deliberately **not** `core`'s `generateUuidV4`: this package has no `core`
/// dependency and gains nothing from one — it is a presentation library, and
/// the whole point of its small dependency surface is that "what can an AI
/// payload reach?" has a short answer. The id needs to be unique within a
/// conversation so a retry is recognisable as the same answer; it is not a
/// database key and nothing parses it.
///
/// The time prefix is not for ordering — it is what makes two ids minted in
/// the same millisecond on the same device still differ if the random half
/// ever collided.
String mintAiUiInteractionId() {
  final random = Random.secure();
  final suffix = List<int>.generate(
    8,
    (_) => random.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return 'int_${DateTime.now().microsecondsSinceEpoch}_$suffix';
}
