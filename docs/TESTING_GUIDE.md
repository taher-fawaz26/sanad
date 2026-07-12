# Testing Guide

## Stack

| Tool | Purpose |
|------|---------|
| `flutter_test` / `test` | Unit and widget tests |
| `bloc_test` | BLoC event/state testing |
| `mocktail` | Mock generation |
| `packages/testing` | Shared fakes, helpers, matchers |

## Coverage Targets

- **80%** for `domain/` and `data/` layers per feature package
- No `test/` at app level — test packages, not apps

## Test Structure

Mirror source files:
```
lib/src/domain/usecases/login_usecase.dart
  → test/src/domain/usecases/login_usecase_test.dart
```

Golden tests: `test/goldens/`

## Unit Test (UseCase)

```dart
void main() {
  late FakeAuthRepository fakeRepo;
  late AuthLoginUseCase useCase;

  setUp(() {
    fakeRepo = FakeAuthRepository();
    useCase = AuthLoginUseCase(fakeRepo);
  });

  test('returns user on success', () async {
    fakeRepo.loginResult = TaskEither.right(testUser);
    final result = await useCase(LoginParams(email: 'a@b.com', password: 'pass')).run();
    expect(result.isRight(), true);
  });
}
```

## BLoC Test

```dart
blocTest<AuthBloc, AuthState>(
  'emits [Loading, Success] on login',
  build: () => AuthBloc(mockLoginUseCase),
  act: (bloc) => bloc.add(AuthLoginEvent(email: 'a@b.com', password: 'pass')),
  expect: () => [AuthLoginLoadingState(), AuthLoginSuccessState(testUser)],
);
```

## Widget Test

```dart
testWidgets('renders login form', (tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(360, 800),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.light(),
        home: const LoginPage(),
      ),
    ),
  );
  expect(find.byType(AppTextField), findsNWidgets(2));
});
```

## Running Tests

```bash
# Single package
cd packages/auth && flutter test

# All packages
melos test

# With coverage
melos coverage
```

## Fake Repositories

Use `packages/testing` for shared fakes:
```dart
import 'package:testing/testing.dart';
```

Create package-specific fakes in `packages/testing/lib/src/fakes/`.
