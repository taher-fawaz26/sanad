# Testing Guide

Complete testing architecture for the Sanad platform — every test category, every layer.

**Shared utilities:** `packages/testing`

---

## Stack

| Tool | Purpose |
|------|---------|
| `flutter_test` / `test` | Unit and widget tests |
| `bloc_test` | BLoC event/state testing |
| `mocktail` | Mock generation |
| `golden_toolkit` | Golden snapshot tests (`design_system` only) |
| `packages/testing` | Shared fakes, mocks, helpers, matchers |

---

## Test Hierarchy

| Category | Layer | Framework | Scope |
|----------|-------|-----------|-------|
| Unit — UseCase | `domain/` | `test` + `mocktail` | Pure logic, no Flutter |
| Unit — Entity / Value Object | `domain/` | `test` | Pure Dart |
| Unit — Repository | `data/` | `test` + `mocktail` | Mocked datasource |
| Unit — DataSource | `data/` | `test` + `mocktail` | Mocked `BaseApiClient` |
| BLoC | `presentation/bloc/` | `bloc_test` + `mocktail` | Mocked UseCases |
| Widget | `presentation/pages/` + `widgets/` | `flutter_test` + `mocktail` | Pumped with theme + DI |
| Golden | `design_system/components/` | `flutter_test` + `golden_toolkit` | Snapshot regression |
| Integration | Full feature flow | `integration_test` + Fakes | E2E against fakes |

---

## Test Folder Structure

```
packages/features/<feature>/test/
├── src/
│   ├── data/
│   │   ├── datasources/
│   │   │   └── <feature>_remote_datasource_test.dart
│   │   ├── models/
│   │   │   └── <feature>_response_model_test.dart
│   │   └── repositories/
│   │       └── <feature>_repository_impl_test.dart
│   ├── domain/
│   │   └── usecases/
│   │       └── <action>_usecase_test.dart
│   └── presentation/
│       └── bloc/
│           └── <feature>_bloc_test.dart
└── goldens/                  # design_system only
    └── <component>_test.dart
```

Mirror source files: `lib/src/x.dart` → `test/src/x_test.dart`

---

## Naming Conventions

| Artifact | Convention | Example |
|----------|-----------|---------|
| Test file | `<source_file>_test.dart` | `login_usecase_test.dart` |
| `group` | Class or method under test | `group('AuthLoginUseCase', ...)` |
| `test` / `blocTest` | Behaviour in plain English | `'returns UserEntity when credentials are valid'` |
| Mock class | `Mock<Interface>` | `MockAuthRepository` |
| Fake class | `Fake<Interface>` | `FakeAuthRepository` |
| Test data class | `<Feature>TestData` | `AuthTestData.validLoginParams` |

---

## Mock Strategy (mocktail)

Use mocks for **external dependencies** whose behaviour varies per test:

```dart
class MockAuthRepository extends Mock implements AuthRepository {}

setUp(() => registerFallbackValue(const LoginParams(...)));
when(() => mock.login(any())).thenReturn(TaskEither.right(testUser));
```

**Rules:**
- Shared mocks live in `packages/testing/lib/src/mocks/` if used by 2+ packages
- Package-local mocks stay in that package's `test/` folder
- Never mock a concrete class — mock the abstract interface only

---

## Fake Strategy

Use **Fake implementations** (not mocktail) for repository fakes in widget/integration tests:

```dart
class FakeOrdersRepository implements OrdersRepository {
  TaskEither<Failure, List<OrderEntity>> fetchResult =
      TaskEither.right([]);

  @override
  TaskEither<Failure, List<OrderEntity>> fetchOrders() => fetchResult;
}
```

**Rules:**
- Fakes are stateful; mocks are behavioural
- Shared fakes go in `packages/testing/lib/src/fakes/`
- Integration tests use fakes; unit tests use mocks

---

## Unit Test (UseCase)

```dart
void main() {
  late MockAuthRepository mockRepo;
  late AuthLoginUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = AuthLoginUseCase(mockRepo);
  });

  test('returns LoginResponseEntity when credentials are valid', () async {
    when(() => mockRepo.login(any())).thenReturn(
      TaskEither.right(testLoginResponse),
    );
    final result = await useCase(
      const LoginParams(identifier: 'a@b.com', password: 'pass'),
    ).run();
    expect(result.isRight(), isTrue);
  });
}
```

---

## BLoC Test

```dart
sandBlocTest<AuthBloc, AuthState>(
  'emits [Loading, Success] when login succeeds',
  build: () {
    when(() => mockLoginUseCase(any())).thenReturn(
      TaskEither.right(testLoginResponse),
    );
    return AuthBloc(loginUseCase: mockLoginUseCase, ...);
  },
  act: (bloc) => bloc.add(const AuthLoginEvent(...)),
  expect: () => [
    const AuthLoginLoadingState(),
    AuthLoginSuccessState(testLoginResponse),
  ],
);
```

---

## Widget Test

```dart
testWidgets('renders empty state when orders list is empty', (tester) async {
  await pumpDsWidget(
    tester,
    BlocProvider<OrdersBloc>(
      create: (_) => OrdersBloc(fetchOrdersUseCase: fakeUseCase)
        ..add(const FetchOrdersEvent()),
      child: const OrdersPage(),
    ),
  );
  await tester.pump();
  expect(find.byType(AppGenericEmptyState), findsOneWidget);
});
```

---

## Golden Test (design_system only)

```dart
testWidgets('AppButton renders correctly in light mode', (tester) async {
  await pumpDsWidget(tester, const AppButton(label: 'Confirm', onPressed: null));
  await expectLater(
    find.byType(AppButton),
    matchesGoldenFile('goldens/app_button_light.png'),
  );
});
```

Update goldens: `flutter test --update-goldens`

---

## Integration Test

Integration tests live in `apps/<app>/integration_test/`:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('full login flow succeeds', (tester) async {
    await configureDependencies();
    app.main();
    await tester.pumpAndSettle();
    // ...
  });
}
```

---

## Coverage Rules

| Layer | Minimum | CI blocking? |
|-------|---------|-------------|
| `domain/usecases/` | 100% | Yes |
| `data/repositories/` | 80% | Yes |
| `data/datasources/` | 80% | Yes |
| `data/models/` (fromJson/toEntity) | 90% | Yes |
| `presentation/bloc/` | 80% | Yes |
| `presentation/pages/` | 0% (excluded) | No |
| `presentation/widgets/` | 0% (excluded) | No |

---

## Shared Test Helpers (`packages/testing`)

| Helper | Purpose |
|--------|---------|
| `pumpDsWidget(tester, widget)` | Pumps with `ScreenUtilInit` + `AppTheme.light()` |
| `pumpDsWidgetDark(tester, widget)` | Same but dark theme |
| `buildTestApp(home)` | Returns configured `MaterialApp` |
| `FakeBaseApiClient` | In-memory `BaseApiClient` |
| `FailureMatchers` | Custom matchers for `Failure` hierarchy |
| `TaskEitherX.toTest()` | Runs `TaskEither` and asserts right/left |
| `sandBlocTest` | Convenience wrapper around `blocTest` |

---

## Running Tests

```bash
# Single package
cd packages/features/auth && flutter test

# All packages
melos test

# With coverage
melos coverage

# Update goldens (design_system)
cd packages/design_system && flutter test --update-goldens
```

---

## CI Integration

PR checks run `melos test` with coverage. Domain and data layers must meet coverage thresholds per package.

---

## Decision Tree: Mock vs Fake

```
Is the dependency behaviour different per test case?
  YES → mocktail Mock
  NO, but need realistic state for widget/integration test?
    YES → Fake implementation
    NO → mocktail Mock
```
