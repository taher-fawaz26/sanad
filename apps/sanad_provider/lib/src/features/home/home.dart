/// Provider-only home dashboard — statistic cards driven by backend Font
/// Awesome icons via `BackendIconResolver` (see `design_system`).
///
/// Register [HomeModule] in the provider [ModuleRegistry]. The `/home` route
/// itself stays hand-wired in the provider bottom-nav shell.
library;

export 'home_page.dart';
export 'src/module/home_module.dart';
