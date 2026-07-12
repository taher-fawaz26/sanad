/// Sand Testing — shared test utilities for the Sand monorepo.
///
/// Provides mocks, fakes, and BLoC helpers so individual packages
/// don't need to set up their own test infrastructure.
///
/// **Never import this package from non-test code.**
library;

// Extensions
export 'src/extensions/task_either_extensions.dart';
// Fakes
export 'src/fakes/fake_base_api_client.dart';
export 'src/fakes/fake_user_entity.dart';
// Helpers
export 'src/helpers/bloc_test_helpers.dart';
export 'src/helpers/widget_test_helpers.dart';
// Matchers
export 'src/matchers/failure_matchers.dart';
// Mocks
export 'src/mocks/mock_auth_repository.dart';
export 'src/mocks/mock_user_repository.dart';
