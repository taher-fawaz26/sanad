/// Sanad Shared UI — reusable application-level widgets composed from the
/// design system: scroll pages, slivers, headers, sections, state views,
/// scroll effects, animations, and builders.
///
/// This package must remain feature-independent: it depends only on
/// `design_system`, `app_assets`, `core`, and `localization`.
library;

// Animations
export 'src/animations/collapse_curve.dart';
export 'src/animations/collapse_progress_builder.dart';

// Builders
export 'src/builders/app_grid_builder.dart';
export 'src/builders/app_list_builder.dart';
export 'src/builders/app_scroll_section_builder.dart';

// Effects
export 'src/effects/avatar_collapse_effect.dart';
export 'src/effects/fade_title_effect.dart';

// Extensions
export 'src/extensions/scroll_collapse_extensions.dart';

// Headers
export 'src/headers/app_cover_header.dart';

// Loading — app-wide skeleton (reads) + blocking progress (mutations)
export 'src/loading/app_progress.dart';
export 'src/loading/app_skeleton_list.dart';
export 'src/loading/app_skeletonizer.dart';
export 'src/loading/mutation_listener.dart';

// Pagination
export 'src/pagination/paging_state_adapter.dart';
export 'src/pagination/sanad_paged_list.dart';

// Pages
export 'src/pages/app_nested_scroll_page.dart';
export 'src/pages/app_network_error_page.dart';
export 'src/pages/app_not_found_page.dart';
export 'src/pages/app_scroll_page.dart';
export 'src/pages/auth_screen_shell.dart';

// Popup menu
export 'src/popup_menu/popup_menu.dart';

// Sections
export 'src/sections/app_grid_section.dart';
export 'src/sections/app_list_section.dart';
export 'src/sections/app_section_card.dart';
export 'src/sections/app_section_header.dart';

// Slivers
export 'src/slivers/app_sliver_app_bar.dart';
export 'src/slivers/app_sliver_box.dart';
export 'src/slivers/app_sliver_divider.dart';
export 'src/slivers/app_sliver_gap.dart';
export 'src/slivers/app_sliver_grid.dart';
export 'src/slivers/app_sliver_list.dart';
export 'src/slivers/app_sliver_padding.dart';
export 'src/slivers/app_sliver_section.dart';
export 'src/slivers/app_sliver_state.dart';

// States
export 'src/states/app_empty_state.dart';
export 'src/states/app_empty_view.dart';
export 'src/states/app_error_state.dart';
export 'src/states/app_error_view.dart';
export 'src/states/app_loading_view.dart';

// Widgets
export 'src/widgets/app_add_schedule_day_sheet.dart';
export 'src/widgets/app_compliance_document_card.dart';
export 'src/widgets/app_confirmation_content.dart';
export 'src/widgets/app_enhance_with_ai_button.dart';
export 'src/widgets/app_entity_list_item.dart';
export 'src/widgets/app_inline_link_text.dart';
export 'src/widgets/app_list_card.dart';
export 'src/widgets/app_progress_dialog.dart';
export 'src/widgets/app_schedule_day_row.dart';
export 'src/widgets/app_select_sheet.dart';
export 'src/widgets/app_success_popover.dart';
export 'src/widgets/app_verified_pill.dart';
export 'src/widgets/main_nav_scroll_controller.dart';
export 'src/widgets/media_upload/media_upload_tile.dart';
export 'src/widgets/media_upload/media_upload_tile_data.dart';
export 'src/widgets/sheet_action_row.dart';
export 'src/widgets/show_confirmation_sheet.dart';
export 'src/widgets/nav_visibility.dart';
export 'src/widgets/nav_visibility_controller.dart';
