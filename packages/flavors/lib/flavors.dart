/// Sand Flavors — Dev / QA / Stage / Production environment bundles.
///
/// Depends on sand_config for the configuration types.
/// Apps pick the right [Flavors] constant in their flavor entry-point and
/// register the [FlavorConfig] with GetIt.
library;

import 'package:flavors/flavors.dart' show FlavorConfig, Flavors;

export 'src/flavor_config.dart';
export 'src/flavors.dart';
