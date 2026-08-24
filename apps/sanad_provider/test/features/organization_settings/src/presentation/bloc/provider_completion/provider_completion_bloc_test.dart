import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/cache/provider_completion_cache_store.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/bloc/provider_completion/provider_completion_bloc.dart';

class _MockGetCompletion extends Mock implements GetProviderCompletionUseCase {}

void main() {
  late _MockGetCompletion getCompletion;
  late ProviderCompletionCacheStore cacheStore;
  var languageCode = 'en';

  const completion = ProviderCompletionEntity(
    percentage: 43,
    requiredCompleted: 3,
    requiredTotal: 7,
    visibleToCustomers: false,
    items: [
      ProviderCompletionItemEntity(
        id: ProviderCompletionItemId.category,
        label: 'Category',
        completed: true,
        required: true,
      ),
    ],
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getCompletion = _MockGetCompletion();
    cacheStore = ProviderCompletionCacheStore();
    languageCode = 'en';
  });

  ProviderCompletionBloc buildBloc() => ProviderCompletionBloc(
    getCompletion: getCompletion,
    cacheStore: cacheStore,
    resolveLanguageCode: () => languageCode,
  );

  blocTest<ProviderCompletionBloc, ProviderCompletionState>(
    'Loaded: emits loading then success with the completion entity',
    setUp: () => when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(completion)),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderCompletionLoaded()),
    expect: () => [
      const ProviderCompletionState(status: RequestStatus.loading),
      const ProviderCompletionState(
        status: RequestStatus.success,
        completion: completion,
      ),
    ],
  );

  blocTest<ProviderCompletionBloc, ProviderCompletionState>(
    'Loaded: emits loading then failure on error, never fabricates data',
    setUp: () => when(() => getCompletion(any())).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    ),
    build: buildBloc,
    act: (bloc) => bloc.add(const ProviderCompletionLoaded()),
    verify: (bloc) {
      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.completion, isNull);
      expect(bloc.state.failure, isA<NetworkFailure>());
      expect(bloc.state.hasError, isTrue);
    },
  );

  blocTest<ProviderCompletionBloc, ProviderCompletionState>(
    'Loaded twice within TTL serves the cache and skips the second call',
    setUp: () => when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(completion)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderCompletionLoaded());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProviderCompletionLoaded());
    },
    verify: (_) => verify(() => getCompletion(any())).called(1),
  );

  blocTest<ProviderCompletionBloc, ProviderCompletionState>(
    'Refreshed invalidates the cache and always re-fetches',
    setUp: () => when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(completion)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderCompletionLoaded());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ProviderCompletionRefreshed());
    },
    verify: (_) => verify(() => getCompletion(any())).called(2),
  );

  blocTest<ProviderCompletionBloc, ProviderCompletionState>(
    'a different locale is a distinct cache entry (AR never serves EN)',
    setUp: () => when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(completion)),
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ProviderCompletionLoaded()); // en
      await Future<void>.delayed(Duration.zero);
      languageCode = 'ar';
      bloc.add(const ProviderCompletionLoaded()); // ar → miss → fetch
    },
    verify: (_) => verify(() => getCompletion(any())).called(2),
  );
}
