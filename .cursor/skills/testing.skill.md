---
name: testing
description: Write tests — unit, BLoC, widget, golden; use packages/testing utilities
---

# Testing Skill

Write tests following Sanad conventions.

## Unit Test (UseCase)

```dart
void main() {
  late FakeFeatureRepository fakeRepo;
  late GetDataUseCase useCase;

  setUp(() {
    fakeRepo = FakeFeatureRepository();
    useCase = GetDataUseCase(fakeRepo);
  });

  test('returns data on success', () async {
    fakeRepo.result = TaskEither.right(testEntity);
    final result = await useCase(params).run();
    expect(result.isRight(), true);
  });

  test('returns failure on error', () async {
    fakeRepo.result = TaskEither.left(NetworkFailure());
    final result = await useCase(params).run();
    expect(result.isLeft(), true);
  });
}
```

## BLoC Test

```dart
blocTest<FeatureBloc, FeatureState>(
  'emits [Loading, Success] on fetch',
  build: () => FeatureBloc(mockUseCase),
  act: (bloc) => bloc.add(const FeatureFetchEvent()),
  expect: () => [
    const FeatureLoadingState(),
    FeatureSuccessState(testEntity),
  ],
);
```

## Widget Test

```dart
testWidgets('renders title', (tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: const FeaturePage(),
      ),
    ),
  );
  expect(find.text('feature.title'.tr()), findsOneWidget);
});
```

## Golden Test

```dart
testWidgets('golden test', (tester) async {
  await tester.pumpWidget(buildTestApp(const FeaturePage()));
  await expectLater(find.byType(FeaturePage), matchesGoldenFile('goldens/feature_page.png'));
});
```

## Coverage Target

80% for `domain/` and `data/` layers per feature package.
