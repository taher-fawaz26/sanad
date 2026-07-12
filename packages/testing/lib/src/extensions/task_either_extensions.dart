import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Test extensions for [TaskEither].
extension TaskEitherX<L, R> on TaskEither<L, R> {
  /// Runs the task and returns the [Either] result.
  Future<Either<L, R>> toTest() => run();

  /// Asserts the result is [Right] and returns the value.
  Future<R> expectRight() async {
    final result = await run();
    expect(result.isRight(), isTrue, reason: 'Expected Right but got $result');
    return result.getOrElse((_) => throw StateError('unreachable'));
  }

  /// Asserts the result is [Left] and returns the failure.
  Future<L> expectLeft() async {
    final result = await run();
    expect(result.isLeft(), isTrue, reason: 'Expected Left but got $result');
    return result.fold((l) => l, (_) => throw StateError('unreachable'));
  }
}

/// Asserts a [Failure] is of type [T].
void expectFailure<T extends Failure>(Failure failure) {
  expect(failure, isA<T>());
}
