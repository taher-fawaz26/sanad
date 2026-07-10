import 'package:get_it/get_it.dart';

/// Global service locator — thin wrapper around [GetIt.I].
///
/// All packages register their own dependencies via extension methods on [sl].
/// Apps call `sl.registerX(...)` in their bootstrap phase.
final GetIt sl = GetIt.instance;
