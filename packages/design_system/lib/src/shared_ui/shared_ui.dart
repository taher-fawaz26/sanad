/// Sanad design system — higher-level composed UI barrel export.
///
/// `shared_ui/` holds domain-agnostic, composed UI built from `components/`
/// primitives and design tokens (e.g. empty states, loading, retry views).
/// Feature widgets never belong here — see the Component Ownership Policy
/// in `docs/ARCHITECTURE.md`.
library;

export 'app_confirmation_content.dart';
export 'app_empty_state.dart';
export 'app_entity_list_item.dart';
export 'app_network_error_page.dart';
export 'app_progress_dialog.dart';
export 'app_success_popover.dart';
