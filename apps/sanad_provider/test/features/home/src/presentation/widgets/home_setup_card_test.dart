import 'package:core/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sanad_provider/src/features/home/src/presentation/widgets/home_setup_card.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:sanad_provider/src/features/organization_settings/src/data/cache/provider_completion_cache_store.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/usecases/get_provider_completion_usecase.dart';
import 'package:testing/testing.dart';

class _MockGetCompletion extends Mock implements GetProviderCompletionUseCase {}

const _completion = ProviderCompletionEntity(
  percentage: 75,
  requiredCompleted: 3,
  requiredTotal: 4,
  visibleToCustomers: false,
  items: [],
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  await pumpDsWidget(tester, SingleChildScrollView(child: child));
}

void main() {
  late _MockGetCompletion getCompletion;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    getCompletion = _MockGetCompletion();
  });

  ProviderCompletionBloc buildBloc() => ProviderCompletionBloc(
    getCompletion: getCompletion,
    cacheStore: ProviderCompletionCacheStore(),
    resolveLanguageCode: () => 'en',
  )..add(const ProviderCompletionLoaded());

  testWidgets('renders the backend percentage and steps summary', (
    tester,
  ) async {
    when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(_completion));
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await _pump(
      tester,
      BlocProvider<ProviderCompletionBloc>.value(
        value: bloc,
        child: HomeSetupCard(onCompleteSetup: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('home.setup_title'), findsOneWidget);
    expect(find.text('home.setup_steps_summary'), findsOneWidget);
    expect(find.text('home.complete_setup'), findsOneWidget);
  });

  testWidgets('tapping Complete Setup invokes the callback', (tester) async {
    when(
      () => getCompletion(any()),
    ).thenAnswer((_) => TaskEither.right(_completion));
    final bloc = buildBloc();
    addTearDown(bloc.close);
    var tapped = false;

    await _pump(
      tester,
      BlocProvider<ProviderCompletionBloc>.value(
        value: bloc,
        child: HomeSetupCard(onCompleteSetup: () => tapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('home.complete_setup'));
    await tester.tap(find.text('home.complete_setup'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows a compact error state instead of the CTA on failure', (
    tester,
  ) async {
    when(() => getCompletion(any())).thenAnswer(
      (_) => TaskEither.left(const NetworkFailure(message: 'boom')),
    );
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await _pump(
      tester,
      BlocProvider<ProviderCompletionBloc>.value(
        value: bloc,
        child: HomeSetupCard(onCompleteSetup: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home.complete_setup'), findsNothing);
  });
}
