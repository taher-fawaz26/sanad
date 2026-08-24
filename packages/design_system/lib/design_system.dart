/// Sanad Design System — theme, colors, typography, tokens, and UI components.
library;

// Re-exported so a feature can hold/thread a `SlidableController` (e.g. into
// `AppSwipeActionHint`/`AppSwipeActions.controller`) without depending on
// `flutter_slidable` directly. Deliberately narrow — `Slidable`/`ActionPane`/
// `SlidableAction` stay internal to `AppSwipeActions`.
export 'package:flutter_slidable/flutter_slidable.dart' show SlidableController;
// Re-exported so consumers can build `FaIcon`s from a `BackendIconResolver`
// result without adding their own `font_awesome_flutter` dependency.
export 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Theme BLoC — ThemeBloc, ThemeState, ThemeEvent, AppThemeMode
export 'src/blocs/theme/theme_bloc.dart';
// Components
export 'src/components/app_action_sheet.dart';
export 'src/components/app_alert.dart';
export 'src/components/app_avatar.dart';
export 'src/components/app_avatar_stack.dart';
export 'src/components/app_backdrop.dart';
export 'src/components/app_button.dart';
export 'src/components/app_button_group.dart';
export 'src/components/app_checkbox.dart';
export 'src/components/app_chip.dart';
export 'src/components/app_close_icon.dart';
export 'src/components/app_date_picker.dart';
export 'src/components/app_divider.dart';
export 'src/components/app_feature_icon.dart';
export 'src/components/app_field_action.dart';
export 'src/components/app_floating_action_button.dart';
export 'src/components/app_grouped_key_value_list.dart';
export 'src/components/app_image_placeholder.dart';
export 'src/components/app_key_value_card.dart';
export 'src/components/app_map_link_card.dart';
export 'src/components/app_network_image.dart';
export 'src/components/app_notification_icon.dart';
export 'src/components/app_field_label.dart';
export 'src/components/app_field_trailing.dart';
export 'src/components/app_phone_field.dart';
export 'src/components/app_fill_remaining_scrollable.dart';
export 'src/components/app_loading_indicator.dart';
export 'src/components/app_refresh_indicator.dart';
export 'src/components/app_select_field.dart';
export 'src/components/app_stat_card.dart';
export 'src/components/app_svg_picture.dart';
export 'src/components/app_wizard_step_indicator.dart';
export 'src/components/app_icon_button.dart';
export 'src/components/app_large_nav_bar.dart';
export 'src/components/app_nav_bar.dart';
export 'src/components/app_notification_badge.dart';
export 'src/components/app_page_indicator.dart';
export 'src/components/app_popover.dart';
export 'src/components/app_otp_field.dart';
export 'src/components/app_progress_bar.dart';
export 'src/components/app_radio.dart';
export 'src/components/app_radio_tile.dart';
export 'src/components/app_search_field.dart';
export 'src/components/app_section.dart';
export 'src/components/app_segmented_control.dart';
export 'src/components/app_shimmer.dart';
export 'src/components/app_slider.dart';
export 'src/components/app_snackbar.dart';
export 'src/components/app_status_badge.dart';
export 'src/components/app_stepper.dart';
export 'src/components/app_swipe_action_hint.dart';
export 'src/components/app_swipe_actions.dart';
export 'src/components/app_switch.dart';
export 'src/components/app_table_cell.dart';
export 'src/components/app_table_row.dart';
export 'src/components/app_text_field.dart';
export 'src/components/app_verified_badge.dart';
// Dimensions & spacing
export 'src/dimensions/app_radius.dart';
export 'src/dimensions/responsive_dimension.dart';
// Icons
export 'src/icons/backend_icon_resolver.dart';
export 'src/spacing/responsive_spacing.dart';
// Theme
export 'src/theme/app_font.dart';
export 'src/theme/app_theme.dart';
// Colors
//
// Only the public color API is exported here. `LightColors`, `DarkColors`,
// `ColorScale`, and the raw Figma `*Palette` ramps are theme-assembly
// internals with zero usage outside this package — access colors via
// `context.appColors` instead. `field_tokens.dart` (`FieldTokens`) IS
// exported below: it has real external consumers (e.g. `AppOtpField` in
// `packages/otp`).
export 'src/theme/colors/app_colors.dart';
export 'src/theme/colors/field_tokens.dart';
// Tokens — single barrel; see src/theme/tokens.dart for the full re-export
// list (avoids duplicating ~30 individual export lines here).
export 'src/theme/tokens.dart';
// Typography
export 'src/theme/typography/app_typography.dart';
export 'src/theme/typography/arabic_type_scale.dart';
export 'src/theme/typography/device_class.dart';
export 'src/theme/typography/responsive_font_scale.dart';
export 'src/theme/typography/type_scale.dart';
