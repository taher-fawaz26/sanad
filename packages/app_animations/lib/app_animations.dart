/// Sanad Animation Design System — the single home for motion tokens,
/// reusable effects/patterns, page transitions, and the Lottie wrapper.
///
/// This package deliberately does NOT re-export `flutter_animate`,
/// `animations`, or `lottie` — consumers use the semantic API below, never
/// the underlying packages directly (see `dep_rules.yaml`'s
/// `lottie_allowed_packages` / `flutter_animate_allowed_packages` /
/// `animations_allowed_packages`, enforced by `scan_imports.dart`).
///
/// See the package README for the full usage guide, motion-token reference,
/// reduced-motion contract, and performance rules.
library;

export 'src/diagnostics/animation_debug.dart';
export 'src/effects/app_effects.dart';
export 'src/lottie/app_lottie.dart';
export 'src/lottie/app_lottie_asset.dart';
export 'src/motion/app_motion.dart';
export 'src/motion/app_motion_curve.dart';
export 'src/motion/app_motion_duration.dart';
export 'src/patterns/app_ambient_gradient.dart';
export 'src/patterns/app_breathe.dart';
export 'src/patterns/app_button_feedback.dart';
export 'src/patterns/app_list_entrance.dart';
export 'src/patterns/app_page_entrance.dart';
export 'src/patterns/app_staggered_column.dart';
export 'src/patterns/app_state_transition.dart';
export 'src/patterns/app_swipe_action_motion.dart';
export 'src/transitions/app_page_transitions.dart';
