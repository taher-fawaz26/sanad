import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:bloc_test/bloc_test.dart';
export 'package:mocktail/mocktail.dart';

/// Convenience re-exports + helpers so test files have a single import.

/// Wraps [blocTest] with the most common setup for BLoC unit tests.
/// Use when you need extra setup but still want readable test declarations.
void sandBlocTest<B extends BlocBase<S>, S>(
  String description, {
  required B Function() build,
  void Function()? setUp,
  S Function()? seed,
  dynamic Function(B)? act,
  Duration? wait,
  int skip = 0,
  dynamic Function()? expect,
  void Function(B)? verify,
  dynamic Function()? errors,
  void Function()? tearDown,
}) {
  blocTest<B, S>(
    description,
    build: build,
    setUp: setUp,
    seed: seed,
    act: act,
    wait: wait,
    skip: skip,
    expect: expect,
    verify: verify,
    errors: errors,
    tearDown: tearDown,
  );
}
