import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matchers for the [Failure] hierarchy.
abstract final class FailureMatchers {
  FailureMatchers._();

  /// Matches a [Failure] with the given [message].
  static Matcher hasMessage(String message) =>
      _FailureMessageMatcher(message);

  /// Matches a failure of type [T].
  static Matcher isFailureOf<T extends Failure>() => isA<T>();
}

class _FailureMessageMatcher extends Matcher {
  _FailureMessageMatcher(this.expected);

  final String expected;

  @override
  bool matches(dynamic item, Map matchState) =>
      item is Failure && item.message == expected;

  @override
  Description describe(Description description) =>
      description.add('Failure with message "$expected"');
}
