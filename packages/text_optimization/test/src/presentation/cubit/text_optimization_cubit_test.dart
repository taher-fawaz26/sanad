import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:text_optimization/text_optimization.dart';

class _MockTextOptimizationRepository extends Mock
    implements TextOptimizationRepository {}

void main() {
  late _MockTextOptimizationRepository repository;
  late OptimizeTextUseCase useCase;

  setUp(() {
    repository = _MockTextOptimizationRepository();
    useCase = OptimizeTextUseCase(repository);
  });

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'optimize emits loading then success with the trimmed optimized text',
    setUp: () {
      when(
        () => repository.optimize('a rough draft'),
      ).thenAnswer((_) => TaskEither.right('A polished draft.'));
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) => cubit.optimize('a rough draft'),
    expect: () => [
      const TextOptimizationState(status: RequestStatus.loading),
      const TextOptimizationState(
        status: RequestStatus.success,
        optimizedText: 'A polished draft.',
      ),
    ],
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'optimize trims the request text before sending it',
    setUp: () {
      when(
        () => repository.optimize('untrimmed'),
      ).thenAnswer((_) => TaskEither.right('ok'));
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) => cubit.optimize('  untrimmed  '),
    verify: (_) {
      verify(() => repository.optimize('untrimmed')).called(1);
    },
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'empty input fails immediately without calling the repository',
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) => cubit.optimize('   '),
    expect: () => [
      isA<TextOptimizationState>()
          .having((s) => s.status, 'status', RequestStatus.failure)
          .having(
            (s) => s.failure?.message,
            'failure.message',
            'common.enhance_with_ai_empty_input_error',
          ),
    ],
    verify: (_) {
      verifyNever(() => repository.optimize(any()));
    },
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'an empty optimized result fails instead of replacing the text',
    setUp: () {
      when(
        () => repository.optimize('input'),
      ).thenAnswer((_) => TaskEither.right('   '));
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) => cubit.optimize('input'),
    expect: () => [
      const TextOptimizationState(status: RequestStatus.loading),
      isA<TextOptimizationState>()
          .having((s) => s.status, 'status', RequestStatus.failure)
          .having((s) => s.optimizedText, 'optimizedText', isNull)
          .having(
            (s) => s.failure?.message,
            'failure.message',
            'common.enhance_with_ai_empty_result_error',
          ),
    ],
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'a repository failure always lands on a terminal failure state',
    setUp: () {
      when(() => repository.optimize('input')).thenAnswer(
        (_) => TaskEither.left(
          const ServerFailure(message: 'boom', code: '500'),
        ),
      );
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) => cubit.optimize('input'),
    expect: () => [
      const TextOptimizationState(status: RequestStatus.loading),
      isA<TextOptimizationState>()
          .having((s) => s.status, 'status', RequestStatus.failure)
          .having(
            (s) => s.failure,
            'failure',
            const ServerFailure(message: 'boom', code: '500'),
          ),
    ],
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'a second optimize call is dropped while one is already in flight',
    setUp: () {
      when(() => repository.optimize('input')).thenAnswer(
        (_) => TaskEither(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return const Right('done');
        }),
      );
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) {
      cubit
        ..optimize('input')
        ..optimize('input');
    },
    wait: const Duration(milliseconds: 30),
    verify: (_) {
      verify(() => repository.optimize('input')).called(1);
    },
  );

  blocTest<TextOptimizationCubit, TextOptimizationState>(
    'acknowledge resets a consumed success back to initial',
    setUp: () {
      when(
        () => repository.optimize('input'),
      ).thenAnswer((_) => TaskEither.right('done'));
    },
    build: () => TextOptimizationCubit(useCase),
    act: (cubit) async {
      await cubit.optimize('input');
      cubit.acknowledge();
    },
    expect: () => [
      const TextOptimizationState(status: RequestStatus.loading),
      const TextOptimizationState(
        status: RequestStatus.success,
        optimizedText: 'done',
      ),
      const TextOptimizationState(),
    ],
  );
}
