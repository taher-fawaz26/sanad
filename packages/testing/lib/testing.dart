/// Sand Testing — shared test utilities for the Sand monorepo.
///
/// Provides mocks, fakes, and BLoC helpers so individual packages
/// don't need to set up their own test infrastructure.
///
/// **Never import this package from non-test code.**
library;

// Fakes
export 'src/fakes/fake_user_entity.dart';
// Helpers
export 'src/helpers/bloc_test_helpers.dart';
// Mocks
export 'src/mocks/mock_auth_repository.dart';
export 'src/mocks/mock_user_repository.dart';
