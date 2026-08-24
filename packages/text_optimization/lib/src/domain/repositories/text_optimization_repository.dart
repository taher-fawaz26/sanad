import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// Domain contract for the "Enhance with AI" text-optimization flow.
///
/// Knows nothing of HTTP, JSON, Dio, or the third-party host — that all
/// stays behind the data layer's remote data source.
// Base class pattern: single abstract method is intentional by design.
// ignore: one_member_abstracts
abstract class TextOptimizationRepository {
  TaskEither<Failure, String> optimize(String text);
}
