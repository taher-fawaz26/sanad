import 'package:core/src/domain/failures/failure.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

// Base class pattern: single abstract method is intentional by design.
// ignore: one_member_abstracts
abstract class UseCase<TResult, Params> {
  TaskEither<Failure, TResult> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
